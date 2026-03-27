---
name: docker-compose
description: Docker Compose orchestration for development and local testing
license: MIT
compatibility: opencode
metadata:
  audience: experienced-developers
  infrastructure: docker
  tools: docker-compose
---

# Docker Compose Orchestration

This skill covers Docker Compose orchestration for development and local testing. Use this when managing services, configuring containers, or troubleshooting development environments.

## Overview

CSKU Lab uses Docker Compose (`docker-compose.dev.yaml`) to orchestrate all services and infrastructure during development.

## Service Configuration

### Main Services (Backend APIs)

**main-server** (Port 8080)
```yaml
main-server:
  build:
    context: ./main-server
    dockerfile: Dockerfile.dev
  ports:
    - "8080:8080"
  environment:
    DATABASE_URL: postgresql://user:pass@db:5432/csku
    REDIS_URL: redis://redis:6379
    RABBITMQ_URL: amqp://guest:guest@rabbitmq:5672/
  depends_on:
    - db
    - redis
    - rabbitmq
  volumes:
    - ./main-server:/app  # Hot reload
```

**config-server** (Port 8081)
```yaml
config-server:
  build:
    context: ./config-server
    dockerfile: Dockerfile.dev
  ports:
    - "8081:8081"
  environment:
    MONGO_URL: mongodb://mongo:27017
    REDIS_URL: redis://redis:6379
  depends_on:
    - mongo
    - redis
```

**task-server** (Port 8082)
```yaml
task-server:
  build:
    context: ./task-server
    dockerfile: Dockerfile.dev
  ports:
    - "8082:8082"
  environment:
    MONGO_URL: mongodb://mongo:27017
  depends_on:
    - mongo
```

**go-grader-master** (Port 8083)
```yaml
go-grader-master:
  build:
    context: ./go-grader
    dockerfile: docker/master/Dockerfile.dev
  ports:
    - "8083:8083"
  environment:
    RABBITMQ_URL: amqp://guest:guest@rabbitmq:5672/
    CONFIG_SERVER_URL: config-server:8081
    TASK_SERVER_URL: task-server:8082
  depends_on:
    - rabbitmq
    - config-server
    - task-server
```

**go-grader-worker**
```yaml
go-grader-worker:
  build:
    context: ./go-grader
    dockerfile: docker/worker/Dockerfile
  privileged: true  # Required for Isolate
  environment:
    RABBITMQ_URL: amqp://guest:guest@rabbitmq:5672/
    MASTER_URL: go-grader-master:8083
  depends_on:
    - rabbitmq
    - go-grader-master
  volumes:
    - /var/lib/isolate:/var/lib/isolate  # Isolate data
```

### Infrastructure Services

**PostgreSQL (main-server database)**
```yaml
db:
  image: postgres:15-alpine
  ports:
    - "5432:5432"
  environment:
    POSTGRES_USER: csku
    POSTGRES_PASSWORD: dev_password
    POSTGRES_DB: csku_lab
  volumes:
    - postgres_data:/var/lib/postgresql/data
  healthcheck:
    test: ["CMD-SHELL", "pg_isready -U csku"]
    interval: 10s
    timeout: 5s
    retries: 5
```

**MongoDB (config-server, task-server)**
```yaml
mongo:
  image: mongo:7.0
  ports:
    - "27017:27017"
  environment:
    MONGO_INITDB_ROOT_USERNAME: root
    MONGO_INITDB_ROOT_PASSWORD: dev_password
  volumes:
    - mongo_data:/data/db
  healthcheck:
    test: echo 'db.runCommand("ping").ok' | mongosh localhost:27017
    interval: 10s
    timeout: 5s
    retries: 5
```

**RabbitMQ (message queue)**
```yaml
rabbitmq:
  image: rabbitmq:3.12-management-alpine
  ports:
    - "5672:5672"    # AMQP port
    - "15672:15672"  # Management UI
  environment:
    RABBITMQ_DEFAULT_USER: guest
    RABBITMQ_DEFAULT_PASS: guest
  volumes:
    - rabbitmq_data:/var/lib/rabbitmq
  healthcheck:
    test: rabbitmq-diagnostics -q ping
    interval: 10s
    timeout: 5s
    retries: 5
```

**Redis (caching, pub/sub)**
```yaml
redis:
  image: redis:7-alpine
  ports:
    - "6379:6379"
  volumes:
    - redis_data:/data
  healthcheck:
    test: ["CMD", "redis-cli", "ping"]
    interval: 10s
    timeout: 5s
    retries: 5
```

**MinIO (S3-compatible storage)**
```yaml
minio:
  image: minio/minio:latest
  ports:
    - "9000:9000"    # API
    - "9001:9001"    # Console
  environment:
    MINIO_ROOT_USER: minioadmin
    MINIO_ROOT_PASSWORD: minioadmin
  volumes:
    - minio_data:/data
  command: server /data --console-address ":9001"
  healthcheck:
    test: curl -f http://localhost:9000/minio/health/live || exit 1
    interval: 30s
    timeout: 20s
    retries: 3
```

## Common Commands

### Starting Services

```bash
# Start all services in background
./compose.sh up -d

# Start specific service
./compose.sh up -d main-server

# Start and view logs
./compose.sh up main-server

# Start with fresh volumes
./compose.sh down -v && ./compose.sh up -d
```

### Viewing Logs

```bash
# All services
./compose.sh logs -f

# Specific service
./compose.sh logs -f main-server

# Last 100 lines
./compose.sh logs --tail=100 main-server

# Follow specific pattern
./compose.sh logs -f main-server | grep ERROR
```

### Stopping Services

```bash
# Stop all running services
./compose.sh down

# Stop and remove volumes
./compose.sh down -v

# Stop specific service
./compose.sh stop main-server

# Restart service
./compose.sh restart main-server
```

### Service Health

```bash
# Check service status
./compose.sh ps

# Check service health
./compose.sh ps main-server
docker inspect super-app-main-server-1
```

## Networking

### Service Discovery

Services can reach each other by hostname (service name):
- `http://main-server:8080`
- `http://config-server:8081`
- `mongodb://mongo:27017`
- `amqp://rabbitmq:5672`

### Port Mapping

Services expose ports to host:
- `localhost:8080` → main-server (inside container port 8080)
- `localhost:5432` → PostgreSQL (inside container port 5432)
- `localhost:27017` → MongoDB (inside container port 27017)

### Custom Networks

Services are on the default `bridge` network automatically. Create custom networks for isolation if needed:

```yaml
networks:
  backend:
  frontend:

services:
  main-server:
    networks:
      - backend
```

## Volumes

### Data Persistence

**Named Volumes:**
```yaml
volumes:
  postgres_data:
  mongo_data:
  redis_data:
```

Services using named volumes preserve data between restarts:
```bash
./compose.sh down  # Keeps data
docker volume ls   # See volumes
```

**Local Bind Mounts:**
```yaml
volumes:
  - ./main-server:/app  # Live code updates
  - ./data:/var/data    # Shared data
```

### Cleanup

```bash
# Remove unused volumes
docker volume prune

# Remove specific volume
docker volume rm super-app_postgres_data

# Remove everything
./compose.sh down -v
```

## Dockerfile Patterns

### Development Image (Dockerfile.dev)

```dockerfile
FROM golang:1.25-alpine

WORKDIR /app
RUN go install github.com/cosmtrek/air@latest

COPY go.mod go.sum ./
RUN go mod download

COPY . .

EXPOSE 8080
CMD ["air"]
```

**Advantages:**
- Hot reload with Air
- Fast iteration
- Full debug symbols

### Production Image (Dockerfile)

```dockerfile
# Build stage
FROM golang:1.25-alpine as builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -o app ./cmd/app

# Runtime stage
FROM alpine:latest
RUN apk --no-cache add ca-certificates
COPY --from=builder /app/app /app
EXPOSE 8080
CMD ["/app"]
```

**Advantages:**
- Smaller image size
- No build tools in final image
- Better security

## Troubleshooting

### Service Won't Start

```bash
# Check logs for errors
./compose.sh logs main-server

# Common issues:
# 1. Port already in use
lsof -i :8080
kill -9 <PID>

# 2. Volume permission issues
sudo chown -R $(id -u):$(id -g) ./data

# 3. Out of disk space
docker system df
docker system prune -a
```

### Database Connection Issues

```bash
# Test PostgreSQL connection
psql -h localhost -U csku -d csku_lab

# Test MongoDB connection
mongosh --host localhost --username root --password dev_password

# Test Redis connection
redis-cli -h localhost

# Check service is running
./compose.sh ps db
./compose.sh logs db
```

### Network Issues

```bash
# Check service hostname resolution
docker exec super-app-main-server-1 ping config-server

# Check port accessibility
docker exec super-app-main-server-1 curl http://config-server:8081/health

# Inspect network
docker network inspect super-app_default
```

### Resource Issues

```bash
# Check container resource usage
docker stats

# Limit container resources
# In compose file:
resources:
  limits:
    cpus: '0.5'
    memory: 512M
  reservations:
    cpus: '0.25'
    memory: 256M

# Check Docker disk space
docker system df

# Clean up
docker system prune -a --volumes
```

## Development Best Practices

### Hot Reload Setup

Services should mount code directories for live updates:

```yaml
volumes:
  - ./main-server:/app
```

Requires development-focused Dockerfile with Air or similar tool watching for changes.

### Environment Configuration

Use `.env` file for secrets (NOT committed):

```bash
DATABASE_PASSWORD=secure_password
REDIS_PASSWORD=secret
```

Override in docker-compose:
```yaml
environment:
  DATABASE_PASSWORD: ${DATABASE_PASSWORD}
```

### Health Checks

Always add health checks to critical services:

```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
  interval: 10s
  timeout: 5s
  retries: 5
```

### Dependency Management

Use `depends_on` with health checks:

```yaml
depends_on:
  db:
    condition: service_healthy
  redis:
    condition: service_healthy
```

---

**When to use this skill:** Use this when managing Docker Compose, configuring services, troubleshooting development environments, or understanding container orchestration.
