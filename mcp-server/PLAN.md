# cs-lab admin MCP — roadmap

Status of the build and what's left. v1 (submissions + grading) is implemented and
building; everything below is planned.

## Done — v1

- [x] Transport switch: `http` (primary/prod, Streamable HTTP) + `stdio` (local), `--readonly` gate
- [x] Token forwarding auth (no local validation; main-server enforces)
- [x] main-server REST client
- [x] Tools: `submission_get`, `submission_list`, `submission_delete`, `submission_grade`, `material_regrade`
- [x] Dockerfile.prod, gitops Jsonnet example

## Decisions locked

| Decision | Choice |
|----------|--------|
| Primary transport | `http` (prod); `stdio` for local admin |
| Backend wiring | REST → main-server (reuse its RBAC/permission logic) |
| Auth | forward caller `access_token`; MCP validates nothing |
| v1 tool scope | submissions + grading |
| Tasks | **dropped from v1** — gRPC-only, no REST |

---

## Remaining work

### 1. Repo & CI
- [ ] Decide home: standalone `CSKU-Lab/mcp-server` repo vs super-app subdir (currently subdir).
- [ ] If standalone: extract, add as submodule, wire CI (build + push `cskulab/mcp-server:<tag>`).
- [ ] Add `otel` shared module (`github.com/CSKU-Lab/otel`) for tracing — matches the other four services. Currently the OTEL env vars are set in gitops but not consumed.

### 2. Close the v1 auth/observability gaps
- [ ] OTEL wiring: init `CSKU-Lab/otel` in `main()`, instrument the http handler + main-server client (otelhttp).
- [ ] Structured request logging + a real `/healthz` that pings main-server.
- [ ] `CrossOriginProtection` on the Streamable HTTP handler if exposed beyond localhost.

### 3. Fix `submission_list` cross-user gap
main-server has no list-all-users submissions endpoint. Options (pick one):
- [ ] **A** — add `GET /api/v1/cms/submissions` (admin, filters: user/material/section/lab + pagination) to main-server, then a `submission_list_all` tool. *(uniform, real auth)*
- [ ] **B** — add a `gradebook_export` tool wrapping `GET /cms/sections/:id/gradebook/export` (XLSX) for cross-user grade views. *(no main-server change)*

### 4. Tasks (re-add, deferred from v1)
- [ ] Either add `/cms/tasks` REST proxy in main-server wrapping `TaskService` gRPC (keeps MCP pure-REST + real auth), **or**
- [ ] add a gRPC client in the MCP (copy `main-server/internal/providers/external.go`) — but then task tools bypass main-server auth and MUST re-validate JWT+admin locally.
- [ ] Tools: `task_list`, `task_get`, `task_create`, `task_update`, `task_delete`.

### 5. v2 tool groups (all REST-ready in main-server)
- [ ] **Users** (`/api/v1/admin/users`): `user_list`, `user_get`, `user_create`, `user_import`, `user_update`, `user_delete`, `user_delete_many`.
- [ ] **Materials** (`/api/v1/cms/.../materials`): `material_list`, `material_get`, `material_create`, `material_update`.
- [ ] **Analytics** (`/api/v1/admin/analytics`): `analytics_get`.
- [ ] **Sections/gradebook**: `section_student_status`, `gradebook_get`, `gradebook_export`.

### 6. Config / runners / compares (v3, gRPC)
Only reachable via `ConfigService` gRPC (config-server :8081). Same tradeoff as tasks —
needs either a main-server REST proxy or a direct gRPC client + local auth.
- [ ] `runner_*`, `compare_*` CRUD.

### 7. Grading depth (v3, gRPC)
`GraderService` (go-grader :50052) `Run`/`Grade`/`GenerateTestCases`/`Broadcast` — no
REST passthrough. Only if low-level grader control is needed beyond `material_regrade`.

### 8. Remote http access
- [ ] Decide how MCP clients supply the admin `access_token` over http:
  - client-config header injection (`Authorization: Bearer`), **or**
  - a proper OAuth/session bridge to cs-lab identity.
- [ ] Ingress + TLS if exposed outside the cluster; otherwise keep in-cluster + port-forward.

### 9. Tests
- [ ] Unit: `auth.Resolve` (bearer/cookie/env/missing), `mainclient` (httptest server, cookie attach, error body).
- [ ] Integration: tools/list snapshot per `--readonly`, one happy-path per tool against a mock main-server.
