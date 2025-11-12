package slogger

import (
	"context"
	"io"
	"log/slog"
	"sync"
)

var _ slog.Handler = (*MultiplatformConsoleHandler)(nil)

type MultiplatformConsoleHandler struct {
	opts        Options
	baseHandler slog.Handler
	mu          *sync.Mutex
}

type Options struct {
	Level slog.Leveler
}

func NewMultiplatformConsoleHandler(out io.Writer, opts *Options) *MultiplatformConsoleHandler {
	h := &MultiplatformConsoleHandler{mu: &sync.Mutex{}}
	if opts != nil {
		h.opts = *opts
	}
	if h.opts.Level == nil {
		h.opts.Level = slog.LevelInfo
	}

	h.baseHandler = slog.NewTextHandler(out, &slog.HandlerOptions{
		Level: h.opts.Level,
	})

	return h
}

func (h *MultiplatformConsoleHandler) Enabled(ctx context.Context, level slog.Level) bool {
	return level >= h.opts.Level.Level()
}

func (h *MultiplatformConsoleHandler) WithGroup(name string) slog.Handler {
	return h.baseHandler.WithGroup(name)
}

func (h *MultiplatformConsoleHandler) WithAttrs(attrs []slog.Attr) slog.Handler {
	return h.baseHandler.WithAttrs(attrs)
}

func (h *MultiplatformConsoleHandler) Handle(ctx context.Context, r slog.Record) error {
	return h.handle(ctx, r)
}
