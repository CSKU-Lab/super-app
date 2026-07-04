package mainclient

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
	"time"
)

// Client is a thin REST client for main-server. Every call carries the caller's
// cs-lab access_token as the access_token cookie, so main-server's
// ProtectedRouteMiddleware + permission checks run exactly as they would for a
// browser request. The MCP performs no authorization of its own.
type Client struct {
	base string
	http *http.Client
}

func New(baseURL string) *Client {
	return &Client{
		base: strings.TrimRight(baseURL, "/"),
		http: &http.Client{Timeout: 30 * time.Second},
	}
}

// do issues a request to path (already including /api/v1/...), attaching the
// access_token cookie. body may be nil. On non-2xx it returns an error carrying
// the response body. out (if non-nil) is JSON-decoded from the response.
func (c *Client) do(ctx context.Context, method, path, token string, body any, out any) error {
	var rdr io.Reader
	if body != nil {
		b, err := json.Marshal(body)
		if err != nil {
			return fmt.Errorf("marshal body: %w", err)
		}
		rdr = bytes.NewReader(b)
	}

	req, err := http.NewRequestWithContext(ctx, method, c.base+path, rdr)
	if err != nil {
		return err
	}
	req.Header.Set("Content-Type", "application/json")
	req.AddCookie(&http.Cookie{Name: "access_token", Value: token})

	resp, err := c.http.Do(req)
	if err != nil {
		return fmt.Errorf("call %s %s: %w", method, path, err)
	}
	defer resp.Body.Close()

	data, _ := io.ReadAll(resp.Body)
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return fmt.Errorf("main-server %s %s: %d %s", method, path, resp.StatusCode, strings.TrimSpace(string(data)))
	}
	if out != nil && len(data) > 0 {
		if err := json.Unmarshal(data, out); err != nil {
			return fmt.Errorf("decode response: %w", err)
		}
	}
	return nil
}

// --- Submissions ---

// GetSubmission: GET /api/v1/cms/submissions/:id  -> models.Submission (raw JSON).
func (c *Client) GetSubmission(ctx context.Context, token, id string) (json.RawMessage, error) {
	var out json.RawMessage
	err := c.do(ctx, http.MethodGet, "/api/v1/cms/submissions/"+url.PathEscape(id), token, nil, &out)
	return out, err
}

// DeleteSubmission: DELETE /api/v1/cms/submissions/:id -> 204.
func (c *Client) DeleteSubmission(ctx context.Context, token, id string) error {
	return c.do(ctx, http.MethodDelete, "/api/v1/cms/submissions/"+url.PathEscape(id), token, nil, nil)
}

// ListMySubmissions: GET /api/v1/submissions/ — caller-scoped (returns the
// token owner's submissions, NOT all users'). Filters are optional.
func (c *Client) ListMySubmissions(ctx context.Context, token string, q ListSubmissionsQuery) (json.RawMessage, error) {
	vals := url.Values{}
	if q.MaterialID != "" {
		vals.Set("material_id", q.MaterialID)
	}
	if q.SectionID != "" {
		vals.Set("section_id", q.SectionID)
	}
	if q.LabID != "" {
		vals.Set("lab_id", q.LabID)
	}
	if q.Page > 0 {
		vals.Set("page", fmt.Sprint(q.Page))
	}
	if q.PageSize > 0 {
		vals.Set("page_size", fmt.Sprint(q.PageSize))
	}
	if q.SortOrder != "" {
		vals.Set("sort_order", q.SortOrder)
	}
	path := "/api/v1/submissions/"
	if e := vals.Encode(); e != "" {
		path += "?" + e
	}
	var out json.RawMessage
	err := c.do(ctx, http.MethodGet, path, token, nil, &out)
	return out, err
}

type ListSubmissionsQuery struct {
	MaterialID string
	SectionID  string
	LabID      string
	Page       int
	PageSize   int
	SortOrder  string
}

// --- Grading ---

// GradeSubmission: POST /api/v1/cms/submissions/:id/grade  {manual_score} -> 204.
func (c *Client) GradeSubmission(ctx context.Context, token, id string, manualScore int) error {
	body := map[string]int{"manual_score": manualScore}
	return c.do(ctx, http.MethodPost, "/api/v1/cms/submissions/"+url.PathEscape(id)+"/grade", token, body, nil)
}

// RegradeMaterial: POST /api/v1/cms/sections/:sectionID/labs/:labID/materials/:materialID/regrade -> 202.
func (c *Client) RegradeMaterial(ctx context.Context, token, sectionID, labID, materialID string) error {
	path := fmt.Sprintf("/api/v1/cms/sections/%s/labs/%s/materials/%s/regrade",
		url.PathEscape(sectionID), url.PathEscape(labID), url.PathEscape(materialID))
	return c.do(ctx, http.MethodPost, path, token, nil, nil)
}
