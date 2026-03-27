# Complete Agent Workflow Example

This document walks through a complete feature implementation from start to finish, showing how all agents collaborate.

## Feature Request: Add User Profile API Endpoint

**User Request**:
```
@coordinator - Add GET /api/v1/users/me endpoint that returns the
authenticated user's profile (name, email, role, created_at). Requires
JWT authentication. Return 401 if unauthenticated, proper errors for
server issues. Include tests.
```

## Step 1: Coordinator Creates GitHub Issue

**What coordinator does**:
```bash
gh issue create \
  --title "Add user profile API endpoint" \
  --body "## Feature Description
Add GET /api/v1/users/me REST endpoint to main-server

## Requirements
- Endpoint: GET /api/v1/users/me
- Requires JWT authentication
- Return user profile (name, email, role, created_at)
- Error handling: 401 for unauthenticated, 500 for server errors

## Services Affected
- main-server (HTTP handler, repository, service layer)
- Database (user data already exists)

## Acceptance Criteria
- Endpoint returns 200 with user profile when authenticated
- Endpoint returns 401 when unauthenticated
- All database queries properly parameterized
- Unit tests with mocked DB (>80% coverage)
- Integration tests with real PostgreSQL
- Proper commit message format with Closes #1001"
```

**Result**: GitHub issue #1001 created

## Step 2: Coordinator Routes to Specialists

**Coordinator analyzes**:
- Primary service: main-server (REST API)
- Database: Already have users table
- Frontend: Not needed for API endpoint
- Communication: Not a gRPC service

**Decision**: Route to go-clean-arch specialist

```
@go-clean-arch - Implement issue #1001: Add GET /api/v1/users/me endpoint.
Create feature branch feat/1001-user-profile with subtask branch
feat/1001-api/user-profile-endpoint.

Requirements:
- Handler: GET /api/v1/users/me (requires auth)
- Service: Fetch authenticated user from context
- Repository: GetUserByID query (parameterized)
- Tests: Unit tests (mocked DB) + integration tests (real DB)
- Error handling: 401, 500
```

## Step 3: Go-Clean-Arch Specialist Implements

### Create Branches

```bash
# User creates feature branch
git checkout -b feat/1001-user-profile
git push origin feat/1001-user-profile

# Specialist creates subtask branch
git checkout -b feat/1001-api/user-profile-endpoint
```

### Implement Domain Layer

```go
// domain/user.go (already exists, no changes needed)
package domain

type User struct {
    ID        string
    Email     string
    Name      string
    Role      string
    CreatedAt time.Time
}
```

### Implement Service Layer

```go
// internal/services/user_service.go
package services

type UserService struct {
    repo domain.UserRepository
}

func (s *UserService) GetUserByID(ctx context.Context, id string) (*domain.User, error) {
    return s.repo.GetByID(ctx, id)
}
```

### Implement Handler Layer

```go
// internal/handlers/user_handler.go
package handlers

type UserHandler struct {
    userService services.UserService
}

func (h *UserHandler) GetUserProfile(c *fiber.Ctx) error {
    // Get authenticated user ID from context
    userID := c.Locals("user_id").(string)
    if userID == "" {
        return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
            "error": "Unauthorized",
        })
    }

    user, err := h.userService.GetUserByID(c.Context(), userID)
    if err != nil {
        if errors.Is(err, domain.ErrUserNotFound) {
            return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
                "error": "User not found",
            })
        }
        return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
            "error": "Failed to fetch profile",
        })
    }

    return c.JSON(fiber.Map{
        "id":         user.ID,
        "name":       user.Name,
        "email":      user.Email,
        "role":       user.Role,
        "created_at": user.CreatedAt,
    })
}

// Register route with auth middleware
func (h *UserHandler) RegisterRoutes(app *fiber.App) {
    api := app.Group("/api/v1")
    api.Get("/users/me", AuthMiddleware, h.GetUserProfile)
}
```

### Implement Repository Layer

```go
// internal/repositories/user_repository.go
package repositories

type UserRepository struct {
    db *sqlx.DB
}

func (r *UserRepository) GetByID(ctx context.Context, id string) (*domain.User, error) {
    var user domain.User
    query := `SELECT id, email, name, role, created_at FROM users WHERE id = $1`
    
    err := r.db.GetContext(ctx, &user, query, id)
    if err != nil {
        if errors.Is(err, sql.ErrNoRows) {
            return nil, domain.ErrUserNotFound
        }
        return nil, fmt.Errorf("failed to get user: %w", err)
    }
    
    return &user, nil
}
```

### Unit Tests (Mocked DB)

```go
// internal/handlers/user_handler_test.go
package handlers_test

import (
    "testing"
    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/mock"
)

type MockUserService struct {
    mock.Mock
}

func (m *MockUserService) GetUserByID(ctx context.Context, id string) (*domain.User, error) {
    args := m.Called(ctx, id)
    if args.Get(0) == nil {
        return nil, args.Error(1)
    }
    return args.Get(0).(*domain.User), args.Error(1)
}

func TestGetUserProfile_Success(t *testing.T) {
    mockService := new(MockUserService)
    mockService.On("GetUserByID", mock.Anything, "user-123").Return(
        &domain.User{
            ID:    "user-123",
            Name:  "John Doe",
            Email: "john@example.com",
            Role:  "student",
        },
        nil,
    )

    handler := &UserHandler{userService: mockService}
    
    // Use mock HTTP client to test handler
    // ... test implementation
    
    mockService.AssertExpectations(t)
}

func TestGetUserProfile_Unauthorized(t *testing.T) {
    handler := &UserHandler{userService: nil}
    
    // Test with missing auth token
    // ... verify 401 response
}
```

### Integration Tests (Real DB)

```go
// tests/integration/user_handler_test.go
package integration_test

import (
    "testing"
    "github.com/testcontainers/testcontainers-go"
)

func TestGetUserProfile_Integration(t *testing.T) {
    // Setup test database
    db := setupTestDB(t)
    defer db.Close()

    // Insert test user
    _, err := db.Exec(
        "INSERT INTO users (id, email, name, role, created_at) VALUES ($1, $2, $3, $4, NOW())",
        "user-123", "john@example.com", "John Doe", "student")
    require.NoError(t, err)

    // Create handler with real repository
    repo := repositories.NewUserRepository(db)
    service := services.NewUserService(repo)
    handler := handlers.NewUserHandler(service)

    // Test via HTTP endpoint
    resp := testRequest(t, handler, "GET", "/api/v1/users/me", "user-123")
    
    assert.Equal(t, http.StatusOK, resp.StatusCode)
    
    var result fiber.Map
    json.NewDecoder(resp.Body).Decode(&result)
    
    assert.Equal(t, "John Doe", result["name"])
    assert.Equal(t, "john@example.com", result["email"])
}
```

### Commit with Proper Message

```bash
git add internal/ tests/
git commit -m "feat(api): add user profile endpoint

- Implement GET /api/v1/users/me handler with auth requirement
- Add UserService to fetch authenticated user
- Add parameterized SQL query in repository
- Include unit tests with mocked service (85% coverage)
- Include integration tests with real PostgreSQL
- Proper error handling: 401 for unauthorized, 500 for errors

Closes #1001"
```

### Create PR to Feature Branch

```bash
# Push subtask branch
git push origin feat/1001-api/user-profile-endpoint

# Create PR (to feature branch, NOT main!)
gh pr create \
  --base feat/1001-user-profile \
  --head feat/1001-api/user-profile-endpoint \
  --title "feat(api): add user profile endpoint" \
  --body "Implements GET /api/v1/users/me endpoint for issue #1001.

## Changes
- HTTP handler with authentication
- Service layer to fetch user
- Repository with parameterized queries
- Unit tests with mocks (85% coverage)
- Integration tests with testcontainers

## Testing
- Run: go test -cover ./...
- Coverage: 85% for new code"
```

**Result**: PR created to feature branch (not main!)

## Step 4: QA Specialist Reviews

### Code Review Checklist

```
✅ Architecture: Proper clean architecture (handler → service → repository)
✅ Error Handling: Domain errors and proper HTTP status codes
✅ Database: Parameterized SQL query (no injection vulnerability)
✅ Testing: 85% coverage with both unit and integration tests
✅ Commit Message: Proper format with `Closes #1001`
✅ Security: Auth middleware required, 401 for unauthenticated
✅ Code Quality: No duplicate code, clear method names
✅ Logging: Error cases properly logged
```

### Run Tests

```bash
cd main-server
go test -v -cover ./internal/handlers/...
go test -v -cover ./internal/services/...
go test -v ./tests/integration/...

# Output:
# coverage: 85.2% of statements
# ok  github.com/CSKU-Lab/super-app/main-server/tests/integration  5.234s
```

### Approve and Auto-Merge

```bash
# Approve PR
gh pr review <PR-NUMBER> --approve

# Auto-merge to feature branch
gh pr merge <PR-NUMBER> --auto --squash

# Verify merge
git log --oneline feat/1001-user-profile | head -3
```

**Result**: Subtask PR merged to feature branch

## Step 5: User Creates Final PR

### Create Final PR to Main

```bash
# Switch to feature branch
git checkout feat/1001-user-profile

# Create PR to main
gh pr create \
  --base main \
  --head feat/1001-user-profile \
  --title "feat: add user profile API endpoint (issue #1001)" \
  --body "## Summary
Implements user profile API endpoint with authentication.

## Changes
- GET /api/v1/users/me endpoint
- User service and repository
- Comprehensive tests (>80% coverage)
- Proper error handling

Closes #1001"
```

### Merge to Main

```bash
# Once PR approved and CI passes
gh pr merge <FINAL-PR-NUMBER>

# GitHub automatically closes issue #1001 due to 'Closes #1001'
```

**Result**: Feature branch merged to main, issue auto-closes

## Complete Git History

```
main
├── Previous feature commits...
└── Merge commit: "feat: add user profile API endpoint (issue #1001)"
    │
    └── feat/1001-user-profile (deleted after merge)
        └── feat(api): add user profile endpoint
            └── Closes #1001
```

## Summary

### Timeline
- **Step 1**: Coordinator creates issue #1001
- **Step 2**: Coordinator routes to go-clean-arch
- **Step 3**: go-clean-arch implements (30 mins - 2 hours)
- **Step 4**: QA reviews and auto-merges (5-15 mins)
- **Step 5**: User creates final PR and merges (immediate)

### Parallel Work Opportunity
If this feature also needed a frontend UI component:
- go-clean-arch could work on API handler
- frontend-dev could work on React component in parallel
- service-comms could update API documentation
- QA would review both PRs
- Both merge to feature branch simultaneously

### Key Learnings
- ✅ Specialized agents focus on their domain
- ✅ Clear branching strategy prevents conflicts
- ✅ Commit message format enables auto-closing issues
- ✅ Tests validated before merge
- ✅ QA provides quality gate
- ✅ Feature branch aggregates all work before final merge

---

**Next**: Read `docs/TESTING-STRATEGY.md` for testing patterns
