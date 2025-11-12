package libxray

import (
	"context"
	"fmt"
	"os"
	"runtime/debug"
	"time"

	"github.com/tidwall/gjson"
	"github.com/tidwall/sjson"
)

// SetEnv sets an environment variable for the xray asset location.
func SetEnv(ctx context.Context, dir string) error {
	select {
	case <-ctx.Done():
		return ctx.Err() // Handle context cancellation
	default:
	}

	err := os.Setenv("xray.location.asset", dir)
	if err != nil {
		return err
	}
	return nil
}

// FreeMemory starts a goroutine that frees OS memory at regular intervals.
// It can be canceled via the context, ensuring it doesn't run indefinitely.
func FreeMemory(ctx context.Context, interval time.Duration) {
	go func() {
		ticker := time.NewTicker(interval)
		defer ticker.Stop()

		for {
			select {
			case <-ctx.Done():
				return // Exit the goroutine if context is canceled
			case <-ticker.C:
				debug.FreeOSMemory()
			}
		}
	}()
}

// MaxMemory sets memory limits and starts background memory freeing with context support.
// It ensures the garbage collector is invoked regularly.
// The value parameter specifies the memory limit in megabytes.
func MaxMemory(ctx context.Context, value int64) error {
	select {
	case <-ctx.Done():
		return ctx.Err() // Handle context cancellation
	default:
	}

	// Set garbage collection behavior
	debug.SetGCPercent(10)
	debug.SetMemoryLimit(value * 1024 * 1024) // Convert MB to bytes

	// Start freeing memory every second
	FreeMemory(ctx, 1*time.Second)

	return nil
}

// FreeOSMemory manually triggers the garbage collector to free memory.
func FreeOSMemory(ctx context.Context) error {
	select {
	case <-ctx.Done():
		return ctx.Err() // Handle context cancellation
	default:
	}

	debug.FreeOSMemory()
	return nil
}

// replaceInboundSocksPort modifies the port for the inbound socks configuration in the provided JSON string.
// It uses gjson for parsing and sjson for modification, which is efficient for large JSONs.
func replaceInboundSocksPort(config string, port int32) (string, error) {
	// First, validate the input config is valid JSON.
	// gjson.Valid will quickly check if the string is valid JSON without full parsing.
	if !gjson.Valid(config) {
		return "", fmt.Errorf("failed: invalid JSON config provided")
	}

	// Find the "inbounds" array.
	inboundsResult := gjson.Get(config, "inbounds")
	if !inboundsResult.Exists() || !inboundsResult.IsArray() {
		return "", fmt.Errorf("failed: 'inbounds' array not found or incorrect format")
	}

	modifiedConfig := config // Start with the original config

	// Iterate through the inbounds array using gjson's ForEach
	inboundsResult.ForEach(func(key, value gjson.Result) bool {
		// key here would be the array index (e.g., "0", "1", etc.)
		protocol := value.Get("protocol").String()

		if protocol == "socks" {
			// Construct the path to the 'port' field for this specific inbound object.
			// Example path: "inbounds.0.port", "inbounds.1.port"
			portPath := fmt.Sprintf("inbounds.%s.port", key.String())

			// Use sjson to set the new port value.
			// sjson.Set handles creating new JSON if the path doesn't exist,
			// but here we know 'inbounds' and 'port' should exist for a socks inbound.
			var err error
			modifiedConfig, err = sjson.Set(modifiedConfig, portPath, port)
			if err != nil {
				// If sjson.Set fails for some reason, return the error immediately.
				// This might indicate an invalid path or internal sjson error.
				modifiedConfig = "" // Clear to indicate failure
				return false        // Stop iteration
			}
			// Found and modified, so we can stop iterating.
			return false // Returning false stops the ForEach loop
		}
		return true // Continue to the next element in the array
	})

	if modifiedConfig == "" {
		// This condition would be hit if sjson.Set returned an error within the loop.
		return "", fmt.Errorf("failed: error during JSON modification to set socks port")
	}

	// Optionally, re-indent the JSON for readability if desired.
	// sjson doesn't automatically re-indent the whole document.
	// If pretty-printing is required, you would need to parse with encoding/json
	// and marshal with Indent, or use a gjson/sjson based pretty-printer if available.
	// For most use cases, especially if passed around internally, compactness is better.
	// If pretty-printing is critical, you could do:
	// parsed, _ := gjson.Parse(modifiedConfig).Value().(map[string]interface{})
	// indented, err := json.MarshalIndent(parsed, "", "  ")
	// return string(indented), err
	return modifiedConfig, nil
}
