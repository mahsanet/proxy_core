package server

import (
	"context"
	"fmt"
	"log/slog"
	"net"
	"os"
	"sync"
	"time"

	"segment/global"
	"segment/liboutline"
	"segment/libtun"
	"segment/libxray"
	"segment/slogger"

	// "segment/middleware"
	"segment/proxycoreproto"

	"google.golang.org/grpc"
	"google.golang.org/grpc/reflection"
)

var (
	isVpnMode       bool
	wg              sync.WaitGroup
	isServerStarted bool
	serverError     error

	coreRegistry   = make(map[string]Core)
	coreLock       sync.RWMutex
	activeCoreName = libxray.GetXrayService().CoreName()
)

type Core interface {
	Start(ctx context.Context, opts global.StartOptions) error
	Stop(ctx context.Context) error
	IsRunning() bool
	Version() string
	MeasurePing(ctx context.Context, urls []string) (*proxycoreproto.MeasurePingResponse, error)
	FetchLogs() string
	ClearLogs() bool
	CoreName() string
}

func init() {
	registerCore(libxray.GetXrayService())
	registerCore(liboutline.GetOutlineService())
}

func registerCore(c Core) {
	coreLock.Lock()
	defer coreLock.Unlock()
	coreRegistry[c.CoreName()] = c
}

func getCore(name string) (Core, error) {
	coreLock.RLock()
	core, ok := coreRegistry[name]
	coreLock.RUnlock()
	if !ok {
		return nil, fmt.Errorf("core '%s' not registered", name)
	}
	return core, nil
}

func getActiveCore() (Core, error) {
	return getCore(activeCoreName)
}

type server struct {
	proxycoreproto.UnimplementedProxyCoreServer
	logger *slog.Logger
}

func (s *server) StartCore(ctx context.Context, req *proxycoreproto.StartCoreRequest) (*proxycoreproto.Empty, error) {
	// Currently this feature is not needed and not implemented well other sides

	// if detected := middleware.DetectCoreNameFromConfig(req.Config); detected != "" && detected != req.CoreName {
	// 	log.Printf("Overriding coreName: '%s' -> '%s'", req.CoreName, detected)
	// 	req.CoreName = detected
	// }

	core, err := getCore(req.CoreName)
	if err != nil {
		return nil, err
	}

	coreLock.Lock()
	activeCoreName = req.CoreName
	coreLock.Unlock()

	isVpnMode = req.IsVpnMode

	opts := global.StartOptions{
		Dir:       req.Dir,
		Config:    req.Config,
		Memory:    int64(req.Memory),
		IsString:  req.IsString,
		ProxyPort: req.ProxyPort,
	}

	if err := core.Start(ctx, opts); err != nil {
		return nil, fmt.Errorf("failed to start core '%s': %w", req.CoreName, err)
	}
	s.logger.Info("Core started")

	if isVpnMode && !libtun.IsStarted() {
		if err := libtun.Start(int(req.TunFD), fmt.Sprintf("127.0.0.1:%d", req.ProxyPort)); err != nil {
			return nil, fmt.Errorf("failed to start tun2socks: %w", err)
		}
		s.logger.Info("Tun2socks started")
	}

	return &proxycoreproto.Empty{}, nil
}

func (s *server) StopCore(ctx context.Context, _ *proxycoreproto.Empty) (*proxycoreproto.Empty, error) {
	core, err := getActiveCore()
	if err != nil {
		return nil, err
	}

	if !core.IsRunning() {
		return &proxycoreproto.Empty{}, nil
	}

	if err := core.Stop(ctx); err != nil {
		return nil, fmt.Errorf("failed to stop core: %w", err)
	}
	s.logger.Info("Core stopped")

	if libtun.IsStarted() {
		libtun.Stop()
		s.logger.Info("Tun2socks stopped")
	}

	return &proxycoreproto.Empty{}, nil
}

func (s *server) IsCoreRunning(ctx context.Context, _ *proxycoreproto.Empty) (*proxycoreproto.BooleanResponse, error) {
	core, err := getActiveCore()
	if err != nil {
		return nil, err
	}
	return &proxycoreproto.BooleanResponse{Message: core.IsRunning()}, nil
}

func (s *server) GetVersion(ctx context.Context, _ *proxycoreproto.Empty) (*proxycoreproto.VersionResponse, error) {
	core, err := getActiveCore()
	if err != nil {
		return nil, err
	}
	return &proxycoreproto.VersionResponse{Message: core.Version()}, nil
}

func (s *server) MeasurePing(ctx context.Context, req *proxycoreproto.MeasurePingRequest) (*proxycoreproto.MeasurePingResponse, error) {
	core, err := getActiveCore()
	if err != nil {
		return nil, err
	}

	ctx, cancel := context.WithTimeout(ctx, 15*time.Second)
	defer cancel()

	return core.MeasurePing(ctx, req.Url)
}

func (s *server) FetchLogs(ctx context.Context, _ *proxycoreproto.Empty) (*proxycoreproto.LogResponse, error) {
	core, err := getActiveCore()
	if err != nil {
		return nil, err
	}
	if !core.IsRunning() {
		return nil, fmt.Errorf("core is not running")
	}
	return &proxycoreproto.LogResponse{Logs: core.FetchLogs()}, nil
}

func (s *server) ClearLogs(ctx context.Context, _ *proxycoreproto.Empty) (*proxycoreproto.Empty, error) {
	core, err := getActiveCore()
	if err != nil {
		return nil, err
	}
	if !core.IsRunning() {
		return nil, fmt.Errorf("core is not running")
	}
	if !core.ClearLogs() {
		return nil, fmt.Errorf("failed to clear logs")
	}
	return &proxycoreproto.Empty{}, nil
}

// -- IOS Delegate Wrappers --

func HandleStartCore(ctx context.Context, req *proxycoreproto.StartCoreRequest) (*proxycoreproto.Empty, error) {
	l := slog.New(slogger.NewMultiplatformConsoleHandler(os.Stdout, &slogger.Options{
		Level: slog.LevelDebug,
	}))
	return (&server{logger: l}).StartCore(ctx, req)
}
func HandleStopCore(ctx context.Context, req *proxycoreproto.Empty) (*proxycoreproto.Empty, error) {
	l := slog.New(slogger.NewMultiplatformConsoleHandler(os.Stdout, &slogger.Options{
		Level: slog.LevelDebug,
	}))
	return (&server{logger: l}).StopCore(ctx, req)
}
func HandleIsCoreRunning(ctx context.Context, req *proxycoreproto.Empty) (*proxycoreproto.BooleanResponse, error) {
	return (&server{}).IsCoreRunning(ctx, req)
}
func HandleGetVersion(ctx context.Context, req *proxycoreproto.Empty) (*proxycoreproto.VersionResponse, error) {
	return (&server{}).GetVersion(ctx, req)
}
func HandleMeasurePing(ctx context.Context, req *proxycoreproto.MeasurePingRequest) (*proxycoreproto.MeasurePingResponse, error) {
	return (&server{}).MeasurePing(ctx, req)
}
func HandleFetchLogs(ctx context.Context, req *proxycoreproto.Empty) (*proxycoreproto.LogResponse, error) {
	return (&server{}).FetchLogs(ctx, req)
}
func HandleClearLogs(ctx context.Context, req *proxycoreproto.Empty) (*proxycoreproto.Empty, error) {
	return (&server{}).ClearLogs(ctx, req)
}

// -- GRPC Server Boot --

func waitForServer() {
	wg.Wait()
}

func WaitForServer() {
	waitForServer()
}

func startGRPCServer(l *slog.Logger) error {
	if isServerStarted {
		l.Info("gRPC server already running")
		return nil
	}
	isServerStarted = true

	wg.Add(1)
	go func() {
		defer wg.Done()

		// TODO: pick a port that isn't in this list:
		// /proc/sys/net/ipv4/ip_local_unbindable_ports
		// Or migrate to using unix domain sockets
		lis, err := net.Listen("tcp", "127.0.0.1:30051")
		if err != nil {
			l.Error("failed to listen", slog.Any("error", err))
			serverError = err
			isServerStarted = false
			return
		}

		grpcServer := grpc.NewServer()
		proxycoreproto.RegisterProxyCoreServer(grpcServer, &server{logger: l})
		reflection.Register(grpcServer)

		if err := grpcServer.Serve(lis); err != nil {
			l.Error("gRPC serve failed", slog.Any("error", err))
			serverError = err
			isServerStarted = false
		}
		l.Info("gRPC server listening at", slog.Any("address", lis.Addr()))
	}()

	return nil
}

func StartGRPCServer() bool {
	l := slog.New(slogger.NewMultiplatformConsoleHandler(os.Stdout, &slogger.Options{
		Level: slog.LevelDebug,
	}))

	if !isServerStarted {
		l.Info("Starting gRPC server")
		if err := startGRPCServer(l); err != nil {
			l.Error("Failed to start gRPC server", slog.Any("error", err))
			return false
		}
		go waitForServer()
	}
	return isServerStarted
}
