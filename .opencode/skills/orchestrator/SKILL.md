---
name: orchestrator
description: Multi-agent orchestration patterns for complex tasks across microservices
license: MIT
compatibility: opencode
metadata:
  audience: experienced-developers
  pattern: agent-coordination
  scope: multi-service
---

# Multi-Agent Orchestration

This skill describes orchestration patterns for coordinating work across multiple agents for complex tasks in CSKU Lab. Use this when you need to delegate work to specialized agents or when tasks span multiple microservices.

## Orchestration Philosophy

The orchestrator pattern allows a primary agent to break down complex work and delegate specialized tasks to other agents:

- **Simple tasks** → Handle directly
- **Multi-service tasks** → Dispatch to appropriate agents
- **Parallel work** → Coordinate independent tasks
- **Sequential dependencies** → Manage task ordering

## When to Use Orchestration

### Dispatch to Specialized Agents When:

1. **Task involves multiple services**
   - Main-server + config-server changes
   - Distributed grading system updates
   - Database schema + API changes

2. **Different expertise areas needed**
   - Backend + Frontend work
   - Infrastructure + Application code
   - Grading system + Database changes

3. **Parallel work opportunities exist**
   - Independent service changes
   - Test execution
   - Documentation updates

4. **Task requires specific tools/context**
   - Go microservices (load go-microservices skill)
   - gRPC design (load grpc-api-design skill)
   - Database migrations (load database-migrations skill)

### Handle Directly When:

- Single service, single concern
- Limited scope (< 30 lines of code)
- No architectural decisions needed
- No skill-specific knowledge required

## Orchestration Patterns

### Pattern 1: Sequential Coordination

**Use Case:** Changes that depend on each other (schema → API → frontend)

```
Task Analysis
    ↓
Backend Dev: Add database column
    ↓
Backend Dev: Update API response
    ↓
Frontend Dev: Update UI
    ↓
Integration Testing
```

**Implementation:**
1. Analyze requirements
2. Dispatch backend work first
3. Wait for completion
4. Dispatch frontend work with backend context
5. Run integration tests

### Pattern 2: Parallel Coordination

**Use Case:** Independent changes that can happen simultaneously

```
Task Analysis
    ↓
┌──────────────────────┬───────────────────────┐
│                      │                       │
Service A Changes  Service B Changes   Documentation
│                      │                       │
└──────────────────────┴───────────────────────┘
         ↓
Integration Testing
```

**Implementation:**
1. Analyze task to identify independent work
2. Dispatch multiple agents in parallel with context
3. Collect results
4. Run integration tests
5. Merge changes

### Pattern 3: Hierarchical Coordination

**Use Case:** Complex tasks with sub-tasks (multi-service gRPC changes)

```
Main Task: Add new gRPC service feature
    │
    ├─ Skill Load: grpc-api-design
    │
    ├─ Proto Definition
    │  └─ Backend Dev: Define proto
    │
    ├─ Service Implementation
    │  ├─ Backend Dev: Implement gRPC server
    │  └─ Backend Dev: Add gRPC client
    │
    ├─ Integration
    │  └─ Integration Tests
    │
    └─ Documentation
       └─ Update API docs
```

## Example Orchestrations

### Scenario 1: Add User Authentication

**Task:** Add JWT authentication to config-server

**Analysis:**
- Main-server: Already has JWT (reference implementation)
- config-server: Needs middleware + token validation
- Database: May need user table updates
- gRPC: Add auth metadata handling

**Orchestration Plan:**

```
1. Load Skills
   - Load go-microservices skill
   - Load grpc-api-design skill (for gRPC auth)

2. Backend Work (Sequential)
   - Dispatch: "Add authentication middleware to config-server"
     - Reference main-server implementation
     - Update gRPC interceptors
     - Add auth headers to requests
   
   - Wait for completion
   
   - Dispatch: "Add JWT validation to requests"
     - Parse and verify tokens
     - Add to context
   
   - Wait for completion
   
   - Dispatch: "Write integration tests"

3. Documentation
   - Dispatch: "Document auth changes"
```

### Scenario 2: Add New Assignment Submission Type

**Task:** Support video submissions (currently text-based code)

**Analysis:**
- main-server: REST API, submission handling
- task-server: Assignment schema
- Database: New submission type enum
- Frontend: Upload UI changes
- Storage: MinIO integration

**Orchestration Plan:**

```
1. Load Skills
   - go-microservices (backend changes)
   - docker-compose (test environment)
   - database-migrations (schema changes)

2. Parallel Phase 1 (Independent)
   - Backend Dev: "Update assignment schema in task-server"
     - Add submission_type field
     - Update MongoDB schema
   
   - Backend Dev: "Add submission type enum to main-server"
     - Create enums
     - Update validation

3. Sequential Phase 2 (Depends on Phase 1)
   - Wait for Phase 1 completion
   
   - Backend Dev: "Implement MinIO upload handling"
     - Add file upload to submission
     - Store in MinIO
   
   - Frontend Dev: "Add video upload UI"
     - Video preview
     - File validation

4. Integration
   - Run end-to-end tests
   - Test file upload flow
   - Verify storage

5. Documentation
   - Update API documentation
   - Update architecture docs
```

### Scenario 3: Fix Grading Timeout Issues

**Task:** Investigate and fix timeout issues in go-grader

**Analysis:**
- Docker Compose: Service configuration
- Code-Sandbox: Isolate settings
- Go-grader: Worker implementation
- Database: Query timeouts
- RabbitMQ: Queue health

**Orchestration Plan:**

```
1. Load Skills
   - docker-compose (service inspection)
   - code-sandbox (isolate configs)
   - go-microservices (worker code)

2. Investigation (Parallel)
   - Explore: "Check go-grader worker logs"
     - Find timeout pattern
     - Identify affected tasks
   
   - Explore: "Check isolate configuration"
     - Review resource limits
     - Check wall-time settings
   
   - Explore: "Check RabbitMQ queue health"
     - Queue depth
     - Connection issues

3. Root Cause Analysis
   - Synthesize findings
   - Determine likely cause

4. Implementation (Varies)
   - If Docker: Update docker-compose timeout
   - If Isolate: Adjust sandbox config
   - If Worker: Optimize grading code
   - If Queue: Add monitoring

5. Testing
   - Run grading tasks
   - Monitor execution time
   - Verify fixes
```

## Coordination Protocols

### Information Passing

When dispatching agents, provide:

```
What to do: Clear, specific task
Why it matters: Context and dependencies
What to reference: Related code/services
How to verify: Success criteria and tests
Dependencies: What must complete first
Timeline: Urgency and deadlines
```

**Example:**
```
Task: Update main-server to call new config-server endpoint

Context: We added GetStatus() to config-server. main-server health checks 
need to verify config service health.

Reference:
- Main-server health endpoint: internal/adapters/http/health.go
- New config-server endpoint: config-server/protos/config_service.proto (GetStatus RPC)
- Existing config-server client: main-server/internal/adapters/grpc/config_client.go

Verification:
- Health endpoint returns 500 if config-server unavailable
- Health checks include config-server status
- Tests pass: go test ./internal/adapters/http
- Manual: curl localhost:8080/health

Dependencies: config-server GetStatus must be deployed first
Timeline: Needed for release next week
```

### Monitoring Parallel Work

When dispatching multiple agents in parallel:

1. **Track progress** - Know which agent is on what task
2. **Identify blockers** - If one task fails, halt dependent tasks
3. **Collect outputs** - Gather results and merge changes
4. **Validate integration** - Ensure changes work together
5. **Rollback if needed** - Have plan to revert all changes

## Escalation Rules

### When to Escalate to Different Agents

**Escalate if:**
- Current agent is blocked waiting for another service
- Task changes domain mid-way
- Specialized knowledge is suddenly needed
- Multi-agent coordination becomes necessary

**Example:**
```
You: Working on main-server submission API
Issue: Need to understand task-server schema
Action: Dispatch task to @explore to search task-server proto definitions
```

## Integration Points

### Before Integration Testing

All agents must:
- [ ] Run unit tests in their changes (`go test ./...`)
- [ ] Verify changes don't break builds
- [ ] Update documentation
- [ ] Consider error cases

### After Individual Work

Before merging parallel work:
- [ ] Run full test suite
- [ ] Check gRPC contract compatibility
- [ ] Verify database schema consistency
- [ ] Test Docker Compose startup
- [ ] Check API backward compatibility

### Post-Integration

After all work is merged:
- [ ] Run end-to-end tests
- [ ] Load test changed services
- [ ] Security review of new code
- [ ] Performance benchmarking
- [ ] Documentation review

## Anti-Patterns to Avoid

### ❌ Task Overloading

Don't give one agent too much:
```
Bad: "Update config-server to support new features, improve performance, 
add monitoring, and integrate with new logging service"

Good: "Add GetStatus() RPC to config-server to support health checks"
     (other changes in separate tasks)
```

### ❌ Unclear Dependencies

Don't leave ordering ambiguous:
```
Bad: "Update authentication in main-server and config-server"

Good: "First: Update config-server auth middleware"
     "Then: Update main-server to send auth headers to config-server"
```

### ❌ Context Loss

Don't assume agents know project state:
```
Bad: "Add the new field"

Good: "Add 'submission_type' field to Submission message in task-server 
to support video submissions alongside text submissions"
```

### ❌ No Verification Plan

Don't skip testing:
```
Bad: "Update the database schema"

Good: "Add 'status' column with default 'active' to submissions table.
Verify: Old code still works without schema changes, migration is backward compatible"
```

## Best Practices

1. **Load Skills First** - Let agents understand domain
2. **Be Specific** - Clear requirements, not vague directions
3. **Provide Context** - Why this change, what depends on it
4. **Sequential When Needed** - Don't parallelize dependent work
5. **Verify Integration** - Run full tests after parallel work
6. **Document Decisions** - Explain architectural choices
7. **Plan Rollbacks** - Know how to undo changes if needed
8. **Monitor Progress** - Track status of multi-agent work

---

**When to use this skill:** Use this when designing complex multi-service changes, coordinating parallel work across agents, or planning large feature implementations involving multiple microservices.

**Related Skills:**
- go-microservices (backend service patterns)
- grpc-api-design (inter-service communication)
- docker-compose (service orchestration)
- database-migrations (schema management)
- code-sandbox (grading system)
