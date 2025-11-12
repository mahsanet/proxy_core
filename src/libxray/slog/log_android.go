//go:build android

package log

/*
#cgo LDFLAGS: -landroid -llog
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <android/log.h>
*/
import "C"
import (
	"unsafe"

	"github.com/GFW-knocker/Xray-core/common/log"
	"github.com/GFW-knocker/Xray-core/common/serial"
)

type androidLogger struct{}

func (a *androidLogger) Handle(msg log.Message) {
	var priority = C.ANDROID_LOG_INFO
	var message string

	switch m := msg.(type) {
	case *log.GeneralMessage:
		switch m.Severity {
		case log.Severity_Unknown:
			priority = C.ANDROID_LOG_UNKNOWN
		case log.Severity_Error:
			priority = C.ANDROID_LOG_ERROR
		case log.Severity_Warning:
			priority = C.ANDROID_LOG_WARN
		case log.Severity_Info:
			priority = C.ANDROID_LOG_INFO
		case log.Severity_Debug:
			priority = C.ANDROID_LOG_DEBUG
		}
		message = serial.ToString(m.Content)
	default:
		message = msg.String()
	}

	WriteLogToBuffer(message) // save to memory

	cmsg := C.CString(message)
	defer C.free(unsafe.Pointer(cmsg))
	C.__android_log_write(C.int(priority), C.CString("xray"), cmsg)
}

// registerPlatformLogger returns the android-specific handler
func registerPlatformLogger() log.Handler {
	return &androidLogger{}
}
