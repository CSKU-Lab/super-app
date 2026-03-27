---
name: code-sandbox
description: IOI Isolate configuration and safe code execution patterns
license: MIT
compatibility: opencode
metadata:
  audience: experienced-developers
  component: go-grader
  isolation: isolate
---

# Code Sandbox & IOI Isolate

This skill covers IOI Isolate configuration and safe code execution patterns. Use this when working on go-grader workers, configuring sandboxes, or managing code execution security.

## Overview

CSKU Lab uses IOI Isolate for sandboxed code execution. The system prevents malicious code from:
- Accessing the host filesystem
- Consuming excessive resources
- Interfering with other tasks
- Modifying system state

## Architecture

### Components

**Master (go-grader-master, Port 8083):**
- Receives gRPC grading requests
- Queues tasks to RabbitMQ
- Collects results from workers

**Workers (go-grader-worker):**
- Consume tasks from RabbitMQ
- Execute code in Isolate sandbox
- Report execution results

**Isolate Container:**
- Docker image with IOI Isolate
- Privileged mode required
- Mounted volumes for data

### Execution Flow

```
1. Client submits code via main-server
2. main-server → RabbitMQ (queue submission)
3. go-grader-master → RabbitMQ (listen for submissions)
4. Master distributes to available workers
5. Worker → Isolate sandbox (execute code)
6. Isolate → Worker (results: output, exit code, resource usage)
7. Worker → RabbitMQ (send results)
8. Master → main-server → Client (results)
```

## Isolate Configuration

### Directory Structure

```
go-grader/
├── docker/worker/Dockerfile      # Worker image with Isolate
├── isolate-config/
│   └── default.conf              # Isolate sandbox config
├── cmd/
│   ├── master/                   # Master service
│   ├── worker/                   # Worker service
│   └── isolate-runner/           # Isolate CLI wrapper
└── internal/
    ├── execution/                # Execution management
    └── sandbox/                  # Sandbox interface
```

### Resource Limits Configuration

**default.conf:**
```ini
# Memory limit in KB
memLimitInKB = 262144             # 256 MB

# CPU time limit in seconds
cpuTimeLimit = 5                  # 5 seconds

# Wall-clock time limit in seconds
wallTimeLimit = 10                # 10 seconds

# File size limit in bytes
fileSizeLimit = 1048576           # 1 MB

# I/O time limit in seconds
ioTimeLimit = 3                   # 3 seconds

# Number of processes
maxProcesses = 10

# Number of threads per process
maxThreads = 100
```

### Sandbox Directories

**Directory Layout Inside Sandbox:**
```
/
├── tmp/                          # Temporary files
├── var/
│   └── log/                      # Logs (if enabled)
├── home/
│   └── user/
│       ├── input.txt             # Standard input
│       ├── output.txt            # Standard output
│       ├── error.txt             # Standard error
│       └── solution.cpp          # User code
└── etc/
    ├── passwd                    # Minimal passwd
    └── group                     # Minimal group
```

**Mount Points:**
- Read-only: System libraries, compilers
- Read-write: Home directory, temp
- No access: Host filesystem

## Safe Code Execution Patterns

### Execution Steps

1. **Prepare Sandbox**
   - Create isolated filesystem
   - Copy user code
   - Set resource limits

2. **Compile Code** (if needed)
   ```bash
   isolate --box-id=1 --processes --cg-timing \
     -- g++ -o solution solution.cpp
   ```

3. **Run with Input**
   ```bash
   isolate --box-id=1 --stdin=input.txt --stdout=output.txt \
     --time=5 --mem=256 \
     -- ./solution
   ```

4. **Collect Results**
   - Exit code
   - Runtime statistics
   - Output files
   - Error messages

5. **Cleanup**
   - Destroy sandbox
   - Remove isolated filesystem

### Go Implementation Pattern

```go
type SandboxExecutor struct {
    isolateBoxID int
    config       *IsolateConfig
}

func (e *SandboxExecutor) Execute(ctx context.Context, req *ExecuteRequest) (*ExecuteResult, error) {
    // 1. Prepare sandbox
    if err := e.prepareSandbox(); err != nil {
        return nil, err
    }
    defer e.cleanup()
    
    // 2. Copy user code
    if err := e.copyFiles(req.Code, req.Input); err != nil {
        return nil, err
    }
    
    // 3. Compile if needed
    if req.Language == "cpp" {
        if _, err := e.compile(); err != nil {
            return &ExecuteResult{
                Status: StatusCompilationError,
                Error:  err.Error(),
            }, nil
        }
    }
    
    // 4. Execute with timeout
    ctx, cancel := context.WithTimeout(ctx, e.config.WallTimeLimit)
    defer cancel()
    
    result, err := e.run(ctx, req)
    if err != nil {
        return nil, err
    }
    
    // 5. Check exit code and resources
    return e.processResult(result), nil
}
```

## Supported Languages

### Language Specifications

**C++ (gcc/g++)**
```go
{
    Language: "cpp",
    Compiler: "g++",
    Extension: ".cpp",
    CompileCmd: "g++ -O2 -o solution solution.cpp",
    RunCmd: "./solution",
}
```

**Python 3**
```go
{
    Language: "python",
    Compiler: "",  // No compilation
    Extension: ".py",
    RunCmd: "python3 solution.py",
}
```

**Java**
```go
{
    Language: "java",
    Compiler: "javac",
    Extension: ".java",
    CompileCmd: "javac Solution.java",
    RunCmd: "java Solution",
}
```

**JavaScript (Node.js)**
```go
{
    Language: "javascript",
    Compiler: "",
    Extension: ".js",
    RunCmd: "node solution.js",
}
```

## Result Processing

### Execution Status

```go
type ExecutionStatus string

const (
    StatusOK ExecutionStatus = "OK"
    StatusCompilationError ExecutionStatus = "COMPILATION_ERROR"
    StatusRuntimeError ExecutionStatus = "RUNTIME_ERROR"
    StatusTimeLimitExceeded ExecutionStatus = "TIME_LIMIT_EXCEEDED"
    StatusMemoryLimitExceeded ExecutionStatus = "MEMORY_LIMIT_EXCEEDED"
    StatusWrongAnswer ExecutionStatus = "WRONG_ANSWER"
)
```

### Result Structure

```go
type ExecuteResult struct {
    Status        ExecutionStatus
    ExitCode      int
    Output        string
    Error         string
    Time          float64    // seconds
    Memory        int64      // KB
    Verdict       string     // PASS/FAIL/ERROR
}
```

### Result Determination

```go
func (e *SandboxExecutor) determineVerdict(result *ExecuteResult) ExecutionStatus {
    // Check resource limits first
    if result.Time > e.config.CPUTimeLimit {
        return StatusTimeLimitExceeded
    }
    if result.Memory > e.config.MemoryLimitKB {
        return StatusMemoryLimitExceeded
    }
    
    // Then check exit code
    if result.ExitCode != 0 {
        return StatusRuntimeError
    }
    
    // Finally compare output
    if result.Output != expectedOutput {
        return StatusWrongAnswer
    }
    
    return StatusOK
}
```

## Testing the Sandbox

### Manual Testing

```bash
# Create a test directory
mkdir -p /tmp/test_isolate
cd /tmp/test_isolate

# Create test code
cat > solution.cpp << 'EOF'
#include <iostream>
int main() {
    std::cout << "Hello World" << std::endl;
    return 0;
}
EOF

# Create input
echo "test input" > input.txt

# Run with isolate
isolate --box-id=1 \
  --stdin=input.txt \
  --stdout=output.txt \
  --time=5 \
  --mem=256 \
  --processes \
  -- bash -c "g++ -o solution solution.cpp && ./solution"

# Check results
cat output.txt
```

### Integration Testing

```go
func TestSandboxExecution(t *testing.T) {
    executor := NewSandboxExecutor(1, defaultConfig)
    
    result, err := executor.Execute(context.Background(), &ExecuteRequest{
        Language: "cpp",
        Code:     `
            #include <iostream>
            int main() {
                std::cout << "Hello" << std::endl;
                return 0;
            }
        `,
        Input:    "",
        Timeout:  5,
    })
    
    assert.NoError(t, err)
    assert.Equal(t, StatusOK, result.Status)
    assert.Contains(t, result.Output, "Hello")
}
```

## Security Best Practices

### Input Validation

```go
// Limit code size
const maxCodeSize = 1024 * 100  // 100 KB

func (e *SandboxExecutor) validateInput(code string) error {
    if len(code) > maxCodeSize {
        return fmt.Errorf("code too large: %d > %d", len(code), maxCodeSize)
    }
    
    // Check for forbidden patterns
    forbiddenPatterns := []string{
        "system(",
        "exec(",
        "fork(",
        "dlopen(",
    }
    
    for _, pattern := range forbiddenPatterns {
        if strings.Contains(code, pattern) {
            return fmt.Errorf("forbidden function: %s", pattern)
        }
    }
    
    return nil
}
```

### Resource Enforcement

```go
// Always enforce limits
type SandboxConfig struct {
    TimeLimit       time.Duration  // Max 30s
    MemoryLimit     int64          // Max 512MB
    FileSizeLimit   int64          // Max 100MB
    MaxProcesses    int            // Max 10
    MaxThreads      int            // Max 100
}

func NewSandboxConfig() *SandboxConfig {
    return &SandboxConfig{
        TimeLimit:     30 * time.Second,
        MemoryLimit:   512 * 1024 * 1024,
        FileSizeLimit: 100 * 1024 * 1024,
        MaxProcesses:  10,
        MaxThreads:    100,
    }
}
```

### Monitoring Execution

```go
// Track execution metrics
type ExecutionMetrics struct {
    TaskID        string
    Language      string
    Status        ExecutionStatus
    TimeUsed      float64
    MemoryUsed    int64
    OutputSize    int64
    ExecutedAt    time.Time
    Duration      time.Duration
}

func (m *ExecutionMetrics) Log(logger *slog.Logger) {
    logger.Info("execution_completed",
        slog.String("task_id", m.TaskID),
        slog.String("status", string(m.Status)),
        slog.Float64("time_sec", m.TimeUsed),
        slog.Int64("memory_kb", m.MemoryUsed),
    )
}
```

## Troubleshooting

### Isolation Failures

```bash
# Check if isolate is installed
which isolate

# Verify permissions
id  # Should see isolate group

# Test basic isolation
isolate --box-id=1 -- echo "Test"
```

### Resource Limit Issues

```bash
# Increase system limits if needed
ulimit -a

# Common issues:
# - Memory limit too high → OOM
# - Time limit too tight → timeout on slow systems
# - Process limit too low → cannot spawn subprocesses
```

### Sandbox Not Cleaning Up

```bash
# List active boxes
isolate -s

# Destroy specific box
isolate --cleanup --box-id=1

# Destroy all
for i in {1..255}; do
  isolate --cleanup --box-id=$i 2>/dev/null
done
```

## Performance Optimization

### Parallel Execution

Workers can run multiple sandboxes in parallel (different box IDs):

```go
const (
    MaxConcurrentTasks = 10
    BoxIDStart = 1
    BoxIDEnd = 255
)

type WorkerPool struct {
    activeBoxes chan int  // Available box IDs
}

func NewWorkerPool() *WorkerPool {
    pool := make(chan int, MaxConcurrentTasks)
    for i := BoxIDStart; i < BoxIDStart+MaxConcurrentTasks; i++ {
        pool <- i
    }
    return &WorkerPool{activeBoxes: pool}
}
```

### Caching Compiled Code

For repeated language/code combinations:

```go
type CompileCache struct {
    cache map[string]string  // hash -> compiled binary path
    mu    sync.RWMutex
}
```

---

**When to use this skill:** Use this when working on go-grader workers, configuring sandboxes, optimizing code execution, or ensuring security of the grading system.
