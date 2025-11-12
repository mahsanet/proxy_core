package log

import (
	"bytes"
	"sync"

	alog "github.com/GFW-knocker/Xray-core/app/log"
	"github.com/GFW-knocker/Xray-core/common"
	"github.com/GFW-knocker/Xray-core/common/log"
)

var (
	logBuffer      = &bytes.Buffer{}
	logMutex       sync.RWMutex
	loggerAdded    bool
	maxBufferSize  = 2 * 1024 * 1024 // 2MB max
	loggingEnabled = true
)

// WriteLogToBuffer appends a message to the buffer, trimming it if oversized.
func WriteLogToBuffer(msg string) {
	logMutex.Lock()
	defer logMutex.Unlock()

	if !loggingEnabled {
		return
	}

	// Trim buffer if it exceeds limit
	if logBuffer.Len() > maxBufferSize {
		data := logBuffer.Bytes()
		if cut := bytes.IndexByte(data[len(data)/2:], '\n'); cut != -1 {
			logBuffer = bytes.NewBuffer(data[len(data)/2+cut+1:])
		} else {
			logBuffer.Reset()
		}
	}

	logBuffer.WriteString(msg + "\n")
}

// StartLogger sets up the platform-specific log handler once.
func StartLogger() {
	logMutex.Lock()
	defer logMutex.Unlock()

	if loggerAdded {
		return
	}

	logBuffer.Reset()

	common.Must(alog.RegisterHandlerCreator(alog.LogType_Console, func(_ alog.LogType, _ alog.HandlerCreatorOptions) (log.Handler, error) {
		return registerPlatformLogger(), nil
	}))

	loggerAdded = true
}

// StopLogger clears buffer and disables logging.
func StopLogger() {
	logMutex.Lock()
	defer logMutex.Unlock()

	logBuffer.Reset()
	loggerAdded = false
}

// FetchLogs returns and clears the buffered logs.
func FetchLogs() string {
	logMutex.Lock()
	defer logMutex.Unlock()

	if logBuffer.Len() == 0 {
		return ""
	}

	logs := logBuffer.String()
	logBuffer.Reset()
	return logs
}

func ClearLogs() bool {
	logMutex.Lock()
	defer logMutex.Unlock()

	loggingEnabled = false
	logBuffer.Reset()
	loggingEnabled = true // Optional: re-enable immediately
	return true
}
