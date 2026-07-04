package auth

import (
	"fmt"
	"net/http"
	"strings"

	"github.com/modelcontextprotocol/go-sdk/mcp"
)

// Resolve extracts the cs-lab access_token for the current tool call.
//
// http transport: the token rides on the MCP HTTP request. We accept either
//   - Authorization: Bearer <token>
//   - Cookie: access_token=<token>   (mirrors main-server ProtectedRouteMiddleware)
//
// stdio transport: there is no HTTP request, so fall back to the token loaded
// from CSLAB_ACCESS_TOKEN (passed as fallback).
//
// The token is NOT validated here — it is forwarded to main-server, which owns
// JWT validation + admin/RBAC/permission enforcement. This keeps the MCP a thin
// proxy and avoids duplicating (and drifting from) the auth logic.
func Resolve(req *mcp.CallToolRequest, fallback string) (string, error) {
	if req != nil && req.Extra != nil && req.Extra.Header != nil {
		if tok := fromHeader(req.Extra.Header); tok != "" {
			return tok, nil
		}
	}
	if fallback != "" {
		return fallback, nil
	}
	return "", fmt.Errorf("no cs-lab access_token: send Authorization: Bearer <token> or Cookie access_token=<token> (http), or set CSLAB_ACCESS_TOKEN (stdio)")
}

func fromHeader(h http.Header) string {
	if a := h.Get("Authorization"); a != "" {
		if strings.HasPrefix(a, "Bearer ") {
			return strings.TrimPrefix(a, "Bearer ")
		}
	}
	// Parse Cookie header for access_token.
	req := &http.Request{Header: h}
	if ck, err := req.Cookie("access_token"); err == nil {
		return ck.Value
	}
	return ""
}
