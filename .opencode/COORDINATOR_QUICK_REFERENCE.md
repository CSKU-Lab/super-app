# Coordinator Quick Reference

## One-Command Start

```bash
# Press Tab in OpenCode to cycle through agents
# Select "coordinator"
```

## One-Message Feature Request

```
Coordinator, [describe feature with requirements and acceptance criteria]
```

Example:
```
Coordinator, add dark mode support where users can toggle dark/light 
theme in settings, and have their preference persisted across sessions.
```

## What Happens Automatically

| Step | What | Who | Time |
|------|------|-----|------|
| 1 | Create GitHub issue | Coordinator | 2 min |
| 2 | Analyze & route | Coordinator | 3 min |
| 3 | Implement (parallel) | 5 Specialists | 20-45 min |
| 4 | Create PRs | Specialists | Auto |
| 5 | Post progress | Coordinator | Real-time |
| 6 | Review code | qa-specialist | 10-15 min |
| 7 | Post feedback | qa-specialist | Auto |
| 8 | Merge (if approved) | Coordinator | Auto |
| 9 | Close issue | GitHub | Auto |

**Total Time: 45-75 minutes** (depending on complexity)

## The 5 Specialists

```
┌─────────────────────────────────────────┐
│ Coordinator (Primary Agent)             │
│ Routes work to specialists              │
└──────────────┬──────────────────────────┘
               │
    ┌──────────┼──────────┬──────────┬─────────────┐
    │          │          │          │             │
    ▼          ▼          ▼          ▼             ▼
  db-design  go-clean   frontend-  service-    qa-
  -impl      arch       dev        comms       specialist
  
Database   Backend    Frontend   gRPC/Msg     Code Review
& Queries  Services   Components Queue & API  & Testing
PostgreSQL Go Code    React/TS   Proto Defs   >80% Coverage
MongoDB    REST API   TailwindCSS RabbitMQ    Security Check
Migrations Unit Tests Component   API Docs    Git Format
```

## Real-Time Tracking

Watch the GitHub issue for progress:

```
Issue #999: "Add dark mode support"

✅ Coordinator: Issue created, specialists assigned
   🟡 IN_PROGRESS: 2024-03-28 14:30

   Assigned Specialists:
   - frontend-dev: Create toggle component
   - db-design-impl: Add user_preferences table
   - go-clean-arch: Add settings API endpoint
   - service-comms: Document endpoint

   Timeline: ~45 minutes
   Dependencies: Parallel work (independent tasks)

---

✅ Progress Update
   🟡 IN_PROGRESS: 2024-03-28 14:40

   ✅ db-design-impl: Migration created (PR #1001)
   🟡 frontend-dev: Component in progress
   🟡 go-clean-arch: Endpoint implementation
   ⏳ service-comms: Awaiting endpoint completion

---

✅ All PRs Created
   🟡 AWAITING_QA: 2024-03-28 14:50

   PR #1001: feat(database): add user_preferences table
   PR #1002: feat(api): add settings endpoint
   PR #1003: feat(ui): add dark mode toggle

   QA specialist is now reviewing...

---

✅ QA Review Complete
   ✅ APPROVED: 2024-03-28 15:00

   ## QA Specialist Assessment

   Architecture: ✅ Clean separation
   Testing: ✅ 86% coverage
   Security: ✅ No vulnerabilities
   Database: ✅ Proper migrations
   Git: ✅ Proper Closes # format

   **Ready for merge!**

---

✅ Merging to Main
   ✅ MERGED: 2024-03-28 15:05

   Merged PR #1001, #1002, #1003
   Issue auto-closing...
   Timeline: 35 minutes

🎉 Feature Complete!
```

## Parallel vs Sequential Decision

### Use Parallel When Tasks Are Independent
- Database schema design + Frontend UI development
- gRPC proto definitions + Backend service implementation
- Multiple unrelated API endpoints

### Use Sequential When Tasks Are Dependent
- Database schema → Repository layer → Service → Handler
- Proto definitions → Service implementation → API endpoint
- API endpoint → Frontend integration

**Coordinator Decides Automatically** based on your requirements!

## Retry Logic (Automatic)

If a specialist struggles:

```
Task fails
  │
  ├→ Retry 1 (immediate): Same task, clearer instructions
  │   └─ Success? → Continue
  │   └─ Fail? ↓
  │
  ├→ Retry 2 (2 min): Simplified scope, step-by-step
  │   └─ Success? → Continue
  │   └─ Fail? ↓
  │
  ├→ Retry 3 (5 min): Detailed steps + code templates
  │   └─ Success? → Continue
  │   └─ Fail? ↓
  │
  └→ Escalation: Post issue comment asking for help
      └─ You provide info → Coordinator retries
```

## When to Respond (What You Do)

| Scenario | Action |
|----------|--------|
| Specialist blocked 3x | Respond to escalation comment |
| Feature requirements unclear | Add comment with clarification |
| Missing API credentials | Post credentials/config info |
| Dependency not available | Report what's missing |
| Want to speed up | Comment "prioritize" |
| Want to cancel | Comment "cancel" |

## Successful Example Timeline

```
14:30  User: "Add authentication feature"
14:32  Coordinator: Issue #999 created
14:33  Coordinator: Specialists assigned, progress posted
14:35  Coordinator: Posts initial assignment comment

14:40  db-design-impl: PR #1001 created (5 min work)
14:50  go-clean-arch: PR #1002 created (20 min work)
14:55  frontend-dev: PR #1003 created (25 min work)
15:00  Coordinator: Posts "All PRs Created" comment
15:00  qa-specialist: Starts review

15:10  qa-specialist: Posts ✅ APPROVED comment
15:11  Coordinator: Merges PR #1001
15:12  Coordinator: Merges PR #1002
15:13  Coordinator: Merges PR #1003
15:14  Issue #999: Auto-closes ✅
15:15  Coordinator: Posts final status comment

🎉 Feature shipped in 45 minutes!
```

## Common Feature Patterns

### Pattern: Authentication System
- **Services**: main-server (backend), web (frontend), PostgreSQL
- **Execution**: Database (parallel) → Backend (depends on DB) → Frontend (depends on Backend)
- **Time**: 30-45 minutes

### Pattern: Dark Mode
- **Services**: web (frontend), main-server (backend for preferences)
- **Execution**: Frontend and Backend in parallel
- **Time**: 20-30 minutes

### Pattern: New gRPC Service
- **Services**: config-server + main-server + main-server client
- **Execution**: Proto → Service → Client (sequential)
- **Time**: 40-60 minutes

### Pattern: Distributed Feature
- **Services**: All services (database, backend, frontend, comms)
- **Execution**: Everything in parallel except dependencies
- **Time**: 60-90 minutes

## Troubleshooting Checklist

```
❓ Issue not created?
  ✓ Are you using coordinator agent? (Tab to select)
  ✓ Did you describe a feature?
  ✓ Do you have GitHub auth? (gh auth login)

❓ Specialist stuck?
  ✓ Check GitHub issue for blocker comments
  ✓ Respond to escalation with needed info
  ✓ Coordinator will retry automatically

❓ QA rejected code?
  ✓ Coordinator routes specialist back
  ✓ Specialist fixes issues on PR
  ✓ QA reviews again (loop)

❓ PR not merged?
  ✓ Check issue for QA review status
  ✓ QA must post ✅ APPROVED first
  ✓ Then coordinator merges

❓ Tests failing?
  ✓ QA will catch and reject
  ✓ Specialist adds more tests
  ✓ QA reviews second attempt
```

## File Locations

```
/.opencode/agents/
├── coordinator.md (PRIMARY AGENT - updated)
├── db-design-impl.md (specialist)
├── frontend-dev.md (specialist)
├── go-clean-arch.md (specialist)
├── qa-specialist.md (specialist)
└── service-comms.md (specialist)

/.opencode/
├── COORDINATOR_WORKFLOW.md (this manual)
├── COORDINATOR_ARCHITECTURE.md (visual diagrams)
└── COORDINATOR_QUICK_REFERENCE.md (this file)
```

## Key Differences: Before vs After

| Aspect | Before | After |
|--------|--------|-------|
| **Agent Type** | Subagent (invoked) | Primary agent (Tab-selectable) |
| **Role** | Helper/advisor | Orchestrator |
| **GitHub Integration** | Manual issue creation | Auto-creates & tracks |
| **Specialist Routing** | Single specialist | All 5 coordinated |
| **Progress Tracking** | Manual | Real-time comments |
| **Failure Handling** | Manual retries | Automatic with backoff |
| **QA Integration** | Manual routing | Automatic coordination |
| **Merge Decision** | Manual | Automatic post-approval |
| **PR Templates** | Manual | Auto-generated |

## Feature Request Template

For best results, structure your request like:

```
Coordinator, [feature description]

Requirements:
- [Requirement 1]
- [Requirement 2]
- [Requirement 3]

Acceptance Criteria:
- [ ] Users can [action]
- [ ] Data is [property]
- [ ] System [behavior]

Services Affected:
- [Service 1]: [why]
- [Service 2]: [why]
```

Example:
```
Coordinator, add user dashboard showing submitted assignments.

Requirements:
- Display list of assignments with status
- Show due dates and grades
- Filter by status (pending, graded, late)
- Responsive on mobile/tablet

Acceptance Criteria:
- [ ] Users can view their assignments
- [ ] Assignment status is accurate
- [ ] Filters work correctly
- [ ] Mobile layout is responsive

Services Affected:
- Database: Query optimization for assignments
- Backend: Add dashboard API endpoint
- Frontend: Create dashboard component
```

## Success Metrics

Your implementation is successful when:

✅ GitHub issue created and closed  
✅ All PRs merged to main  
✅ QA gave final approval  
✅ Feature works as described  
✅ Tests pass (>80% coverage)  
✅ No blockers during execution  
✅ Timeline met (within estimate)  

## Next Steps

1. **Try it**: Open OpenCode and press Tab to select coordinator
2. **Describe a feature**: "Add [feature] to [service]"
3. **Watch GitHub**: Follow the issue for real-time updates
4. **Wait for merge**: Coordinator will handle everything
5. **Celebrate**: Your feature is live! 🎉

---

For more details:
- Full workflow: See `COORDINATOR_WORKFLOW.md`
- Visual architecture: See `COORDINATOR_ARCHITECTURE.md`
- Agent details: See `.opencode/agents/coordinator.md`
