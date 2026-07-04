# cs-lab admin MCP server

An [MCP](https://modelcontextprotocol.io) server exposing cs-lab admin operations
as tools. Thin proxy over **main-server**'s REST API — it holds no auth logic and
no secrets; it forwards the caller's `access_token` to main-server, which owns JWT
+ admin/RBAC/permission enforcement.

Built with the official [Go SDK](https://github.com/modelcontextprotocol/go-sdk) `v1.6.1`.

## Transports

`http` is the primary (prod) transport; `stdio` is for local admin use.

```bash
# http (prod) — Streamable HTTP, one endpoint at /mcp
mcp-server --transport=http --addr=:8090

# stdio (local) — token comes from CSLAB_ACCESS_TOKEN
CSLAB_ACCESS_TOKEN=<cs-lab access_token> mcp-server --transport=stdio
```

> Uses **Streamable HTTP**, not the deprecated HTTP+SSE transport.

### Flags / env

| Flag | Env | Default | Meaning |
|------|-----|---------|---------|
| `--transport` | `MCP_TRANSPORT` | `http` | `http` or `stdio` |
| `--addr` | `MCP_ADDR` | `:8090` | http listen address |
| `--path` | `MCP_PATH` | `/mcp` | http endpoint path |
| `--readonly` | — | `false` | register only `*_get` / `*_list` tools |
| — | `MAIN_SERVER_URL` | *(required)* | main-server base URL |
| — | `CSLAB_ACCESS_TOKEN` | *(required for stdio)* | admin access_token |

## Auth

The MCP performs **no** authorization. Per call it resolves a cs-lab `access_token`:

- **http**: from the incoming MCP request — `Authorization: Bearer <token>` **or**
  `Cookie: access_token=<token>`.
- **stdio**: from `CSLAB_ACCESS_TOKEN`.

The token is attached as the `access_token` cookie on every main-server call, so
`ProtectedRouteMiddleware` + per-resource `Permission(...)` checks run exactly as
for a browser. A non-admin token simply gets 403s from main-server. This means the
MCP can never become an auth bypass, and there is no duplicated/drifting JWT logic.

## Tools (v1: submissions + grading)

| Tool | main-server endpoint | Mutating |
|------|----------------------|----------|
| `submission_get` | `GET /api/v1/cms/submissions/:id` | no |
| `submission_list` | `GET /api/v1/submissions/` *(caller-scoped)* | no |
| `submission_delete` | `DELETE /api/v1/cms/submissions/:id` | yes |
| `submission_grade` | `POST /api/v1/cms/submissions/:id/grade` | yes |
| `material_regrade` | `POST /api/v1/cms/sections/:sectionID/labs/:labID/materials/:materialID/regrade` | yes |

### Known gaps / v1 scope

- **Tasks excluded.** main-server has no task REST — `TaskService` is gRPC-only.
  v1 is REST-to-main-server only. Add later via gRPC client or a main-server task
  REST proxy.
- **`submission_list` is caller-scoped.** main-server has no list-all-users
  submissions endpoint; it returns the token owner's submissions. For cross-user
  views use gradebook export (a future tool) or add an admin list endpoint.

## Deploy (GitOps / ArgoCD)

Example manifests in [`deploy/gitops/apps/mcp-server/`](./deploy/gitops/apps/mcp-server).
To ship:

1. Build & push `cskulab/mcp-server:<tag>` (see `Dockerfile.prod`).
2. Copy `deploy/gitops/apps/mcp-server/` into the `gitops` repo under `apps/`.
   (Uses shared libs `../../lib/{deployment,service,configmap}.libsonnet`.)
3. Register in `gitops/argocd/appsets/apps-appset.jsonnet` `autoApps`:
   ```jsonnet
   { name: 'mcp-server', path: 'apps/mcp-server', serverSideApply: true },
   ```
4. Verify `mainServerUrl` port in `params.libsonnet` matches main-server's Service.
5. Expose externally (Ingress) only if remote MCP clients need it; otherwise keep
   it in-cluster and reach it via port-forward.

No ExternalSecret is needed — the MCP stores no credentials.

## Layout

```
cmd/mcp-server/main.go        flag/env parse, transport switch
internal/config               config load + validate
internal/auth                 per-request token resolution (no validation)
internal/mainclient           main-server REST client (forwards access_token)
internal/tools                tool definitions (submissions, grading)
internal/server               builds mcp.Server, registers tools
deploy/gitops                 ArgoCD/Jsonnet deploy example
```
