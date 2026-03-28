# Testing Guide for CSKU Lab

This document describes how to set up and use the isolated test environment for E2E and integration testing.

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Test Environment Setup](#test-environment-setup)
- [Running Tests](#running-tests)
- [Port Reference](#port-reference)
- [Troubleshooting](#troubleshooting)
- [CI/CD Integration](#cicd-integration)

## Overview

The test environment is completely isolated from the development environment. This means:

- **Different ports**: All services run on different ports than dev
- **Separate data**: Test databases don't interfere with dev data
- **Independent lifecycle**: Start/stop test env without affecting dev
- **Parallel execution**: Both environments can run simultaneously

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    DEVELOPMENT ENVIRONMENT                  │
├─────────────────────────────────────────────────────────────┤
│  PostgreSQL:5432  MongoDB:27017  Redis:6379  RabbitMQ:5672  │
│  MinIO:9000                                                 │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ (completely isolated)
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      TEST ENVIRONMENT                       │
├─────────────────────────────────────────────────────────────┤
│  PostgreSQL:5433  MongoDB:27018  Redis:6380  RabbitMQ:5673  │
│  MinIO:9010                                                 │
└─────────────────────────────────────────────────────────────┘
```

## Quick Start

### 1. Start Test Environment

```bash
./scripts/test-env-setup.sh start
```

This starts all test infrastructure services and waits for them to be healthy.

### 2. Run Your Tests

```bash
# Example: Run main-server tests against test database
cd main-server
export $(cat ../.env.test | xargs)
go test ./...
```

### 3. Stop Test Environment

```bash
./scripts/test-env-setup.sh stop
```

## Test Environment Setup

### Prerequisites

- Docker installed and running
- Docker Compose installed
- Ports 5433, 27018, 6380, 5673, 9010, 9011, 15673 available

### Available Commands

```bash
# Start the test environment
./scripts/test-env-setup.sh start

# Stop the test environment
./scripts/test-env-setup.sh stop

# Stop and remove all test data (volumes)
./scripts/test-env-setup.sh clean

# Reset everything (stop, clean volumes, start fresh)
./scripts/test-env-setup.sh reset

# Check health of all services
./scripts/test-env-setup.sh health

# Show status of all services
./scripts/test-env-setup.sh status

# Show logs for all services
./scripts/test-env-setup.sh logs

# Show logs for specific service
./scripts/test-env-setup.sh logs test-db
```

### Service Health Checks

The setup script automatically waits for all services to be healthy before returning. Health checks verify:

- **PostgreSQL**: Can accept connections and respond to queries
- **MongoDB**: Responds to ping command
- **Redis**: Responds to PING command
- **RabbitMQ**: Responds to diagnostics ping
- **MinIO**: Responds to readiness check

## Running Tests

### Environment Variables

Test environment variables are defined in:

- `.env.test` (root level - all services)
- `main-server/.env.test` (main-server specific)

Load them before running tests:

```bash
# Load all test environment variables
export $(cat .env.test | grep -v '^#' | xargs)

# Or use a specific service env file
export $(cat main-server/.env.test | grep -v '^#' | xargs)
```

### Integration Tests

```bash
# Start test environment
./scripts/test-env-setup.sh start

# Run tests with test environment
cd main-server
export $(cat .env.test | xargs)
go test ./... -v

# Stop when done
./scripts/test-env-setup.sh stop
```

### E2E Tests

For E2E tests that need the full stack:

```bash
# 1. Start test infrastructure
./scripts/test-env-setup.sh start

# 2. Start your services pointing to test infrastructure
# (in separate terminals or use docker-compose.test.yaml with your services)

# 3. Run E2E tests
npm run test:e2e  # or your E2E test command

# 4. Clean up
./scripts/test-env-setup.sh stop
```

### Database Seeding for Tests

```bash
# Connect to test PostgreSQL
psql -h localhost -p 5433 -U test_user -d test_main_server

# Connect to test MongoDB
mongosh mongodb://test_root:test_root_password@localhost:27018/admin

# Clean all test databases
./scripts/test-env-setup.sh clean-db
```

## Port Reference

### Test Environment Ports

| Service | Test Port | Dev Port | Difference |
|---------|-----------|----------|------------|
| PostgreSQL | 5433 | 5432 | +1 |
| MongoDB | 27018 | 27017 | +1 |
| Redis | 6380 | 6379 | +1 |
| RabbitMQ AMQP | 5673 | 5672 | +1 |
| RabbitMQ Management | 15673 | 15672 | +1 |
| MinIO API | 9010 | 9000 | +10 |
| MinIO Console | 9011 | 9001 | +10 |

### Test Credentials

| Service | Username | Password | Database/Bucket |
|---------|----------|----------|-----------------|
| PostgreSQL | test_user | test_password | test_main_server |
| MongoDB (root) | test_root | test_root_password | admin |
| MongoDB (config) | test_config_user | test_config_password | test_config_server |
| MongoDB (task) | test_task_user | test_task_password | test_task_server |
| Redis | - | test_password | - |
| RabbitMQ | test_user | test_password | - |
| MinIO | test_minio_user | test_minio_password | test-bucket |

## Troubleshooting

### Port Conflicts

If you see "port already in use" errors:

```bash
# Check what's using the port
lsof -i :5433

# Kill the process if needed
kill -9 <PID>

# Or use clean to remove everything
./scripts/test-env-setup.sh clean
```

### Services Not Starting

```bash
# Check logs
./scripts/test-env-setup.sh logs

# Check specific service
./scripts/test-env-setup.sh logs test-db

# Check health
./scripts/test-env-setup.sh health

# Full reset
./scripts/test-env-setup.sh reset
```

### Database Connection Issues

```bash
# Test PostgreSQL connection
psql -h localhost -p 5433 -U test_user -d test_main_server -c "SELECT 1"

# Test MongoDB connection
mongosh mongodb://test_root:test_root_password@localhost:27018/admin --eval "db.runCommand({ping: 1})"

# Test Redis connection
redis-cli -h localhost -p 6380 -a test_password ping

# Test RabbitMQ
rabbitmq-diagnostics -q ping
```

### Permission Issues

If you encounter permission errors with volumes:

```bash
# Fix volume permissions (Linux/Mac)
sudo chown -R $(id -u):$(id -g) ./data

# Or remove volumes and start fresh
./scripts/test-env-setup.sh clean
./scripts/test-env-setup.sh start
```

### Slow Startup

If services take too long to become healthy:

1. Check available system resources
2. Increase Docker memory limit (Docker Desktop settings)
3. Check for port conflicts
4. Review logs for errors: `./scripts/test-env-setup.sh logs`

## CI/CD Integration

### GitHub Actions Example

```yaml
name: E2E Tests

on: [push, pull_request]

jobs:
  e2e:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Start Test Environment
        run: |
          ./scripts/test-env-setup.sh start
          ./scripts/test-env-setup.sh health
      
      - name: Run Tests
        run: |
          export $(cat .env.test | grep -v '^#' | xargs)
          cd main-server
          go test ./... -v
      
      - name: Cleanup
        if: always()
        run: ./scripts/test-env-setup.sh stop
```

### GitLab CI Example

```yaml
e2e_tests:
  stage: test
  script:
    - ./scripts/test-env-setup.sh start
    - ./scripts/test-env-setup.sh health
    - export $(cat .env.test | grep -v '^#' | xargs)
    - cd main-server && go test ./... -v
  after_script:
    - ./scripts/test-env-setup.sh stop
```

### Docker-in-Docker Considerations

For CI environments using DinD:

```bash
# Use host network or explicit port mapping
export TEST_HOST=host.docker.internal
# Or for Linux CI:
export TEST_HOST=localhost
```

## Best Practices

1. **Always use test environment for automated tests**: Never run tests against dev databases
2. **Clean up after tests**: Use `./scripts/test-env-setup.sh stop` or `clean`
3. **Load env vars before testing**: `export $(cat .env.test | xargs)`
4. **Use health checks**: Verify services are ready before running tests
5. **Parallel CI jobs**: Each job can have its own isolated test environment
6. **Reset between test suites**: Use `reset` command for clean state

## File Reference

| File | Purpose |
|------|---------|
| `docker-compose.test.yaml` | Test infrastructure services |
| `.env.test` | Root-level test environment variables |
| `main-server/.env.test` | Main-server specific test variables |
| `scripts/test-env-setup.sh` | Test environment management script |
| `TESTING.md` | This documentation |

## Support

For issues or questions:

1. Check service logs: `./scripts/test-env-setup.sh logs`
2. Verify health: `./scripts/test-env-setup.sh health`
3. Reset environment: `./scripts/test-env-setup.sh reset`
4. Review this documentation
