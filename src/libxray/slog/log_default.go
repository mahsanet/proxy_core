//go:build !android

package log

import (
	"github.com/GFW-knocker/Xray-core/common/log"
	"github.com/GFW-knocker/Xray-core/common/serial"
)

type defaultLogger struct{}

func (l *defaultLogger) Handle(msg log.Message) {
	var message string
	switch m := msg.(type) {
	case *log.GeneralMessage:
		message = serial.ToString(m.Content)
	default:
		message = msg.String()
	}
	WriteLogToBuffer(message)
}

// registerPlatformLogger returns a basic handler for non-Android platforms
func registerPlatformLogger() log.Handler {
	return &defaultLogger{}
}
