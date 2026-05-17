# Git Workflow & Release Process

> **Agent context:** This document explains how to work with Git branches, commits, and releases across the CS Lab super-app and its submodules. Follow this when making code changes.

## Overview

This project uses **semantic-release** for automated versioning and GitHub Releases. All services (web, main-server, go-grader, task-server, config-server) follow the same branching and release model.

## Branching Strategy

| Branch | Purpose |
|--------|---------|
| `main` | **Production-ready code.** Only merged via PR from `develop`. semantic-release runs here and creates tags + GitHub releases. |
| `develop` | **Active development.** Feature branches merge here. This is the default branch you should branch from. |
| `feat/*` | Feature branches. Branch from `develop`, merge back into `develop`. |
| `fix/*` | Bug fix branches. Branch from `develop`, merge back into `develop`. |

**Rule:** Never commit directly to `main`. All changes go through `develop` first.

## Workflow for Making Changes

### 1. Create a feature branch from `develop`

```bash
git checkout develop
git pull origin develop
git checkout -b feat/my-feature-name
```

### 2. Make changes and commit

Use **Conventional Commits** format so semantic-release can determine the next version:

```
feat: add auto-grading for C++ submissions
fix: resolve race condition in submission queue
chore: update dependencies
docs: add API endpoint examples
refactor: simplify transaction retry logic
test: add unit tests for grade calculator
```

**Important commit types for versioning:**

| Type | Effect on version |
|------|-------------------|
| `feat:` | Minor bump (e.g. `0.4.0` → `0.5.0`) |
| `fix:` | Patch bump (e.g. `0.4.0` → `0.4.1`) |
| `BREAKING CHANGE:` in body | Major bump (e.g. `0.4.0` → `1.0.0`) |
| `chore:`, `docs:`, `refactor:`, `test:` | No version bump |

### 3. Push and open a PR to `develop`

```bash
git push origin feat/my-feature-name
```

Open a PR targeting the **`develop`** branch of the respective repository.

### 4. Merge to `develop`

Use **squash and merge** or a regular merge. The merge commit message should also follow conventional commits if you want it to count toward release analysis.

### 5. Release to `main`

When `develop` is ready for release, open a PR from `develop` → `main`. Once merged:

- **semantic-release** triggers automatically on the `main` branch push
- It analyzes all commits since the last tag
- It creates a new git tag (e.g. `v0.5.0`)
- It generates a **GitHub Release** with auto-generated notes
- It updates `CHANGELOG.md` (and `package.json` for the `web` service)
- The new tag push triggers **Docker image builds** via the existing `docker-publish.yml` workflows

## Submodules

This repository (`super-app`) is a parent repo containing git submodules:

- `web/` — Next.js frontend
- `main-server/` — Go REST API
- `go-grader/` — Go gRPC code execution service
- `task-server/` — Go gRPC task service
- `config-server/` — Go gRPC config service

### Working with submodules

Each submodule is its own independent repository with its own `main`/`develop` branches. The parent repo (`super-app`) only tracks submodule commit pointers.

**When you change code inside a submodule:**
1. Commit and push the submodule first (e.g., inside `web/`)
2. Then in the parent repo, the submodule will show as modified
3. Stage the submodule and commit in `super-app` to update the pointer

**Example:**
```bash
# Inside web/
git checkout -b feat/my-feature
git add .
git commit -m "feat: add new component"
git push origin feat/my-feature
# (open PR to develop, merge)

# Back in super-app/
git add web
git commit -m "chore: update web submodule"
git push origin main
```

## Release Automation

Each service has a `.github/workflows/release.yml` that runs semantic-release. No manual tagging is needed.

**What semantic-release does on `main` push:**
1. Reads commits since last tag
2. Determines version bump (patch / minor / major)
3. Creates git tag (e.g. `v0.5.1`)
4. Creates GitHub Release with notes
5. Updates `CHANGELOG.md`
6. For `web`: also bumps `package.json` version

**What happens after the tag is created:**
- The `docker-publish.yml` workflow triggers on tag pushes (`v*`)
- Docker images are built and pushed with the tag
- The `update-gitops` job updates the deployment config in the `gitops` submodule

## Commit Message Checklist

When writing commits (especially as an agent), follow this:

- [ ] Use present tense (`feat: add X` not `feat: added X`)
- [ ] Use imperative mood (`fix: resolve Y` not `fix: resolves Y`)
- [ ] Lowercase type prefix
- [ ] No period at the end of the subject line
- [ ] Separate subject from body with a blank line if needed
- [ ] Include `BREAKING CHANGE:` in the body for breaking changes

**Good examples:**
```
feat: add semantic versioning to sidebar
fix: prevent duplicate submissions on rapid clicks
chore: bump go-grader submodule to v0.3.1
```

**Bad examples:**
```
Added feature to sidebar.          ← no type prefix, past tense
feat: Added sidebar version.        ← past tense, period at end
FIX: prevent duplicate submissions   ← uppercase type prefix
```

## Agent Guidelines

- Always check which branch you are on before making changes.
- If you are in a submodule, follow the submodule's branch rules.
- If you create commits that should trigger a release, use `feat:` or `fix:`.
- If you are doing cleanup, refactoring, or docs, use `chore:`, `refactor:`, or `docs:` so no release is triggered.
- Never force-push to `main`.
- Never create manual tags — semantic-release handles this.
