# Super App - CSKU Lab Platform

A microservices-based learning management and code grading platform. Setup the entire project in just 1 command:

```sh
./setup.sh
```

## Overview

**Type:** Microservices Architecture (5 Go services + infrastructure)  
**Language:** Go (backend) | TypeScript/React (frontend)  
**Infrastructure:** Docker Compose with PostgreSQL, MongoDB, RabbitMQ, Redis, MinIO  
**Pattern:** Master-Worker (grading), Clean Architecture (API)

## Services at a Glance

| Service | Role | Port | Language | Database |
|---------|------|------|----------|----------|
| **main-server** | REST API, auth, submissions | 8080 | Go | PostgreSQL |
| **config-server** | Configuration service | 8081 | Go | MongoDB |
| **task-server** | Task/assignment metadata | 8082 | Go | MongoDB |
| **go-grader** | Code grading orchestration | 8083 | Go | - |
| **web** | Frontend UI | 3000 | TypeScript/React | - |
| **api-docs** | API documentation | - | Postman | - |

## Quick Start

```sh
# Setup everything
./setup.sh

# Start services
./compose.sh up

# Hot reload a service
cd main-server && air

# Run tests
cd [service] && go test ./...
```

## Architecture

```
User Browser (Next.js web app)
    ↓ HTTP/REST
main-server (Port 8080, PostgreSQL)
    ├─ gRPC → config-server (MongoDB)
    ├─ gRPC → task-server (MongoDB)  
    └─ gRPC → go-grader master (Port 8083)
                   ↓ RabbitMQ
                Workers (IOI Isolate)
                   ↓
              Results back

Infrastructure: PostgreSQL, MongoDB, RabbitMQ, Redis, MinIO
```

## Key Points

- **Microservices:** Each service is an independent Git submodule
- **gRPC:** Service-to-service communication (config, task, grader)
- **REST API:** Client-facing endpoints on main-server
- **Async Grading:** RabbitMQ queues distribute grading tasks to workers
- **Code Isolation:** Student code runs safely in IOI Isolate containers
- **Scalable:** Add workers via Docker Compose for horizontal scaling

## Documentation

- **AGENTS.md** - Detailed project architecture and patterns (for AI agents)
- **.opencode/skills/** - Specialized skills for development domains
  - `go-microservices/` - Go development patterns
  - `grpc-api-design/` - gRPC service design
  - `docker-compose/` - Docker orchestration
  - `database-migrations/` - Database management
  - `code-sandbox/` - Isolate configuration
  - `orchestrator/` - Multi-agent coordination
- **api-docs/** - Postman API collections

## Development

**Clone with submodules:**
```sh
git clone --recurse-submodules <repo-url>
```

**Project structure:**
```
super-app/
├── main-server/          # Core REST API
├── config-server/        # Configuration service
├── task-server/          # Task definitions
├── go-grader/            # Grading orchestration
├── isolate-docker/       # Code sandbox
├── web/                  # Frontend (Next.js)
├── api-docs/             # API documentation
├── docker-compose.dev.yaml
├── setup.sh              # One-command setup
└── compose.sh            # Docker Compose wrapper
```

