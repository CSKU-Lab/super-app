# Quick Reference: QA Feedback & Approval Workflow

## What Changed?

The coordinator workflow now includes a **QA feedback loop** where:
1. QA specialist posts a detailed comment on the GitHub issue
2. Coordinator reads that comment to make merge decisions
3. If rejected, coordinator routes work back to specialists

## Key Steps

### Step 5: Route to QA ✅
```
Coordinator → QA Specialist: "Please review all PRs for issue #3"
```

### Step 6: QA Comments on Issue ⭐ NEW & CRITICAL
```
QA posts on GitHub Issue #3:
├─ Assessment table (Architecture, Testing, Security, etc.)
├─ Strengths & comments
└─ Status: ✅ APPROVED or ❌ REJECTED
```

### Step 7: Coordinator Fetches Feedback ⭐ NEW
```bash
gh issue view #3 --json comments
# Read the QA comment
# Extract approval status
```

### Step 8: Merge Decision Based on Feedback ⭐ NEW
```
IF QA == APPROVED
  → Merge all PRs to main
  → Issue auto-closes
  → Done!

IF QA == REJECTED
  → Report changes to specialists
  → Loop back to Step 4
  → Specialists fix & resubmit
```

---

## QA Specialist: What You Need to Do

### Required: Post Comment on GitHub Issue

**After reviewing all PRs:**

```markdown
## QA Review Complete - Issue #{number}

**Reviewed PRs**:
- PR #XX: description
- PR #YY: description

**Assessment**

| Dimension | Status | Notes |
|-----------|--------|-------|
| Architecture | ✅ PASS | ... |
| Testing | ✅ PASS | ... |
| Error Handling | ✅ PASS | ... |
| Security | ✅ PASS | ... |
| Code Quality | ✅ PASS | ... |
| Git Hygiene | ✅ PASS | ... |

**Summary**
- All criteria met
- Tests passing
- >80% coverage

---

**APPROVAL STATUS: ✅ APPROVED FOR MERGE**
```

Or if rejecting:

```markdown
## QA Review - Issue #{number}

**Approval Status: ❌ REJECTED - CHANGES REQUIRED**

**Blockers**:
1. Test coverage at 65%, need 80%
2. Missing error handling

**Required Changes**:
1. Add unit tests for edge cases
2. Implement error handlers

---

**Please address above items and resubmit for review.**
```

---

## Coordinator: What It Does

### Before Merging (NEW)
```
1. Get QA comment from issue:
   gh issue view #3 --json comments

2. Parse comment for approval status:
   if (comment includes "✅ APPROVED")
     → Merge PRs
   else if (comment includes "❌ REJECTED")
     → Report changes to specialists
     → Wait for resubmission
```

### Merge PRs (if Approved)
```bash
gh pr merge #45 --auto --squash
gh pr merge #46 --auto --squash
```

### Wait for Changes (if Rejected)
```
Route feedback back to:
- frontend-dev specialist
- go-clean-arch specialist
- (or whichever specialist has blockers)

Loop back to Step 4 (Monitor Implementation)
```

---

## Files Modified

### 1. `.opencode/agents/coordinator.md`
- Added Steps 5-7 (QA feedback loop)
- Added Step 8 (merge decision logic)
- Added handling for rejected changes
- Emphasized "NEVER skip formal workflow"

### 2. `.opencode/agents/qa-specialist.md`
- Added Section 7: GitHub Issue Feedback Comment (CRITICAL)
- Provided comment format template
- Added success metrics: "Feedback comment posted on GitHub issue"

### 3. `COORDINATOR-WORKFLOW.md` (new)
- Complete workflow documentation
- 8-step process diagram
- Real examples with Issue #3
- Troubleshooting guide

---

## How to Use It

### As a User
```
@coordinator create issue for: bug - fix compare script selector

Coordinator will:
1. Create issue #3
2. Route specialists (frontend, backend)
3. Wait for PRs
4. Route to QA
5. Wait for QA comment on issue
6. Fetch feedback & decide merge
7. Merge if approved, or route back if rejected
```

### As QA Specialist
```
After reviewing PRs:
1. Go to GitHub issue #3
2. Add a comment with assessment table
3. Include approval status (✅ or ❌)
4. List required changes if rejected

Done! Coordinator reads your comment and makes merge decision.
```

### As Coordinator
```
After routing to QA:
1. Wait for QA to post comment on issue
2. Read comment: gh issue view #3
3. Check approval status in comment
4. If APPROVED: merge PRs
5. If REJECTED: report changes to specialists
6. Report final status to user
```

---

## Real Example Flow

```
Timeline:
─────────────────────────────────────────────

09:00 AM - User: "@coordinator fix compare script selector"
          ✅ Issue #3 created

09:05 AM - frontend-dev starts work on PR #45
          go-clean-arch starts work on PR #46

10:00 AM - PR #45 created by frontend-dev
          PR #46 created by go-clean-arch
          ✅ Routed to QA specialist

10:30 AM - QA finishes review
          ✅ QA posts comment on Issue #3:
             "## QA Review Complete
              **Status: ✅ APPROVED FOR MERGE**"

10:35 AM - Coordinator reads QA comment
          ✅ Fetches approval status: APPROVED
          ✅ Merges PR #45 to main
          ✅ Merges PR #46 to main
          ✅ Issue #3 auto-closes
          
10:36 AM - User: "Issue #3 fix complete. All PRs merged."
```

---

## Benefits

✅ **Clear Tracking**: QA feedback visible on GitHub issue
✅ **Transparent Decisions**: Coordinator's merge logic based on QA comment
✅ **Rejection Handling**: Specialists can fix and resubmit
✅ **Parallel Work**: Specialists work independently while QA reviews
✅ **Audit Trail**: Complete history on GitHub issue
✅ **No Direct Fixes**: Everything goes through formal workflow

---

## Common Scenarios

### Scenario 1: Approved on First Try ✅
```
QA posts: "✅ APPROVED FOR MERGE"
Result: Coordinator merges immediately
```

### Scenario 2: Rejected - Need Tests
```
QA posts: "❌ REJECTED - Coverage at 65%, need >80%"
Result: Coordinator routes back to specialists
        Specialists add tests
        Resubmit to QA
```

### Scenario 3: Multiple PRs
```
Issue #5 has:
  - PR #50: frontend (from frontend-dev)
  - PR #51: backend (from go-clean-arch)
  - PR #52: database (from db-design-impl)

QA reviews all 3
Posts single comment on Issue #5
Coordinator merges all 3 (if approved)
```

---

## Important Notes

🔴 **CRITICAL**: QA MUST post comment on GitHub issue
   - Coordinator cannot proceed without it
   - Comment must include approval status
   - Comment format should follow template

🔴 **CRITICAL**: Coordinator will NOT merge without QA comment
   - Not even if tests pass
   - Not even if specialists say "ready"
   - Waits for QA feedback comment

✅ **BEST PRACTICE**: Keep comments clear & specific
   - List blocked issues
   - List required changes
   - Be constructive

✅ **BEST PRACTICE**: Resubmit promptly after fixes
   - Don't wait after addressing changes
   - Request QA re-review immediately
