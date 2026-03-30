# Git Workflow Skill

This skill provides guidance for managing git operations in the CSKU Lab Super-App project with strict branching and review requirements.

## Branching Strategy

### Main Branch (`main`)
- **Purpose**: Production-ready code only
- **Protection**: Pull Request review required
- **Force Push**: STRICTLY FORBIDDEN
- **Merge Source**: Only from `develop` branch via PR
- **Deployment**: Code on `main` is automatically deployed to production

### Develop Branch (`develop`)
- **Purpose**: Integration branch for features and fixes
- **Merge Source**: Feature and fix branches via PR
- **PR Required**: Yes, at least one approval
- **Force Push**: Not allowed

### Feature & Fix Branches

#### Creating Feature Branches
```bash
# Always branch from develop
git checkout develop
git pull origin develop
git checkout -b feature/<feature-name>
# Example: feature/add-user-authentication
# Example: feature/implement-grading-api
```

#### Creating Fix Branches  
```bash
# Always branch from develop
git checkout develop
git pull origin develop
git checkout -b fix/<fix-name>
# Example: fix/memory-leak-in-worker
# Example: fix/grpc-timeout-issue
```

#### Branch Naming Convention
- Use lowercase with hyphens
- Be descriptive but concise
- Prefix with `feature/` or `fix/`
- Good: `feature/add-submission-api`, `fix/database-connection-pool`
- Bad: `feature/new-stuff`, `my-branch`, `WIP`

## Commit Messages

### Format
```
<type>(<scope>): <subject>

<body>

<footer>
```

### Type
- `feat`: New feature
- `fix`: Bug fix
- `refactor`: Code restructuring without behavior change
- `test`: Adding or updating tests
- `docs`: Documentation changes
- `chore`: Build, dependencies, or tooling changes

### Scope
- Service name: `main-server`, `config-server`, `task-server`, `go-grader`, `web`
- Generic: `ci`, `deps`, `docs`
- Example: `feat(main-server): add user profile endpoint`

### Subject
- Imperative mood: "add" not "added" or "adds"
- No period at the end
- Max 50 characters
- Be specific about what changed

### Body (Optional but Recommended)
- Explain **why**, not what
- Wrap at 72 characters
- Use bullet points for multiple changes
- Separate from subject with blank line

### Footer (Optional)
- Reference issues: `Closes #123`, `Fixes #456`
- Note breaking changes: `BREAKING CHANGE: description`

### Examples

**Simple commit:**
```
feat(main-server): add user authentication endpoint

Implement JWT-based authentication for user login with password hashing.
```

**Complex commit with footer:**
```
feat(task-server): implement task caching with Redis

- Cache task definitions in Redis for 1 hour
- Invalidate cache on task update
- Add cache hit/miss metrics

Closes #789
```

**Fix with context:**
```
fix(config-server): prevent memory leak in gRPC connections

Close gRPC connections properly in shutdown handler.
Previously connections were left open, causing memory to leak
over time as the server restarted.

Fixes #456
```

## Pull Request Workflow

### Before Creating a PR

1. **Pull latest develop**
   ```bash
   git fetch origin
   git rebase origin/develop
   ```

2. **Run tests locally**
   ```bash
   go test ./...
   npm test  # if frontend changes
   ```

3. **Ensure code quality**
   - Linting passes
   - No console errors/warnings
   - No commented-out code
   - Clear and concise comments

### Creating a Pull Request

1. **Push feature branch**
   ```bash
   git push -u origin feature/<feature-name>
   ```

2. **Create PR on GitHub**
   - Base branch: `develop` (NOT `main`)
   - Title: Follow commit message format `type(scope): description`
   - Description: Include what changed and why
   - Link issues: Use `Closes #123` in description
   - Add labels: `type/feat`, `type/fix`, `service/main-server`, etc.

3. **PR Description Template**
   ```markdown
   ## Summary
   Brief description of changes (2-3 sentences)

   ## Changes
   - Change 1
   - Change 2
   - Change 3

   ## Testing
   - [ ] Unit tests added/updated
   - [ ] Integration tests pass
   - [ ] Manual testing completed

   ## Type
   - [ ] Feature
   - [ ] Bug fix
   - [ ] Refactoring
   - [ ] Documentation

   Closes #issue-number
   ```

### Code Review Process

1. **Request reviewers**: At least 1-2 reviewers
2. **Address feedback**: Push additional commits (don't amend)
3. **Keep updated**: Rebase if develop diverges
4. **Approval**: At least 1 approval required
5. **Merge**: Use "Squash and merge" for feature branches

### Merging to Develop

```bash
# Via GitHub UI (preferred)
1. Click "Squash and merge" button
2. Confirm final commit message
3. Delete feature branch

# Via CLI (if needed)
git checkout develop
git pull origin develop
git merge --squash feature/<feature-name>
git commit -m "feat(scope): description"
git push origin develop
```

## Promoting to Main

When ready for production release:

1. **Create Release Branch**
   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b release/<version>
   # Example: release/1.0.0
   ```

2. **Version Bump** (if applicable)
   - Update version in `package.json`, `go.mod`, etc.
   - Update CHANGELOG
   - Commit: `chore(release): bump version to 1.0.0`

3. **Create PR: release → main**
   - Base: `main`
   - Title: `chore(release): version 1.0.0`
   - Description: Summary of changes, key features

4. **Merge to Main**
   - Requires approval from maintainer
   - Click "Create a merge commit" (preserve history)
   - Delete release branch

5. **Merge Back to Develop**
   ```bash
   git checkout develop
   git pull origin develop
   git merge main
   git push origin develop
   ```

## Important Rules

### ⚠️ CRITICAL REMINDERS

**NEVER push directly to `main` or `develop`. All changes MUST go through PRs to `develop`.**

```bash
# ❌ WRONG - Never do this:
git push origin main
git push origin develop

# ✅ CORRECT - Always do this:
git checkout -b feature/my-feature develop
git push -u origin feature/my-feature
gh pr create --base develop
gh pr merge <PR_NUMBER> --squash
```

### ✅ DO

- Create feature branches from `develop`
- Use descriptive branch names
- Write clear commit messages
- Create PRs for all changes (target: `develop`)
- Request code reviews
- Keep commits focused and atomic
- Test locally before pushing
- Rebase feature branches on latest develop
- Use "Squash and merge" for feature branches
- **Always create PRs to `develop`, NEVER to `main`**

### ❌ DON'T

- **NEVER** force push to `main` or `develop`
- **NEVER** commit directly to `main` or `develop`
- **NEVER** merge feature branches directly to `main`
- **NEVER** push to `main` or `develop` branches directly
- **NEVER** use generic branch names (`feature/new`, `fix/bug`)
- **NEVER** skip code review
- **NEVER** leave conflicts unresolved
- **NEVER** rewrite public history (already pushed commits)
- **NEVER** commit secrets or `.env` files

## Common Workflows

### Standard Feature Development
```bash
# Start feature
git checkout develop
git pull origin develop
git checkout -b feature/user-profile

# Make changes, commit, push
git add .
git commit -m "feat(main-server): add user profile endpoint"
git push -u origin feature/user-profile

# Create PR, get review, merge via GitHub

# Clean up locally
git checkout develop
git pull origin develop
git branch -d feature/user-profile
```

### Updating Feature Branch from Develop
```bash
# Rebase on latest develop
git fetch origin
git rebase origin/develop

# If conflicts, resolve them
git add .
git rebase --continue

# Force push to feature branch (safe - it's your own branch)
git push origin feature/<name> --force-with-lease
```

### Syncing with Main After Release
```bash
# Merge main into develop
git checkout develop
git pull origin develop
git merge main
git push origin develop
```

### Emergency Hotfix from Main
```bash
# Create hotfix branch from main
git checkout main
git pull origin main
git checkout -b hotfix/security-patch

# Make fix, commit, push
git add .
git commit -m "fix(main-server): patch security vulnerability"
git push -u origin hotfix/security-patch

# Create PR: hotfix/... → main
# After approval, merge to main
# Then merge main back to develop
```

## Safety Checks Before Push

```bash
# 1. Verify correct branch
git branch -v

# 2. Check what will be pushed
git log origin/develop..HEAD
git diff origin/develop...HEAD

# 3. Verify tests pass
go test ./...

# 4. Run linters
go fmt ./...
go vet ./...

# 5. Final check before push
git push -u origin feature/<name>
```

## Troubleshooting

### Accidentally Committed to develop
```bash
# Undo the commit (keep changes)
git reset --soft HEAD~1

# Create new feature branch
git checkout -b feature/your-feature

# Commit changes properly
git commit -m "feat(scope): description"
```

### Need to Update Feature Branch
```bash
# Rebase on latest develop
git fetch origin
git rebase origin/develop

# If conflicts occur, resolve and continue
git add .
git rebase --continue

# Force push with safety
git push origin feature/<name> --force-with-lease
```

### PR Has Merge Conflicts
```bash
# Update your branch from develop
git fetch origin
git rebase origin/develop

# Resolve conflicts in your editor
git add .
git rebase --continue

# Push updated branch
git push origin feature/<name> --force-with-lease
```

## Git Configuration

Recommended git configuration for this workflow:

```bash
# Set up your identity (do this once)
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Helpful defaults
git config --global pull.rebase true
git config --global fetch.prune true
git config --global rebase.autostash true
git config --global push.default current

# Optional: safety features
git config --global push.safeWithLease true  # Use --force-with-lease by default
```

## References

- Main branch protection rules prevent direct commits
- Develop branch requires PR reviews
- All PRs must pass CI/CD checks before merging
- Commit history is preserved for audit trail
- Release notes auto-generated from commit messages
