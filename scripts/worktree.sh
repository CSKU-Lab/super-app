#!/bin/bash

# CSKU Lab Git Worktree Helper Script
# Manages git worktrees for isolated development per issue
# Usage: ./scripts/worktree.sh <command> [options]

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
Usage: ${SCRIPT_NAME} <command> [options]

Commands:
  create <service> <branch-name> [--force]
      Create a new worktree for a service
      Example: ./scripts/worktree.sh create main-server feat/123-main-server

  list [--service <service>]
      List all worktrees or filter by service
      Example: ./scripts/worktree.sh list --service main-server

  remove <service> <worktree-name> [--force]
      Remove a worktree safely
      Example: ./scripts/worktree.sh remove main-server main-server-feat-123-abc123

  lock <service> <worktree-name>
      Lock a worktree to prevent accidental removal

  unlock <service> <worktree-name>
      Unlock a worktree to allow removal

  cleanup-all [--older-than <hours>]
      Remove inactive/stale worktrees
      Example: ./scripts/worktree.sh cleanup-all --older-than 72h

  help
      Show this help message

Options:
  --force              Skip confirmations
  --older-than <time>  Time format: e.g., 24h, 7d

Examples:
  # Create worktree for issue #123 on main-server
  ./scripts/worktree.sh create main-server feat/123-main-server

  # List all worktrees
  ./scripts/worktree.sh list

  # Lock worktree during development
  ./scripts/worktree.sh lock main-server main-server-feat-123-abc123

  # Remove after PR merge
  ./scripts/worktree.sh remove main-server main-server-feat-123-abc123
EOF
}

# Validate service name
validate_service() {
    local service=$1
    local valid_services=("main-server" "config-server" "task-server" "go-grader" "isolate-docker" "web" "api-docs")
    
    for valid in "${valid_services[@]}"; do
        if [[ "$service" == "$valid" ]]; then
            return 0
        fi
    done
    
    print_error "Invalid service: $service"
    print_info "Valid services: ${valid_services[*]}"
    return 1
}

# Create worktree
cmd_create() {
    local service=$1
    local branch=$2
    local force=${3:-}
    
    if [[ -z "$service" ]] || [[ -z "$branch" ]]; then
        print_error "Missing required arguments"
        echo "Usage: ${SCRIPT_NAME} create <service> <branch-name> [--force]"
        return 1
    fi
    
    validate_service "$service" || return 1
    
    # Check if .git directory or file exists for the service (submodule has .git file, worktree has .git dir)
    local git_dir="${REPO_ROOT}/${service}/.git"
    if [[ ! -f "$git_dir" ]] && [[ ! -d "$git_dir" ]]; then
        print_error "Service directory not found: ${REPO_ROOT}/${service}"
        return 1
    fi
    
    # Create worktree directory if it doesn't exist
    mkdir -p "$WORKTREE_ROOT"
    
    # Generate unique worktree name with timestamp
    local timestamp=$(date +%s | tail -c 6)
    local worktree_name="${service}-${branch}-${timestamp}"
    local worktree_path="${WORKTREE_ROOT}/${worktree_name}"
    
    # Check if worktree already exists
    if [[ -d "$worktree_path" ]]; then
        print_warning "Worktree already exists at: $worktree_path"
        if [[ "$force" != "--force" ]]; then
            read -p "Remove and recreate? (y/N) " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                return 1
            fi
            git worktree remove "$worktree_path" 2>/dev/null || true
        else
            git worktree remove "$worktree_path" 2>/dev/null || true
        fi
    fi
    
    # Create the worktree
    print_info "Creating worktree for $service..."
    
    # Get the service's git directory
    cd "$REPO_ROOT"
    
    # Check if branch exists in service
    local branch_exists=$(cd "$service" && git show-ref --verify --quiet "refs/remotes/origin/$branch" 2>/dev/null && echo "yes" || echo "no")
    
    if [[ "$branch_exists" == "no" ]]; then
        # Create new branch from develop
        print_info "Creating new branch from develop..."
        git -C "$service" worktree add -b "$branch" "$worktree_path" origin/develop 2>/dev/null || \
            git -C "$service" worktree add -b "$branch" "$worktree_path" develop 2>/dev/null || \
            git -C "$service" worktree add -b "$branch" "$worktree_path" HEAD 2>/dev/null || {
            print_error "Failed to create worktree"
            return 1
        }
    else
        # Create worktree from existing branch
        git -C "$service" worktree add "$worktree_path" "origin/$branch" 2>/dev/null || {
            print_error "Failed to create worktree"
            return 1
        }
    fi
    
    print_success "Worktree created at: $worktree_path"
    print_info "Branch: $branch"
    echo ""
    echo "Next steps for agent:"
    echo "  cd $worktree_path"
    echo "  git branch -v  # Verify branch"
    echo "  # ... make changes ..."
    echo "  git push -u origin $branch"
    
    return 0
}

# List worktrees
cmd_list() {
    local filter_service=${2:-}
    
    if [[ ! -d "$WORKTREE_ROOT" ]]; then
        print_info "No worktrees found. Create one with: ./scripts/worktree.sh create <service> <branch>"
        return 0
    fi
    
    local count=0
    local header_printed=0
    
    cd "$REPO_ROOT"
    
    for worktree_dir in "$WORKTREE_ROOT"/*; do
        if [[ ! -d "$worktree_dir" ]]; then
            continue
        fi
        
        local worktree_name=$(basename "$worktree_dir")
        local service=$(echo "$worktree_name" | cut -d'-' -f1-2)
        
        # Apply service filter if provided
        if [[ -n "$filter_service" ]] && [[ "$service" != "$filter_service" ]]; then
            continue
        fi
        
        # Print header on first match
        if [[ $header_printed -eq 0 ]]; then
            echo ""
            printf "%-35s %-30s %-10s %s\n" "Service" "Branch" "Locked" "Path"
            printf "%-35s %-30s %-10s %s\n" "-------" "------" "------" "----"
            header_printed=1
        fi
        
        # Get branch info
        local branch=""
        if git -C "$worktree_dir" rev-parse --git-dir &>/dev/null; then
            branch=$(cd "$worktree_dir" && git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
        else
            branch="invalid"
        fi
        
        # Check if locked
        local locked="no"
        if [[ -f "${worktree_dir}/.git" ]]; then
            # Read .git file to find actual location
            local git_file_content=$(cat "${worktree_dir}/.git" 2>/dev/null)
            if grep -q "lock" <<< "$git_file_content" 2>/dev/null; then
                locked="yes"
            fi
        fi
        
        # Check if lock file exists
        if [[ -f "${worktree_dir}/.git/index.lock" ]]; then
            locked="yes"
        fi
        
        printf "%-35s %-30s %-10s %s\n" "$service" "$branch" "$locked" "$worktree_name"
        ((count++))
    done
    
    if [[ $count -eq 0 ]]; then
        if [[ -n "$filter_service" ]]; then
            print_info "No worktrees found for service: $filter_service"
        else
            print_info "No worktrees found. Create one with: ./scripts/worktree.sh create <service> <branch>"
        fi
        return 0
    fi
    
    echo ""
    print_info "Total: $count worktree(s)"
    return 0
}

# Remove worktree
cmd_remove() {
    local service=$1
    local worktree_name=$2
    local force=${3:-}
    
    if [[ -z "$service" ]] || [[ -z "$worktree_name" ]]; then
        print_error "Missing required arguments"
        echo "Usage: ${SCRIPT_NAME} remove <service> <worktree-name> [--force]"
        return 1
    fi
    
    validate_service "$service" || return 1
    
    local worktree_path="${WORKTREE_ROOT}/${worktree_name}"
    
    if [[ ! -d "$worktree_path" ]]; then
        print_error "Worktree not found: $worktree_path"
        print_info "Use '${SCRIPT_NAME} list' to see available worktrees"
        return 1
    fi
    
    # Check if worktree has uncommitted changes
    if [[ -d "$worktree_path/.git" ]] || [[ -f "$worktree_path/.git" ]]; then
        local dirty=$(cd "$worktree_path" && git status --porcelain 2>/dev/null || echo "")
        if [[ -n "$dirty" ]]; then
            print_warning "Worktree has uncommitted changes"
            if [[ "$force" != "--force" ]]; then
                read -p "Continue with removal? (y/N) " -n 1 -r
                echo
                if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                    return 1
                fi
            fi
        fi
    fi
    
    # Confirm removal
    if [[ "$force" != "--force" ]]; then
        read -p "Remove worktree at: $worktree_path? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return 1
        fi
    fi
    
    print_info "Removing worktree..."
    
    cd "$REPO_ROOT"
    
    # Remove worktree
    if git -C "$service" worktree remove "$worktree_path" 2>/dev/null; then
        print_success "Worktree removed: $worktree_name"
        return 0
    else
        # Fallback: force removal if git worktree remove fails
        print_warning "Forced removal of worktree..."
        rm -rf "$worktree_path"
        print_success "Worktree removed: $worktree_name"
        return 0
    fi
}

# Lock worktree
cmd_lock() {
    local service=$1
    local worktree_name=$2
    
    if [[ -z "$service" ]] || [[ -z "$worktree_name" ]]; then
        print_error "Missing required arguments"
        echo "Usage: ${SCRIPT_NAME} lock <service> <worktree-name>"
        return 1
    fi
    
    validate_service "$service" || return 1
    
    local worktree_path="${WORKTREE_ROOT}/${worktree_name}"
    
    if [[ ! -d "$worktree_path" ]]; then
        print_error "Worktree not found: $worktree_path"
        return 1
    fi
    
    # Create lock file
    touch "${worktree_path}/.worktree.lock"
    print_success "Worktree locked: $worktree_name"
    print_info "Prevent accidental removal during active development"
    
    return 0
}

# Unlock worktree
cmd_unlock() {
    local service=$1
    local worktree_name=$2
    
    if [[ -z "$service" ]] || [[ -z "$worktree_name" ]]; then
        print_error "Missing required arguments"
        echo "Usage: ${SCRIPT_NAME} unlock <service> <worktree-name>"
        return 1
    fi
    
    validate_service "$service" || return 1
    
    local worktree_path="${WORKTREE_ROOT}/${worktree_name}"
    
    if [[ ! -d "$worktree_path" ]]; then
        print_error "Worktree not found: $worktree_path"
        return 1
    fi
    
    # Remove lock file
    rm -f "${worktree_path}/.worktree.lock"
    print_success "Worktree unlocked: $worktree_name"
    print_info "Safe to remove after work completion"
    
    return 0
}

# Cleanup stale worktrees
cmd_cleanup_all() {
    local older_than=${2:-72h}
    
    if [[ ! -d "$WORKTREE_ROOT" ]]; then
        print_info "No worktrees to clean"
        return 0
    fi
    
    # Convert time format to seconds
    local max_age_seconds=259200  # 72 hours default
    
    if [[ "$older_than" == *"h" ]]; then
        max_age_seconds=$((${older_than%h} * 3600))
    elif [[ "$older_than" == *"d" ]]; then
        max_age_seconds=$((${older_than%d} * 86400))
    fi
    
    print_info "Cleaning worktrees older than: $older_than"
    
    local current_time=$(date +%s)
    local count=0
    
    cd "$REPO_ROOT"
    
    for worktree_dir in "$WORKTREE_ROOT"/*; do
        if [[ ! -d "$worktree_dir" ]]; then
            continue
        fi
        
        local worktree_name=$(basename "$worktree_dir")
        
        # Check if locked
        if [[ -f "${worktree_dir}/.worktree.lock" ]]; then
            print_info "Skipping locked worktree: $worktree_name"
            continue
        fi
        
        # Get directory age
        local dir_mtime=$(stat -f%m "$worktree_dir" 2>/dev/null || stat -c%Y "$worktree_dir" 2>/dev/null)
        local age=$((current_time - dir_mtime))
        
        if [[ $age -gt $max_age_seconds ]]; then
            print_info "Removing stale worktree: $worktree_name (${age}s old)"
            
            # Try to remove
            if rm -rf "$worktree_dir"; then
                ((count++))
            fi
        fi
    done
    
    if [[ $count -eq 0 ]]; then
        print_info "No stale worktrees found"
    else
        print_success "Cleaned up $count worktree(s)"
    fi
    
    return 0
}

# Main command router
main() {
    local command=${1:-help}
    shift || true  # Remove command from args
    
    case "$command" in
        create)
            cmd_create "$@"
            ;;
        list)
            cmd_list "$@"
            ;;
        remove)
            cmd_remove "$@"
            ;;
        lock)
            cmd_lock "$@"
            ;;
        unlock)
            cmd_unlock "$@"
            ;;
        cleanup-all)
            cmd_cleanup_all "$@"
            ;;
        help|--help|-h)
            print_usage
            ;;
        *)
            print_error "Unknown command: $command"
            print_usage
            return 1
            ;;
    esac
}

main "$@"
