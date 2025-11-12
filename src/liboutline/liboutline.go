package liboutline

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"log/slog"
	"net"
	"net/http"
	"net/netip"
	"strings"
	"sync"
	"syscall"
	"time"

	"segment/global"
	"segment/proxycoreproto"

	"github.com/Jigsaw-Code/outline-sdk/transport"
	"github.com/Jigsaw-Code/outline-sdk/transport/shadowsocks"
	"github.com/things-go/go-socks5"
)

// SSConfig documents the expected JSON fields.
type SSConfig struct {
	Server     string `json:"server"`
	ServerPort int    `json:"server_port"`
	Password   string `json:"password"`
	Method     string `json:"method"`
	Verbose    bool   `json:"verbose,omitempty"`
	LocalAddr  string `json:"local_addr,omitempty"`
}

// logWriter captures logs in memory.
type logWriter struct {
	mu       sync.Mutex
	messages []string
}

func (w *logWriter) Write(p []byte) (int, error) {
	w.mu.Lock()
	defer w.mu.Unlock()
	w.messages = append(w.messages, strings.TrimRight(string(p), "\n"))
	return len(p), nil
}

func (w *logWriter) FetchLogs() string {
	w.mu.Lock()
	defer w.mu.Unlock()
	if len(w.messages) == 0 {
		return ""
	}
	out := strings.Join(w.messages, "\n")
	w.messages = nil
	return out
}

func (w *logWriter) Clear() {
	w.mu.Lock()
	w.messages = nil
	w.mu.Unlock()
}

// OutlineService manages a Shadowsocks-based SOCKS5 proxy.
type OutlineService struct {
	mu               sync.Mutex
	server           *socks5.Server
	listener         net.Listener
	ssStreamDialer   transport.StreamDialer
	ssPacketListener transport.PacketListener
	cancelFunc       context.CancelFunc
	logWriter        *logWriter
	logger           *slog.Logger
	isRunning        bool
}

var (
	outlineService     *OutlineService
	outlineServiceOnce sync.Once
)

// GetOutlineService returns the singleton instance.
func GetOutlineService() *OutlineService {
	outlineServiceOnce.Do(func() {
		outlineService = &OutlineService{logWriter: &logWriter{}}
	})
	return outlineService
}

// CoreName returns the service identifier.
func (osrv *OutlineService) CoreName() string {
	return "outline"
}

// Start launches the proxy based on JSON config.
func (osrv *OutlineService) Start(ctx context.Context, opts global.StartOptions) error {
	osrv.mu.Lock()
	defer osrv.mu.Unlock()

	if osrv.isRunning {
		return errors.New("proxy is already running")
	}

	// Parse config
	var cfg SSConfig
	if err := json.Unmarshal([]byte(opts.Config), &cfg); err != nil {
		return fmt.Errorf("invalid config JSON: %w", err)
	}
	if cfg.Server == "" || cfg.ServerPort == 0 || cfg.Password == "" || cfg.Method == "" {
		return errors.New("missing required config fields")
	}
	osrv.initLogger()

	// Setup Shadowsocks dialer
	if err := osrv.initDialers(cfg); err != nil {
		return err
	}

	// SOCKS5 server with custom dial
	osrv.initSocksServer()

	// Prepare cancellation
	serveCtx, cancel := context.WithCancel(ctx)
	osrv.cancelFunc = cancel

	// Listen with SO_REUSEADDR and SO_REUSEPORT
	addr := netip.AddrPortFrom(netip.MustParseAddr("127.0.0.1"), uint16(opts.ProxyPort))
	if err := osrv.initListener(serveCtx, addr); err != nil {
		return err
	}

	osrv.isRunning = true

	// Serve in background
	go func(osrv *OutlineService) {
		// Accept loop unblocks on listener.Close()
		_ = osrv.server.Serve(osrv.listener)
	}(osrv)

	osrv.logger.Info("proxy started", "address", addr.String())
	return nil
}

func (osrv *OutlineService) initDialers(cfg SSConfig) error {
	key, err := shadowsocks.NewEncryptionKey(cfg.Method, cfg.Password)
	if err != nil {
		return fmt.Errorf("create encryption key: %w", err)
	}

	packetListener, err := shadowsocks.NewPacketListener(
		transport.FuncPacketEndpoint(func(ctx context.Context) (net.Conn, error) {
			d := &transport.UDPDialer{}
			return d.DialPacket(ctx, fmt.Sprintf("%s:%d", cfg.Server, cfg.ServerPort))
		}), key,
	)
	if err != nil {
		return fmt.Errorf("create shadowsocks packet listener: %w", err)
	}
	osrv.ssPacketListener = packetListener

	streamDialer, err := shadowsocks.NewStreamDialer(
		transport.FuncStreamEndpoint(func(ctx context.Context) (transport.StreamConn, error) {
			d := &transport.TCPDialer{}
			return d.DialStream(ctx, fmt.Sprintf("%s:%d", cfg.Server, cfg.ServerPort))
		}), key,
	)
	if err != nil {
		return fmt.Errorf("create shadowsocks stream dialer: %w", err)
	}
	osrv.ssStreamDialer = streamDialer

	return nil
}

func (osrv *OutlineService) initSocksServer() {
	tcpHandler := func(ctx context.Context, addr string) (net.Conn, error) {
		conn, err := osrv.ssStreamDialer.DialStream(ctx, addr)
		if err != nil {
			osrv.logger.Info("connection failed", "network", "tcp", "target", addr, "error", err.Error())
			return nil, err
		}

		osrv.logger.Info("connection established", "network", "tcp", "target", addr)

		return conn, nil
	}

	udpHandler := func(ctx context.Context, addr string) (net.Conn, error) {
		conn, err := transport.PacketListenerDialer{Listener: osrv.ssPacketListener}.DialPacket(ctx, addr)
		if err != nil {
			osrv.logger.Info("connection failed", "network", "udp", "target", addr, "error", err.Error())
			return nil, err
		}

		osrv.logger.Info("connection established", "network", "udp", "target", addr)

		return conn, nil
	}

	opts := []socks5.Option{
		socks5.WithDial(func(ctx context.Context, network, addr string) (net.Conn, error) {
			if network == "tcp" {
				return tcpHandler(ctx, addr)
			}

			if network == "udp" {
				return udpHandler(ctx, addr)
			}

			return nil, fmt.Errorf("unknown network: %s", network)
		}),
	}

	osrv.server = socks5.NewServer(opts...)
}

func (osrv *OutlineService) initListener(ctx context.Context, addrPort netip.AddrPort) error {
	lc := net.ListenConfig{Control: func(_, _ string, r syscall.RawConn) error {
		var serr error
		r.Control(func(fd uintptr) {
			serr = syscall.SetsockoptInt(int(fd), syscall.SOL_SOCKET, syscall.SO_REUSEADDR, 1)
		})
		return serr
	}}

	listener, err := lc.Listen(ctx, "tcp", addrPort.String())
	if err != nil {
		return fmt.Errorf("listen error: %w", err)
	}

	// Mark running before serving
	osrv.listener = listener

	return nil
}

// Stop shuts down the proxy immediately.
func (osrv *OutlineService) Stop(ctx context.Context) error {
	osrv.mu.Lock()
	defer osrv.mu.Unlock()

	if !osrv.isRunning {
		return nil
	}
	// Prevent new operations
	osrv.isRunning = false

	// Cancel any pending dials
	if osrv.cancelFunc != nil {
		osrv.cancelFunc()
	}

	// Close listener to unblock Serve immediately
	if osrv.listener != nil {
		osrv.listener.Close()
	}

	// Reset state
	osrv.server = nil
	osrv.listener = nil
	osrv.ssStreamDialer = nil
	osrv.ssPacketListener = nil
	osrv.cancelFunc = nil

	osrv.logger.Info("proxy stopped")
	return nil
}

// IsRunning indicates proxy status.
func (osrv *OutlineService) IsRunning() bool {
	osrv.mu.Lock()
	defer osrv.mu.Unlock()
	return osrv.isRunning
}

// FetchLogs retrieves in-memory logs.
func (osrv *OutlineService) FetchLogs() string {
	return osrv.logWriter.FetchLogs()
}

// ClearLogs empties stored logs.
func (osrv *OutlineService) ClearLogs() bool {
	osrv.logWriter.Clear()
	return true
}

// MeasurePing performs HTTP GETs via the proxy.
func (osrv *OutlineService) MeasurePing(ctx context.Context, urls []string) (*proxycoreproto.MeasurePingResponse, error) {
	if ctx == nil || urls == nil {
		return nil, errors.New("invalid parameters")
	}
	client := &http.Client{
		Transport: &http.Transport{DialContext: func(dctx context.Context, network, addr string) (net.Conn, error) {
			return osrv.ssStreamDialer.DialStream(dctx, addr)
		}},
		Timeout: 12 * time.Second,
	}
	results := make([]*proxycoreproto.PingResult, 0, len(urls))
	for _, u := range urls {
		url := u
		if url == "" {
			url = "https://www.google.com/generate_204"
		}
		start := time.Now()
		resp, err := client.Get(url)
		if err != nil || (resp.StatusCode != http.StatusOK && resp.StatusCode != http.StatusNoContent) {
			results = append(results, &proxycoreproto.PingResult{Url: url, Delay: -1})
			continue
		}
		resp.Body.Close()
		d := time.Since(start).Milliseconds()
		results = append(results, &proxycoreproto.PingResult{Url: url, Delay: d})
		osrv.logger.Debug("ping", "url", url, "delay", d)
	}
	if len(results) == 0 {
		return nil, errors.New("no results")
	}
	return &proxycoreproto.MeasurePingResponse{Results: results}, nil
}

// Version returns the build version.
func (osrv *OutlineService) Version() string {
	return "Latest main branch"
}
