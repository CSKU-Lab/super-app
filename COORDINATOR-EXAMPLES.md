# Coordinator Agent - Prompt Examples

This document provides examples of how to request features, bug fixes, and other work using the `@coordinator` agent.

## Quick Start

Use this format to request work:

```
@coordinator create issue for: [type] - [description]
```

Where:
- `[type]` = `bug`, `feature`, `hotfix`, `enhancement`, `refactor`
- `[description]` = Clear description of what needs to be done

---

## Example Requests

### 1. Simple Bug Fix

**Prompt:**
```
@coordinator create issue for: bug - fix compare script selector dropdown 
broken after backend pagination update
```

**What Coordinator Does:**
- ✅ Creates GitHub issue #X
- ✅ Routes frontend-dev specialist to fix ConfigService
- ✅ Routes go-clean-arch to verify API contract
- ✅ Monitors PRs and routes to QA
- ✅ Waits for QA feedback comment on issue
- ✅ Merges when QA approves

---

### 2. Detailed Bug Fix

**Prompt:**
```
@coordinator create issue for: bug - ConfigService returns paginated object 
instead of data array

Root cause: Backend API updated to return {pagination: {...}, data: [...]} 
but frontend expects array

Affected components:
- web/src/services/config.service.ts (getRunners, getCompareScripts methods)
- web/src/components/CompareScript.tsx (dropdown selector)
- web/src/components/AllowedRunners.tsx (autocomplete)

Impact: CMS Materials config UI broken - users cannot select compare scripts 
or allowed runners
```

**What Coordinator Does:**
- ✅ Creates detailed GitHub issue with root cause
- ✅ Routes specialists with full context
- ✅ Tracks work with clear requirements
- ✅ Manages code review and approval process

---

### 3. Simple Feature Request

**Prompt:**
```
@coordinator create issue for: feature - add dark mode toggle to user settings
```

---

### 4. Detailed Feature Request

**Prompt:**
```
@coordinator create issue for: feature - implement user notification preferences

Requirements:
- Add notification preference page in user settings
- Options: email notifications, in-app notifications, disable all
- Store preferences in database
- Persist across sessions

Services involved:
- frontend: new settings page component
- backend: preference endpoints and database schema
- database: user_notifications table

Acceptance criteria:
- [ ] Settings UI works
- [ ] Preferences saved to database
- [ ] Preferences persist on reload
- [ ] Email notifications respect preference
- [ ] >80% test coverage
```

---

### 5. Database Feature

**Prompt:**
```
@coordinator create issue for: feature - add user analytics tracking table

Schema:
- user_id (FK to users table)
- page_visited (string)
- action (view, click, submit)
- timestamp (datetime)
- metadata (JSON for additional data)

Indexes needed:
- user_id + timestamp for fast lookups
- page_visited for analytics queries

Also add migration and seed data examples
```

---

### 6. Backend API Addition

**Prompt:**
```
@coordinator create issue for: feature - add user profile endpoint

Requirements:
- GET /api/users/me - get current user profile
- Requires authentication
- Return user data: id, name, email, role, avatar_url
- Include unit tests with >80% coverage
- Document in Postman collection

Services:
- main-server: REST API handler
- database: user query
```

---

### 7. Frontend Component

**Prompt:**
```
@coordinator create issue for: feature - create code editor component

Requirements:
- Monaco editor integration
- Support for multiple languages (Go, Python, JavaScript, Java)
- Syntax highlighting
- Code completion
- Theme support (light/dark)
- Line numbers and minimap

Components needed:
- CodeEditor.tsx (main component)
- useCodeEditor.ts (custom hook)
- useMonacoTheme.ts (theme management)

Acceptance criteria:
- [ ] Editor loads code files
- [ ] Syntax highlighting works for all languages
- [ ] Code completion functional
- [ ] Responsive design (mobile, tablet, desktop)
- [ ] Component tests >80% coverage
```

---

### 8. Hotfix (Urgent Production Issue)

**Prompt:**
```
@coordinator create issue for: hotfix - API returning 500 errors on login

Urgency: CRITICAL - Production issue affecting all users

Current state: Users cannot log in, getting 500 Internal Server Error

Last known working state: Commit abc1234 (2 days ago)

Suspected cause: Recent authentication changes in main-server

Please investigate and fix immediately
```

---

### 9. Multi-Service Feature

**Prompt:**
```
@coordinator create issue for: feature - implement code submission and grading system

This is a multi-service epic:

Services involved:
- frontend (web): submission form, code editor, grade display
- backend (main-server): submission endpoints, grade storage
- grading (go-grader): execute code, compare output, generate feedback
- database: submissions and grades tables

Workflow:
1. Student submits code via web UI
2. Submission queued to RabbitMQ
3. go-grader processes submission
4. Results stored in database
5. Student sees grade and feedback

Acceptance criteria:
- [ ] Code can be submitted
- [ ] Grading executes in sandbox
- [ ] Grades stored and retrievable
- [ ] Student can view grades
- [ ] All tests pass with >80% coverage
```

---

### 10. Security Fix

**Prompt:**
```
@coordinator create issue for: bug - SQL injection vulnerability in user search

Severity: HIGH

Location: main-server GET /api/users?search={query}

Issue: User search parameter not parameterized, vulnerable to SQL injection

Example vulnerable query:
SELECT * FROM users WHERE name = '{user_input}'

Should be:
SELECT * FROM users WHERE name = $1

Also check for similar issues in other endpoints

Acceptance criteria:
- [ ] Search parameter properly parameterized
- [ ] Security audit of all query endpoints
- [ ] Unit tests for SQL injection prevention
- [ ] No other injection vulnerabilities found
```

---

### 11. Performance Optimization

**Prompt:**
```
@coordinator create issue for: enhancement - optimize dashboard query performance

Current issue: Dashboard takes 5+ seconds to load

Suspected cause: N+1 query problem when fetching assignments with submissions

Areas to optimize:
- Assignment list query with join to get submission count
- User profile query with related data
- Course statistics calculation

Acceptance criteria:
- [ ] Dashboard loads in <1 second
- [ ] No N+1 queries
- [ ] Database indexes optimized
- [ ] Query analysis performed
- [ ] Performance metrics documented
```

---

### 12. Refactoring Task

**Prompt:**
```
@coordinator create issue for: refactor - convert UserService from interface{} 
to generics

Current code uses interface{} and type assertions, making it unsafe

Refactoring:
- Convert UserRepository to use generics
- Improve type safety
- Maintain backward compatibility
- Add tests to verify behavior unchanged

Services affected:
- main-server internal/services/user_service.go
- main-server internal/repositories/user_repository.go
```

---

## What NOT to Do

### ❌ Bad Examples

```
@coordinator let's fix the login issue
```
❌ Too vague, no clear description

```
@coordinator add dark mode
```
❌ Missing "create issue for:" format

```
@coordinator can you help me with the database?
```
❌ Not a clear request

```
@coordinator please do everything needed for user authentication
```
❌ Too broad, not specific

---

## ✅ Good Format Template

```
@coordinator create issue for: [type] - [short title]

[Optional: detailed description]

[Optional: affected services/components]

[Optional: acceptance criteria as checklist]
```

---

## Coordinator Response

When you use the correct format, the coordinator will:

1. **Create GitHub Issue** with your description
   - Issue number: #X
   - URL: https://github.com/CSKU-Lab/super-app/issues/X

2. **Analyze Requirements** and identify affected services

3. **Route to Specialists** in parallel (if independent):
   - `frontend-dev` for UI/React/TypeScript
   - `go-clean-arch` for backend/Go services
   - `db-design-impl` for database/migrations
   - `service-comms` for gRPC/inter-service APIs
   - `qa-specialist` for code review

4. **Create Feature Branches** with format: `feat/{issue}-{domain}/{description}`

5. **Monitor PRs** created by specialists

6. **Route to QA** for code review

7. **QA Posts Feedback** on GitHub issue with approval/rejection

8. **Make Merge Decision**:
   - ✅ If APPROVED → Merge PRs to main
   - ❌ If REJECTED → Route back to specialists with required changes

9. **Report Status** with summary and links

---

## Benefits

✅ **GitHub Issue Tracking** - Everything visible and trackable  
✅ **Parallel Work** - Specialists work independently  
✅ **Clear Feedback** - QA comments visible on issue  
✅ **Automatic Decisions** - Merge based on QA approval  
✅ **No Direct Fixes** - Everything formal and documented  
✅ **Auto-Closes** - Issue closes when PRs merged  

---

## Common Request Types

| Type | Format | Example |
|------|--------|---------|
| Bug | `bug - what's broken` | `bug - login endpoint returning 401` |
| Feature | `feature - what to build` | `feature - add email notifications` |
| Hotfix | `hotfix - urgent issue` | `hotfix - database connection failing` |
| Enhancement | `enhancement - what to improve` | `enhancement - optimize query performance` |
| Refactor | `refactor - what to improve` | `refactor - convert to generics` |

---

## Tips for Best Results

1. **Be Specific**
   - Describe exactly what's broken or needed
   - Include affected components

2. **Include Context**
   - Root cause (if known)
   - Error messages (if bug)
   - Requirements (if feature)

3. **List Services Involved**
   - Frontend, backend, database, etc.
   - Helps coordinator route correctly

4. **Add Acceptance Criteria**
   - Clear checklist for "done"
   - Used by QA to verify work

5. **Keep It Concise**
   - One sentence title
   - Bullet points for details
   - No need for long explanations

---

## Getting Help

If you need clarification on:
- **Workflow**: Read `COORDINATOR-WORKFLOW.md`
- **QA Process**: Read `QA-FEEDBACK-WORKFLOW.md`
- **Agent Rules**: Check `.opencode/agents/coordinator.md`

---

**Ready to request work?** Use `@coordinator create issue for: ...` to get started! 🚀
