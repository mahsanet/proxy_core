package libxray

import (
	"context"
	"errors"
	"fmt"
	"net"
	"net/http"
	"segment/global"
	log "segment/libxray/slog"
	"segment/proxycoreproto"
	"sync"
	"time"

	xraynet "github.com/GFW-knocker/Xray-core/common/net"
	"github.com/GFW-knocker/Xray-core/core"
	_ "github.com/GFW-knocker/Xray-core/main/distro/all"
)

// XrayService encapsulates the core instance and server lifecycle management.
type XrayService struct {
	instance  *core.Instance // Holds the Xray core instance
	mutex     sync.Mutex     // Ensures thread-safe access to the instance
	isRunning bool           // Tracks if the server is running
	readyChan chan struct{}  // Channel to signal when service is fully ready
}

// global instance of XrayService
var (
	xrayService *XrayService
	once        sync.Once
)

// GetXrayService returns the singleton instance of XrayService.
func GetXrayService() *XrayService {
	once.Do(func() {
		xrayService = &XrayService{
			readyChan: make(chan struct{}),
		}
	})
	return xrayService
}
func (xs *XrayService) CoreName() string {
	return "xray"
}

// Start initializes and starts the Xray service using the provided configuration.
// It manages memory and environment settings, with optional context support for cancellation.
func (xs *XrayService) Start(ctx context.Context, opts global.StartOptions) error {
	xs.mutex.Lock()
	defer xs.mutex.Unlock()

	if xs.isRunning {
		return errors.New("failed: xray service is already running")
	}

	// Initialize logger
	log.StartLogger()

	// Set the environment and memory limits with context support
	if err := SetEnv(ctx, opts.Dir); err != nil {
		return fmt.Errorf("failed: unable to set environment: %v", err)
	}

	if err := MaxMemory(ctx, opts.Memory); err != nil {
		return fmt.Errorf("failed: unable to set memory limit: %v", err)
	}

	// Load and initialize the Xray core instance
	instance, err := xs.loadServer(ctx, opts.Config, opts.IsString, opts.ProxyPort)
	if err != nil {
		return fmt.Errorf("failed: unable to load Xray server: %v", err)
	}

	// Start the Xray instance with context checks
	select {
	case <-ctx.Done():
		return fmt.Errorf("failed: context cancelled while starting: %v", ctx.Err())
	default:
		if err = instance.Start(); err != nil {
			return fmt.Errorf("failed: unable to start Xray instance: %v", err)
		}
	}

	xs.instance = instance
	xs.isRunning = true

	if err := FreeOSMemory(ctx); err != nil {
		return fmt.Errorf("failed: unable to free memory after start: %v", err)
	}

	// Signal that the service is ready
	close(xs.readyChan)

	return nil
}

// Stop gracefully shuts down the Xray service.
func (xs *XrayService) Stop(ctx context.Context) error {
	xs.mutex.Lock()
	defer xs.mutex.Unlock()

	if !xs.isRunning {
		return nil
	}

	// Stop/Clean logger
	log.StopLogger()

	if xs.instance != nil {
		if err := xs.instance.Close(); err != nil {
			return fmt.Errorf("failed: unable to close Xray instance: %v", err)
		}
	}
	xs.instance = nil
	xs.isRunning = false
	// Reset ready channel for next start
	xs.readyChan = make(chan struct{})
	return nil
}

// Version returns the current version of the Xray core.
func (xs *XrayService) Version() string {
	return core.Version()
}

// IsRunning returns true if the Xray service is currently running.
func (xs *XrayService) IsRunning() bool {
	xs.mutex.Lock()
	defer xs.mutex.Unlock()
	return xs.isRunning
}

// MeasurePing measures the delay between the Xray instance and given URLs.
// Returns ping results for given URLs in milliseconds(ms).
func (xs *XrayService) MeasurePing(ctx context.Context, urls []string) (*proxycoreproto.MeasurePingResponse, error) {
	if ctx == nil {
		return nil, errors.New("failed: context cannot be nil")
	}

	if urls == nil {
		return nil, errors.New("failed: urls slice cannot be nil")
	}

	// Wait for service to be ready
	select {
	case <-xs.readyChan:
		// Service is ready, continue
	case <-ctx.Done():
		return nil, ctx.Err()
	}

	xs.mutex.Lock()
	defer xs.mutex.Unlock()

	// Check if Xray service is running before proceeding
	if !xs.isRunning {
		return nil, errors.New("failed: xray service is not running, please start it first")
	}

	// Ensure instance is initialized and available
	if xs.instance == nil {
		return nil, errors.New("failed: xray instance is nil despite service being marked as running")
	}

	tr := &http.Transport{
		TLSHandshakeTimeout: 6 * time.Second,
		DisableKeepAlives:   true,
		DialContext: func(ctx context.Context, network, addr string) (net.Conn, error) {
			if ctx == nil {
				return nil, errors.New("failed: context cannot be nil in DialContext")
			}
			if network == "" || addr == "" {
				return nil, errors.New("failed: network or address cannot be empty")
			}

			dest, err := xraynet.ParseDestination(fmt.Sprintf("%s:%s", network, addr))
			if err != nil {
				return nil, fmt.Errorf("failed: unable to parse destination: %v", err)
			}

			conn, err := core.Dial(ctx, xs.instance, dest)
			if err != nil {
				return nil, fmt.Errorf("failed: unable to dial: %v", err)
			}
			return conn, nil
		},
		ResponseHeaderTimeout: 10 * time.Second,
		IdleConnTimeout:       30 * time.Second,
		MaxIdleConnsPerHost:   10,
	}

	client := &http.Client{
		Transport: tr,
		Timeout:   12 * time.Second,
	}
	defer tr.CloseIdleConnections()

	results := make([]*proxycoreproto.PingResult, 0, len(urls))
	for _, url := range urls {
		select {
		case <-ctx.Done():
			return nil, ctx.Err()
		default:
			if len(url) == 0 {
				url = "https://www.google.com/generate_204"
			}

			req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
			if err != nil {
				return nil, fmt.Errorf("failed: invalid request for URL %s: %v", url, err)
			}

			start := time.Now()
			resp, err := client.Do(req)
			if err != nil {
				return nil, fmt.Errorf("failed: request failed for URL %s: %v", url, err)
			}

			if resp != nil {
				defer resp.Body.Close()
				if resp.StatusCode != http.StatusOK && resp.StatusCode != http.StatusNoContent {
					return nil, fmt.Errorf("failed: unexpected status code %d for URL %s", resp.StatusCode, url)
				}
			}

			delay := time.Since(start).Milliseconds()
			results = append(results, &proxycoreproto.PingResult{
				Url:   fmt.Sprintf("%s (%dms)", url, delay),
				Delay: delay,
			})
		}
	}

	if len(results) == 0 {
		return nil, errors.New("failed: no valid results obtained from any URL")
	}

	return &proxycoreproto.MeasurePingResponse{
		Results: results,
	}, nil
}

func (xs *XrayService) FetchLogs() string {
	// Ensure logs are properly initialized
	if !xs.IsRunning() {
		return ""
	}
	return log.FetchLogs()
}

func (xs *XrayService) ClearLogs() bool {
	return log.ClearLogs()
}
