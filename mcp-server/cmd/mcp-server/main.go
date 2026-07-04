package main

import (
	"context"
	"flag"
	"log"
	"log/slog"
	"net/http"
	"os"

	"github.com/CSKU-Lab/mcp-server/internal/config"
	"github.com/CSKU-Lab/mcp-server/internal/mainclient"
	"github.com/CSKU-Lab/mcp-server/internal/server"
	"github.com/modelcontextprotocol/go-sdk/mcp"
)

func main() {
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("config: %v", err)
	}

	// Flags override env. http is the primary (prod) transport.
	flag.StringVar(&cfg.Transport, "transport", cfg.Transport, "transport: http (default, prod) or stdio (local admin)")
	flag.StringVar(&cfg.Addr, "addr", cfg.Addr, "http listen address")
	flag.StringVar(&cfg.MCPPath, "path", cfg.MCPPath, "http path for the MCP endpoint")
	flag.BoolVar(&cfg.ReadOnly, "readonly", cfg.ReadOnly, "register only read tools (*_get, *_list)")
	flag.Parse()

	if err := cfg.Validate(); err != nil {
		log.Fatalf("config: %v", err)
	}

	client := mainclient.New(cfg.MainServerURL)
	logger := slog.New(slog.NewTextHandler(os.Stderr, nil))

	switch cfg.Transport {
	case "stdio":
		// Single long-lived server; token comes from CSLAB_ACCESS_TOKEN.
		s := server.Build(cfg, client)
		logger.Info("starting", "transport", "stdio", "readonly", cfg.ReadOnly)
		if err := s.Run(context.Background(), &mcp.StdioTransport{}); err != nil {
			log.Fatalf("stdio run: %v", err)
		}

	case "http":
		// A fresh server per request so the token is read from that request's headers.
		handler := mcp.NewStreamableHTTPHandler(
			func(_ *http.Request) *mcp.Server { return server.Build(cfg, client) },
			&mcp.StreamableHTTPOptions{Logger: logger},
		)
		mux := http.NewServeMux()
		mux.Handle(cfg.MCPPath, handler)
		mux.HandleFunc("/healthz", func(w http.ResponseWriter, _ *http.Request) { w.WriteHeader(http.StatusOK) })

		logger.Info("starting", "transport", "http", "addr", cfg.Addr, "path", cfg.MCPPath, "readonly", cfg.ReadOnly)
		if err := http.ListenAndServe(cfg.Addr, mux); err != nil {
			log.Fatalf("http serve: %v", err)
		}
	}
}
