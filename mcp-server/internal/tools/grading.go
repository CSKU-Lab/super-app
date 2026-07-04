package tools

import (
	"context"

	"github.com/CSKU-Lab/mcp-server/internal/auth"
	"github.com/modelcontextprotocol/go-sdk/mcp"
)

type gradeSubmissionIn struct {
	ID          string `json:"id" jsonschema:"submission UUID"`
	ManualScore int    `json:"manual_score" jsonschema:"manual score to set (>= 0)"`
}

type regradeMaterialIn struct {
	SectionID  string `json:"section_id" jsonschema:"section UUID"`
	LabID      string `json:"lab_id" jsonschema:"lab UUID"`
	MaterialID string `json:"material_id" jsonschema:"material UUID"`
}

func registerGradingTools(r *Registrar) {
	// Grading is mutating — skip entirely in read-only mode.
	if r.deps.ReadOnly {
		return
	}

	mcp.AddTool(r.server, &mcp.Tool{
		Name:        "submission_grade",
		Description: "Set a manual score on a submission (POST /cms/submissions/:id/grade).",
	}, func(ctx context.Context, req *mcp.CallToolRequest, in gradeSubmissionIn) (*mcp.CallToolResult, okResult, error) {
		token, err := auth.Resolve(req, r.deps.StdioToken)
		if err != nil {
			return nil, okResult{}, err
		}
		if err := r.deps.Client.GradeSubmission(ctx, token, in.ID, in.ManualScore); err != nil {
			return nil, okResult{}, err
		}
		return nil, okResult{OK: true, Detail: "manual score set on " + in.ID}, nil
	})

	mcp.AddTool(r.server, &mcp.Tool{
		Name: "material_regrade",
		Description: "Bulk re-run grading for every submission of a material " +
			"(POST /cms/sections/:sectionID/labs/:labID/materials/:materialID/regrade). Async (202).",
	}, func(ctx context.Context, req *mcp.CallToolRequest, in regradeMaterialIn) (*mcp.CallToolResult, okResult, error) {
		token, err := auth.Resolve(req, r.deps.StdioToken)
		if err != nil {
			return nil, okResult{}, err
		}
		if err := r.deps.Client.RegradeMaterial(ctx, token, in.SectionID, in.LabID, in.MaterialID); err != nil {
			return nil, okResult{}, err
		}
		return nil, okResult{OK: true, Detail: "regrade queued for material " + in.MaterialID}, nil
	})
}
