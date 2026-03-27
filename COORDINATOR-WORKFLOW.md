# CSKU Lab - Coordinator Agent Workflow with QA Feedback Loop

This document describes the complete workflow for the Coordinator Agent, including the new QA feedback and approval loop.

## Overview

The coordinator orchestrates feature implementation and bug fixes across specialist agents with a formal GitHub issue-based workflow. All work is tracked, coordinated, and reviewed before merging to main.

## Complete Workflow Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         COORDINATOR WORKFLOW                                 │
└─────────────────────────────────────────────────────────────────────────────┘

┌─ STEP 1: Receive Request ─────────────────────────────────────────────────┐
│  User: "Fix compare script selector bug"                                   │
│  ✓ Parse requirements and affected services                                │
└──────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─ STEP 2: Create GitHub Issue ────────────────────────────────────────────┐
│  ✓ Use `gh issue create` to create issue                                 │
│  ✓ Include root cause, requirements, acceptance criteria                 │
│  ✓ Return issue number (e.g., #3)                                        │
│  📍 Location: https://github.com/CSKU-Lab/super-app/issues/3            │
└──────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─ STEP 3: Route to Specialists ────────────────────────────────────────┐
│  ┌─ frontend-dev specialist                                            │
│  │  ✓ Fix ConfigService                                              │
│  │  ✓ Branch: feat/3-frontend/fix-config-service                    │
│  │  ✓ Create PR with "Closes #3" in commit                          │
│  │                                                                    │
│  └─ go-clean-arch specialist (in parallel if independent)            │
│     ✓ Verify API contract                                            │
│     ✓ Branch: feat/3-backend/verify-api-contract                    │
│     ✓ Create PR with "Closes #3" in commit                          │
└──────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─ STEP 4: Monitor Implementation ──────────────────────────────────────┐
│  ✓ Wait for specialists to complete                                  │
│  ✓ Verify PRs created to feature branches                            │
│  ✓ Check branch naming: feat/{issue-number}-{domain}/{description}  │
│  ✓ Verify commit format includes "Closes #3"                        │
└──────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─ STEP 5: Route to QA Specialist for Review ──────────────────────────┐
│  QA Specialist receives all PRs:                                      │
│  ┌─────────────────────────────────────────────────────────────┐     │
│  │ Code Review Checklist:                                      │     │
│  │ ✓ Architecture & design patterns                           │     │
│  │ ✓ Error handling (domain errors, logging)                 │     │
│  │ ✓ Database & data access (parameterized queries)          │     │
│  │ ✓ API & communication consistency                         │     │
│  │ ✓ Frontend (TypeScript, components, styling)              │     │
│  │ ✓ Testing (>80% coverage, edge cases)                     │     │
│  │ ✓ Code quality (no duplicates, clear logic)               │     │
│  │ ✓ Security (no credentials, validation)                   │     │
│  │ ✓ Git hygiene (proper commit format)                      │     │
│  └─────────────────────────────────────────────────────────────┘     │
│  ✓ Run tests and verify >80% code coverage                          │
│  ✓ Check all acceptance criteria met                                │
└──────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─ STEP 6: QA Posts Feedback Comment on GitHub Issue ─────────────────┐
│  🔴 CRITICAL STEP: QA posts detailed comment on issue #3            │
│                                                                      │
│  Comment includes:                                                   │
│  ✓ List of reviewed PRs                                             │
│  ✓ Assessment table (Architecture/Testing/Security/etc)             │
│  ✓ Approval Status: ✅ APPROVED or ❌ REJECTED                      │
│  ✓ Required changes (if rejected)                                   │
│                                                                      │
│  📍 Posted to: https://github.com/CSKU-Lab/super-app/issues/3      │
└──────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─ STEP 7: Coordinator Fetches QA Feedback ────────────────────────────┐
│  ✓ Use `gh issue view #3 --json comments`                            │
│  ✓ Parse QA comment for approval status                              │
│  ✓ Extract required changes (if any)                                 │
└──────────────────────────────────────────────────────────────────────────┘
                                    │
                    ┌───────────────┴───────────────┐
                    │                               │
                    ▼                               ▼
            ✅ APPROVED                      ❌ REJECTED
                    │                               │
                    ▼                               ▼
    ┌──sMERGE DECISION ─┐      ┌─ SEND CHANGES TO SPECIALISTS ─┐
    │                  │      │                                │
    │ ✓ Merge all PRs  │      │ ✓ Report required changes      │
    │   to main branch │      │ ✓ Route back to specialists    │
    │ ✓ Issue auto-    │      │ ✓ Loop to STEP 4               │
    │   closes on      │      │ (Monitor Implementation)       │
    │   final merge    │      │                                │
    │                  │      └────────────────────────────────┘
    └──────────────────┘
                    │
                    ▼
┌─ STEP 8: Report Final Status ─────────────────────────────────────┐
│  ✓ All PRs merged successfully                                    │
│  ✓ Issue #3 auto-closed                                          │
│  ✓ Summarize completed work                                      │
│    - Issue number                                                │
│    - Services updated (frontend, backend)                        │
│    - QA approval confirmation                                    │
│    - Merge commit references                                     │
└──────────────────────────────────────────────────────────────────────────┘
```

## Detailed Steps

### Step 1: Receive Feature/Bug Request

**User Input Example:**
```
@coordinator create issue for: bug - Fix compare script selector dropdown 
after backend config API was updated to return paginated responses
```

**Coordinator Actions:**
- Parse request for requirements
- Identify affected services (frontend, backend)
- Do NOT skip to direct implementation

---

### Step 2: Create GitHub Issue

**Command:**
```bash
gh issue create \
  --title "Fix compare script selector - API response pagination mismatch" \
  --body "## Root Cause
The main-server config API returns paginated responses but frontend 
ConfigService expects data arrays.

## Affected Components
- main-server: GET /cms/configs/runners, GET /cms/configs/compare-scripts
- web: ConfigService, CompareScript.tsx, AllowedRunners.tsx

## Acceptance Criteria
- [ ] ConfigService.getRunners() returns array
- [ ] ConfigService.getCompareScripts() returns array
- [ ] Dropdowns work in CMS Materials
- [ ] Tests pass with >80% coverage" \
  --label "bug"
```

**Output:**
```
Created Issue #3
https://github.com/CSKU-Lab/super-app/issues/3
```

---

### Step 3: Route to Specialists

**Coordinator Decision:**
- This bug affects frontend UI and backend API
- Backend API is correct (no changes needed)
- Frontend ConfigService needs fixing
- Work can be done in parallel

**Routing:**

```
Issue #3 Specialist Assignments:

1. frontend-dev
   Task: Fix ConfigService to extract data from paginated responses
   Branch: feat/3-frontend/fix-config-service
   PR will have: "Closes #3" in commit message
   
2. go-clean-arch (verification only)
   Task: Verify backend API contract is correct
   Branch: feat/3-backend/verify-api-contract
   PR will have: "Closes #3" in commit message
```

---

### Step 4: Monitor Implementation

**Coordinator Monitors:**
- ✅ frontend-dev creates `feat/3-frontend/fix-config-service` branch
- ✅ go-clean-arch creates `feat/3-backend/verify-api-contract` branch
- ✅ Both create PRs with "Closes #3" in commits
- ✅ Specialist work completes

**Example PR:**
```
Title: Fix ConfigService pagination extraction
Branch: feat/3-frontend/fix-config-service
Commit: fix(config-service): extract data array from paginated responses
        Closes #3
```

---

### Step 5: Route to QA Specialist

**Coordinator Action:**
```
QA Specialist, please review the following PRs for issue #3:
- PR #45: frontend-dev - fix config service
- PR #46: go-clean-arch - verify API contract

Requirements:
1. Review code against checklist (architecture, testing, security, etc.)
2. Verify >80% test coverage
3. Check all tests pass
4. Post detailed feedback on GitHub issue #3
5. Include approval status: ✅ APPROVED or ❌ REJECTED
```

---

### Step 6: QA Posts Feedback Comment

**QA Specialist Posts on Issue #3:**

```markdown
## QA Review Complete - Issue #3

**Reviewed PRs**:
- PR #45: fix(config-service): extract data array from paginated responses
- PR #46: docs(config-api): verify pagination contract for frontend integration

**Overall Assessment**

| Dimension | Status | Notes |
|-----------|--------|-------|
| Architecture | ✅ PASS | Clean service pattern, proper separation |
| Testing | ✅ PASS | 85% coverage, edge cases covered |
| Error Handling | ✅ PASS | Proper error boundaries |
| Security | ✅ PASS | Input validation in place |
| Code Quality | ✅ PASS | Clear, maintainable code |
| Git Hygiene | ✅ PASS | Proper "Closes #3" format |

**Strengths**:
- Clean extraction of data array from pagination wrapper
- Comprehensive unit and integration tests
- Proper TypeScript types maintained
- Good documentation of API contract

**Minor Comments**:
- Consider adding JSDoc comments for ConfigService methods
- Great test coverage!

---

**APPROVAL STATUS: ✅ APPROVED FOR MERGE**

Ready to merge to main branch. Issue will auto-close on final merge.
```

---

### Step 7: Coordinator Fetches QA Feedback

**Coordinator Command:**
```bash
gh issue view #3 --json comments
```

**Coordinator Parsing:**
- Reads QA comment from issue #3
- Extracts approval status: ✅ APPROVED
- No required changes identified

---

### Step 8: Coordinator Makes Merge Decision

**Decision Logic:**

```
IF QA_STATUS == "APPROVED"
  ├─ Merge PR #45 to main
  ├─ Merge PR #46 to main
  ├─ Issue #3 auto-closes (because of "Closes #3" keyword)
  └─ Report success
  
ELSE IF QA_STATUS == "REJECTED"
  ├─ Extract required changes from QA comment
  ├─ Route feedback back to specialists
  ├─ Specialists make changes to PRs
  ├─ Loop back to Step 5 (QA review again)
  └─ Repeat until APPROVED
```

**Merge Commands:**
```bash
gh pr merge #45 --auto --squash
gh pr merge #46 --auto --squash
```

**Result:**
- Both PRs merged
- Commits contain "Closes #3"
- Issue #3 auto-closes
- Commit history preserved

---

### Step 8: Report Final Status

**Coordinator Report:**
```
✅ Issue #3 Fix Complete

**Issue**: Fix compare script selector - API response pagination mismatch

**Specialist Work**:
- ✅ frontend-dev: Fixed ConfigService to extract data array
- ✅ go-clean-arch: Verified API contract

**QA Review**:
- ✅ Approved by QA specialist
- ✅ >80% test coverage verified
- ✅ All tests passing

**Merge Status**:
- ✅ PR #45 merged to main (commit: abc1234)
- ✅ PR #46 merged to main (commit: def5678)
- ✅ Issue #3 auto-closed

**Changes Deployed**:
- web/src/services/config.service.ts updated
- ConfigService.getRunners() now returns correct array
- ConfigService.getCompareScripts() now returns correct array
- Compare script dropdown working
- Allowed runners dropdown working
```

---

## QA Approval Scenarios

### Scenario 1: Approved on First Review ✅

```markdown
## QA Review Complete - Issue #3

**Approval Status: ✅ APPROVED**

All criteria met. Ready to merge.
```

**Coordinator Action**: Merge all PRs immediately

---

### Scenario 2: Rejected - Changes Required ❌

```markdown
## QA Review - Issue #3

**Approval Status: ❌ REJECTED - CHANGES REQUIRED**

**Blockers**:
1. Test coverage at 65%, below 80% requirement
2. Missing error handling for API pagination failures

**Required Changes**:
1. Add unit tests for edge cases (missing data, empty pagination)
2. Add integration test with actual paginated response
3. Add error handler for malformed pagination object
```

**Coordinator Action**: 
1. Route feedback back to specialists
2. Specialists make changes to PRs
3. Loop back to Step 5 for QA re-review

---

## Key Rules

### 🔴 CRITICAL RULES

1. **Always Create GitHub Issue First**
   - Even for "quick" bug fixes
   - No direct code implementation
   - Issue number is reference point for all work

2. **Specialist Routing is Required**
   - Not optional
   - Enables parallel work tracking
   - Ensures proper domain expertise

3. **QA Comment on Issue is Mandatory**
   - QA must post detailed feedback comment
   - Coordinator reads this comment to make merge decisions
   - No approval without comment
   - Comment format must include approval status

4. **Merge Only After QA Approval**
   - Coordinator fetches QA comment
   - Checks approval status
   - Only merges if ✅ APPROVED
   - If ❌ REJECTED, routes back to specialists

### ✅ BEST PRACTICES

1. **Use Parallel Routing When Independent**
   - Frontend changes + backend verification can happen in parallel
   - Different database tables can happen in parallel
   - Reduces total time-to-merge

2. **Provide Clear Acceptance Criteria**
   - In GitHub issue description
   - QA uses these to validate implementation
   - Specialists use these to guide work

3. **Maintain Commit Message Format**
   - All commits must have "Closes #{issue-number}"
   - This auto-closes issue on merge
   - Required by QA checklist

---

## Files Modified for This Workflow

1. **`.opencode/agents/coordinator.md`**
   - Updated to enforce formal workflow always
   - Added QA feedback loop (Steps 5-7)
   - Added merge decision logic

2. **`.opencode/agents/qa-specialist.md`**
   - Added GitHub issue comment requirement
   - Provided comment format template
   - Added to success metrics

3. **`COORDINATOR-WORKFLOW.md`** (this file)
   - Complete workflow documentation
   - Detailed step-by-step guide
   - QA approval scenarios

---

## Example: Issue #3 Complete Workflow

### Issue Created
- **Title**: Fix compare script selector - API response pagination mismatch
- **URL**: https://github.com/CSKU-Lab/super-app/issues/3

### Specialists Routed
- **frontend-dev** → `feat/3-frontend/fix-config-service`
- **go-clean-arch** → `feat/3-backend/verify-api-contract`

### QA Posted Comment
```
## QA Review Complete - Issue #3
**Approval Status: ✅ APPROVED FOR MERGE**
```

### Coordinator Decision
- ✅ Merge PR #45 (frontend fix)
- ✅ Merge PR #46 (backend verification)
- ✅ Issue #3 auto-closes
- ✅ Features deployed to main

---

## Troubleshooting

### Q: QA didn't post comment on issue

**A**: Coordinator cannot make merge decision. Contact QA specialist to post required feedback comment.

### Q: QA rejected but didn't list changes

**A**: QA comment must include specific required changes. Request clarification comment from QA.

### Q: Multiple PRs for one issue

**A**: This is normal for multi-service features. Coordinator waits for all PRs, routes all to QA, merges all after approval.

### Q: Issue didn't auto-close after merge

**A**: Check that commits include "Closes #{issue-number}" format. Only exact format triggers auto-close.

---

## Summary

This workflow ensures:
- ✅ All work tracked via GitHub issues
- ✅ Parallel specialist coordination
- ✅ QA review before merge
- ✅ Feedback captured on issue for transparency
- ✅ Clear approval/rejection process
- ✅ Automatic issue closure on merge
