package ios

import (
	"context"
	"fmt"
	"strings"

	"segment/proxycoreproto"
	"segment/server"
)

// StartGRPCIOS starts the gRPC server used by Flutter+iOS.
func StartGRPCIOS() bool {
	return server.StartGRPCServer()
}

// StartCoreIOS starts a specified core with given config.
// Returns "true" on success or "ERROR_CORE:<error>".
func StartCoreIOS(coreName string, dir string, config string, memory int32, isString bool, proxyPort int32) string {
	ctx := context.Background()

	req := &proxycoreproto.StartCoreRequest{
		CoreName:  coreName,
		Dir:       dir,
		Config:    config,
		Memory:    memory,
		IsString:  isString,
		ProxyPort: proxyPort,
		IsVpnMode: false,
	}

	_, err := server.HandleStartCore(ctx, req)
	if err != nil {
		return "ERROR_CORE: " + err.Error()
	}
	return "true"
}

// StopCoreIOS stops the currently running core.
func StopCoreIOS() bool {
	ctx := context.Background()
	_, err := server.HandleStopCore(ctx, &proxycoreproto.Empty{})
	return err == nil
}

// IsCoreRunningIOS checks if the current core is running.
func IsCoreRunningIOS() bool {
	ctx := context.Background()
	resp, err := server.HandleIsCoreRunning(ctx, &proxycoreproto.Empty{})
	if err != nil {
		return false
	}
	return resp.Message
}

// GetVersionIOS gets version of the active core.
func GetVersionIOS() string {
	ctx := context.Background()
	resp, err := server.HandleGetVersion(ctx, &proxycoreproto.Empty{})
	if err != nil {
		return "unknown"
	}
	return resp.Message
}

// MeasurePingIOS measures latency to comma-separated URLs.
func MeasurePingIOS(urls string) string {
	ctx := context.Background()

	urlList := []string{}
	for _, u := range strings.Split(urls, ",") {
		u = strings.TrimSpace(u)
		if u != "" {
			urlList = append(urlList, u)
		}
	}

	req := &proxycoreproto.MeasurePingRequest{Url: urlList}
	resp, err := server.HandleMeasurePing(ctx, req)
	if err != nil {
		return err.Error()
	}

	delays := []string{}
	for _, r := range resp.Results {
		delays = append(delays, fmt.Sprintf("%d", r.Delay))
	}
	return strings.Join(delays, ",")
}

// FetchLogsIOS returns logs from the active core.
func FetchLogsIOS() string {
	ctx := context.Background()
	resp, err := server.HandleFetchLogs(ctx, &proxycoreproto.Empty{})
	if err != nil {
		return ""
	}
	return resp.Logs
}

// ClearLogsIOS clears logs of the active core.
func ClearLogsIOS() {
	ctx := context.Background()
	_, _ = server.HandleClearLogs(ctx, &proxycoreproto.Empty{})
}
