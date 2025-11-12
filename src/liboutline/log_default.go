//go:build !android

package liboutline

import (
	"io"
	"log/slog"
	"os"
)

// initLogger sets up structured logging.
func (osrv *OutlineService) initLogger() {
	level := slog.LevelDebug

	w := io.MultiWriter(os.Stdout, osrv.logWriter)
	h := slog.NewTextHandler(w, &slog.HandlerOptions{Level: level})
	osrv.logger = slog.New(h)
}
