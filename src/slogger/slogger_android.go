//go:build android

package slogger

/*
#cgo LDFLAGS: -landroid -llog
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <android/log.h>
*/
import "C"
import (
	"bytes"
	"context"
	"log/slog"
	"unsafe"
)

func (h *MultiplatformConsoleHandler) handle(ctx context.Context, r slog.Record) error {
	h.mu.Lock()
	defer h.mu.Unlock()

	if err := h.baseHandler.Handle(ctx, r); err != nil {
		return err
	}

	buf := bytes.Buffer{}
	slog.NewTextHandler(&buf, &slog.HandlerOptions{
		Level: h.opts.Level,
		ReplaceAttr: func(groups []string, a slog.Attr) slog.Attr {
			if (a.Key == slog.TimeKey || a.Key == slog.LevelKey) && len(groups) == 0 {
				return slog.Attr{} // remove excess keys
			}
			return a
		},
	}).Handle(ctx, r)

	aLogLevel := C.ANDROID_LOG_INFO
	switch r.Level {
	case slog.LevelDebug:
		aLogLevel = C.ANDROID_LOG_DEBUG
	case slog.LevelWarn:
		aLogLevel = C.ANDROID_LOG_WARN
	case slog.LevelError:
		aLogLevel = C.ANDROID_LOG_ERROR
	}

	cstr := C.CString(string(buf.Bytes()))
	C.__android_log_write(C.int(aLogLevel), C.CString("proxy_core"), cstr)
	C.free(unsafe.Pointer(cstr))

	return nil
}
