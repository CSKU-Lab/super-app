---
name: grpc-api-design
description: gRPC service design and implementation patterns for inter-service communication
license: MIT
compatibility: opencode
metadata:
  audience: experienced-developers
  protocol: grpc
  languages: go,protobuf
---

# gRPC API Design

This skill covers gRPC service design and implementation patterns. Use this when adding new gRPC endpoints, modifying proto definitions, or coordinating communication between services.

## Overview

CSKU Lab uses gRPC for inter-service communication:
- **main-server** calls config-server, task-server, and go-grader
- **go-grader** calls task-server and config-server
- All gRPC services implement request-response patterns
- No streaming APIs currently used

## Protocol Buffer Structure

### Directory Layout

```
service/protos/
├── service.proto           # Main service definition
├── messages.proto          # Shared message types
└── (other supporting protos)

service/genproto/          # Auto-generated Go code
├── servicepb/
│   ├── service_grpc.pb.go
│   ├── service.pb.go
│   └── ...
```

### Naming Conventions

**Proto Files:**
- Use `snake_case` file names: `config_service.proto`
- Each major service gets one proto file
- Shared messages in `messages.proto`

**Package Names:**
```protobuf
package csku.config.v1;  // package namespace.service.version
```

**Service Names:**
```protobuf
service ConfigService {
    rpc GetConfig(GetConfigRequest) returns (GetConfigResponse);
}
```

**Message Names:**
- Requests: `{Verb}{Noun}Request` → `GetConfigRequest`
- Responses: `{Verb}{Noun}Response` → `GetConfigResponse`
- Data: `{Noun}` → `Config`
- Lists: `{Noun}List` or just repeat message

## Proto3 Best Practices

### Message Definition

**Good:**
```protobuf
message Config {
    string key = 1;           // Required identifiers first
    string value = 2;
    int64 created_at = 3;     // Timestamps as int64 (unix millis)
    string description = 4;   // Optional descriptions
}
```

**Avoid:**
- Nested messages (use separate protos)
- Large nested structures
- Optional fields without default values

### Service Definitions

**Standard pattern:**
```protobuf
service ConfigService {
    rpc GetConfig(GetConfigRequest) returns (GetConfigResponse) {}
    rpc CreateConfig(CreateConfigRequest) returns (CreateConfigResponse) {}
    rpc UpdateConfig(UpdateConfigRequest) returns (UpdateConfigResponse) {}
    rpc DeleteConfig(DeleteConfigRequest) returns (DeleteConfigResponse) {}
    rpc ListConfigs(ListConfigsRequest) returns (ListConfigsResponse) {}
}
```

### Error Handling

**Standard error codes (not gRPC codes):**
```protobuf
enum ErrorCode {
    ERROR_CODE_UNSPECIFIED = 0;
    ERROR_CODE_NOT_FOUND = 1;
    ERROR_CODE_INVALID_ARGUMENT = 2;
    ERROR_CODE_INTERNAL = 3;
    ERROR_CODE_UNAUTHORIZED = 4;
}

message ErrorDetails {
    ErrorCode code = 1;
    string message = 2;
    string details = 3;
}

message GetConfigResponse {
    oneof result {
        Config config = 1;
        ErrorDetails error = 2;
    }
}
```

## Service Implementation

### Go Server Implementation

**Structure:**
```go
type server struct {
    configpb.UnimplementedConfigServiceServer
    repo   domain.ConfigRepository
    cache  *redis.Client
}

func (s *server) GetConfig(ctx context.Context, req *configpb.GetConfigRequest) (*configpb.GetConfigResponse, error) {
    // Validate request
    if req.Key == "" {
        return nil, status.Error(codes.InvalidArgument, "key is required")
    }
    
    // Call business logic
    config, err := s.repo.GetByKey(ctx, req.Key)
    if err != nil {
        return nil, status.Error(codes.Internal, "failed to get config")
    }
    
    return &configpb.GetConfigResponse{
        Config: &configpb.Config{
            Key:   config.Key,
            Value: config.Value,
        },
    }, nil
}
```

### Error Handling in gRPC

**Standard Error Codes:**
- `codes.InvalidArgument` - Invalid request parameter
- `codes.NotFound` - Resource not found
- `codes.Internal` - Server error
- `codes.Unavailable` - Service temporarily unavailable
- `codes.Unauthenticated` - Authentication failed

**Pattern:**
```go
if notFound {
    return nil, status.Error(codes.NotFound, "config not found")
}

if validationErr {
    return nil, status.Error(codes.InvalidArgument, "invalid config key")
}

if internalErr {
    return nil, status.Error(codes.Internal, "internal server error")
}
```

### Client Implementation

**Connection Management:**
```go
// In main or service initialization
conn, err := grpc.Dial(
    "config-server:8081",
    grpc.WithTransportCredentials(insecure.NewCredentials()),
    grpc.WithDefaultCallOptions(
        grpc.MaxCallRecvMsgSize(1024*1024*100), // 100MB
    ),
)
if err != nil {
    log.Fatalf("failed to dial: %v", err)
}
defer conn.Close()

client := configpb.NewConfigServiceClient(conn)
```

**Making Requests:**
```go
ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
defer cancel()

resp, err := client.GetConfig(ctx, &configpb.GetConfigRequest{
    Key: "grader_timeout",
})
if err != nil {
    if st, ok := status.FromError(err); ok {
        switch st.Code() {
        case codes.NotFound:
            log.Println("Config not found")
        case codes.Internal:
            log.Println("Server error")
        }
    }
}
```

## Versioning Strategy

### API Versions

**Current approach:**
- Single version in package: `csku.config.v1`
- No multiple versions in production (upgrade all services together)
- Major changes: Deprecate old API, add new API alongside

**If versioning becomes necessary:**
```protobuf
// Old API (v1)
rpc GetConfig(GetConfigRequest) returns (GetConfigResponse) {}

// New API (v2) - added alongside for transition period
rpc GetConfigV2(GetConfigV2Request) returns (GetConfigV2Response) {}
```

### Backward Compatibility

**Rules:**
- Never remove fields
- Never change field numbers
- Only add new optional fields
- Use reserved keywords for deprecated fields:

```protobuf
message Config {
    string key = 1;
    string value = 2;
    reserved 3;  // deprecated: old_field
    reserved "old_field";
    int64 created_at = 4;
}
```

## Testing gRPC Services

### Unit Tests with Mock Server

```go
func TestGetConfig(t *testing.T) {
    // Create test server
    lis, _ := net.Listen("tcp", "localhost:0")
    s := grpc.NewServer()
    
    mockServer := &server{
        repo: mock.NewMockConfigRepository(),
    }
    configpb.RegisterConfigServiceServer(s, mockServer)
    go s.Serve(lis)
    defer s.Stop()
    
    // Create client
    conn, _ := grpc.Dial(lis.Addr().String(), grpc.WithInsecure())
    client := configpb.NewConfigServiceClient(conn)
    
    // Test
    resp, err := client.GetConfig(context.Background(), &configpb.GetConfigRequest{Key: "test"})
    assert.NoError(t, err)
    assert.NotNil(t, resp)
}
```

### Integration Tests

```go
func TestGetConfig_Integration(t *testing.T) {
    // Use real service connection
    conn, _ := grpc.Dial("localhost:8081", grpc.WithInsecure())
    client := configpb.NewConfigServiceClient(conn)
    
    resp, err := client.GetConfig(context.Background(), &configpb.GetConfigRequest{Key: "real_key"})
    assert.NoError(t, err)
}
```

## Common Patterns

### Pagination

```protobuf
message ListConfigsRequest {
    int32 page = 1;       // 1-indexed
    int32 page_size = 2;  // 10-100
}

message ListConfigsResponse {
    repeated Config configs = 1;
    int32 total_count = 2;
    int32 current_page = 3;
    int32 total_pages = 4;
}
```

### Filtering

```protobuf
message ListConfigsRequest {
    string filter = 1;  // JSON filter: {"status": "active"}
    int32 page = 2;
    int32 page_size = 3;
}
```

### Metadata/Headers

```go
// Client sending metadata
header := metadata.Pairs(
    "authorization", "Bearer token123",
    "x-request-id", "req-123",
)
ctx = metadata.NewOutgoingContext(context.Background(), header)

// Server receiving metadata
md, ok := metadata.FromIncomingContext(ctx)
if ok {
    auth := md.Get("authorization")
}
```

## Code Generation

### Generating Go Code

**From service root:**
```bash
# Install protoc compiler and plugins
brew install protobuf
go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest

# Generate code
protoc --go_out=. --go_opt=paths=source_relative \
       --go-grpc_out=. --go-grpc_opt=paths=source_relative \
       protos/config_service.proto
```

### Generated Files

- `*.pb.go` - Protocol buffer message definitions
- `*_grpc.pb.go` - gRPC service interface and client stubs

**Never edit generated files directly** - regenerate from proto files.

## Performance Considerations

### Connection Pooling

```go
// Reuse connections!
conn := grpc.Dial("config-server:8081")  // Do this once
client1 := configpb.NewConfigServiceClient(conn)
client2 := configpb.NewConfigServiceClient(conn)
```

### Message Size Limits

```go
conn, _ := grpc.Dial(
    "config-server:8081",
    grpc.WithDefaultCallOptions(
        grpc.MaxCallRecvMsgSize(1024*1024*100),  // 100MB
        grpc.MaxCallSendMsgSize(1024*1024*100),  // 100MB
    ),
)
```

### Timeouts

```go
ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
defer cancel()
resp, err := client.GetConfig(ctx, &configpb.GetConfigRequest{})
```

## Security

### TLS in Production

```go
creds, _ := credentials.NewClientTLSFromFile("cert.pem", "server.example.com")
conn, _ := grpc.Dial("config-server:8081", grpc.WithTransportCredentials(creds))
```

### Authentication via Metadata

```go
// Server-side interceptor
func authInterceptor(ctx context.Context, req interface{}, info *grpc.UnaryServerInfo, handler grpc.UnaryHandler) (interface{}, error) {
    md, ok := metadata.FromIncomingContext(ctx)
    if !ok {
        return nil, status.Error(codes.Unauthenticated, "missing metadata")
    }
    // Verify token in md.Get("authorization")
    return handler(ctx, req)
}

s := grpc.NewServer(grpc.UnaryInterceptor(authInterceptor))
```

---

**When to use this skill:** Use this when designing new gRPC services, adding endpoints, modifying message structures, or implementing gRPC clients across services.
