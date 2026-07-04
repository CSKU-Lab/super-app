package tools

import (
	"github.com/modelcontextprotocol/go-sdk/mcp"
)

// Registrar bundles the MCP server with the shared Deps so tool files can add
// tools and respect the read-only flag.
type Registrar struct {
	server *mcp.Server
	deps   Deps
}

func NewRegistrar(server *mcp.Server, deps Deps) *Registrar {
	return &Registrar{server: server, deps: deps}
}
