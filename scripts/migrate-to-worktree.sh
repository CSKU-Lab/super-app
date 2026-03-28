#!/bin/bash

# CSKU Lab - Migrate Submodules to Git Worktrees
# Converts existing submodule setup to git worktree setup (one-time migration)
# This script automatically converts all 7 submodules to worktrees on first run

set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKTREE_ROOT="${REPO_ROOT}/.worktrees"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_error() {
    echo -e "${RED}❌ Error: $1${NC}" >&2
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_usage() {
    cat << EOF
Usage: ${SCRIPT_NAME} [options]

Options:
  --dry-run           Show what would happen without making changes
  --force             Skip confirmations
  --keep-submodules   Keep old submodule paths after migration

Description:
  Converts all git submodules to git worktrees for CSKU Lab development.
  This creates fresh worktrees for all 7 services:
  - main-server
  - config-server
  - task-server
  - go-grader
  - isolate-docker
  - web
  - api-docs

  Each worktree is created from the service's current branch/commit.
  .gitignore is updated to exclude .worktrees/ directory.

Example:
  # Preview migration
  ./scripts/migrate-to-worktree.sh --dry-run

  # Execute migration
  ./scripts/migrate-to-worktree.sh

  # Keep submodule references after migration
  ./scripts/migrate-to-worktree.sh --keep-submodules
EOF
}

# Services to migrate
SERVICES=(
    "main-server"
    "config-server"
    "task-server"
    "go-grader"
    "isolate-docker"
    "web"
    "api-docs"
)

# Validate migration
validate_migration() {
    print_info "Validating migration setup..."
    
    # Check if git repo
    if ! git -C "$REPO_ROOT" rev-parse --git-dir &>/dev/null; then
        print_error "Not a git repository: $REPO_ROOT"
        return 1
    fi
    
    # Check if submodules initialized (check both .git files and .git/modules)
    local submodule_count=0
    for service in "${SERVICES[@]}"; do
        local service_path="${REPO_ROOT}/${service}"
        # Check for .git file (submodule reference) or .git directory (worktree)
        if [[ -f "${service_path}/.git" ]] || [[ -d "${service_path}/.git" ]]; then
            ((submodule_count++))
        elif [[ -d "${REPO_ROOT}/.git/modules/${service}" ]]; then
            # Submodule registered in .git/modules but not checked out yet
            ((submodule_count++))
        fi
    done
    
    if [[ $submodule_count -eq 0 ]]; then
        print_error "No submodules found. Run: git submodule update --init --recursive"
        return 1
    fi
    
    print_success "Validation passed ($submodule_count submodules found)"
    return 0
}

# Migrate service to worktree
migrate_service() {
    local service=$1
    local dry_run=$2
    
    local service_path="${REPO_ROOT}/${service}"
    
    # Check if service is initialized (either as submodule or worktree)
    if [[ ! -f "$service_path/.git" ]] && [[ ! -d "$service_path/.git" ]]; then
        if [[ ! -d "${REPO_ROOT}/.git/modules/${service}" ]]; then
            print_warning "Skipping $service (not initialized)"
            return 0
        fi
    fi
    
    print_info "Processing: $service"
    
    # Get current branch (handle both submodule and worktree)
    local current_branch
    if [[ -d "$service_path/.git" ]] || [[ -f "$service_path/.git" ]]; then
        current_branch=$(cd "$service_path" && git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "develop")
    else
        # Submodule not yet checked out, assume develop
        current_branch="develop"
    fi
    print_info "  Current branch: $current_branch"
    
    # Generate timestamp for uniqueness
    local timestamp=$(date +%Y%m%d)
    # Replace slashes in branch name to avoid path issues
    local safe_branch=$(echo "$current_branch" | tr '/' '-')
    local worktree_name="${service}-${safe_branch}-${timestamp}"
    local worktree_path="${WORKTREE_ROOT}/${worktree_name}"
    
    print_info "  Worktree: $worktree_name"
    
    if [[ "$dry_run" != "--dry-run" ]]; then
        # Create worktree
        mkdir -p "$WORKTREE_ROOT"
        
        # Check if already exists
        if [[ -d "$worktree_path" ]]; then
            print_warning "  Worktree already exists, skipping"
            return 0
        fi
        
        # Create the worktree from service's current branch
        if git -C "$service_path" worktree add "$worktree_path" "$current_branch" 2>/dev/null || \
           git -C "$service_path" worktree add "$worktree_path" HEAD 2>/dev/null; then
            print_success "  Created: $worktree_path"
        else
            print_error "Failed to create worktree for $service"
            return 1
        fi
    fi
    
    return 0
}

# Update .gitignore
update_gitignore() {
    local dry_run=$1
    local gitignore_path="${REPO_ROOT}/.gitignore"
    
    print_info "Updating .gitignore..."
    
    # Check if already excluded
    if grep -q "^\.worktrees/" "$gitignore_path" 2>/dev/null; then
        print_info ".worktrees already in .gitignore"
        return 0
    fi
    
    if [[ "$dry_run" != "--dry-run" ]]; then
        # Add to .gitignore
        {
            echo ""
            echo "# Git worktrees - ephemeral, local development only"
            echo ".worktrees/"
        } >> "$gitignore_path"
        print_success "Added .worktrees/ to .gitignore"
    else
        print_info "[dry-run] Would add .worktrees/ to .gitignore"
    fi
    
    return 0
}

# Main migration
main() {
    local dry_run=""
    local force=""
    local keep_submodules=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                dry_run="--dry-run"
                ;;
            --force)
                force="--force"
                ;;
            --keep-submodules)
                keep_submodules="--keep-submodules"
                ;;
            --help|-h)
                print_usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                print_usage
                return 1
                ;;
        esac
        shift
    done
    
    echo ""
    print_info "CSKU Lab: Migrate Submodules to Git Worktrees"
    echo ""
    
    # Check if already migrated
    if [[ -d "$WORKTREE_ROOT" ]] && [[ $(ls -A "$WORKTREE_ROOT" 2>/dev/null | wc -l) -gt 0 ]]; then
        print_warning "Worktrees already exist at: $WORKTREE_ROOT"
        if [[ "$force" != "--force" ]]; then
            read -p "Proceed with migration anyway? (y/N) " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                print_info "Migration cancelled"
                return 0
            fi
        fi
    fi
    
    # Validate setup
    validate_migration || return 1
    
    echo ""
    
    if [[ "$dry_run" == "--dry-run" ]]; then
        print_info "DRY RUN MODE - No changes will be made"
        echo ""
    fi
    
    # Migrate each service
    local success_count=0
    for service in "${SERVICES[@]}"; do
        if migrate_service "$service" "$dry_run"; then
            ((success_count++))
        fi
    done
    
    echo ""
    
    # Update .gitignore
    update_gitignore "$dry_run"
    
    echo ""
    
    # Summary
    if [[ "$dry_run" == "--dry-run" ]]; then
        print_success "DRY RUN COMPLETE"
        echo ""
        print_info "If satisfied, run again without --dry-run to execute migration"
    else
        print_success "Migration complete!"
        echo ""
        echo "Migration Summary:"
        echo "  ✅ $success_count/${#SERVICES[@]} services migrated"
        echo "  ✅ Worktrees created in: $WORKTREE_ROOT"
        echo "  ✅ .gitignore updated"
        echo ""
        print_info "Next: Run './compose.sh up' to start development with worktrees"
    fi
    
    echo ""
    
    return 0
}

main "$@"
