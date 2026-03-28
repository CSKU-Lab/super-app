#!/bin/bash

# Test Environment Setup Script
# Manages the isolated test environment for E2E and integration testing
# This environment runs completely independently from the development environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
COMPOSE_FILE="docker-compose.test.yaml"
ENV_FILE=".env.test"
PROJECT_NAME="super-app-test"

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if docker and docker-compose are available
check_prerequisites() {
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed or not in PATH"
        exit 1
    fi

    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        log_error "Docker Compose is not installed"
        exit 1
    fi

    # Determine docker compose command
    if docker compose version &> /dev/null; then
        DOCKER_COMPOSE="docker compose"
    else
        DOCKER_COMPOSE="docker-compose"
    fi
}

# Wait for a service to be healthy
wait_for_service() {
    local service=$1
    local max_attempts=${2:-30}
    local attempt=1

    log_info "Waiting for $service to be healthy..."

    while [ $attempt -le $max_attempts ]; do
        local status=$(docker inspect --format='{{.State.Health.Status}}' "${PROJECT_NAME}-${service}" 2>/dev/null || echo "unknown")

        if [ "$status" = "healthy" ]; then
            log_success "$service is healthy"
            return 0
        elif [ "$status" = "unhealthy" ]; then
            log_error "$service is unhealthy"
            return 1
        fi

        echo -n "."
        sleep 2
        attempt=$((attempt + 1))
    done

    log_error "$service did not become healthy within $((max_attempts * 2)) seconds"
    return 1
}

# Start the test environment
start_environment() {
    log_info "Starting test environment..."

    # Check if already running
    if $DOCKER_COMPOSE -f $COMPOSE_FILE -p $PROJECT_NAME ps | grep -q "Up"; then
        log_warning "Test environment is already running"
        log_info "Use './scripts/test-env-setup.sh health' to check service status"
        return 0
    fi

    # Start services
    log_info "Starting test infrastructure services..."
    $DOCKER_COMPOSE -f $COMPOSE_FILE -p $PROJECT_NAME up -d

    # Wait for all services to be healthy
    log_info "Waiting for all services to be healthy..."

    local services=("test-db" "test-mongo" "test-redis" "test-rabbitmq" "test-minio")
    local failed=0

    for service in "${services[@]}"; do
        if ! wait_for_service "$service" 30; then
            failed=1
        fi
    done

    if [ $failed -eq 1 ]; then
        log_error "Some services failed to start properly"
        log_info "Check logs with: ./scripts/test-env-setup.sh logs"
        return 1
    fi

    # Wait for MinIO setup to complete
    log_info "Waiting for MinIO bucket setup..."
    sleep 3

    log_success "Test environment is ready!"
    log_info ""
    log_info "Service URLs:"
    log_info "  PostgreSQL: localhost:5433 (test_main_server)"
    log_info "  MongoDB:    localhost:27018 (test_config_server, test_task_server)"
    log_info "  Redis:      localhost:6380"
    log_info "  RabbitMQ:   localhost:5673 (Management: http://localhost:15673)"
    log_info "  MinIO:      localhost:9010 (Console: http://localhost:9011)"
    log_info ""
    log_info "Credentials:"
    log_info "  PostgreSQL: test_user / test_password"
    log_info "  MongoDB:    test_root / test_root_password"
    log_info "  Redis:      test_password"
    log_info "  RabbitMQ:   test_user / test_password"
    log_info "  MinIO:      test_minio_user / test_minio_password"
}

# Stop the test environment
stop_environment() {
    log_info "Stopping test environment..."
    $DOCKER_COMPOSE -f $COMPOSE_FILE -p $PROJECT_NAME down
    log_success "Test environment stopped"
}

# Stop and remove volumes (clean everything)
clean_environment() {
    log_warning "This will stop the test environment and remove all test data!"
    read -p "Are you sure? (y/N): " confirm

    if [[ $confirm =~ ^[Yy]$ ]]; then
        log_info "Stopping test environment and removing volumes..."
        $DOCKER_COMPOSE -f $COMPOSE_FILE -p $PROJECT_NAME down -v
        log_success "Test environment cleaned"
    else
        log_info "Clean cancelled"
    fi
}

# Clean databases but keep environment running
clean_databases() {
    log_warning "This will clean all test databases while keeping the environment running!"
    read -p "Are you sure? (y/N): " confirm

    if [[ $confirm =~ ^[Yy]$ ]]; then
        log_info "Cleaning test databases..."

        # Clean PostgreSQL
        log_info "Cleaning PostgreSQL database..."
        docker exec ${PROJECT_NAME}-test-db psql -U test_user -d test_main_server -c "
            DO \$\$ DECLARE
                r RECORD;
            BEGIN
                FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = 'public') LOOP
                    EXECUTE 'DROP TABLE IF EXISTS ' || quote_ident(r.tablename) || ' CASCADE';
                END LOOP;
            END \$\$;
        " 2>/dev/null || log_warning "Could not clean PostgreSQL (may be empty)"

        # Clean MongoDB config database
        log_info "Cleaning MongoDB config database..."
        docker exec ${PROJECT_NAME}-test-mongo mongosh test_config_server --eval "db.dropDatabase()" --quiet 2>/dev/null || log_warning "Could not clean MongoDB config db"

        # Clean MongoDB task database
        log_info "Cleaning MongoDB task database..."
        docker exec ${PROJECT_NAME}-test-mongo mongosh test_task_server --eval "db.dropDatabase()" --quiet 2>/dev/null || log_warning "Could not clean MongoDB task db"

        # Clean Redis
        log_info "Cleaning Redis..."
        docker exec ${PROJECT_NAME}-test-redis redis-cli -a test_password FLUSHALL 2>/dev/null || log_warning "Could not clean Redis"

        log_success "Test databases cleaned"
    else
        log_info "Clean cancelled"
    fi
}

# Check health of all services
check_health() {
    log_info "Checking test environment health..."

    local services=("test-db" "test-mongo" "test-redis" "test-rabbitmq" "test-minio")
    local all_healthy=true

    echo ""
    printf "%-20s %-15s %-20s\n" "SERVICE" "STATUS" "HEALTH"
    printf "%-20s %-15s %-20s\n" "--------------------" "---------------" "--------------------"

    for service in "${services[@]}"; do
        local container_name="${PROJECT_NAME}-${service}"
        local status=$(docker inspect --format='{{.State.Status}}' "$container_name" 2>/dev/null || echo "not found")
        local health=$(docker inspect --format='{{.State.Health.Status}}' "$container_name" 2>/dev/null || echo "N/A")

        if [ "$status" = "running" ] && [ "$health" = "healthy" ]; then
            printf "%-20s ${GREEN}%-15s${NC} ${GREEN}%-20s${NC}\n" "$service" "$status" "$health"
        elif [ "$status" = "running" ]; then
            printf "%-20s ${YELLOW}%-15s${NC} ${YELLOW}%-20s${NC}\n" "$service" "$status" "$health"
            all_healthy=false
        else
            printf "%-20s ${RED}%-15s${NC} ${RED}%-20s${NC}\n" "$service" "$status" "$health"
            all_healthy=false
        fi
    done

    echo ""

    if $all_healthy; then
        log_success "All services are healthy"
        return 0
    else
        log_warning "Some services are not healthy"
        return 1
    fi
}

# Show logs
show_logs() {
    local service=$1

    if [ -n "$service" ]; then
        log_info "Showing logs for $service..."
        $DOCKER_COMPOSE -f $COMPOSE_FILE -p $PROJECT_NAME logs -f "$service"
    else
        log_info "Showing logs for all services..."
        $DOCKER_COMPOSE -f $COMPOSE_FILE -p $PROJECT_NAME logs -f
    fi
}

# Reset environment (stop, clean, start)
reset_environment() {
    log_info "Resetting test environment..."
    stop_environment
    $DOCKER_COMPOSE -f $COMPOSE_FILE -p $PROJECT_NAME down -v 2>/dev/null || true
    start_environment
}

# Show status
show_status() {
    log_info "Test environment status:"
    echo ""
    $DOCKER_COMPOSE -f $COMPOSE_FILE -p $PROJECT_NAME ps
    echo ""
    check_health
}

# Show help
show_help() {
    echo "Test Environment Setup Script"
    echo ""
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  start       Start the test environment"
    echo "  stop        Stop the test environment"
    echo "  clean       Stop and remove all test data (volumes)"
    echo "  reset       Stop, clean volumes, and start fresh"
    echo "  health      Check health of all services"
    echo "  status      Show status of all services"
    echo "  logs        Show logs for all services"
    echo "  logs <svc>  Show logs for specific service"
    echo "  help        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 start                    # Start test environment"
    echo "  $0 stop                     # Stop test environment"
    echo "  $0 reset                    # Full reset with clean data"
    echo "  $0 logs test-db             # Show PostgreSQL logs"
    echo ""
    echo "Service Names for logs:"
    echo "  test-db, test-mongo, test-redis, test-rabbitmq, test-minio"
    echo ""
    echo "Port Mapping:"
    echo "  PostgreSQL:  localhost:5433"
    echo "  MongoDB:     localhost:27018"
    echo "  Redis:       localhost:6380"
    echo "  RabbitMQ:    localhost:5673 (Management: 15673)"
    echo "  MinIO:       localhost:9010 (Console: 9011)"
}

# Main command handler
main() {
    check_prerequisites

    case "${1:-help}" in
        start)
            start_environment
            ;;
        stop)
            stop_environment
            ;;
        clean)
            clean_environment
            ;;
        clean-db)
            clean_databases
            ;;
        reset)
            reset_environment
            ;;
        health)
            check_health
            ;;
        status)
            show_status
            ;;
        logs)
            show_logs "$2"
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "Unknown command: $1"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
