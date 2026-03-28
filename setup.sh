#!/bin/zsh
set -a

source <(doppler secrets download --no-file --format env)

# -----------------------------------------------------------------------------
# Step 0: Initialize Git Worktrees (if needed)
# -----------------------------------------------------------------------------
echo "-----------------------------------------------------------------------------"
echo "Step 0: Initializing Git Worktrees"
echo "-----------------------------------------------------------------------------"

if [[ ! -d ".worktrees" ]] || [[ $(ls -A .worktrees 2>/dev/null | wc -l) -eq 0 ]]; then
    echo "🔄 Setting up git worktrees for first time..."
    ./scripts/migrate-to-worktree.sh --force
    echo "✅ Git worktrees initialized!"
else
    echo "✅ Git worktrees already initialized"
    # Optional: clean up old worktrees older than 72 hours
    # ./scripts/worktree.sh cleanup-all --older-than 72h > /dev/null 2>&1 || true
fi
echo ""

# Define some colors and symbols
if command -v tput >/dev/null 2>&1 && tput setaf 1 >/dev/null 2>&1; then
    GREEN=$(tput setaf 2)
    NC=$(tput sgr0)
    CHECK="[${GREEN}✔${NC}]"
else
    CHECK="[✔]"
fi
LOADING="[ ]"

# Function to display a loading indicator
loading() {
  local text="$1"
  local i=0
  while :; do
    printf "\r%s %s%s%s" "$LOADING" "$text" "$(printf "%.${i}s" "...")" "   "
    i=$(( (i+1) % 4 ))
    sleep 0.2
    [ "${done+set}" = "set" ] && break
  done
  printf "\r%s %s%s%s\n" "$CHECK" "$text" "   " "   "
}

# -----------------------------------------------------------------------------
# Step 1: Start all services
# -----------------------------------------------------------------------------
echo "-----------------------------------------------------------------------------"
echo "Step 1: Starting all services"
echo "-----------------------------------------------------------------------------"
done=false
loading "Starting Docker Compose services..."
docker compose -f docker-compose.dev.yaml up -d db mongo s3 rabbitmq
done=true

# Get all service names
SERVICES=$(docker compose -f docker-compose.dev.yaml ps --services)

# Function to check if a service is healthy
is_healthy() {
  local service_name=$1
  local container_ids=$(docker ps -q --filter "name=$service_name")
  if [[ -z "$container_ids" ]]; then
    echo "Container for service '$service_name' not found." >&2
    return 1
  fi

  for container_id in $container_ids; do
    local health_status=$(docker inspect "$container_id" --format='{{json .State.Health.Status}}')
    if [ "$health_status" = '"healthy"' ]; then
      return 0 # Healthy (at least one container is healthy)
    fi
  done

  return 1 # Not healthy (no healthy containers found)
}

# Wait for all services to be healthy
ALL_HEALTHY=false
while [ "$ALL_HEALTHY" = false ]; do
  ALL_HEALTHY=true
  for service in ${(f)SERVICES}; do
    if ! is_healthy "$service"; then
      ALL_HEALTHY=false
      echo "Service '$service' is not yet healthy. Waiting..."
      sleep 5
      break
    fi
  done

  if [ "$ALL_HEALTHY" = true ]; then
    echo "All services are healthy."
    break
  fi
done
echo "${CHECK} All services are healthy"

# -----------------------------------------------------------------------------
# Step 2: Create Postgres users and databases
# -----------------------------------------------------------------------------
echo "-----------------------------------------------------------------------------"
echo "Step 2: Creating Postgres users and databases"
echo "-----------------------------------------------------------------------------"
done=false
loading "Creating Postgres users and databases..."
docker compose -f docker-compose.dev.yaml exec -T db bash /scripts/01-create-databases.sh
done=true
echo "${CHECK} Created Postgres users and databases"

# -----------------------------------------------------------------------------
# Step 3: Create MongoDB users
# -----------------------------------------------------------------------------
echo "-----------------------------------------------------------------------------"
echo "Step 3: Creating MongoDB users"
echo "-----------------------------------------------------------------------------"
done=false
loading "Creating MongoDB users..."
docker compose -f docker-compose.dev.yaml exec -T mongo bash /scripts/01-init-users.sh
done=true
echo "${CHECK} Created MongoDB users"

# -----------------------------------------------------------------------------
# Step 4: Create S3 Access ID and Secret Key
# -----------------------------------------------------------------------------
echo "-----------------------------------------------------------------------------"
echo "Step 4.1: Creating S3 Access ID and Secret Key"
echo "-----------------------------------------------------------------------------"
done=false
loading "Creating S3 Access ID and Secret Key..."
docker run --rm -v ./scripts/minio:/scripts --network super-app_default -e MINIO_ROOT_USER=$MINIO_ROOT_USER -e MINIO_ROOT_PASSWORD=$MINIO_ROOT_PASSWORD -e MAIN_SERVER_S3_ACCESS_KEY_ID=$MAIN_SERVER_S3_ACCESS_KEY_ID -e MAIN_SERVER_S3_SECRET_ACCESS_KEY=$MAIN_SERVER_S3_SECRET_ACCESS_KEY --entrypoint /scripts/01-create-access-id-and-secret-key.sh minio/mc
done=true
echo "${CHECK} Created S3 Access ID and Secret Key"

echo "-----------------------------------------------------------------------------"
echo "Step 4.2: Public S3 Access Policy"
echo "-----------------------------------------------------------------------------"
done=false
loading "Public S3 Access Policy..."
docker run --rm -v ./scripts/minio:/scripts --network super-app_default -e MINIO_ROOT_USER=$MINIO_ROOT_USER -e MINIO_ROOT_PASSWORD=$MINIO_ROOT_PASSWORD -e MAIN_SERVER_S3_ACCESS_KEY_ID=$MAIN_SERVER_S3_ACCESS_KEY_ID -e MAIN_SERVER_S3_SECRET_ACCESS_KEY=$MAIN_SERVER_S3_SECRET_ACCESS_KEY --entrypoint /scripts/02-add-bucket-public-policy.sh minio/mc
done=true
echo "${CHECK} Public S3 Access Policy created"

echo "Finished setting up infrastructure."
# -----------------------------------------------------------------------------
# Step 5: Migrate Postgres databases
# -----------------------------------------------------------------------------
echo "-----------------------------------------------------------------------------"
echo "Step 5: Migrating Postgres databases"
echo "-----------------------------------------------------------------------------"
done=false
loading "Migrating Postgres databases..."
(DATABASE_URL=$(echo "$MAIN_SERVER_DATABASE_URL" | sed 's/db/localhost/g'); cd main-server && ./scripts/migrate.sh --auto-approve >> /dev/null)
done=true
echo "${CHECK} Migrated Postgres databases"

echo "Finished database migrations."


echo "-----------------------------------------------------------------------------"
echo "Step 6: Seed Main server data"
echo "-----------------------------------------------------------------------------"
done=false
loading "Seeding Main server data..."
(DATABASE_URL=$(echo "$MAIN_SERVER_DATABASE_URL" | sed 's/db/localhost/g'); cd main-server && go run cmd/seed/seed.go >> /dev/null)
done=true
echo "${CHECK} Seeded Main server data"


echo "-----------------------------------------------------------------------------"
echo "Step 7: Start remaining services"
echo "-----------------------------------------------------------------------------"
done=false
loading "Starting remaining services..."
docker compose -f docker-compose.dev.yaml up -d >> /dev/null
done=true
echo "${CHECK} All remaining services started"


echo "Ready to go!"

set +a
