# CSKU Lab - Agent Context & Skills

This document provides specialized context for AI agents working on the Super-App project. It describes the project architecture, development patterns, and specialized skills available to coordinate work across the microservices platform.

## Project Overview

**CSKU Lab** is a microservices-based learning management and code grading platform. The system consists of 5 Go backend services, a Next.js frontend, and comprehensive API documentation.

- **Primary Language**: Go (backend services)
- **Frontend**: TypeScript/React (Next.js)
- **Infrastructure**: Docker Compose with PostgreSQL, MongoDB, RabbitMQ, Redis, MinIO
- **Architecture Pattern**: Microservices with Master-Worker (for grading), Clean Architecture (for API)

## Microservices Overview

### Service Topology

```
┌─────────────────────────────────────┐
│     main-server (Port 8080)         │
│     Core REST API - GoFiber         │
│     Database: PostgreSQL             │
└──────────┬──────────────────────────┘
           │
    ┌──────┼──────┐
    │      │      │
    ▼      ▼      ▼
config  task    go-grader
server  server  (master-worker)
(8081)  (8082)  (8083)
```

### Backend Services

| Service | Port | Database | Purpose | Key Patterns |
|---------|------|----------|---------|--------------|
| **main-server** | 8080 | PostgreSQL | Core REST API, auth, submissions | GoFiber, sqlx, RabbitMQ integration |
| **config-server** | 8081 | MongoDB | Configuration management | gRPC, Redis caching |
| **task-server** | 8082 | MongoDB | Task definitions & metadata | gRPC, read-heavy |
| **go-grader** | 8083 | - | Distributed code grading | Master-worker, RabbitMQ, Isolate |
| **isolate-docker** | - | - | Sandboxed code execution | IOI Isolate, Docker privileged |

### Frontend & Documentation

| Component | Port | Technology | Purpose |
|-----------|------|------------|---------|
| **web** | 3000 | Next.js, TypeScript | User interface & code editor |
| **api-docs** | - | Postman Collections | API reference & testing |

## Development Patterns by Service

### Go Microservices (main-server, config-server, task-server, go-grader)

**Standard Structure:**
```
service/
├── cmd/                    # Entrypoints
├── internal/               # Private business logic
├── domain/                 # Models, interfaces
├── adapters/              # HTTP, gRPC, DB
├── tests/                 # Unit & integration tests
└── go.mod                 # Dependencies
```

**Technology Stack:**
- **HTTP Framework**: GoFiber v3
- **Database Drivers**: sqlx (PostgreSQL), MongoDB Go driver
- **Communication**: gRPC (protobuf), RabbitMQ (AMQP)
- **Caching**: Redis
- **Migrations**: Atlas for schema management
- **Dev**: Air (hot reload), Docker Compose

**Code Patterns:**
- Repository pattern for data access
- Dependency injection via constructors
- Error handling: custom error types in domain
- Context propagation for tracing
- Middleware for cross-cutting concerns

### Frontend (web)

**Technology Stack:**
- Next.js 14+ with TypeScript
- React for components
- TailwindCSS for styling
- Zod/Validation for forms
- React Query/SWR for API calls

**API Integration:**
- REST calls to main-server (Port 8080)
- Real-time updates via WebSocket/Server-Sent Events
- Authentication: JWT tokens

### Grading System

**Architecture:**
- **Master**: Accepts gRPC requests, queues tasks to RabbitMQ
- **Workers**: Execute code in IOI Isolate, report results
- **Isolation**: Docker containers with privileged mode for Isolate

**Key Concepts:**
- Task isolation via Isolate sandbox
- Resource limits: CPU, memory, time, I/O
- Safe code execution prevents system compromise
- Horizontal scaling via multiple workers

## Development Workflow

### Local Development Setup

```bash
# One-command setup
./setup.sh

# Start services
./compose.sh up

# Hot reload in service (from service directory)
cd main-server && air

# Run tests
go test ./...

# Run migrations
./scripts/migrate.sh
```

### Git Workflow

- Commit message format: `<type>: <description>`
- Types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`
- Example: `feat: add user authentication to config-server`
- Submodules tracked separately (each service is independent repo)

### Service Interaction Patterns

**main-server → other services:**
- gRPC calls to config-server, task-server, go-grader
- All interactions are request-response
- Services are stateless (except workers)

**Async Processing:**
- Submissions queued to RabbitMQ
- Background workers process grading tasks
- Results sent back via submission callbacks

### Database Patterns

**PostgreSQL (main-server):**
- Raw SQL with sqlx (no ORM)
- Migrations managed by Atlas
- Schema in `postgresql/` directory
- Seed data via `cmd/seed/seed.go`

**MongoDB (config-server, task-server):**
- Go MongoDB driver
- Document-based storage
- Indexed queries for performance

### Testing Patterns

- Unit tests: `*_test.go` files with `testing.T`
- Integration tests: test database interactions
- Test containers: Docker for isolated test environments
- Coverage expectations: >80% for critical paths

## Communication Protocols

### gRPC (Service-to-Service)

**Definition Files:**
- Located in `protos/` directories
- Generated code in `genproto/`
- All services define proto files

**Pattern:**
```
main-server -(gRPC)→ config-server
main-server -(gRPC)→ task-server  
main-server -(gRPC)→ go-grader
```

### REST API (Client-facing)

**main-server endpoints:**
- User authentication
- Course & assignment management
- Submission handling
- Grade retrieval

**Versioning:**
- No version prefix (unified API)
- Backward compatibility required

### Message Queue (Async Tasks)

**RabbitMQ Usage:**
- Task distribution: master → workers
- Submission processing: main-server → workers
- Fanout pattern for pub/sub

## Code Review Checklist for Agents

When reviewing code across services:

- [ ] **Error Handling**: Custom errors, proper logging, no panic()
- [ ] **Testing**: Unit tests included, >80% coverage for new code
- [ ] **Dependencies**: No circular imports, clean architecture maintained
- [ ] **Database**: Migrations in Atlas, parameterized queries
- [ ] **Concurrency**: Proper context usage, goroutine safety
- [ ] **API Design**: Consistent request/response format, proper status codes
- [ ] **Documentation**: Comments for exported functions, README updates
- [ ] **Performance**: No N+1 queries, caching where appropriate

## Available Skills

The following specialized skills are available to guide development:

### Skill: go-microservices
Best practices for developing Go microservices in the CSKU Lab platform. Covers project structure, error handling, dependency injection, and testing patterns specific to our Go services.

**Load with**: `skill({ name: "go-microservices" })`

### Skill: grpc-api-design
gRPC service design and implementation patterns. Covers proto definitions, service interfaces, error handling, and versioning strategies for inter-service communication.

**Load with**: `skill({ name: "grpc-api-design" })`

### Skill: docker-compose
Docker Compose orchestration for development and local testing. Covers service configuration, volume management, networking, and health checks.

**Load with**: `skill({ name: "docker-compose" })`

### Skill: database-migrations
Atlas and database migration patterns for PostgreSQL and MongoDB. Covers schema management, backward-compatible migrations, and data synchronization.

**Load with**: `skill({ name: "database-migrations" })`

### Skill: code-sandbox
IOI Isolate configuration and safe code execution patterns. Covers resource limits, security boundaries, and execution monitoring.

**Load with**: `skill({ name: "code-sandbox" })`

### Skill: orchestrator
Multi-agent orchestration patterns. Use this skill to understand how to dispatch tasks to specialized agents for different service types.

**Load with**: `skill({ name: "orchestrator" })`

## Orchestrator Pattern for Agents

### How to Route Work to Specialized Agents

When working on tasks that involve multiple services, agents should use the orchestrator pattern:

1. **Analyze the Request**: Identify which services are involved
   - Just main-server? → Backend developer
   - Multiple gRPC services? → Need coordination
   - Includes frontend? → Frontend + backend work
   - Grading system? → Special isolate/sandbox considerations

2. **Use Task Tool for Specialization**:
   ```
   @backend-developer - work on main-server changes
   @general - run tests across multiple services
   @explore - search for patterns in codebase
   ```

3. **Parallel Work Pattern**:
   - For independent changes: dispatch multiple agents in parallel
   - For dependent changes: coordinate sequentially
   - Always verify integration tests after parallel work

### Example Orchestration Scenarios

**Scenario 1: Add new gRPC endpoint**
1. Design proto changes with Go microservices skill
2. Update task-server implementation
3. Update main-server to call new endpoint
4. Write integration tests
5. Verify with end-to-end test

**Scenario 2: Database schema change**
1. Plan migration with database-migrations skill
2. Create Atlas migration file
3. Update ORM/queries in affected services
4. Run migrations locally
5. Verify backward compatibility

**Scenario 3: Grading feature enhancement**
1. Load code-sandbox skill for safety considerations
2. Update go-grader service
3. Potentially update isolate config
4. Add resource limit tests
5. Verify sandbox isolation

## Important Guidelines

### Security
- Never trust user input directly
- All submissions run in isolated Isolate containers
- Rate limiting on public endpoints
- Authentication required for sensitive operations

### Performance
- Use Redis for caching frequently accessed configs
- Index MongoDB queries appropriately
- Batch gRPC calls when possible
- Monitor RabbitMQ queue depth

### Reliability
- Implement circuit breakers for remote calls
- Graceful degradation if a service is down
- Proper timeout configurations
- Health check endpoints on all services

### Maintainability
- Keep services focused on single responsibility
- Document public APIs with comments
- Write testable code (dependency injection)
- Keep migration files in git history

## File References

- **README.md**: Comprehensive architecture overview
- **docker-compose.dev.yaml**: Local development environment
- **setup.sh**: Automated setup script
- **compose.sh**: Docker Compose wrapper with Doppler secrets
- **.gitmodules**: Submodule configuration (7 services)

## Troubleshooting

### Service won't start
1. Check `./compose.sh logs <service>`
2. Verify environment variables in `.env`
3. Ensure all submodules are initialized: `git submodule update --init --recursive`

### Database migrations fail
1. Check Atlas migration files in service `atlas/` directories
2. Verify database is running: `./compose.sh ps`
3. Check for previous failed migrations

### gRPC calls failing
1. Verify service is running and healthy
2. Check proto files are in sync between services
3. Regenerate code: `make generate` (if available)

### Tests failing
1. Run with verbose: `go test -v ./...`
2. Check test database is clean
3. Review test containers setup

---

**Last Updated**: March 28, 2026  
**For Agents**: Use this document as context for all development decisions. Load relevant skills when needed.
