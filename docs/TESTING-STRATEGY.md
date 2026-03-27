# Testing Strategy for AI Agent Team

This document outlines testing patterns, fixtures, and integration test setup.

## Testing Philosophy

**Coverage Goal**: >80% for all new code

**Types of Tests**:
1. **Unit Tests**: Mocked dependencies, fast execution
2. **Integration Tests**: Real databases/services, slower but comprehensive
3. **Component Tests** (Frontend): Real DOM, user interactions

## Unit Testing Pattern (Go Services)

### Mock Repository

```go
type MockUserRepository struct {
    mock.Mock
}

func (m *MockUserRepository) GetByID(ctx context.Context, id string) (*domain.User, error) {
    args := m.Called(ctx, id)
    if args.Get(0) == nil {
        return nil, args.Error(1)
    }
    return args.Get(0).(*domain.User), args.Error(1)
}
```

### Unit Test Example

```go
func TestUserService_GetUser_Success(t *testing.T) {
    mockRepo := new(MockUserRepository)
    mockRepo.On("GetByID", mock.Anything, "123").Return(
        &domain.User{ID: "123", Name: "John", Email: "john@example.com"},
        nil,
    )
    
    service := services.NewUserService(mockRepo)
    user, err := service.GetUser(context.Background(), "123")
    
    assert.NoError(t, err)
    assert.Equal(t, "John", user.Name)
    mockRepo.AssertExpectations(t)
}
```

## Integration Testing Pattern (Go Services)

### TestContainers Setup

```go
func setupTestDatabase(t *testing.T) *sqlx.DB {
    ctx := context.Background()
    
    req := testcontainers.ContainerRequest{
        Image:        "postgres:15",
        ExposedPorts: []string{"5432/tcp"},
        Env: map[string]string{
            "POSTGRES_PASSWORD": "test",
            "POSTGRES_DB":       "test_db",
        },
        WaitingFor: wait.ForLog("database system is ready to accept connections"),
    }
    
    container, err := testcontainers.GenericContainer(ctx,
        testcontainers.GenericContainerRequest{
            ContainerRequest: req,
            Started:         true,
        })
    require.NoError(t, err)
    
    t.Cleanup(func() {
        container.Terminate(ctx)
    })
    
    host, _ := container.Host(ctx)
    port, _ := container.MappedPort(ctx, "5432")
    dsn := fmt.Sprintf("postgres://postgres:test@%s:%s/test_db?sslmode=disable",
        host, port.Port())
    
    db, err := sqlx.Connect("postgres", dsn)
    require.NoError(t, err)
    
    // Run migrations
    runMigrations(t, db)
    
    return db
}
```

### Integration Test Example

```go
func TestUserRepository_GetByID_Integration(t *testing.T) {
    db := setupTestDatabase(t)
    defer db.Close()
    
    // Seed test data
    seedDatabase(t, db, fixtures.SeedUsers)
    
    repo := repositories.NewUserRepository(db)
    user, err := repo.GetByID(context.Background(), "user-001")
    
    assert.NoError(t, err)
    assert.Equal(t, "Alice", user.Name)
    assert.Equal(t, "alice@example.com", user.Email)
}
```

## Test Fixtures

```go
// tests/fixtures/users.go
package fixtures

var SeedUsers = []domain.User{
    {
        ID:    "user-001",
        Email: "alice@example.com",
        Name:  "Alice",
        Role:  "instructor",
    },
    {
        ID:    "user-002",
        Email: "bob@example.com",
        Name:  "Bob",
        Role:  "student",
    },
}

func SeedDatabase(t *testing.T, db *sqlx.DB, users []domain.User) {
    for _, user := range users {
        _, err := db.Exec(
            "INSERT INTO users (id, email, name, role) VALUES ($1, $2, $3, $4)",
            user.ID, user.Email, user.Name, user.Role)
        require.NoError(t, err)
    }
}
```

## Mock gRPC Stubs

```go
// tests/mocks/config_service.go
package mocks

type MockConfigServiceClient struct {
    mock.Mock
}

func (m *MockConfigServiceClient) GetConfig(ctx context.Context, 
    in *pb.ConfigRequest, opts ...grpc.CallOption) (*pb.ConfigResponse, error) {
    args := m.Called(ctx, in)
    if args.Get(0) == nil {
        return nil, args.Error(1)
    }
    return args.Get(0).(*pb.ConfigResponse), args.Error(1)
}

// Usage in tests
func TestServiceWithMockDependency(t *testing.T) {
    mockConfigClient := new(MockConfigServiceClient)
    mockConfigClient.On("GetConfig", mock.Anything, mock.Anything).Return(
        &pb.ConfigResponse{Value: "test-value"},
        nil,
    )
    
    service := services.NewMainService(mockConfigClient)
    // ... test implementation
}
```

## Frontend Component Testing (React)

```tsx
// app/components/UserProfile.test.tsx
import React from 'react';
import { render, screen, waitFor } from '@testing-library/react';
import '@testing-library/jest-dom';
import { UserProfile } from './UserProfile';
import * as api from '@/lib/api';

jest.mock('@/lib/api');

describe('UserProfile', () => {
  it('should display loading spinner while fetching', () => {
    (api.getUserProfile as jest.Mock).mockImplementation(
      () => new Promise(() => {})
    );
    
    render(<UserProfile userId="123" />);
    expect(screen.getByTestId('loading-spinner')).toBeInTheDocument();
  });

  it('should display user profile when loaded', async () => {
    const mockUser = {
      id: '123',
      name: 'John',
      email: 'john@example.com',
      role: 'student',
      createdAt: '2024-01-01',
      updatedAt: '2024-01-01',
    };

    (api.getUserProfile as jest.Mock).mockResolvedValue(mockUser);

    render(<UserProfile userId="123" />);

    await waitFor(() => {
      expect(screen.getByText('John')).toBeInTheDocument();
    });
  });
});
```

## Coverage Validation

```bash
# Go Services
cd main-server && go test -cover -v ./...

# Output: coverage: 85.2% of statements

# Detailed coverage report
go test -coverprofile=coverage.out ./...
go tool cover -html=coverage.out  # Opens in browser

# Frontend
cd web && npm test -- --coverage

# Output:
# Statements   : 85.2% ( 512/600 )
# Branches     : 78.5% ( 157/200 )
# Functions    : 82.1% ( 123/150 )
# Lines        : 85.5% ( 513/600 )
```

## Testing Checklist by Service

### Go Services (Unit + Integration)

- [ ] Unit tests for all public functions
- [ ] Mocked repositories in unit tests
- [ ] Integration tests with testcontainers
- [ ] Error scenarios covered
- [ ] Edge cases tested
- [ ] >80% coverage for new code
- [ ] No test interdependencies
- [ ] Fixtures for consistent test data

### Frontend (Component + Unit)

- [ ] Component renders correctly
- [ ] Loading states handled
- [ ] Error states displayed
- [ ] User interactions trigger callbacks
- [ ] API calls mocked
- [ ] Form validation works
- [ ] Responsive design verified
- [ ] >80% coverage for new code

### Database (Migration + Fixture)

- [ ] Migration creates proper schema
- [ ] Constraints enforced
- [ ] Indexes present
- [ ] Fixtures can seed data
- [ ] No orphaned foreign keys
- [ ] Backward compatibility verified

## Common Testing Issues

### N+1 Query Problem

```go
// ❌ BAD - N+1 queries
users := repo.GetAllUsers(ctx)
for _, user := range users {
    assignments := repo.GetAssignmentsByUserID(ctx, user.ID)
}

// ✅ GOOD - Single join query
users := repo.GetUsersWithAssignments(ctx)
```

### Test Data Pollution

```go
// ✅ GOOD - Use setup/teardown
func TestSomething(t *testing.T) {
    db := setupTestDatabase(t)
    defer db.Close()  // Cleanup happens automatically
    
    // Test runs with clean database
}
```

### Flaky Tests

```go
// ❌ BAD - Race conditions
func TestAsync(t *testing.T) {
    go doSomethingAsync()
    time.Sleep(1 * time.Second)  // Flaky!
}

// ✅ GOOD - Use wait/assert patterns
func TestAsync(t *testing.T) {
    ch := make(chan string)
    go doSomethingAsync(ch)
    result := <-ch  // Wait for actual result
    assert.Equal(t, expected, result)
}
```

## Coverage Report Generation

```bash
# Go services
go test ./... -coverprofile=coverage.out
go tool cover -html=coverage.out -o coverage.html

# Frontend
npm test -- --coverage --watchAll=false

# Generate combined report
cat coverage.out | go tool cover -html=/dev/stdin
```

## Performance Considerations

- Unit tests: <100ms per test
- Integration tests: <5 seconds per test
- Component tests: <200ms per test
- Total test suite: <5 minutes

If tests slow: Profile with `-cpuprofile` and optimize hot paths

---

**Next**: See specific agent prompts for service-specific testing patterns
