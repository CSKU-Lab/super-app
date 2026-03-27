# Coordinator Agent - Complete Documentation Index

Welcome to the Coordinator-driven end-to-end workflow for CSKU Lab super-app! This document is your entry point to understanding and using the new Coordinator primary agent.

## 📚 Documentation Files

### 1. **COORDINATOR_QUICK_REFERENCE.md** (START HERE for immediate use)
   - **Best for**: Quick start, common patterns, troubleshooting
   - **Contains**: 
     - One-command start (Press Tab to switch)
     - Feature request template
     - Common patterns (authentication, dark mode, gRPC services)
     - Timeline expectations
     - Troubleshooting checklist
   - **Read time**: 5-10 minutes

### 2. **COORDINATOR_WORKFLOW.md** (Complete User Manual)
   - **Best for**: Understanding the full workflow, details, examples
   - **Contains**:
     - Detailed workflow phases
     - Real-world example (user auth feature)
     - GitHub progress tracking examples
     - Failure handling & retry logic
     - Timeline breakdown
     - Common patterns
   - **Read time**: 15-20 minutes

### 3. **COORDINATOR_ARCHITECTURE.md** (Visual Architecture)
   - **Best for**: Understanding system design, data flow, parallelization
   - **Contains**:
     - End-to-end flow diagram
     - Parallel vs sequential execution
     - Specialist routing decision tree
     - Failure handling flowchart
     - GitHub issue lifecycle
     - Data flow diagrams
   - **Read time**: 10-15 minutes

### 4. **.opencode/agents/coordinator.md** (Agent Configuration)
   - **Best for**: Technical details, agent configuration, precise workflow
   - **Contains**:
     - YAML configuration (mode: primary, permissions)
     - Detailed prompt instructions
     - Service routing rules
     - PR template generation
     - GitHub issue progress updates
     - Retry logic implementation
     - Commit message format
   - **Read time**: 10-15 minutes

---

## 🚀 Quick Start (2 minutes)

### 1. Switch to Coordinator Agent
```
Press Tab in OpenCode to cycle through primary agents
Select "coordinator" from the list
```

### 2. Describe Your Feature
```
Coordinator, add user authentication with profile management.

Users should be able to:
- Sign up with email and password
- Log in with credentials
- View and edit their profile
- Log out
```

### 3. Watch GitHub
Open the GitHub issue created by the Coordinator and watch progress in real-time.

### 4. Wait for Completion
The Coordinator will:
- Route specialists in parallel/sequential order
- Handle failures with intelligent retry
- Coordinate QA review
- Merge when approved
- Auto-close the issue

---

## 🎯 Which Document Should I Read?

### "I want to start using it immediately"
→ Read: **COORDINATOR_QUICK_REFERENCE.md**

### "I want to understand the workflow"
→ Read: **COORDINATOR_WORKFLOW.md**

### "I want to see diagrams and data flow"
→ Read: **COORDINATOR_ARCHITECTURE.md**

### "I want to understand the technical configuration"
→ Read: **.opencode/agents/coordinator.md**

### "I'm troubleshooting an issue"
→ Read: **COORDINATOR_QUICK_REFERENCE.md** (Troubleshooting Checklist section)

### "I want to understand parallel execution"
→ Read: **COORDINATOR_ARCHITECTURE.md** (Parallel vs Sequential section)

### "I want to see a real example"
→ Read: **COORDINATOR_WORKFLOW.md** (Example: Full Feature Implementation section)

---

## 📋 The 5 Specialist Agents

The Coordinator orchestrates these 5 specialists:

### **go-clean-arch** (Backend Services)
- Implements features in Go microservices
- Services: main-server, config-server, task-server, go-grader
- Pattern: Clean architecture (domain → services → handlers)
- Testing: Unit tests with mocks, >80% coverage

### **db-design-impl** (Database Design)
- Designs schemas and manages migrations
- Databases: PostgreSQL (main-server), MongoDB (config/task)
- Tools: Atlas for PostgreSQL migrations
- Testing: Integration tests with testcontainers

### **frontend-dev** (React/Next.js)
- Implements UI components and features
- Stack: Next.js, TypeScript, TailwindCSS, React Query
- Pattern: Component-based, custom hooks
- Testing: Jest, React Testing Library, >80% coverage

### **service-comms** (Inter-Service Communication)
- Designs gRPC APIs and message queues
- Protocols: gRPC (sync), RabbitMQ (async)
- Documentation: Postman API collections
- Pattern: Proto-first API design

### **qa-specialist** (Code Review & QA)
- Reviews code quality, security, tests
- Validation: >80% test coverage, architecture, security
- Approval: Posts feedback on GitHub issue
- Decision: ✅ APPROVED or ❌ REJECTED

---

## 🔄 Workflow Summary

```
1. USER DESCRIBES FEATURE
   ↓
2. COORDINATOR CREATES GITHUB ISSUE #999
   ├─ Title: Feature description
   ├─ Body: Requirements, acceptance criteria
   └─ Labels: feature, domain, priority
   ↓
3. COORDINATOR ANALYZES & ROUTES SPECIALISTS
   ├─ Identifies affected services
   ├─ Plans parallel/sequential execution
   └─ Posts initial assignment comment
   ↓
4. SPECIALISTS IMPLEMENT IN PARALLEL
   ├─ Each specialist works on their component
   ├─ Coordinator monitors progress
   ├─ Retry logic handles failures
   └─ Posts progress updates
   ↓
5. SPECIALISTS CREATE PRs
   ├─ PR #1001 (Database)
   ├─ PR #1002 (Backend)
   ├─ PR #1003 (Frontend)
   └─ etc.
   ↓
6. COORDINATOR ROUTES TO QA SPECIALIST
   ├─ QA reviews all PRs
   ├─ Validates >80% test coverage
   └─ Posts feedback on issue
   ↓
7. COORDINATOR MAKES MERGE DECISION
   ├─ If ✅ APPROVED: Merge all PRs
   ├─ If ❌ REJECTED: Route back to specialists
   └─ Repeat until approved
   ↓
8. GITHUB ISSUE AUTO-CLOSES
   ├─ All PRs merged to main
   ├─ Feature is live
   └─ Done! 🎉
```

---

## ⏱️ Expected Timeline

| Complexity | Analysis | Implementation | QA Review | Total |
|-----------|----------|-----------------|-----------|-------|
| Simple | 2 min | 5-10 min | 5 min | ~15 min |
| Medium | 3 min | 15-20 min | 10 min | ~30 min |
| Complex | 5 min | 30-45 min | 15 min | ~60 min |
| Ultra | 5 min | 45-60 min | 20 min | ~90 min |

---

## 🔍 Key Features

### ✅ Parallel Execution
Independent tasks run simultaneously, saving 30-50% time.

Example:
```
Database schema design (5 min)     ⟶ All happen at the same time
Frontend UI components (5 min)     ⟶ Coordinator orchestrates
Backend API endpoints (5 min)      ⟶ Results merge automatically
```

### ✅ Intelligent Dependency Detection
Dependent tasks run in sequence automatically.

Example:
```
Database schema → Repository layer → Service layer → API handler → UI
(Sequential: each depends on previous output)
```

### ✅ PR Template Generation
Pre-filled PR templates with issue context, acceptance criteria, testing checklists.

### ✅ Real-Time Progress Tracking
GitHub issue comments updated as work progresses.

### ✅ Automatic Retry Logic
Failed tasks retry up to 3 times with exponential backoff:
- Attempt 1: Immediate (clarified instructions)
- Attempt 2: 2-min wait (simplified scope)
- Attempt 3: 5-min wait (detailed steps + templates)
- Escalation: User help requested if all fail

### ✅ QA-Gated Merges
No code merges without QA approval. All PRs reviewed for:
- Architecture consistency
- Test coverage >80%
- Security vulnerabilities
- Git commit format
- Code quality

### ✅ Full Traceability
Every action tracked in GitHub issue for audit trail.

### ✅ Single Issue Per Feature
One GitHub issue = Complete feature end-to-end.

---

## 🎓 Learning Path

### Level 1: Getting Started (5 min)
1. Read: **COORDINATOR_QUICK_REFERENCE.md** (Quick Start section)
2. Try it: Switch to coordinator and describe a feature
3. Observe: GitHub issue creation and specialist assignments

### Level 2: Understanding Workflow (15 min)
1. Read: **COORDINATOR_WORKFLOW.md** (Workflow Phases section)
2. Review: GitHub Issue Progress Tracking examples
3. Understand: How progress updates work

### Level 3: Advanced Usage (20 min)
1. Read: **COORDINATOR_ARCHITECTURE.md** (Full document)
2. Study: Parallel vs Sequential Execution patterns
3. Learn: Failure handling and retry logic

### Level 4: Troubleshooting (10 min)
1. Read: **COORDINATOR_QUICK_REFERENCE.md** (Troubleshooting section)
2. Reference: Common patterns for your use case
3. Know: When to respond to escalations

---

## 💡 Tips for Best Results

### ✅ Be Specific
**Good:** "Add authentication with email/password and JWT tokens"
**Bad:** "Add authentication"

### ✅ Include Acceptance Criteria
```
Users should be able to:
- [ ] Sign up with email
- [ ] Log in with credentials
- [ ] See profile page
- [ ] Edit profile
```

### ✅ Mention Affected Services
```
Database: Add users table with auth fields
Backend: main-server auth endpoints
Frontend: Login and profile pages
```

### ✅ Watch the GitHub Issue
New comments are posted as work advances.

### ✅ Respond to Escalations
If a specialist is blocked, coordinator posts an issue comment asking for help. Respond quickly!

---

## 🚨 Common Issues & Solutions

### Issue: "GitHub issue not created"
**Solution**: 
- Confirm you're using coordinator agent (press Tab)
- Check GitHub authentication: `gh auth login`
- Describe a feature clearly with requirements

### Issue: "Specialist blocked (red escalation)"
**Solution**:
- Check GitHub issue for coordinator's escalation comment
- Respond to the comment with requested information
- Coordinator will retry automatically

### Issue: "QA rejected code"
**Solution**:
- Read QA's feedback comment on GitHub issue
- Coordinator will route specialists back for fixes
- Specialists update PRs
- QA reviews again (loop continues until approved)

### Issue: "Tests failing"
**Solution**:
- This is part of QA review (expected)
- QA specialist catches test failures
- Coordinator routes back to specialists for fixes
- Process repeats until QA approves

---

## 📞 When to Contact Support

### Message Coordinator During Session
For workflow questions or clarifications:
- "Coordinator, what services are affected?"
- "Coordinator, can you explain the retry logic?"

### Check Documentation Files
For configuration or workflow understanding:
- `.opencode/agents/coordinator.md` (Technical config)
- `COORDINATOR_WORKFLOW.md` (Full manual)
- `COORDINATOR_ARCHITECTURE.md` (Diagrams)

### Respond to Issue Comments
For escalations from coordinator:
- Post response directly on GitHub issue
- Provide requested information/context
- Coordinator reads and retries automatically

---

## 🎯 Success Criteria

Your feature implementation is successful when:

✅ GitHub issue created and closed  
✅ All PRs merged to main  
✅ QA gave ✅ APPROVED status  
✅ Feature works as described  
✅ Tests pass with >80% coverage  
✅ No critical blockers  
✅ Timeline approximately met  

---

## 📚 Additional Resources

### CSKU Lab Documentation
- Architecture: [README.md](../README.md)
- Services: [AGENTS.md](../AGENTS.md)
- Setup: [setup.sh](../setup.sh)

### OpenCode Documentation
- Agents: https://opencode.ai/docs/agents
- Configuration: https://opencode.ai/docs/config

### GitHub CLI
- Installation: `brew install gh` (macOS) or `apt install gh` (Linux)
- Authentication: `gh auth login`
- Issues: `gh issue create`, `gh issue view`

---

## 🎉 You're Ready!

The Coordinator is fully configured and ready to use. 

**Next steps:**
1. Press Tab in OpenCode to switch to coordinator
2. Describe a feature you want to build
3. Watch the GitHub issue for real-time progress
4. Your feature will be implemented, tested, and merged automatically!

Questions? Check the documentation files above for detailed explanations and examples.

Happy coding! 🚀
