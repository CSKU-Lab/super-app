package config

import (
	"fmt"
	"os"
)

// Config holds runtime configuration, populated from flags + env.
type Config struct {
	// Transport is "http" (prod default) or "stdio" (local admin).
	Transport string
	// Addr is the listen address in http mode, e.g. ":8090".
	Addr string
	// MCPPath is the HTTP path the Streamable HTTP handler is mounted on.
	MCPPath string
	// ReadOnly registers only *_get / *_list tools when true.
	ReadOnly bool

	// MainServerURL is the base URL of main-server, e.g. http://main-server.cs-lab.svc.cluster.local:3000
	MainServerURL string

	// StdioToken is the cs-lab access_token used in stdio mode (no HTTP request to read it from).
	// Sourced from CSLAB_ACCESS_TOKEN. Ignored in http mode (token comes per-request).
	StdioToken string
}

// Load reads env vars. Flags are applied by the caller after Load.
func Load() (*Config, error) {
	c := &Config{
		Transport:     getenv("MCP_TRANSPORT", "http"),
		Addr:          getenv("MCP_ADDR", ":8090"),
		MCPPath:       getenv("MCP_PATH", "/mcp"),
		MainServerURL: os.Getenv("MAIN_SERVER_URL"),
		StdioToken:    os.Getenv("CSLAB_ACCESS_TOKEN"),
	}
	return c, nil
}

// Validate checks required fields for the chosen transport.
func (c *Config) Validate() error {
	if c.MainServerURL == "" {
		return fmt.Errorf("MAIN_SERVER_URL is required")
	}
	if c.Transport == "stdio" && c.StdioToken == "" {
		return fmt.Errorf("stdio transport requires CSLAB_ACCESS_TOKEN (cs-lab admin access_token)")
	}
	if c.Transport != "http" && c.Transport != "stdio" {
		return fmt.Errorf("transport must be http or stdio, got %q", c.Transport)
	}
	return nil
}

func getenv(k, def string) string {
	if v := os.Getenv(k); v != "" {
		return v
	}
	return def
}
