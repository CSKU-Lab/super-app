# Production Deployment Guide

This guide explains how to deploy the Super App using Docker Compose in production.

## Overview

The production deployment includes:

### Application Services
- **main-server** (port 8080) - Main API server
- **config-server** (port 8081) - Configuration gRPC service
- **task-server** (port 50051) - Task management gRPC service
- **go-grader-master** (port 50052) - Grader master node
- **go-grader-worker** - Grader worker nodes (privileged mode)

### Infrastructure Services
- **PostgreSQL** (db) - Primary database
- **MongoDB** (mongo) - NoSQL database for config and tasks
- **Redis** (cache) - Caching layer
- **RabbitMQ** (rabbitmq) - Message queue
- **MinIO** (s3) - Object storage

## Prerequisites

- Docker 24.0+
- Docker Compose 2.20+
- 8GB+ RAM recommended
- Linux host (required for go-grader-worker privileged mode)

## Quick Start

### 1. Create Secrets Directory

```bash
mkdir -p secrets
```

### 2. Generate Secret Files

Create all 15 required secret files:

```bash
# OAuth & JWT Secrets
echo "your_google_client_id_here" > secrets/google_client_id.txt
echo "your_google_client_secret_here" > secrets/google_client_secret.txt
echo "your_jwt_secret_min_32_chars" > secrets/jwt_secret.txt
echo "your_jwt_refresh_secret_min_32_chars" > secrets/jwt_refresh_secret.txt

# S3/MinIO Secrets
echo "minio_access_key" > secrets/s3_access_key_id.txt
echo "minio_secret_key_min_8_chars" > secrets/s3_secret_access_key.txt

# Database Secrets
echo "secure_postgres_password" > secrets/postgres_password.txt
echo "root" > secrets/mongo_root_username.txt
echo "secure_mongo_root_password" > secrets/mongo_root_password.txt
echo "config_password" > secrets/mongo_config_password.txt
echo "task_password" > secrets/mongo_task_password.txt

# Message Queue & Cache Secrets
echo "secure_rabbitmq_password" > secrets/rabbitmq_password.txt
echo "secure_redis_password" > secrets/redis_password.txt

# MinIO Console Access
echo "minio_admin_user" > secrets/minio_root_user.txt
echo "secure_minio_admin_password" > secrets/minio_root_password.txt
```

### 3. Create Environment File

Create a `.env` file in the root directory:

```bash
# Main Server
MAIN_SERVER_API_URL=https://your-domain.com
MAIN_SERVER_PORT=8080
MAIN_SERVER_COOKIE_DOMAIN=.your-domain.com
MAIN_SERVER_FRONTEND_URL=https://your-domain.com
MAIN_SERVER_DEV_MODE=false
MAIN_SERVER_S3_USE_SSL=false
MAIN_SERVER_S3_BUCKET=uploads
MAIN_SERVER_S3_FRONTEND_URL=https://your-domain.com/files

# PostgreSQL
POSTGRES_USER=cs_pg_user
POSTGRES_DB=main-server

# MongoDB
MONGO_CONFIG_DB=config_server
MONGO_TASK_DB=task_server

# Go Grader
GO_GRADER_RUN_QUEUE_AMOUNT=1
GO_GRADER_GRADE_QUEUE_AMOUNT=10

# Redis
REDIS_PASSWORD=secure_redis_password
```

### 4. Start Services

```bash
docker compose up -d
```

### 5. Verify Deployment

```bash
# Check all services are running
docker compose ps

# View logs
docker compose logs -f main-server

# Check service health
docker compose ps --format "table {{.Name}}\t{{.Status}}"
```

## Service Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    External Traffic                         │
│                         (port 8080)                         │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      main-server                            │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Internal Network: super-app-network                 │   │
│  │                                                       │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌────────────┐  │   │
│  │  │ config-server│  │ task-server  │  │go-grader-  │  │   │
│  │  │   (gRPC)     │  │   (gRPC)     │  │   master   │  │   │
│  │  └──────────────┘  └──────────────┘  └────────────┘  │   │
│  │         │                  │                │         │   │
│  │         └──────────────────┼────────────────┘         │   │
│  │                            │                          │   │
│  │                    ┌───────┴───────┐                  │   │
│  │                    │go-grader-worker│                  │   │
│  │                    │  (privileged)  │                  │   │
│  │                    └────────────────┘                  │   │
│  └──────────────────────────────────────────────────────┘   │
│                              │                               │
│         ┌────────────────────┼────────────────────┐         │
│         │                    │                    │         │
│         ▼                    ▼                    ▼         │
│  ┌─────────────┐      ┌─────────────┐      ┌──────────┐   │
│  │  PostgreSQL │      │  MongoDB    │      │  Redis   │   │
│  │    (db)     │      │   (mongo)   │      │ (cache)  │   │
│  └─────────────┘      └─────────────┘      └──────────┘   │
│                                                             │
│  ┌─────────────┐      ┌─────────────┐                      │
│  │  RabbitMQ   │      │    MinIO    │                      │
│  │             │      │    (s3)     │                      │
│  └─────────────┘      └─────────────┘                      │
└─────────────────────────────────────────────────────────────┘
```

## Configuration Reference

### Main Server Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `MAIN_SERVER_API_URL` | Public API URL | - |
| `MAIN_SERVER_PORT` | Server port | `8080` |
| `MAIN_SERVER_COOKIE_DOMAIN` | Cookie domain | - |
| `MAIN_SERVER_FRONTEND_URL` | Frontend URL | - |
| `MAIN_SERVER_DEV_MODE` | Development mode | `false` |
| `MAIN_SERVER_S3_USE_SSL` | S3 SSL enabled | `false` |
| `MAIN_SERVER_S3_BUCKET` | S3 bucket name | - |
| `MAIN_SERVER_S3_FRONTEND_URL` | S3 public URL | - |

### Database Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `POSTGRES_USER` | PostgreSQL username | `cs_pg_user` |
| `POSTGRES_DB` | PostgreSQL database | `main-server` |
| `MONGO_CONFIG_DB` | MongoDB config database | `config_server` |
| `MONGO_TASK_DB` | MongoDB task database | `task_server` |

### Go Grader Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `GO_GRADER_RUN_QUEUE_AMOUNT` | Run queue workers | `1` |
| `GO_GRADER_GRADE_QUEUE_AMOUNT` | Grade queue workers | `10` |

## Operations

### Viewing Logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f main-server

# Last 100 lines
docker compose logs --tail=100 main-server
```

### Restarting Services

```bash
# Restart single service
docker compose restart main-server

# Restart all services
docker compose restart
```

### Stopping Services

```bash
# Stop without removing volumes
docker compose down

# Stop and remove volumes (WARNING: deletes all data)
docker compose down -v
```

### Updating Services

```bash
# Pull latest images
docker compose pull

# Recreate containers with new images
docker compose up -d --force-recreate
```

### Health Checks

```bash
# Check service health status
docker compose ps

# Test main-server health
curl http://localhost:8080/health

# Test gRPC services (requires grpc_health_probe)
grpc_health_probe -addr=localhost:8081  # config-server
grpc_health_probe -addr=localhost:50051 # task-server
grpc_health_probe -addr=localhost:50052 # go-grader-master
```

## Data Persistence

All data is persisted in Docker volumes:

| Volume | Service | Data Location |
|--------|---------|---------------|
| `postgres_data` | PostgreSQL | `/var/lib/postgresql/data` |
| `mongo_data` | MongoDB | `/data/db` |
| `rabbitmq_data` | RabbitMQ | `/var/lib/rabbitmq` |
| `minio_data` | MinIO | `/data` |
| `cache` | Redis | `/data` |

### Backup Database

```bash
# PostgreSQL backup
docker compose exec db pg_dump -U cs_pg_user main-server > backup.sql

# MongoDB backup
docker compose exec mongo mongodump --out=/data/backup
```

### Restore Database

```bash
# PostgreSQL restore
docker compose exec -T db psql -U cs_pg_user main-server < backup.sql

# MongoDB restore
docker compose exec mongo mongorestore /data/backup
```

## Security Considerations

### Secret File Permissions

Restrict access to secret files:

```bash
chmod 600 secrets/*.txt
chown root:root secrets/*.txt
```

### Network Security

- Only port 8080 is exposed to the host
- All inter-service communication is on an internal network
- Infrastructure ports (5432, 27017, 6379, 5672, 9000) are NOT exposed

### Container Security

- Services run as non-root users where possible
- `go-grader-worker` requires privileged mode for isolate sandbox
- Read-only root filesystem can be enabled for additional security

## Troubleshooting

### Service Won't Start

```bash
# Check logs
docker compose logs <service-name>

# Check if secret files exist
ls -la secrets/

# Validate secret file content (no trailing newlines)
cat -A secrets/jwt_secret.txt
```

### Database Connection Issues

```bash
# Test PostgreSQL connection
docker compose exec db pg_isready -U cs_pg_user

# Test MongoDB connection
docker compose exec mongo mongosh --eval "db.runCommand({ping:1})"

# Check health status
docker compose ps
```

### MinIO Access

MinIO console is available internally at `s3:9001`. To access temporarily:

```bash
# Port forward MinIO console
docker compose up -d s3
docker compose ps s3  # Note the container ID
docker run --rm -it --network container:<container-id> alpine wget -qO- http://localhost:9001
```

### RabbitMQ Management

RabbitMQ management UI is on internal network only. Access via:

```bash
# Port forward temporarily
docker compose up -d rabbitmq
docker compose exec rabbitmq rabbitmq-diagnostics -q status
```

## Environment-Specific Configurations

### Development

Use `docker-compose.dev.yaml` instead:
- Hot-reload enabled
- All ports exposed
- Volume mounts for source code
- No secrets (uses env vars)

### Staging

Copy production config with modified values:
```bash
cp .env .env.staging
# Edit .env.staging with staging-specific values
docker compose --env-file .env.staging up -d
```

### Production

- Use this `docker-compose.yaml`
- Ensure all secrets are properly configured
- Consider adding a reverse proxy (nginx/traefik)
- Set up monitoring and alerting
- Configure log aggregation

## Monitoring & Observability

### Resource Usage

```bash
# View resource usage
docker compose top

# View stats
docker stats $(docker compose ps -q)
```

### Log Aggregation

For production, consider:
- ELK Stack (Elasticsearch, Logstash, Kibana)
- Loki + Grafana
- Cloud-based solutions (Datadog, New Relic)

### Metrics

Services expose metrics that can be scraped by Prometheus:
- PostgreSQL: Use pg_exporter sidecar
- MongoDB: Use mongodb_exporter sidecar
- Redis: Built-in INFO command
- RabbitMQ: Management plugin (port 15672)

## Scaling

### Horizontal Scaling

```bash
# Scale go-grader-worker
docker compose up -d --scale go-grader-worker=3

# Scale main-server (requires load balancer)
docker compose up -d --scale main-server=3
```

### Vertical Scaling

Adjust resource limits in `docker-compose.yaml`:

```yaml
services:
  main-server:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
        reservations:
          cpus: '1'
          memory: 1G
```

## Support

For issues or questions:
1. Check service logs: `docker compose logs <service>`
2. Verify health status: `docker compose ps`
3. Review this guide's troubleshooting section
4. Check individual service documentation
