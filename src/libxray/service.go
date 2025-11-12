package libxray

import (
	"context"
	"fmt"
	"os"
	"strings"

	"github.com/GFW-knocker/Xray-core/common/cmdarg"
	"github.com/GFW-knocker/Xray-core/core"
	"github.com/GFW-knocker/Xray-core/infra/conf/serial"
)

// loadServer initializes the Xray core server based on the configuration provided and replaces the inbound socks port.
func (xs *XrayService) loadServer(ctx context.Context, config string, isStr bool, port int32) (*core.Instance, error) {
	select {
	case <-ctx.Done():
		return nil, ctx.Err() // Handle context cancellation
	default:
	}

	var jsonConfig *core.Config
	var err error

	if isStr {
		// Replace the inbound socks port in the string configuration
		config, err = replaceInboundSocksPort(config, port)
		if err != nil {
			return nil, fmt.Errorf("failed: unable to replace inbound socks port: %v", err)
		}

		// Parse the modified configuration string as JSON
		jsonConfig, err = serial.LoadJSONConfig(strings.NewReader(config))
		if err != nil {
			return nil, fmt.Errorf("failed: unable to parse JSON config: %v", err)
		}
	} else {
		// Read the file content and replace the inbound socks port
		fileContent, err := os.ReadFile(config)
		if err != nil {
			return nil, fmt.Errorf("failed: unable to read config file: %v", err)
		}

		modifiedConfig, err := replaceInboundSocksPort(string(fileContent), port)
		if err != nil {
			return nil, fmt.Errorf("failed: unable to replace inbound socks port: %v", err)
		}

		// Write the modified content back to the file (optional, if needed)
		err = os.WriteFile(config, []byte(modifiedConfig), 0644)
		if err != nil {
			return nil, fmt.Errorf("failed: unable to write modified config file: %v", err)
		}

		// Load the configuration from the modified file
		file := cmdarg.Arg{config}
		jsonConfig, err = core.LoadConfig("json", file)
		if err != nil {
			return nil, fmt.Errorf("failed: unable to load config from file: %v", err)
		}
	}

	// Initialize the Xray core server with the modified configuration
	server, err := core.New(jsonConfig)
	if err != nil {
		return nil, fmt.Errorf("failed: unable to create Xray instance: %v", err)
	}

	return server, nil
}
