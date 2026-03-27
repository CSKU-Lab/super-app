# Coordinator-Driven End-to-End Workflow

This document explains how to use the **Coordinator Primary Agent** to implement features across the CSKU Lab super-app using a coordinated team of specialist agents.

## Overview

The **Coordinator** is now a **primary agent** (switchable via Tab key) that orchestrates end-to-end feature implementation. Instead of directly implementing features, the Coordinator:

1. **Analyzes** your feature request
2. **Creates a GitHub issue** with structured requirements
3. **Routes work** to 5 specialist agents in parallel/sequential order
4. **Tracks progress** with real-time GitHub updates
5. **Handles failures** with retry logic
6. **Coordinates QA review** and merge decisions

## Quick Start

### 1. Switch to Coordinator Agent

Press **Tab** repeatedly to cycle through primary agents, or use your configured `switch_agent` keybind to select **coordinator**.

### 2. Describe Your Feature

Simply describe what you want to build:

```
Coordinator, implement user authentication with profile management.

Users should be able to:
- Sign up with email and password
- Log in with credentials
- View and edit their profile
- Log out
```

### 3. Coordinator Does The Rest

The Coordinator will:
- Create GitHub issue #999 with acceptance criteria
- Route specialists in parallel/sequential order
- Post progress updates to the GitHub issue
- Monitor specialist execution with retry logic
- Wait for QA approval
- Coordinate the merge

## Specialist Team

The Coordinator orchestrates these 5 specialists:

| Specialist | Role | Services |
|-----------|------|----------|
| **go-clean-arch** | Backend implementation | main-server, config-server, task-server, go-grader |
| **db-design-impl** | Database design & migrations | PostgreSQL (main-server), MongoDB (config/task servers) |
| **frontend-dev** | React/Next.js components | web (port 3000) |
| **service-comms** | gRPC APIs, message queues | Proto definitions, RabbitMQ |
| **qa-specialist** | Code review & testing | All services |

## Workflow Phases

### Phase 1: Analysis & Issue Creation

**Coordinator's Actions:**
- Parses your feature requirements
- Identifies affected services
- Creates structured GitHub issue
- Posts initial assignment comment

**You See:**
- Issue number: #999
- Issue title: "Add user authentication with profile management"
- Issue body: Requirements, acceptance criteria, service boundaries
- GitHub issue comment: Assignment list and timeline

### Phase 2: Specialist Execution

**Coordinator's Actions:**
- Routes independent tasks in parallel
- Routes dependent tasks sequentially
- Provides PR templates for consistency
- Posts progress updates as specialists work
- Monitors execution with retry logic

**Specialists Do:**
- Implement their assigned components
- Follow clean architecture patterns
- Write tests with >80% coverage
- Create PRs to feature branch
- Include `Closes #{issue}` in commit messages

**You See:**
- Real-time progress updates on GitHub issue
- PR links as they're created
- Status emoji indicators (🟡 IN_PROGRESS, ✅ COMPLETED, etc.)

### Phase 3: QA Review

**Coordinator's Actions:**
- Routes all PRs to qa-specialist
- Waits for QA feedback on GitHub issue
- Monitors QA review progress

**QA Specialist Does:**
- Reviews code quality, architecture, tests
- Verifies >80% test coverage
- Posts comprehensive feedback comment on GitHub issue
- Includes approval status: ✅ APPROVED or ❌ REJECTED

**You See:**
- QA feedback comment on GitHub issue #999
- Detailed review with strengths and comments
- Clear approval or rejection decision

### Phase 4: Merge Decision & Completion

**If QA Approves (✅):**
- Coordinator merges all PRs to main branch
- GitHub issue auto-closes
- Coordinator posts success summary
- Feature is live!

**If QA Rejects (❌):**
- Coordinator posts feedback comment
- Specialists fix issues based on QA comments
- Loop back to QA review
- Repeat until QA approves

## GitHub Issue Comments - Progress Tracking

The Coordinator posts structured comments to keep you informed:

### Initial Assignment
```
## Implementation Starting - Issue #999

**Assigned Specialists**:
- **go-clean-arch**: Create auth service, login/signup endpoints
- **db-design-impl**: Design users table with auth fields
- **frontend-dev**: Create LoginForm and UserProfile components
- **service-comms**: Define JWT token format

Timeline: Expected completion by [date]
Status: 🟡 IN_PROGRESS
```

### Progress Updates (As Work Completes)
```
## Progress Update - Issue #999

✅ db-design-impl: Users table schema created
✅ go-clean-arch: Auth service implemented
🟡 frontend-dev: LoginForm component in progress
🟡 service-comms: JWT format definition pending

Status: 🟡 IN_PROGRESS
```

### PR Created Notifications
```
## PR Created - Issue #999

PR #1001: feat(auth): add login/signup endpoints
- Specialist: go-clean-arch
- Service: main-server
- Status: 🟡 AWAITING_REVIEW
```

### QA Review Started
```
## QA Review Started - Issue #999

All specialists completed! QA is now reviewing:
- PR #1001: auth service
- PR #1002: users table
- PR #1003: login components

Status: 🟡 QA_REVIEW_IN_PROGRESS
```

### QA Feedback Posted
```
## QA Review Complete - Issue #999

✅ **APPROVED** - Ready for merge

Architecture: ✅ Clean separation of concerns
Testing: ✅ 85% coverage with integration tests
Security: ✅ No vulnerabilities
Git: ✅ Proper Closes # format
```

### Merge Confirmation
```
## Merging to Main - Issue #999

✅ All PRs approved by QA

Merged PRs:
- PR #1001: feat(auth): add login/signup endpoints
- PR #1002: feat(database): create users table
- PR #1003: feat(ui): add login components

GitHub issue will auto-close shortly. 🎉
```

## Failure Handling & Retry Logic

If a specialist encounters a problem, the Coordinator automatically retries:

### Retry Sequence

**Attempt 1 (Immediate):** Same task with clarified instructions
**Attempt 2 (2 min wait):** Simplified scope with step-by-step guidance
**Attempt 3 (5 min wait):** Very detailed step-by-step approach

### When Coordinator Escalates to You

After 3 failed attempts, the Coordinator posts an issue comment:

```
## ⚠️ Specialist Encountered Blocker - Issue #999

**Specialist**: go-clean-arch
**Task**: Implement authentication middleware
**Attempts**: 3 failed

**Error Context**:
- Attempt 1: Module import failed
- Attempt 2: Type mismatch in handler
- Attempt 3: Missing middleware pattern

**Please Help**: 
- Check if grpc-middleware package is in go.mod
- Or provide example middleware pattern from codebase

Status: 🔴 REQUIRES_USER_INPUT
```

**What You Should Do:**
- Respond to the issue comment with missing information
- The Coordinator will read your response and retry with updated context

## Example: Full Feature Implementation

### User Input
```
Coordinator, implement dark mode support for the application.

Users should be able to:
- Toggle dark/light mode in settings
- Have preference persisted across sessions
- See dark theme applied to all pages
- System theme preference is respected on first visit
```

### Coordinator Creates Issue #1005
- Title: "Add dark mode support"
- Body: Requirements, acceptance criteria, affected services
- Labels: feature, frontend, enhancement

### Coordinator Routes Specialists
```
In Parallel:
├─ frontend-dev: Create DarkModeToggle component, ThemeContext, CSS
└─ db-design-impl: Add user_preferences table for theme setting

Then Sequential:
└─ go-clean-arch: Add GET/PUT /api/v1/users/preferences endpoint
                  for persisting theme selection

Then Parallel:
├─ service-comms: Document new API endpoint
└─ qa-specialist: Review when all PRs created
```

### Progress Timeline
- **T+5min**: db-design-impl creates PR with migration
- **T+10min**: Coordinator posts progress update
- **T+15min**: frontend-dev creates PR with UI components
- **T+20min**: go-clean-arch creates PR with API endpoint
- **T+25min**: Coordinator posts all-PRs-created comment
- **T+30min**: qa-specialist reviews and approves
- **T+35min**: Coordinator merges PRs, issue auto-closes
- **T+40min**: Dark mode is live in production! 🎉

## Key Features

### ✅ Parallel Execution
Independent tasks run in parallel to save time. Database and frontend work simultaneously.

### ✅ Sequential Coordination
Dependent tasks run in order. API endpoints created before frontend consumes them.

### ✅ Real-Time Progress Tracking
GitHub issue comments keep you informed of every milestone.

### ✅ Automatic PR Template Generation
Each specialist gets a pre-filled PR template with acceptance criteria.

### ✅ Intelligent Retry Logic
Failed tasks retry with backoff and improved instructions.

### ✅ QA-Gated Merges
Code doesn't merge until QA approves. No surprises!

### ✅ One Issue Per Feature
All work tracked in single GitHub issue for traceability.

### ✅ Architecture Consistency
All code follows CSKU Lab clean architecture patterns.

## Tips for Best Results

### 1. Be Specific with Requirements
**Good:** "Add authentication with email/password and JWT tokens"
**Bad:** "Add authentication"

### 2. Include Acceptance Criteria
```
Users should be able to:
- [ ] Sign up with email and password
- [ ] Validate email format
- [ ] Hash passwords securely
- [ ] Log in with JWT token
- [ ] Refresh token after expiration
```

### 3. Mention Affected Services
```
This affects:
- Database: Add users table
- Backend: main-server API endpoints
- Frontend: Login page component
```

### 4. Watch the GitHub Issue
Keep the GitHub issue open to watch progress. New comments are posted as work advances.

### 5. Respond to Escalations Quickly
If Coordinator hits a blocker, respond to the issue comment quickly so retries can proceed.

## Common Patterns

### Pattern 1: Database-First Feature
```
Database schema → Backend API → Frontend UI
(Sequential: each depends on previous)
```

Example: "Add assignments feature"

### Pattern 2: Frontend-First Feature
```
Frontend components → Backend API → Database schema
(Sequential: frontend mock → backend implement → persist)
```

Example: "Add dark mode toggle" (can work without backend first)

### Pattern 3: Service Communication Feature
```
Proto definitions → Service implementation → Integration tests
(Sequential: contract first → implementation → testing)
```

Example: "Add config service endpoint"

### Pattern 4: Distributed System Feature
```
Database + gRPC proto + Services + Frontend (all parallel after schema)
(Parallel: each specialist works independently on their part)
```

Example: "Add distributed task grading" (all components needed)

## Troubleshooting

### Coordinator Doesn't Create Issue
**Check:** Are you using the Coordinator agent? (Tab to switch)
**Check:** Do you have GitHub access configured?
**Solution:** Run `gh auth login` to authenticate with GitHub

### Specialist Work Stalled
**Check:** GitHub issue comments for Coordinator status updates
**Check:** Any blocker/escalation comments from Coordinator?
**Action:** Respond to escalation comments with required information

### PR Created But Not Merged
**Likely Reason:** Awaiting QA review
**Check:** GitHub issue for "QA_REVIEW_IN_PROGRESS" status
**Wait:** QA specialist will post feedback comment

### Test Coverage Too Low
**Message from QA:** "Test coverage at 72%, below 80% requirement"
**Action:** QA posts rejection, Coordinator routes specialist back
**Next:** Specialist adds more tests, creates new PR
**Result:** QA re-reviews new PR, hopefully approves

## Performance Expectations

### Timeline by Complexity

**Simple Feature** (single service, <50 lines of code)
- Analysis & routing: 2 minutes
- Implementation: 5-10 minutes
- QA review: 5 minutes
- Total: ~15 minutes

**Medium Feature** (2-3 services, 200-500 lines of code)
- Analysis & routing: 3 minutes
- Parallel implementation: 15-20 minutes
- QA review: 10 minutes
- Total: ~30 minutes

**Complex Feature** (4+ services, database, APIs, UI)
- Analysis & routing: 5 minutes
- Parallel implementation: 30-45 minutes
- QA review: 15 minutes
- Total: ~60 minutes

## Architecture Compliance

All specialist work follows CSKU Lab patterns:

- **Clean Architecture**: Domain → Services → Handlers → Repositories
- **Testing**: >80% coverage with unit + integration tests
- **Error Handling**: Domain errors with proper logging
- **Database**: Migrations + indexes + proper normalization
- **API Design**: Consistent REST patterns, proper status codes
- **Frontend**: TypeScript, React patterns, TailwindCSS
- **Communication**: gRPC proto versioning, RabbitMQ patterns

## Getting Help

### Questions About Coordinator?
Ask directly in your OpenCode session. The Coordinator can explain its workflow.

### Feature Not Working as Expected?
Check `/home/imdev/dev/cs-lab/super-app/.opencode/agents/coordinator.md` for detailed instructions.

### Want to Customize?
Edit the coordinator.md file to change behavior, add new specialists, or modify workflow.

## Next Steps

1. **Switch to Coordinator**: Press Tab to select it as primary agent
2. **Describe a Feature**: Tell the Coordinator what to build
3. **Watch GitHub**: Open the created issue to see progress
4. **Wait for QA**: Coordinator will post when QA review is complete
5. **Celebrate**: Your feature is merged and live! 🎉
