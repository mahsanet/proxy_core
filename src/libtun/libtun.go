package libtun

import (
	"fmt"
	"sync"

	"github.com/xjasonlyu/tun2socks/v2/engine"
)

var (
	key     = new(engine.Key)
	started bool // Simple boolean flag for checking the started state
	mu      sync.Mutex
)

// Start initializes tun2socks with the given TUN file descriptor and proxy address.
func Start(tunFD int, proxyAddress string) error {
	mu.Lock()
	defer mu.Unlock()

	// Check if already started
	if started {
		return fmt.Errorf("tun2socks has already been started")
	}
	// Mark as started
	started = true
	key.Device = fmt.Sprintf("fd://%d", tunFD)
	key.Proxy = fmt.Sprintf("socks5://%s", proxyAddress)
	key.MTU = 1500
	key.LogLevel = "info"
	engine.Insert(key)
	engine.Start()
	return nil
}

// Stop stops the tun2socks engine, resets state, and ensures the engine is ready for future starts.
func Stop() {
	mu.Lock()
	defer mu.Unlock()
	engine.Stop()
	started = false       // Reset the started flag
	key = new(engine.Key) // Reset key for the next Start call
}

// IsStarted checks if tun2socks has been started.
func IsStarted() bool {
	mu.Lock()
	defer mu.Unlock()
	return started
}
