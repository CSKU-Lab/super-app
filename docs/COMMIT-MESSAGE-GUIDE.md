# Commit Message Convention Guide

All commits in CSKU Lab follow a strict format for consistency, traceability, and GitHub integration.

## Format

```
type(scope): description

Detailed explanation (optional)

Closes #{issue-number}
```

## Components

### Type (Required)
One of: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`

- **feat**: New feature
- **fix**: Bug fix  
- **refactor**: Code restructuring (no behavior change)
- **test**: Test addition or modification
- **docs**: Documentation changes
- **chore**: Build, dependencies, tooling (no code change)

### Scope (Recommended)
What part of system is affected:
- `api` - REST API endpoints
- `handler` - HTTP request handlers
- `service` - Business logic services
- `repository` - Data access layer
- `database` - Schema or migrations
- `grpc` - gRPC services
- `middleware` - Cross-cutting concerns
- `ui` - Frontend components
- `state` - State management
- `auth` - Authentication/authorization
- `validation` - Input validation
- `error` - Error handling

### Description (Required)
- Concise summary of change
- Start with lowercase
- No period at end
- Imperative mood: "add" not "adds" or "added"
- <50 characters preferred

### Detailed Explanation (Optional)
- Explain why change was made
- Provide context for complex changes
- Can be multiple paragraphs
- Separated from title by blank line

### Closes Keyword (Required for Features)
Link commit to GitHub issue:
```
Closes #999
```

This automatically closes issue #999 when commit is merged to main.

## Examples

### ✅ Good Commits

```
feat(api): add user profile endpoint

- Implement GET /api/v1/users/me handler
- Add repository method to fetch user by ID
- Include unit tests with mocked DB
- Include integration tests with real PostgreSQL

Closes #999
```

```
fix(database): handle null role in user queries

Previously, queries would fail if role was NULL.
Updated migration to add default value and handle in code.

Closes #1005
```

```
refactor(repository): extract common query patterns

Reduce duplication in user-related queries by extracting
common filters into helper methods.
```

```
test(api): improve user profile endpoint coverage

Add test cases for missing error scenarios:
- User not found (404)
- Database connection failure (500)
- Invalid token (401)

Closes #1008
```

```
docs(workflow): update agent team setup guide

Clarify branch naming convention and explain
feature branch vs subtask branch distinction.
```

```
chore(deps): update Go dependencies to latest

Update all Go dependencies to latest versions.
Addresses security vulnerability in testcontainers.
```

### ❌ Bad Commits

```
# Missing issue number
feat: add user profile
```

```
# Vague description  
fix: stuff
```

```
# Wrong format
FEAT(API): Add User Profile Endpoint
```

```
# Too long description in title
feat(api): add user profile endpoint that returns name email role created_at
```

```
# No scope
feat: add endpoint
```

```
# Closed case scope
feat(API): add endpoint
```

## GitHub Integration

### Auto-Close Issues

When commit/PR is merged to main, GitHub automatically closes linked issues:

```
# Commit message
feat(api): add user profile endpoint

Closes #999

# Result after merge to main
- Issue #999 automatically closes
- Pull request linked in issue timeline
- Issue shows "closed" with commit hash
```

### Supported Keywords
All of these work:
- `Closes #999`
- `close #999`
- `Fixes #999`
- `fix #999`
- `Resolves #999`
- `resolve #999`

**Note**: Only works when merged to `main` branch

### Multiple Issues

```
feat(api): add user authentication

Closes #100
Closes #101
Closes #102
```

## Branch-to-Commit Flow

### Feature Branch Workflow

```
1. User creates feature branch:
   feat/999-user-profile
   
2. Specialist creates subtask branch:
   feat/999-api/user-profile-endpoint
   
3. Specialist commits:
   git commit -m "feat(api): add user profile endpoint
   
   Closes #999"
   
4. PR to feature branch (not main)
   
5. QA approves and auto-merges to feature branch
   
6. User creates final PR: feature → main
   
7. GitHub auto-closes #999 when merged to main
```

## Lint and Validation

### Pre-commit Hook (Optional)

```bash
#!/bin/bash
# .git/hooks/pre-commit

# Check commit message format
if ! grep -qE "^(feat|fix|refactor|test|docs|chore)(\([a-z-]+\))?:" "$1"; then
    echo "Commit message must start with type(scope): description"
    exit 1
fi

if ! grep -q "Closes #[0-9]" "$1"; then
    echo "Commit message must include Closes #{issue}"
    exit 1
fi
```

### Manual Validation

```bash
# Check your commit message before pushing
git log -1 --format=%B

# Should output:
# feat(api): add user profile endpoint
# 
# Closes #999
```

## Tips & Tricks

### Reference Multiple Issues

```
feat(api): implement soft delete feature

Closes #100
Closes #101
Closes #102
```

### Reference Without Closing

```
feat(api): add user profile endpoint

Related to #999, #1000

Closes #999
```

### Document Breaking Changes

```
feat(api): change user profile response format

BREAKING CHANGE: response no longer includes 'metadata' field

Closes #999
```

### Link to External Issues

```
fix(grader): handle timeout in sandbox execution

Fixes issue reported in https://github.com/owner/repo/issues/123

Closes #456
```

## Commit Hygiene

### One Concern Per Commit

```bash
# ✅ Good: Focused commits
git commit -m "feat(api): add user profile endpoint"
git commit -m "test(api): add tests for user profile"

# ❌ Bad: Multiple concerns
git commit -m "feat(api): add user profile AND update docs AND fix database query"
```

### Clear Commit History

```bash
# View commit log
git log --oneline --graph --all

# Should show clear progression:
# * abc1234 feat(api): add user profile endpoint (Closes #999)
# * def5678 feat(database): create users table (Closes #998)
# * ghi9012 fix(api): handle null values in response
```

### Rebase Before Merge

```bash
# Keep history clean: rebase instead of merge
git pull origin main --rebase

# Or use squash merge for feature branches
git merge --squash feat/999-user-profile
```

## Debugging Commit Issues

### Find Commits That Closed an Issue

```bash
git log --grep="Closes #999"
```

### Find Commits by Author

```bash
git log --author="agent-name"
```

### Find Commits by Type

```bash
git log --oneline | grep "^feat"
```

## Summary

| Element | Rule | Example |
|---------|------|---------|
| Type | Required, lowercase | `feat` |
| Scope | Recommended, lowercase | `(api)` |
| Description | Required, <50 chars | `add user profile endpoint` |
| Body | Optional, explain why | "Implements..." |
| Closes | Required for features | `Closes #999` |
| Format | `type(scope): desc` | `feat(api): add endpoint` |

---

**Remember**: Good commit messages make code review, debugging, and history navigation much easier!
