// Package tools registers the cs-lab admin MCP tools.
//
// v1 scope: submissions + grading. Tasks are intentionally excluded — main-server
// has no task REST (TaskService is gRPC-only) and v1 is REST-to-main-server only.
package tools

import (
	"encoding/json"

	"github.com/CSKU-Lab/mcp-server/internal/mainclient"
	"github.com/modelcontextprotocol/go-sdk/mcp"
)

// textOf mirrors raw JSON into a text content block so clients that ignore
// structured output still see the payload.
func textOf(raw json.RawMessage) *mcp.CallToolResult {
	return &mcp.CallToolResult{
		Content: []mcp.Content{&mcp.TextContent{Text: string(raw)}},
	}
}

// Deps is what every tool handler needs.
type Deps struct {
	Client *mainclient.Client
	// StdioToken is the fallback access_token for stdio transport (empty in http).
	StdioToken string
	// ReadOnly gates registration of mutating tools.
	ReadOnly bool
}

// jsonResult carries decoded JSON from main-server back to the model as structured
// output. Data is `any` (not json.RawMessage) so the generated output schema is a
// clean permissive object rather than a byte-array.
type jsonResult struct {
	Data any `json:"data" jsonschema:"JSON payload returned by main-server"`
}

// decodeResult unmarshals raw main-server JSON for structured output while keeping
// the raw bytes for the text content block.
func decodeResult(raw json.RawMessage) (jsonResult, error) {
	var v any
	if len(raw) > 0 {
		if err := json.Unmarshal(raw, &v); err != nil {
			return jsonResult{}, err
		}
	}
	return jsonResult{Data: v}, nil
}

// okResult is returned by mutating tools that main-server answers with 2xx-no-body.
type okResult struct {
	OK     bool   `json:"ok" jsonschema:"true when main-server accepted the operation"`
	Detail string `json:"detail" jsonschema:"human-readable outcome"`
}

// Register wires all in-scope tools onto the server, honoring ReadOnly.
func Register(reg *Registrar) {
	registerSubmissionTools(reg)
	registerGradingTools(reg)
}
