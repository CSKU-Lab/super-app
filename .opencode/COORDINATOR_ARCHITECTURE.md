# Coordinator Workflow - Visual Architecture

## End-to-End Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    USER REQUEST                                  │
│         "Implement user authentication"                          │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
        ┌────────────────────────────────┐
        │  COORDINATOR (Primary Agent)   │
        │  ├─ Analyze requirements       │
        │  ├─ Identify services          │
        │  └─ Create GitHub issue #999   │
        └────────────┬───────────────────┘
                     │
        ┌────────────▼──────────────────┐
        │  GitHub Issue #999 Created    │
        │  Title: "User Authentication" │
        │  Labels: feature, backend...  │
        └────────────┬──────────────────┘
                     │
        ┌────────────▼───────────────────────────────┐
        │  Coordinator Posts Issue Comment:          │
        │  "Implementation Starting"                 │
        │  - Specialists assigned                    │
        │  - Timeline: ~30 minutes                   │
        │  - Status: 🟡 IN_PROGRESS                 │
        └────────────┬───────────────────────────────┘
                     │
         ┌───────────┼───────────┬──────────────┐
         │           │           │              │
         ▼           ▼           ▼              ▼
    ┌────────────┬────────┬──────────┬──────────────┐
    │  db-design │go-clean│frontend- │service-comms │
    │  -impl     │arch    │dev       │              │
    │            │        │          │              │
    │Create      │Implement│Create   │Define        │
    │users table │auth    │LoginForm │JWT format    │
    │migration   │service │component │in proto      │
    └──┬─────────┴──┬─────┴────┬─────┴────┬─────────┘
       │            │          │          │
       │(15 min)    │(20 min)  │(18 min) │(10 min)
       │            │          │          │
       ▼            ▼          ▼          ▼
   ┌─────────┐┌──────────┐┌──────────┐┌────────┐
   │PR #1001 ││PR #1002  ││PR #1003  ││PR #1004│
   │Database ││Backend   ││Frontend  ││API Doc │
   └─────────┘└──────────┘└──────────┘└────────┘
       │            │          │          │
       └────────────┼──────────┼──────────┘
                    │          │
       ┌────────────▼──────────▼────────────┐
       │  Coordinator Posts Issue Comment:  │
       │  "All PRs Created"                 │
       │  ✅ db-design-impl                 │
       │  ✅ go-clean-arch                  │
       │  ✅ frontend-dev                   │
       │  ✅ service-comms                  │
       │  Status: 🟡 AWAITING_QA_APPROVAL  │
       └────────────┬──────────────────────┘
                    │
       ┌────────────▼────────────────────┐
       │  qa-specialist Agent Invoked    │
       │  ├─ Review architecture         │
       │  ├─ Check test coverage (>80%)  │
       │  ├─ Verify security             │
       │  └─ Post feedback comment       │
       └────────────┬────────────────────┘
                    │
        ┌───────────▼───────────┐
        │  QA Posts Comment:    │
        │  ✅ APPROVED          │
        │  "All criteria met"   │
        └───────────┬───────────┘
                    │
        ┌───────────▼────────────────────┐
        │  Coordinator Reads Feedback    │
        │  Status = ✅ APPROVED          │
        │  → Proceed to merge            │
        └───────────┬────────────────────┘
                    │
    ┌───────────────┼───────────────────┐
    │               │                   │
    ▼               ▼                   ▼
┌────────────┐┌────────────┐┌───────────────┐
│Merge PR    ││Merge PR    ││Merge PR       │
│#1001 to    ││#1002 to    ││#1003 to main  │
│main        ││main        ││              │
└─────┬──────┘└─────┬──────┘└────┬─────────┘
      │            │             │
      └────────────┼─────────────┘
                   │
        ┌──────────▼──────────┐
        │ GitHub Issue #999   │
        │ Auto-closes ✅      │
        │ Commits merged      │
        └──────────┬──────────┘
                   │
        ┌──────────▼──────────────────────┐
        │ Coordinator Posts Final Comment │
        │ ✅ FEATURE COMPLETE             │
        │ Merged commits: abc123, def456  │
        │ Timeline: 45 minutes            │
        │ All tests passing               │
        └─────────────────────────────────┘
                   │
        ┌──────────▼──────────┐
        │   🎉 FEATURE LIVE   │
        │   Ready to deploy   │
        └─────────────────────┘
```

## Parallel vs Sequential Execution

### Parallel Execution (Independent Work)
```
Feature Request
     │
     ├─→ Database Schema Design ──────────────────┐
     │                                            │
     ├─→ Frontend Components ──────────────────┐  │
     │                                        │  │
     └─→ gRPC Proto Definitions ──────────────┼──┼─→ All Complete
                                              │  │
                                              └──┘
                   ⏱️  Total Time: ~20 minutes
      (instead of sequential: ~60 minutes)
```

### Sequential Execution (Dependent Work)
```
Database Schema Design
     │
     ▼
Repository Layer Implementation
     │
     ▼
Service Layer Implementation
     │
     ▼
API Endpoint Handler
     │
     ▼
Frontend Component Integration
     │
     ▼
All Complete

     ⏱️  Total Time: ~45 minutes
```

### Mixed Parallel & Sequential
```
START
  │
  ├─→ [PARALLEL] Database Design & Frontend UI (independent)
  │        │
  │        └─→ [SEQUENTIAL] Database → Repository → Service
  │                            │
  │                            ▼
  │                    Service Ready
  │        │
  │        └─→ Frontend UI Complete
  │        │
  │        └─→ [PARALLEL] Integrate both (independent integration)
  │                 │
  ├─→ Service Comms: Proto & API Docs (parallel to above)
  │        │
  └─→ [WAIT] All services complete
        │
        ▼
   QA Review
        │
        ▼
   Merge & Deploy
```

## Specialist Routing Decision Tree

```
Feature Request Received
        │
        ▼
Is it database-related?
        │
    ┌───┴───┐
    │ YES   │ NO
    ▼       ▼
┌───────┐  Does it involve backend logic?
│ DB    │      │
│spec   │  ┌───┴───┐
│       │  │ YES   │ NO
└───────┘  ▼       ▼
      ┌────────┐  Does it involve API communication?
      │Backend │      │
      │spec    │  ┌───┴────┐
      │        │  │ YES    │ NO
      └────────┘  ▼        ▼
            ┌──────────┐  Does it have UI?
            │Comms spec│     │
            │          │ ┌───┴───┐
            └──────────┘ │ YES   │ NO
                         ▼       ▼
                    ┌────────┐  └─ (routing issue, re-analyze)
                    │Frontend│
                    │spec    │
                    └────────┘

Assign All Affected Specialists in Parallel if Independent,
Sequential if Dependent on Each Other's Output
```

## Failure Handling Flow

```
Specialist Task Assigned
        │
        ▼
Task Execution
        │
    ┌───┴───┐
    │       │
Success │   │ Failure
    ▼       ▼
Continue  Retry Attempt 1
          ├─ Same task
          ├─ Clearer instructions
          ├─ No wait
          │
          ▼
        Success? 
          ├─ YES → Continue
          └─ NO  ↓
              Retry Attempt 2
              ├─ Simplified scope
              ├─ Step-by-step guide
              ├─ Wait 2 minutes
              │
              ▼
            Success?
              ├─ YES → Continue
              └─ NO  ↓
                  Retry Attempt 3
                  ├─ Minimal scope
                  ├─ Very detailed steps
                  ├─ Code templates
                  ├─ Wait 5 minutes
                  │
                  ▼
                Success?
                  ├─ YES → Continue
                  └─ NO  ↓
                      ESCALATE
                      ├─ Post issue comment
                      ├─ List all error contexts
                      ├─ Ask for user help
                      └─ Wait for response
                           │
                           ▼
                      User Provides Input
                           │
                           ▼
                      Retry with context
```

## GitHub Issue Lifecycle

```
┌─ CREATED ─────────────────────────────────────────────────────────┐
│                                                                    │
│  Created: 2024-03-28 14:30                                        │
│  Title: "Add user authentication with profile management"         │
│  Status: 🟡 OPEN                                                 │
│  Labels: feature, backend, database, frontend                    │
│                                                                    │
└────────────────────────┬────────────────────────────────────────────┘
                         │
       ┌─────────────────▼────────────────┐
       │ Coordinator Comment #1           │
       │ "Implementation Starting"        │
       │ 🟡 Specialists assigned          │
       └─────────────────┬────────────────┘
                         │
       ┌─────────────────▼────────────────┐
       │ Coordinator Comment #2           │
       │ "Progress Update"                │
       │ ✅ Database ready                │
       │ 🟡 Backend in progress           │
       │ 🟡 Frontend in progress          │
       └─────────────────┬────────────────┘
                         │
       ┌─────────────────▼────────────────┐
       │ Coordinator Comment #3           │
       │ "All PRs Created"                │
       │ PR #1001, #1002, #1003           │
       │ 🟡 Awaiting QA review            │
       └─────────────────┬────────────────┘
                         │
       ┌─────────────────▼────────────────┐
       │ QA Specialist Comment #4         │
       │ "QA Review Complete"             │
       │ ✅ APPROVED                      │
       │ "Architecture excellent, tests   │
       │  comprehensive, no issues"       │
       └─────────────────┬────────────────┘
                         │
       ┌─────────────────▼────────────────┐
       │ Coordinator Comment #5           │
       │ "Merging to Main"                │
       │ ✅ PR #1001 merged               │
       │ ✅ PR #1002 merged               │
       │ ✅ PR #1003 merged               │
       │ Issue auto-closing...            │
       └─────────────────┬────────────────┘
                         │
┌─ CLOSED ──────────────▼────────────────────────────────────────────┐
│                                                                    │
│  Closed: 2024-03-28 15:15                                         │
│  Status: ✅ COMPLETED                                             │
│  Merged commits: abc123, def456, ghi789                          │
│  Timeline: 45 minutes                                             │
│                                                                    │
└────────────────────────────────────────────────────────────────────┘
```

## Data Flow: Issue → Specialists → PRs → Merge

```
GitHub Issue #999
     │
     ├─→ Title: "Add authentication"
     ├─→ Description: Requirements, acceptance criteria
     ├─→ Labels: feature, backend, database, frontend
     │
     ▼
Coordinator Parses Issue
     │
     ├─→ Affected services: [main-server, users-db, web]
     ├─→ Specialists: [db-design-impl, go-clean-arch, frontend-dev]
     ├─→ Dependencies: db → backend → frontend
     │
     ▼
Specialist Assignment with PR Template
     │
     ├─→ db-design-impl
     │    ├─ Task: Design users table with auth fields
     │    ├─ PR Template: (pre-filled with issue context)
     │    └─ Expected Output: PR #1001
     │
     ├─→ go-clean-arch
     │    ├─ Task: Implement auth service
     │    ├─ PR Template: (pre-filled with issue context)
     │    └─ Expected Output: PR #1002
     │
     └─→ frontend-dev
         ├─ Task: Create login form
         ├─ PR Template: (pre-filled with issue context)
         └─ Expected Output: PR #1003
     │
     ▼
Specialists Create PRs
     │
     ├─→ PR #1001: "feat(database): create users table"
     │    ├─ Branch: feat/999-database/users-table
     │    ├─ Commits: Closes #999
     │    └─ Status: ✅ Ready
     │
     ├─→ PR #1002: "feat(api): add authentication endpoints"
     │    ├─ Branch: feat/999-backend/auth-endpoints
     │    ├─ Commits: Closes #999
     │    └─ Status: ✅ Ready
     │
     └─→ PR #1003: "feat(ui): add login form component"
         ├─ Branch: feat/999-frontend/login-form
         ├─ Commits: Closes #999
         └─ Status: ✅ Ready
     │
     ▼
Coordinator Sends to QA
     │
     └─→ QA Reviews All PRs
         ├─ Architecture ✅
         ├─ Tests >80% ✅
         ├─ Security ✅
         └─ Git format ✅ → APPROVED
     │
     ▼
Coordinator Merges PRs
     │
     ├─→ Merge PR #1001 to main
     ├─→ Merge PR #1002 to main
     ├─→ Merge PR #1003 to main
     │
     ▼
GitHub Issue Auto-Closes
     │
     └─→ Issue #999 marked CLOSED
         All merged commits: abc123, def456, ghi789
         Timeline: 45 minutes
```

## Retry Strategy Timeline

```
Task: Implement authentication middleware

T+0:00   Specialist receives task
         │
         ▼
T+0:05   First attempt completes
         ├─ Result: ❌ Module import failed
         │
         ▼
T+0:06   Retry Attempt 1 (immediate)
         ├─ Instructions: "Here's the corrected approach..."
         ├─ Context: "Import grpc-middleware package"
         │
         ▼
T+0:10   Attempt 1 result: ❌ Type mismatch
         │
         ▼
T+0:12   Wait 2 minutes [........]
         │
         ▼
T+0:14   Retry Attempt 2 (simplified scope)
         ├─ Instructions: "Let's break this down..."
         ├─ Approach: "First implement basic middleware, extend later"
         │
         ▼
T+0:18   Attempt 2 result: ❌ Pattern not matching codebase
         │
         ▼
T+0:20   Wait 5 minutes [................]
         │
         ▼
T+0:25   Retry Attempt 3 (step-by-step + templates)
         ├─ Instructions: "Follow these exact patterns..."
         ├─ Templates: Full code examples from codebase
         │
         ▼
T+0:30   Attempt 3 result: ✅ SUCCESS
         └─ Specialist continues with task
```

## Agent Switching During Development

```
User → [Tab] → Select Agent

┌─────────────────────────────────────┐
│  PRIMARY AGENTS (Tab-selectable)    │
├─────────────────────────────────────┤
│ → coordinator (NEW - primary)       │
│   build (traditional)               │
│   plan (analysis)                   │
└─────────────────────────────────────┘
         ↓
User selects "coordinator"
         ↓
┌─────────────────────────────────────┐
│  COORDINATOR SESSION                │
├─────────────────────────────────────┤
│ "Add dark mode support"             │
│                                     │
│ Coordinator analyzes...             │
│ Creates GitHub issue #1005...       │
│ Routes to specialists...            │
│ Posts progress updates...           │
│ Waits for QA approval...            │
│ Merges when approved...             │
└─────────────────────────────────────┘
         ↓
Feature complete! Switch back to:
├─ Tab → build (for quick fixes)
├─ Tab → plan (for analysis)
└─ Tab → coordinator (for next feature)
```

This visual architecture shows how all components work together to deliver end-to-end features with coordination, quality gates, and comprehensive tracking.
