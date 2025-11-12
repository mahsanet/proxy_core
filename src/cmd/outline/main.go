//go:build !android

package main

import (
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"log/slog"
	"os"
	"os/signal"
	"strconv"
	"strings"
	"syscall"
	"time"

	"segment/global"
	"segment/liboutline"
)

type cliFlags struct {
	ConfigPath string
	ConfigJSON string
	Server     string
	Port       int
	Password   string
	Method     string
	LocalAddr  string
	Verbose    bool
}

func main() {
	flags := cliFlags{}
	flag.StringVar(&flags.ConfigPath, "config", "config.json", "Config file path")
	flag.StringVar(&flags.ConfigJSON, "json", "", "Raw JSON config")
	flag.StringVar(&flags.Server, "server", "", "SS server address")
	flag.IntVar(&flags.Port, "port", 2080, "SS server port")
	flag.StringVar(&flags.Password, "password", "", "SS password")
	flag.StringVar(&flags.Method, "method", "", "SS encryption method")
	flag.StringVar(&flags.LocalAddr, "local", "", "Local SOCKS address")
	flag.BoolVar(&flags.Verbose, "v", false, "Verbose mode")
	flag.Parse()

	log := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
		Level: func() slog.Level {
			if flags.Verbose {
				return slog.LevelDebug
			}
			return slog.LevelInfo
		}(),
	}))

	cfg := liboutline.SSConfig{}
	switch {
	case flags.ConfigJSON != "":
		_ = json.Unmarshal([]byte(flags.ConfigJSON), &cfg)
	case flags.Server != "" && flags.Password != "" && flags.Method != "":
		cfg = liboutline.SSConfig{
			Server:     flags.Server,
			ServerPort: flags.Port,
			Password:   flags.Password,
			Method:     flags.Method,
			Verbose:    flags.Verbose,
		}
	default:
		data, err := os.ReadFile(flags.ConfigPath)
		if err != nil {
			log.Error("Read config file", slog.String("error", err.Error()))
			os.Exit(1)
		}
		_ = json.Unmarshal(data, &cfg)
	}

	if cfg.LocalAddr == "" {
		cfg.LocalAddr = fmt.Sprintf("0.0.0.0:%d", flags.Port)
	}
	cfg.Verbose = flags.Verbose

	raw, _ := json.Marshal(cfg)
	port := extractPort(cfg.LocalAddr)

	opts := global.StartOptions{
		Config:    string(raw),
		IsString:  true,
		ProxyPort: port,
	}

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	service := liboutline.GetOutlineService()
	if err := service.Start(ctx, opts); err != nil {
		log.Error("Start failed", slog.String("error", err.Error()))
		os.Exit(1)
	}
	go func() {
		ticker := time.NewTicker(200 * time.Millisecond)
		defer ticker.Stop()
		for {
			select {
			case <-ctx.Done():
				return
			case <-ticker.C:
				logs := service.FetchLogs()
				if logs != "" {
					fmt.Print(logs)
				}
			}
		}
	}()
	sig := make(chan os.Signal, 1)
	signal.Notify(sig, syscall.SIGINT, syscall.SIGTERM)
	<-sig
	cancel()
}

func extractPort(addr string) int32 {
	parts := strings.Split(addr, ":")
	if len(parts) != 2 {
		return 2080
	}
	p, err := strconv.Atoi(parts[1])
	if err != nil {
		return 2080
	}
	return int32(p)
}
