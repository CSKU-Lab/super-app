package server

import (
	"github.com/CSKU-Lab/mcp-server/internal/config"
	"github.com/CSKU-Lab/mcp-server/internal/mainclient"
	"github.com/CSKU-Lab/mcp-server/internal/tools"
	"github.com/modelcontextprotocol/go-sdk/mcp"
)

// Build constructs an MCP server with all in-scope tools registered.
//
// Each Streamable HTTP request gets its own *mcp.Server via this function, so
// the token is always read per-request from the incoming HTTP headers. The
// main-server client is stateless and shared safely.
func Build(cfg *config.Config, client *mainclient.Client) *mcp.Server {
	s := mcp.NewServer(&mcp.Implementation{
		Name:    "cs-lab-admin",
		Version: "v0.1.0",
	}, nil)

	reg := tools.NewRegistrar(s, tools.Deps{
		Client:     client,
		StdioToken: cfg.StdioToken,
		ReadOnly:   cfg.ReadOnly,
	})
	tools.Register(reg)
	return s
}
