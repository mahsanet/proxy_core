//go:build !android

package slogger

import (
	"context"
	"log/slog"
)

func (h *MultiplatformConsoleHandler) handle(ctx context.Context, r slog.Record) error {
	h.mu.Lock()
	defer h.mu.Unlock()

	return h.baseHandler.Handle(ctx, r)
}
