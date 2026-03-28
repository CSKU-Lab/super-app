---
name: git-worktree
description: Git worktree workflow for parallel development with isolated branches per issue
license: MIT
compatibility: opencode
metadata:
  audience: ai-agents
  workflow: development
  services: 7
---

# Git Worktree Workflow for CSKU Lab

## Overview

All AI agents working on the CSKU Lab super-app MUST use git worktrees for development. This ensures isolation, prevents conflicts, and enables parallel work across multiple services.

### Why Git Worktree?

- **Isolation**: Each agent gets a dedicated, clean working directory
- **Parallel Work**: Multiple branches of the same service can be checked out simultaneously
- **Single-use**: Fresh worktree per issue, destroyed after completion
- **No Conflicts**: Agents never interfere with each other's work
- **Cleaner Workflow**: No submodule reference updates needed

---

## Architecture

### Worktree Structure

```
.worktrees/
├── main-server-feat-123-abc123/          (Agent-1 on issue #123)
├── main-server-feat-124-def456/          (Agent-1 on issue #124)
├── config-server-feat-123-ghi789/        (Agent-2 on issue #123)
├── go-grader-feat-123-jkl012/            (Agent-3 on issue #123)
└── ...
```

### Naming Convention

Format: `{service}-feat-{issue-number}-{unique-id}`

- `service`: main-server, go-grader, config-server, task-server, isolate-docker, web, api-docs
- `issue-number`: GitHub issue ID (e.g., #123 → 123)
- `unique-id`: Short hash for collision prevention

### Branch Naming

Format in worktree: `feat/{issue}-{service}/{description}`

Examples:
- `feat/123-main-server/add-user-auth`
- `feat/124-config-server/fix-redis-cache`
- `feat/123-web/implement-settings-ui`

---

## Worktree Lifecycle (Per Issue)

### STEP 1: Coordinator Creates Worktrees

When routing to specialists:

```bash
# Create worktree for each service needed
./scripts/worktree.sh create main-server feat/123-main-server
./scripts/worktree.sh create config-server feat/123-config-server

# Output:
# ✅ Worktree created: .worktrees/main-server-feat-123-abc123/
# ✅ Worktree created: .worktrees/config-server-feat-123-def456/
```

### STEP 2: Agent Receives Assignment

Coordinator provides:
- **Worktree path**: `.worktrees/main-server-feat-123-abc123/`
- **Service**: main-server
- **Branch**: feat/123-main-server/add-user-auth
- **Issue**: #123

### STEP 3: Agent Works in Worktree

```bash
# Enter worktree
cd .worktrees/main-server-feat-123-abc123/

# Verify correct branch
git branch -v
# * feat/123-main-server/add-user-auth

# Make changes
# ... implement feature ...

# Commit with proper format
git add .
git commit -m "feat(main-server): add user authentication

- Add JWT token generation
- Implement auth middleware
- Add user session management

Closes #123"

# Push to remote
git push -u origin feat/123-main-server/add-user-auth
```

### STEP 4: Create Pull Request

From the branch created in worktree:
- **Title**: Matches commit message
- **Description**: Links issue with "Closes #123"
- **Target**: develop or main (per coordinator instructions)

### STEP 5: QA Review

QA reviews PR(s) from worktree branches using standard checklist.

### STEP 6: PR Merge

After approval, PR is merged to target branch.

### STEP 7: Coordinator Cleanup

After merge and QA approval:

```bash
# Remove worktree safely
./scripts/worktree.sh remove main-server main-server-feat-123-abc123

# Output:
# ✅ Worktree removed: .worktrees/main-server-feat-123-abc123/
```

---

## Multi-Worktree Scenarios

### Scenario 1: Single Service, Single Agent

**Issue #123**: Fix user authentication in main-server

```
Issue #123
  ↓
1 worktree created: main-server-feat-123-{id}
1 agent works in it
1 PR created
```

### Scenario 2: Multi-Service, Multiple Agents (Parallel)

**Issue #124**: Add OAuth support

```
Issue #124
  ├─ 3 worktrees created (all isolated):
  │  ├─ main-server-feat-124-{id}     (Agent-1)
  │  ├─ config-server-feat-124-{id}   (Agent-2)
  │  └─ web-feat-124-{id}             (Agent-3)
  │
  ├─ Agents work independently (no conflicts)
  │
  └─ 3 PRs created in parallel
```

### Scenario 3: Same Service, Multiple Branches

**Complex testing**: Need to test 2 implementations of same feature

```bash
# Create multiple worktrees for same service
./scripts/worktree.sh create main-server feat/125-main-server-v1
./scripts/worktree.sh create main-server feat/125-main-server-v2

# Agent can test both implementations:
# - .worktrees/main-server-feat-125-v1-{id}/
# - .worktrees/main-server-feat-125-v2-{id}/
```

---

## Agent Instructions (REQUIRED)

### Before Starting Work

1. **Verify worktree location** (provided by coordinator):
   ```bash
   cd {worktree-path}
   git branch -v  # Confirm correct branch
   ```

2. **Always work within assigned worktree**:
   - Never modify submodule paths
   - Never run `git checkout` or `git pull` on parent repo
   - All changes isolated to worktree

3. **Use correct branch naming**:
   - Format: `feat/{issue}-{service}/{description}`
   - Auto-created by coordinator
   - Match this when pushing

### During Development

1. **Make changes normally**:
   ```bash
   # Edit files
   git add .
   git commit -m "feat(service): description"
   git push -u origin feat/{issue}-{service}/{description}
   ```

2. **Follow commit format**:
   - Type: feat, fix, refactor, docs, test, chore
   - Scope: service name
   - Message: Clear description
   - Include: "Closes #{issue}" in PR description

3. **Test locally**:
   ```bash
   cd {worktree-path}
   go test ./...        # For Go services
   npm test             # For web/frontend
   ```

### After Push

1. **Create PR from pushed branch**:
   - Use same branch name: `feat/{issue}-{service}/{description}`
   - Link issue: "Closes #{issue}"
   - Tag reviewers from task assignment

2. **Wait for QA approval**:
   - Coordinator will remove worktree after approval
   - Don't manually delete it

### Important Constraints

- ❌ **Do NOT** modify `.git/` or worktree structure
- ❌ **Do NOT** create worktrees yourself (coordinator creates them)
- ❌ **Do NOT** store persistent state in worktree (ephemeral)
- ❌ **Do NOT** push directly to main/develop (use PRs)
- ✅ **DO** work only within assigned worktree path
- ✅ **DO** commit frequently with clear messages
- ✅ **DO** push to feature branch (auto-created)
- ✅ **DO** create PR from worktree branch

---

## Coordinator Instructions (REQUIRED)

### Creating Worktrees

```bash
# For each service involved in issue
./scripts/worktree.sh create {service} feat/{issue}-{service}

# Examples:
./scripts/worktree.sh create main-server feat/123-main-server
./scripts/worktree.sh create config-server feat/123-config-server
./scripts/worktree.sh create web feat/123-web
```

**Output**: Worktree path to assign to agent

### Monitoring Worktrees

```bash
# List all active worktrees
./scripts/worktree.sh list

# List worktrees for specific service
./scripts/worktree.sh list --service main-server

# Check status
git worktree list
```

### Cleanup Procedure

After PR merge AND QA approval:

```bash
# Wait 5 minutes for final testing confirmation

# Remove each worktree
./scripts/worktree.sh remove main-server main-server-feat-123-{id}
./scripts/worktree.sh remove config-server config-server-feat-123-{id}

# Post comment on GitHub issue
gh issue comment 123 -b "✅ Worktrees cleaned up. Ready for deployment."
```

### Locking Worktrees (Safety)

If worktree is actively being used:

```bash
# Prevent accidental deletion
./scripts/worktree.sh lock main-server main-server-feat-123-{id}

# When work done
./scripts/worktree.sh unlock main-server main-server-feat-123-{id}
```

---

## Helper Script Commands

All worktree operations use `./scripts/worktree.sh`:

### Create

```bash
./scripts/worktree.sh create <service> <branch-name> [--force]

# Creates: .worktrees/{service}-{branch-name}-{timestamp}/
# Returns: Full path to worktree
# Options:
#   --force: Skip confirmations
```

### List

```bash
./scripts/worktree.sh list [--service <service>]

# Output: Table of all worktrees or filtered
# Shows: service | branch | path | status | locked
```

### Remove

```bash
./scripts/worktree.sh remove <service> <worktree-name> [--force]

# Safely removes worktree
# Checks: clean working directory, not locked
# Options:
#   --force: Skip confirmations (use with caution)
```

### Lock/Unlock

```bash
./scripts/worktree.sh lock <service> <worktree-name>
./scripts/worktree.sh unlock <service> <worktree-name>

# Lock: Prevents accidental removal during work
# Unlock: Allows removal after work complete
```

### Cleanup Stale

```bash
./scripts/worktree.sh cleanup-all --older-than <hours>

# Example: Remove inactive worktrees older than 72 hours
./scripts/worktree.sh cleanup-all --older-than 72h
```

---

## Integration with Services

### All 7 Services Supported

1. **main-server** (8080, PostgreSQL, GoFiber)
2. **config-server** (8081, MongoDB, gRPC)
3. **task-server** (8082, MongoDB, gRPC)
4. **go-grader** (8083, Master-worker, RabbitMQ)
5. **isolate-docker** (Sandboxed execution, IOI Isolate)
6. **web** (3000, Next.js, TypeScript)
7. **api-docs** (Documentation, Postman)

### Working in Go Services

```bash
cd .worktrees/main-server-feat-123-{id}/

# Install dependencies
go mod download

# Run hot reload development
air

# Run tests
go test ./...

# Build
go build -o bin/main-server ./cmd
```

### Working in Frontend (web)

```bash
cd .worktrees/web-feat-123-{id}/

# Install dependencies
npm install

# Run development server
npm run dev

# Run tests
npm test

# Build
npm run build
```

### Running Compose

From parent repo:

```bash
# Use compose.sh with worktree paths
./compose.sh up

# Services read code from their worktrees
# (if using worktree paths in service volumes)
```

---

## Troubleshooting

### Worktree Already Exists

**Problem**: `./scripts/worktree.sh create` fails with "branch already exists"

**Solution**:
```bash
# Check if worktree already created
./scripts/worktree.sh list --service main-server

# Use existing worktree instead
# Or force create:
./scripts/worktree.sh create main-server feat/123-main-server --force
```

### Cannot Remove Worktree (Locked)

**Problem**: Worktree is locked, can't remove

**Solution**:
```bash
# Check if locked
./scripts/worktree.sh list | grep main-server

# Unlock it
./scripts/worktree.sh unlock main-server main-server-feat-123-{id}

# Then remove
./scripts/worktree.sh remove main-server main-server-feat-123-{id}
```

### Worktree Has Uncommitted Changes

**Problem**: Can't remove worktree with dirty state

**Solution**:
```bash
# Go to worktree
cd .worktrees/main-server-feat-123-{id}/

# Stash or commit changes
git stash
# OR
git add . && git commit -m "WIP: checkpoint"

# Then remove from parent
cd ../..
./scripts/worktree.sh remove main-server main-server-feat-123-{id}
```

### Branch Mismatch

**Problem**: In wrong branch inside worktree

**Solution**:
```bash
cd .worktrees/main-server-feat-123-{id}/

# Check current branch
git branch -v

# Should be on feat/123-main-server/...
# If not, you may be in wrong worktree
# Verify path matches assignment
```

### Worktree Not Found

**Problem**: Coordinator can't find worktree to remove

**Solution**:
```bash
# List all worktrees to find exact name
./scripts/worktree.sh list

# Get exact name (with timestamp)
# Use in remove command:
./scripts/worktree.sh remove main-server main-server-feat-123-EXACT-ID
```

---

## Best Practices

### For Agents

1. **Verify location first** - Always cd to worktree and run `git branch -v`
2. **Commit frequently** - Small, logical commits with clear messages
3. **Push regularly** - Don't wait until end to push
4. **Test locally** - Run tests in worktree before pushing
5. **Create PR immediately** - Link issue with "Closes #{issue}"
6. **Don't store state** - Worktree is ephemeral, deleted after issue closes

### For Coordinators

1. **Create isolated worktrees** - Never share between agents
2. **Use unique IDs** - Prevent collisions with timestamps
3. **Lock during work** - Prevent accidental cleanup
4. **Clean up after approval** - Timely removal of stale worktrees
5. **Monitor parallel work** - Use `list` command to track all agents
6. **Document assignments** - Link worktree path to agent in issue

---

## Migration from Submodules

The first time you run `./setup.sh`:

```bash
# Automatic conversion happens
./setup.sh

# Output:
# 🔄 Converting submodules to git worktrees (first time setup)...
# ✅ main-server: .worktrees/main-server-develop-20260328/
# ✅ go-grader: .worktrees/go-grader-develop-20260328/
# ✅ config-server: .worktrees/config-server-develop-20260328/
# ✅ task-server: .worktrees/task-server-develop-20260328/
# ✅ isolate-docker: .worktrees/isolate-docker-develop-20260328/
# ✅ web: .worktrees/web-develop-20260328/
# ✅ api-docs: .worktrees/api-docs-main-20260328/
# 
# 7 worktrees created successfully.
# .gitignore updated to exclude .worktrees/
# ✅ Worktree migration complete!
```

No manual steps required - automatic and seamless.

---

## Summary

**REQUIRED for all agents**:
- ✅ Use worktrees for all work
- ✅ Work in assigned worktree path only
- ✅ Follow branch naming convention
- ✅ Follow commit message format
- ✅ Create PR from worktree branch
- ✅ Wait for coordinator cleanup

**REQUIRED for coordinators**:
- ✅ Create isolated worktrees per service per issue
- ✅ Route to specialists with worktree path
- ✅ Monitor parallel work
- ✅ Clean up after QA approval
- ✅ Use helper script for all operations

**Benefits**:
- Parallel work without conflicts
- Clean, isolated environments
- Single-use per issue
- Automatic cleanup
- Scalable for multiple services

---

**Load this skill**: `skill({ name: "git-worktree" })`

**Helper script**: `./scripts/worktree.sh`

**Documentation**: See AGENTS.md and COORDINATOR-WORKFLOW.md
