package tools

import (
	"context"

	"github.com/CSKU-Lab/mcp-server/internal/auth"
	"github.com/CSKU-Lab/mcp-server/internal/mainclient"
	"github.com/modelcontextprotocol/go-sdk/mcp"
)

type getSubmissionIn struct {
	ID string `json:"id" jsonschema:"submission UUID"`
}

type listSubmissionsIn struct {
	MaterialID string `json:"material_id,omitempty" jsonschema:"filter by material UUID"`
	SectionID  string `json:"section_id,omitempty" jsonschema:"filter by section UUID"`
	LabID      string `json:"lab_id,omitempty" jsonschema:"filter by lab UUID"`
	Page       int    `json:"page,omitempty" jsonschema:"1-based page number (default 1)"`
	PageSize   int    `json:"page_size,omitempty" jsonschema:"rows per page (default 20)"`
	SortOrder  string `json:"sort_order,omitempty" jsonschema:"asc or desc (default desc)"`
}

type deleteSubmissionIn struct {
	ID string `json:"id" jsonschema:"submission UUID to delete"`
}

func registerSubmissionTools(r *Registrar) {
	mcp.AddTool(r.server, &mcp.Tool{
		Name:        "submission_get",
		Description: "Get a single submission by ID (CMS view: score, status, payload, results).",
	}, func(ctx context.Context, req *mcp.CallToolRequest, in getSubmissionIn) (*mcp.CallToolResult, jsonResult, error) {
		token, err := auth.Resolve(req, r.deps.StdioToken)
		if err != nil {
			return nil, jsonResult{}, err
		}
		raw, err := r.deps.Client.GetSubmission(ctx, token, in.ID)
		if err != nil {
			return nil, jsonResult{}, err
		}
		res, err := decodeResult(raw)
		if err != nil {
			return nil, jsonResult{}, err
		}
		return textOf(raw), res, nil
	})

	mcp.AddTool(r.server, &mcp.Tool{
		Name: "submission_list",
		Description: "List submissions for the CALLING admin user (caller-scoped — main-server has no " +
			"list-all-users endpoint). Optional filters: material_id, section_id, lab_id + pagination.",
	}, func(ctx context.Context, req *mcp.CallToolRequest, in listSubmissionsIn) (*mcp.CallToolResult, jsonResult, error) {
		token, err := auth.Resolve(req, r.deps.StdioToken)
		if err != nil {
			return nil, jsonResult{}, err
		}
		raw, err := r.deps.Client.ListMySubmissions(ctx, token, mainclient.ListSubmissionsQuery{
			MaterialID: in.MaterialID,
			SectionID:  in.SectionID,
			LabID:      in.LabID,
			Page:       in.Page,
			PageSize:   in.PageSize,
			SortOrder:  in.SortOrder,
		})
		if err != nil {
			return nil, jsonResult{}, err
		}
		res, err := decodeResult(raw)
		if err != nil {
			return nil, jsonResult{}, err
		}
		return textOf(raw), res, nil
	})

	if r.deps.ReadOnly {
		return
	}

	mcp.AddTool(r.server, &mcp.Tool{
		Name:        "submission_delete",
		Description: "Delete a submission by ID. Irreversible.",
	}, func(ctx context.Context, req *mcp.CallToolRequest, in deleteSubmissionIn) (*mcp.CallToolResult, okResult, error) {
		token, err := auth.Resolve(req, r.deps.StdioToken)
		if err != nil {
			return nil, okResult{}, err
		}
		if err := r.deps.Client.DeleteSubmission(ctx, token, in.ID); err != nil {
			return nil, okResult{}, err
		}
		return nil, okResult{OK: true, Detail: "submission " + in.ID + " deleted"}, nil
	})
}
