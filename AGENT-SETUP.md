# CSKU Lab Agent Team Setup Guide

Welcome to the AI Agent Team System for CSKU Lab! This guide will help you get started with our automated feature development platform.

## What is the Agent Team System?

The Agent Team System uses 6 specialized AI agents to implement features across CSKU Lab's microservices platform:

- **Coordinator**: Routes feature requests to specialist agents
- **Go Services Specialist**: Implements features in Go microservices
- **Database Specialist**: Designs schemas and manages migrations
- **Communication Specialist**: Handles gRPC, RabbitMQ, and API documentation
- **Frontend Specialist**: Builds React/Next.js components and interfaces
- **QA Specialist**: Reviews code, validates tests, and approves merges

## Quick Start

### 1. Request a Feature

Switch to the `@coordinator` agent:

```
@coordinator - Please add a user profile API endpoint that returns name, email, role
```

### 2. Let Agents Work

The coordinator will:
- Create a GitHub issue
- Route work to appropriate specialists
- Manage parallel/sequential task execution
- Track progress

### 3. Review & Approve

The QA specialist will:
- Review code quality
- Validate test coverage (>80%)
- Check commit message format
- Auto-merge subtask PRs to feature branch

### 4. Complete the Feature

You create a final PR from feature branch → main:
- All subtask PRs merged automatically
- Feature branch ready to merge
- GitHub issue auto-closes on merge

## Architecture Overview

### Service Distribution

```
┌─────────────────────────────────┐
│      @coordinator               │
│  Route tasks to specialists     │
└────────────┬────────────────────┘
             │
    ┌────────┼────────┬─────────┬──────────┐
    ▼        ▼        ▼         ▼          ▼
 @go-    @db-      @service- @frontend- @qa-
 clean-  design-   comms      dev        specialist
 arch    impl
```

### Git Workflow

```
main (origin)
  │
  ├── feat/999-user-profile (your feature branch)
  │   ├── feat/999-api/user-profile (subtask 1)
  │   ├── feat/999-database/users-table (subtask 2)
  │   └── feat/999-ui/profile-page (subtask 3)
  │       ↓ (QA auto-merges)
  │   [all merged to feature branch]
  │   ↓ (you create final PR)
  └── [merged to main, issue auto-closes]
```

## Feature Request Examples

### Example 1: API Endpoint

```
@coordinator - Add GET /api/v1/submissions/{id} endpoint that returns
submission details. Requires authentication. Include proper error
handling and tests.
```

**What happens**:
- Coordinator creates GitHub issue
- go-clean-arch implements handler + tests
- db-design-impl ensures database queries ready
- qa-specialist reviews and approves
- All PRs auto-merge to feature branch

### Example 2: UI Component

```
@coordinator - Create a submission list component showing submission
ID, status, grade, and timestamp. Make it responsive and sortable
by status.
```

**What happens**:
- Coordinator creates GitHub issue
- frontend-dev implements React component + tests
- service-comms ensures API endpoints documented
- qa-specialist reviews responsiveness and tests
- PR auto-merges to feature branch

### Example 3: Database Feature

```
@coordinator - Add soft-delete support to submissions (add deleted_at
column, update queries to filter, add migration).
```

**What happens**:
- Coordinator creates GitHub issue
- db-design-impl designs schema and migration
- go-clean-arch updates repository queries
- service-comms updates API documentation
- qa-specialist validates coverage and migration safety
- All PRs auto-merge to feature branch

## Branch Naming Convention

### Feature Branch (Your Branch)
```
feat/{issue-number}-{title}

Examples:
feat/999-user-profile
feat/1000-soft-delete
feat/1001-admin-dashboard
```

### Subtask Branch (Agent Branch)
```
feat/{issue}-{domain}/{description}

Examples:
feat/999-api/user-profile-endpoint
feat/999-database/users-table
feat/999-ui/profile-page
```

### Domain Values
- `api` - REST API endpoints (go-clean-arch)
- `database` - Database schemas (db-design-impl)
- `grpc` - gRPC services (service-comms)
- `message-queue` - RabbitMQ patterns (service-comms)
- `ui` - Frontend components (frontend-dev)
- `test` - Test infrastructure (qa-specialist)

## Commit Message Format

All commits must follow this format:

```
type(scope): description

Detailed explanation (optional)

Closes #{issue-number}
```

### Types
- `feat` - New feature
- `fix` - Bug fix
- `refactor` - Code refactoring
- `test` - Test addition
- `docs` - Documentation
- `chore` - Maintenance

### Scopes
- `api` - REST endpoints
- `service` - Business logic
- `repository` - Data access
- `handler` - HTTP handlers
- `database` - Schema/migrations
- `grpc` - gRPC services
- `ui` - Frontend components
- `middleware` - Cross-cutting concerns

### Example
```
feat(api): add user profile endpoint

- Implement GET /api/v1/users/me handler
- Add authentication middleware requirement
- Include unit tests with mocked repository
- Include integration tests with test database

Closes #999
```

## How Agents Collaborate

### Sequential Dependencies

When features depend on each other:

1. **Database Schema First**
   - db-design-impl creates migration
   - Go services wait for schema

2. **Service Implementation**
   - go-clean-arch implements handlers
   - service-comms designs API contract

3. **Frontend Integration**
   - frontend-dev builds UI
   - service-comms updates API docs

### Parallel Work

When work is independent:

- API endpoint & UI component → work in parallel
- Multiple gRPC services → work in parallel
- Unrelated features → work in parallel

The coordinator manages this automatically!

## Testing Requirements

### Go Services (>80% coverage)

```bash
# Unit tests with mocks
func TestGetUser_Success(t *testing.T) {
    mockRepo := new(MockUserRepo)
    // ... test implementation
}

# Integration tests with real DB
func TestGetUserFromDatabase(t *testing.T) {
    db := setupTestDB(t)
    // ... test with real database
}
```

### Frontend (>80% coverage)

```tsx
// Component tests
test('should display user profile when loaded', async () => {
  mockAPI.getUserProfile.mockResolvedValue(mockUser);
  render(<UserProfile userId="123" />);
  expect(screen.getByText('John')).toBeInTheDocument();
});
```

### Coverage Validation

```bash
# Go
go test -cover ./...

# Frontend
npm test -- --coverage
```

## Common Workflows

### Add a New API Endpoint

```
@coordinator - Add POST /api/v1/submissions endpoint that accepts
code, language, taskId. Validate inputs, save to database, queue
for grading.
```

**Expected steps**:
1. db-design-impl: Verify schema ready
2. go-clean-arch: Implement handler + repository
3. service-comms: Document in Postman
4. qa-specialist: Review and approve
5. You: Create final PR feature → main

### Fix a Bug

```
@coordinator - Fix: User profile endpoint returns 500 when user not
found (should return 404). Include test covering the issue.
```

**Expected steps**:
1. go-clean-arch: Fix error handling
2. qa-specialist: Verify test coverage
3. service-comms: Update API docs if needed
4. You: Create final PR feature → main

### Refactor Database Schema

```
@coordinator - Refactor: Split users table into users + user_profiles
for better separation. Include migration, update all queries.
```

**Expected steps**:
1. db-design-impl: Design migration
2. go-clean-arch: Update repository queries
3. frontend-dev: Update state management
4. qa-specialist: Verify backward compatibility
5. You: Create final PR feature → main

## Troubleshooting

### Agent is Stuck or Unresponsive

If an agent hasn't completed work in a reasonable time:

```
@coordinator - Check status of agent work on issue #999.
Can you review what go-clean-arch is working on?
```

### Test Coverage Below 80%

```
@go-clean-arch - Test coverage is at 75%. Please add tests
for the error handling paths to reach 80% coverage.
```

### Merge Conflicts

```
@coordinator - Feature branch has conflicts. Can you coordinate
a rebase against main for the subtask branches?
```

## Checking Progress

### View Branch Status

```bash
git branch -a --list 'feat/*'
git log --graph --oneline --decorate --all
```

### Check PR Status

```bash
gh pr list --state open --search "is:pr"
gh pr view <PR-NUMBER>
```

### View Issue Status

```bash
gh issue view <ISSUE-NUMBER>
```

## What's Next?

1. **Read Full Documentation**:
   - `docs/AGENT-WORKFLOW.md` - Complete workflow examples
   - `docs/TESTING-STRATEGY.md` - Testing patterns
   - `docs/COMMIT-MESSAGE-GUIDE.md` - Commit conventions

2. **Request Your First Feature**:
   - Switch to `@coordinator`
   - Request something simple (e.g., new API endpoint)
   - Watch agents collaborate

3. **Review Agent Work**:
   - Check PRs as they're created
   - Provide feedback to agents
   - Ask questions about implementation

4. **Integrate with Your Workflow**:
   - Create feature branches for user stories
   - Route work to agents
   - Focus on final PR review

## Support & Feedback

- **Questions**: Ask the `@coordinator` agent
- **Issues**: Report at https://github.com/anomalyco/opencode
- **Feedback**: Use `ctrl+p` for available actions

---

**Ready to get started?**

```
@coordinator - Help! I want to add a new assignment API endpoint.
```

Good luck! 🚀
