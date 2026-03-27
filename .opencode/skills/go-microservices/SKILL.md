---
name: go-microservices
description: Best practices for developing Go microservices in the CSKU Lab platform
license: MIT
compatibility: opencode
metadata:
  audience: experienced-developers
  language: go
  services: all-go-services
---

# Go Microservices Development

This skill covers best practices for developing Go microservices in the CSKU Lab platform. Use this when working on main-server, config-server, task-server, or go-grader services.

## Project Structure

Each service follows this standard structure:

```
service/
├── cmd/                      # Entrypoints
│   ├── app/main.go          # Main application server
│   ├── app/worker.go        # Optional: background worker
│   └── seed/seed.go         # Optional: database seeding
├── internal/                 # Private business logic (cannot be imported by other packages)
│   ├── adapters/            # External service adapters
│   │   ├── http/            # HTTP handlers and routes
│   │   ├── db/              # Database queries (sqlx, MongoDB)
│   │   ├── grpc/            # gRPC client implementations
│   │   └── middleware/      # HTTP/gRPC middleware
│   ├── transaction/         # Unit of Work pattern
│   ├── requests/            # Request DTOs with validation
│   └── config/              # Service configuration
├── domain/                   # Public domain models
│   ├── models.go            # Core business entities
│   ├── errors.go            # Custom error types
│   ├── repositories.go      # Repository interfaces
│   └── services.go          # Service interfaces
├── protos/                   # Protocol Buffer definitions
├── genproto/                # Generated gRPC code (auto-generated)
├── postgresql/              # PostgreSQL specific (main-server only)
│   ├── migrations/          # SQL migration files
│   └── schema.sql           # Schema reference
├── atlas/                   # Atlas migration files
│   └── schema.hcl          # Atlas schema definition
├── tests/                   # Tests
│   ├── unit/
│   ├── integration/
│   └── fixtures/
├── Dockerfile               # Container image
├── Dockerfile.dev           # Development image with hot reload
├── .air.toml               # Air hot reload config
├── go.mod                   # Module definition
├── go.sum                   # Dependency checksums
├── Makefile                # Build automation (optional)
└── README.md               # Service documentation
```

## Technology Stack

### HTTP Framework: GoFiber v3

**Router Pattern:**
```go
app := fiber.New()
api := app.Group("/api")
v1 := api.Group("/v1")

// Mount handlers
v1.Post("/submit", handlers.SubmitCode)
v1.Get("/submissions/:id", handlers.GetSubmission)
```

**Middleware Chain:**
- Authentication (JWT + OAuth2)
- Request validation
- Error handling
- Logging & tracing
- CORS (if needed)

### Database Access: sqlx (PostgreSQL) or MongoDB Go Driver

**sqlx Pattern (main-server):**
```go
type UserRepository struct {
    db *sqlx.DB
}

func (r *UserRepository) GetByID(ctx context.Context, id string) (*User, error) {
    var user User
    err := r.db.GetContext(ctx, &user, "SELECT * FROM users WHERE id = $1", id)
    return &user, err
}
```

**MongoDB Pattern (config-server, task-server):**
```go
type ConfigRepository struct {
    collection *mongo.Collection
}

func (r *ConfigRepository) FindByKey(ctx context.Context, key string) (*Config, error) {
    var config Config
    err := r.collection.FindOne(ctx, bson.M{"key": key}).Decode(&config)
    return &config, err
}
```

### gRPC Communication

**Service Definition (protos/service.proto):**
- Use protobuf3 syntax
- Keep message definitions focused
- Use enums for status codes
- Always include context propagation

**Client Pattern:**
```go
conn, _ := grpc.Dial("config-server:8081")
client := configpb.NewConfigClient(conn)
config, _ := client.GetConfig(ctx, &configpb.GetConfigRequest{Key: "key"})
```

### Migrations: Atlas

**PostgreSQL (main-server):**
- Migrations in `postgresql/migrations/`
- Run via `./scripts/migrate.sh`
- Always test migrations backward compatibility
- Use named constraints: `CONSTRAINT uc_users_email UNIQUE (email)`

**MongoDB:**
- No structured migrations
- Document schema changes in comments
- Use schema validation if enforcing structure

### Dependencies & Versions

**Core Dependencies:**
```go
github.com/gofiber/fiber/v3       // HTTP framework
github.com/jmoiron/sqlx            // Database access
go.mongodb.org/mongo-driver        // MongoDB driver
google.golang.org/grpc             // gRPC
google.golang.org/protobuf         // Protocol Buffers
github.com/spf13/cobra             // CLI framework
github.com/joho/godotenv          // Environment loading
```

**Development:**
- `cosmtrek/air` - Hot reload
- `golangci/golangci-lint` - Linting
- `golang/mock` - Test mocking

## Code Patterns

### Error Handling

**Custom Error Types in domain/errors.go:**
```go
type AppError struct {
    Code    string
    Message string
    Status  int
    Err     error
}

func (e *AppError) Error() string {
    return e.Message
}
```

**Usage in handlers:**
```go
if err != nil {
    if appErr, ok := err.(*domain.AppError); ok {
        return c.Status(appErr.Status).JSON(appErr)
    }
    return c.Status(500).JSON(fiber.Map{"error": "Internal server error"})
}
```

### Dependency Injection

**Constructor Pattern:**
```go
type UserService struct {
    repo   domain.UserRepository
    cache  *redis.Client
    logger *slog.Logger
}

func NewUserService(repo domain.UserRepository, cache *redis.Client, logger *slog.Logger) *UserService {
    return &UserService{repo: repo, cache: cache, logger: logger}
}
```

**No service locator pattern - always use constructors.**

### Context Propagation

**Always pass context:**
```go
func (s *Service) GetUser(ctx context.Context, id string) (*User, error) {
    // Pass context to all operations
    user, err := s.repo.GetByID(ctx, id)
    // ...
}
```

**Context keys for values:**
```go
type ctxKey string

const (
    userIDKey ctxKey = "user_id"
    traceIDKey ctxKey = "trace_id"
)

ctx = context.WithValue(ctx, userIDKey, userID)
```

### Repository Pattern

**Interface Definition (domain/repositories.go):**
```go
type UserRepository interface {
    GetByID(ctx context.Context, id string) (*User, error)
    Create(ctx context.Context, user *User) error
    Update(ctx context.Context, user *User) error
    Delete(ctx context.Context, id string) error
}
```

**Implementation:**
```go
type PostgresUserRepository struct {
    db *sqlx.DB
}

func (r *PostgresUserRepository) GetByID(ctx context.Context, id string) (*User, error) {
    // Implementation
}
```

### Unit of Work Pattern (Transactions)

**Transaction Helper:**
```go
func (s *Service) TransferSubmission(ctx context.Context, fromID, toID string) error {
    return s.unitOfWork.Do(ctx, func(tx *sqlx.Tx) error {
        // All operations use tx
        if err := s.updateRepo.Update(ctx, tx, submission); err != nil {
            return err // Automatic rollback
        }
        return nil
    })
}
```

## Testing Patterns

### Unit Tests

**Naming Convention: `*_test.go`**
```go
// file: user_service_test.go
func TestUserService_GetByID(t *testing.T) {
    repo := mock.NewMockUserRepository()
    svc := NewUserService(repo)
    
    user, err := svc.GetByID(context.Background(), "123")
    assert.NoError(t, err)
    assert.Equal(t, "123", user.ID)
}
```

### Integration Tests

**Test Database Setup:**
```go
func TestMain(m *testing.M) {
    // Start test database
    db := setupTestDB()
    defer db.Close()
    
    code := m.Run()
    os.Exit(code)
}
```

**Coverage Expectations:**
- Aim for >80% coverage on critical paths
- Focus on error cases and edge conditions
- Test interface implementations, not implementations

### Table-Driven Tests

```go
func TestValidateEmail(t *testing.T) {
    tests := []struct {
        name    string
        email   string
        wantErr bool
    }{
        {"valid email", "user@example.com", false},
        {"invalid email", "invalid", true},
    }
    
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            err := ValidateEmail(tt.email)
            assert.Equal(t, tt.wantErr, err != nil)
        })
    }
}
```

## Development Workflow

### Hot Reload During Development

```bash
# From service directory
cd main-server
air
```

**Configuration (.air.toml):**
- Watches for file changes
- Automatically rebuilds and restarts
- Excludes vendor, node_modules, etc.

### Running Tests

```bash
# All tests
go test ./...

# With coverage
go test -cover ./...

# Verbose output
go test -v ./...

# Specific test
go test -run TestUserService_GetByID ./...
```

### Database Migrations

```bash
# From service root
./scripts/migrate.sh up
./scripts/migrate.sh down
./scripts/migrate.sh status
```

## Common Pitfalls to Avoid

1. **No panic() in production code** - Use proper error handling
2. **No global variables** - Use dependency injection
3. **No context.Background() in requests** - Always pass request context
4. **No N+1 queries** - Use joins or batch operations
5. **No hardcoded values** - Use environment variables or config
6. **No circular imports** - Keep domain layer independent
7. **No goroutine leaks** - Always close channels and cleanup resources

## Performance Considerations

- **Caching**: Use Redis for frequently accessed config
- **Indexing**: Ensure database queries use proper indexes
- **Connection pooling**: Configure DB connection pool size
- **Timeouts**: Set reasonable timeouts on all external calls
- **Batching**: Batch RPC calls when possible

## Security Practices

- **Input validation**: Validate all request inputs
- **SQL injection**: Always use parameterized queries
- **Authentication**: Enforce JWT/OAuth2 on protected endpoints
- **Authorization**: Check permissions for sensitive operations
- **Secrets**: Never commit API keys; use environment variables
- **Rate limiting**: Implement rate limits on public endpoints

---

**When to use this skill:** Use this skill when working on any Go microservice (main-server, config-server, task-server, go-grader). Consult grpc-api-design skill for gRPC specific patterns.
