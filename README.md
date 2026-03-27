# Super App - CSKU Lab Platform

A microservices-based learning management and code grading platform. Setup the entire project in just 1 command:

```sh
./setup.sh
```

## Project Overview

**Type:** Microservices Architecture (5 Go services + infrastructure)  
**Language:** Go  
**Infrastructure:** Docker Compose with PostgreSQL, MongoDB, RabbitMQ, Redis, MinIO  
**Architecture Pattern:** Master-Worker (for grading), Clean Architecture (for API server)

---

## Directory Structure

```
super-app/
├── main-server/              # REST API server (core application)
│   ├── cmd/app/              # HTTP server & worker entrypoints
│   ├── domain/               # Business logic & services
│   ├── internal/adapters/    # HTTP handlers, database, middlewares
│   ├── postgresql/           # Database schema & migrations
│   └── protos/               # gRPC protobuf definitions
│
├── task-server/              # Task/assignment management service
│   ├── cmd/                  # Service entrypoint
│   ├── internal/             # Service logic
│   ├── mongodb/              # Database integration
│   └── protos/               # gRPC definitions
│
├── config-server/            # Configuration management service
│   ├── cmd/                  # Service entrypoint
│   ├── domain/               # Business entities
│   ├── internal/             # Service logic
│   └── protos/               # gRPC definitions
│
├── go-grader/                # Code grading orchestration (master-worker)
│   ├── cmd/                  # Master & worker entrypoints
│   ├── internal/             # Service logic
│   ├── docker/               # Master & worker Dockerfiles
│   ├── isolate-config/       # Isolate sandbox config
│   └── protos/               # gRPC definitions
│
├── isolate-docker/           # Sandboxed code execution environment
│   ├── base/                 # Base Docker image
│   └── with-compilers/       # Image with language compilers
│
├── web/                      # Frontend web application
│   ├── src/                  # TypeScript/React components
│   ├── public/               # Static assets
│   ├── package.json          # Node.js dependencies
│   └── next.config.ts        # Next.js configuration
│
├── api-docs/                 # API documentation
│   └── CSKU-Lab/             # Postman/API collections
│
├── scripts/                  # Utility shell scripts
├── data/                     # Persistent storage (mounted volumes)
├── docker-compose.dev.yaml   # Development environment orchestration
├── compose.sh                # Docker Compose wrapper with Doppler secrets
├── setup.sh                  # One-command setup script
└── .gitmodules               # Git submodule configuration
```

---

## Microservices Overview

### 1. **main-server** - Core REST API
**Port:** 8080 | **Database:** PostgreSQL | **Framework:** GoFiber v3

Primary REST API server handling user requests, authentication, course management, assignments, submissions, and grading orchestration.

**Key Responsibilities:**
- User authentication (JWT + Google OAuth2)
- Course, lab, and assignment management
- Student submission handling
- File storage integration (MinIO/S3)
- Grading task orchestration via RabbitMQ

**Tech Stack:**
- GoFiber (HTTP framework)
- PostgreSQL (via sqlx, raw SQL)
- RabbitMQ (message queue for submissions)
- Redis (pub/sub, caching)
- gRPC clients (to config, task, and grader services)
- Atlas (database migrations)

**Key Files:**
- `cmd/app/main.go` - HTTP server entrypoint
- `cmd/app/submission_worker.go` - Background worker for grading tasks
- `cmd/seed/seed.go` - Database seeding utility
- `internal/adapters/http/` - REST endpoints

---

### 2. **config-server** - Configuration Management
**Port:** 8081 | **Database:** MongoDB | **Protocol:** gRPC

Centralized configuration service providing dynamic configuration to other services.

**Key Responsibilities:**
- Store and manage grader configurations
- Provide configuration data to other services
- Configuration versioning and updates
- Cache configuration with Redis

**Tech Stack:**
- Go + gRPC
- MongoDB (configuration storage)
- Redis (caching)

**Communicates With:**
- main-server (gRPC client)
- go-grader (configuration queries)

---

### 3. **task-server** - Task/Assignment Management
**Port:** 8082 | **Database:** MongoDB | **Protocol:** gRPC

Manages task and assignment definitions that the grader uses for evaluation.

**Key Responsibilities:**
- Store task/assignment specifications
- Provide task metadata to grader
- Task versioning and management
- Test case management

**Tech Stack:**
- Go + gRPC
- MongoDB (task storage)

**Communicates With:**
- main-server (gRPC client)
- go-grader (task data queries)

---

### 4. **go-grader** - Code Grading Orchestration
**Port:** 8083 (Master) | **Database:** None | **Protocol:** gRPC + RabbitMQ

Distributed code grading system using master-worker architecture for safe, isolated code execution.

**Components:**
- **Master (Port 8083):** Accepts grading tasks from main-server via gRPC, queues them to workers via RabbitMQ
- **Workers:** Execute code in isolated environments using IOI Isolate, report results back to master

**Key Responsibilities:**
- Accept grading requests via gRPC
- Queue tasks to workers via RabbitMQ
- Orchestrate isolated code execution
- Collect and return grading results

**Tech Stack:**
- Go + gRPC (external API)
- RabbitMQ (task distribution between master & workers)
- IOI Isolate (sandboxed code execution)
- Docker (containerized workers)

**Communicates With:**
- main-server (gRPC for grading requests)
- task-server (task definition queries)
- config-server (grader configuration)
- RabbitMQ (task queue distribution)

**Special Features:**
- Workers run with `privileged: true` to manage Isolate containers
- Supports multiple concurrent workers for scalability
- Isolated execution prevents malicious code from affecting system

---

### 5. **isolate-docker** - Sandboxing Environment
**Container Image** | **No Port** | **Base:** IOI Isolate

Docker image wrapping IOI Isolate for safe, sandboxed code execution. Prevents malicious code from affecting the system.

**Components:**
- **base/** - Minimal base image with Isolate
- **with-compilers/** - Extended image with programming language compilers (C++, Python, Java, etc.)

**Purpose:**
- Provides isolated execution environment for student code
- Used by go-grader workers for safe evaluation
- Resource-limited execution (CPU, memory, time limits)

---

### 6. **web** - Frontend Application
**Port:** 3000 (development) | **Framework:** Next.js | **Language:** TypeScript/React

Modern web application providing the user interface for the CSKU Lab platform.

**Key Responsibilities:**
- User authentication interface
- Course and assignment browsing
- Code editor for submissions
- Real-time submission feedback
- Course management (instructor features)
- Student progress tracking

**Tech Stack:**
- Next.js 14+ (React framework)
- TypeScript (type safety)
- TailwindCSS (styling)
- Node.js runtime

**Key Directories:**
- `src/` - React components and pages
- `public/` - Static assets (images, fonts)
- `scripts/` - Build and utility scripts

**Configuration Files:**
- `next.config.ts` - Next.js configuration
- `tsconfig.json` - TypeScript configuration
- `package.json` - Node.js dependencies
- `.env.example` - Environment variable template

**API Integration:**
- Connects to main-server REST API (Port 8080)
- Real-time updates via WebSocket/Server-Sent Events

---

### 7. **api-docs** - API Documentation
**Type:** Postman Collections | **Format:** YAML/JSON

Comprehensive API documentation for the entire platform, organized as Postman collections.

**Contents:**
- CSKU-Lab/ - Postman workspace with API endpoints
- Collections for each service:
  - Main Server endpoints (authentication, courses, assignments, submissions)
  - Task Server endpoints
  - Config Server endpoints
  - Grader endpoints
- Environment variables and pre-request scripts
- Response examples and test cases

**Purpose:**
- Developer reference for API endpoints
- Request/response documentation
- Quick testing of API endpoints
- Integration examples

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                      User Browser                               │
│                    (Web Application)                             │
│                        (Next.js)                                │
└────────────────────────────┬────────────────────────────────────┘
                             │
                         HTTP/REST
                             │
                    ┌────────▼────────┐
                    │  main-server    │
                    │  Port 8080       │
                    │  (GoFiber)       │
                    │  (PostgreSQL)    │
                    └────────┬────────┘
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
    gRPC client         gRPC client          gRPC client
        │                    │                    │
    ┌───▼──────┐       ┌────▼─────┐        ┌────▼─────────┐
    │  config- │       │   task-  │        │  go-grader   │
    │ server   │       │  server   │        │  master      │
    │ Port 8081│       │ Port 8082 │        │ Port 8083     │
    │(MongoDB) │       │(MongoDB)  │        │   (gRPC)      │
    └───┬──────┘       └────┬─────┘        └────┬─────────┘
        │                    │                    │
        │ Config queries     │ Task queries       │
        │                    │              RabbitMQ queue
        │                    │            distribution
        │                    │              │
        │                    │    ┌─────────┴──────────┐
        │                    │    │                    │
        │                    │    │                    │
        │                    └────┤►  Worker 1         │
        │                         │  (Isolate)        │
        │                         │                    │
        │                         │►  Worker N        │
        │                         │  (Isolate)        │
        │                         │                    │
        │                         │ Safe code          │
        │                         │ execution          │
        │                         └──────────┬─────────┘
        │                                    │
        │                              Results
        │                              back to
        │                              main-server
        │
    ┌───┴──────┬────────┬──────────────────────────────────┐
    │           │        │                                  │
    ▼           ▼        ▼                                  ▼
 PostgreSQL  MongoDB  RabbitMQ  Redis      MinIO (S3)
 (Users,     (Tasks,  (Task     (Cache,    (File
  Courses,    Config) Queue)    Pub/Sub)    Storage)
  Grades)

Additional Resources:
├── API Docs (Postman collections)
├── Frontend Web Application (Next.js)
└── Setup & Orchestration Scripts
```

---

## Service Communication Matrix

| From | To | Protocol | Purpose |
|------|-----|----------|---------|
| main-server | config-server | gRPC | Fetch grader configurations |
| main-server | task-server | gRPC | Get task definitions |
| main-server | go-grader | gRPC | Submit grading requests |
| go-grader-master | task-server | gRPC | Query task specifications |
| go-grader-master | config-server | gRPC | Get grading configurations |
| go-grader-master | Workers | RabbitMQ | Distribute grading tasks |
| Workers | Isolate | CLI/Container | Execute isolated code |

---

## Infrastructure Stack

| Component | Purpose | Type |
|-----------|---------|------|
| **PostgreSQL** | User data, courses, assignments, grades | Database |
| **MongoDB** | Task definitions, configurations, metadata | Database |
| **RabbitMQ** | Task queue for grading distribution | Message Queue |
| **Redis** | Caching, pub/sub messaging | Cache/Broker |
| **MinIO** | File storage (S3-compatible) | Object Storage |
| **Isolate** | Sandboxed code execution | Sandbox |
| **Docker Compose** | Service orchestration | Container Orchestration |

---

## Quick Reference Table

| Service | Type | Language | Database | Port | Primary Purpose |
|---------|------|----------|----------|------|-----------------|
| **main-server** | REST API | Go | PostgreSQL | 8080 | Core platform API, submissions, authentication |
| **config-server** | gRPC Service | Go | MongoDB | 8081 | Centralized configuration management |
| **task-server** | gRPC Service | Go | MongoDB | 8082 | Task and assignment metadata |
| **go-grader** | Master-Worker | Go | - | 8083 | Distributed code grading orchestration |
| **web** | Frontend App | TypeScript/React | - | 3000 | User interface, code editor, course management |
| **isolate-docker** | Container Image | - | - | - | Sandboxed code execution environment |
| **api-docs** | Documentation | - | - | - | Postman API collections and documentation |

---

## Development Setup

### Prerequisites
- Docker & Docker Compose
- Go 1.25+ (for local development)
- Doppler CLI (for secrets management)

### Quick Start

**One-command setup:**
```sh
./setup.sh
```

This script:
1. Fetches secrets from Doppler
2. Starts all Docker Compose services (databases, queues, storage)
3. Waits for health checks
4. Runs database migrations
5. Seeds databases with initial data
6. Generates API documentation

### Common Commands

**Start services:**
```sh
./compose.sh up
```

**Stop services:**
```sh
./compose.sh down
```

**View service logs:**
```sh
./compose.sh logs -f [service_name]
```

**Hot-reload development (in service directory):**
```sh
cd main-server
air  # Auto-reloads on file changes
```

**Run tests:**
```sh
cd [service_directory]
go test ./...
```

**Database migrations:**
```sh
./scripts/migrate.sh
```

---

## Git Submodules

This is a monorepo where each service is maintained as a separate Git repository:

```
main-server/      → github.com/CSKU-Lab/main-server
config-server/    → github.com/CSKU-Lab/config-server
task-server/      → github.com/CSKU-Lab/task-server
go-grader/        → github.com/CSKU-Lab/go-grader
isolate-docker/   → github.com/CSKU-Lab/isolate-docker
web/              → github.com/CSKU-Lab/web
api-docs/         → github.com/CSKU-Lab/api-docs
```

To clone with all submodules:
```sh
git clone --recurse-submodules <repo-url>
```

To update submodules:
```sh
git submodule update --remote
```

---

## Key Concepts for AI Agents

### Service Boundaries
- **main-server:** All user-facing API endpoints
- **config-server:** Configuration queries only (read-heavy)
- **task-server:** Task definition queries only (read-heavy)
- **go-grader:** Grading orchestration and code execution isolation

### Data Flow
1. User submits code → main-server (REST)
2. main-server → RabbitMQ (queue submission)
3. go-grader-master dequeues from RabbitMQ
4. Master distributes to available workers via RabbitMQ
5. Worker executes code in Isolate sandbox
6. Results sent back to master → main-server

### Isolation Strategy
- Student code runs in **IOI Isolate** (OS-level sandboxing)
- Workers run in **Docker containers** with **privileged mode**
- Resource limits enforced (CPU, memory, time, I/O)
- No access to host filesystem or network

### Scalability
- **Horizontal scaling:** Add more go-grader workers (via docker-compose)
- **Load balancing:** RabbitMQ distributes tasks across available workers
- **Caching:** Redis reduces database load for frequently accessed configs

---

## Project Structure at a Glance

- **Stateless APIs:** main-server, config-server, task-server can scale horizontally
- **Stateful workers:** go-grader workers maintain task execution state (necessary for sandboxing)
- **Databases:** PostgreSQL (relational), MongoDB (documents) for different data models
- **Async processing:** RabbitMQ decouples submission handling from grading execution
- **Caching layer:** Redis improves performance for configuration and pub/sub operations

This architecture enables concurrent grading, prevents resource exhaustion, and isolates student code execution safely.

