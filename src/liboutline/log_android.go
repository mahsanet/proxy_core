//go:build android

package liboutline

/*
#cgo LDFLAGS: -landroid -llog
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <android/log.h>
*/
import "C"
import (
	"io"
	"log/slog"
	"os"
	"unsafe"
)

type androidLogWriter struct{}

func (androidLogWriter) Write(p []byte) (n int, err error) {
	cstr := C.CString(string(p))
	C.__android_log_write(C.ANDROID_LOG_INFO, C.CString("outline"), cstr)
	C.free(unsafe.Pointer(cstr))
	return len(p), nil
}

// initLogger sets up structured logging.
func (osrv *OutlineService) initLogger() {
	level := slog.LevelDebug

	w := io.MultiWriter(os.Stdout, osrv.logWriter, androidLogWriter{})
	h := slog.NewTextHandler(w, &slog.HandlerOptions{
		Level: level,
		ReplaceAttr: func(groups []string, a slog.Attr) slog.Attr {
			// android logcat includes time
			if a.Key == slog.TimeKey && len(groups) == 0 {
				return slog.Attr{}
			}
			return a
		},
	})
	osrv.logger = slog.New(h)
}
