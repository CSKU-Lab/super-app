---
name: code-sandbox
description: IOI Isolate wrapper implementation and safe code execution patterns
license: MIT
compatibility: opencode
metadata:
  audience: experienced-developers
  component: go-grader
  files: isolate.go, executor.go
---

# Code Sandbox & IOI Isolate Wrapper

This skill covers the CSKU Lab wrapper implementation around IOI Isolate for sandboxed code execution. Use this when working on go-grader's isolate wrapper, executor patterns, or managing code execution security.

## Overview

The CSKU Lab isolate wrapper (in `go-grader/domain/services/isolate.go`) provides a safe, managed interface for executing code in isolated sandboxes using IOI Isolate. It manages:
- Isolate box lifecycle (init, cleanup, reuse)
- Resource limits (time, memory, processes)
- File operations within sandboxes
- Compilation and execution of code
- Metadata extraction from execution results

## Architecture

### Components

**IsolateService** (`isolate.go:17-42`):
- Manages two pools of isolate boxes: **run pool** and **grade pool**
- Run pool: For simple code execution without test cases
- Grade pool: For grading with multiple test cases (sized 2x the concurrency limit)
- Box IDs are pre-allocated in channels for reuse without recreation

**IsolateInstance** (`isolate.go:44-51`):
- Single sandbox instance wrapper
- Manages box paths, metadata paths, and cleanup
- Provides methods for file operations, compilation, and execution
- Handles all isolate CLI invocations via `execute()` wrapper

**ExecutorService** (`executor.go:16-34`):
- Builder pattern for configurable execution
- Supports both simple `Run()` and complex `Grade()` with test cases
- Manages runner and compare service references

### Box ID Allocation

```
Run Pool:     0 to (runQueueAmount - 1)
Grade Pool:   runQueueAmount to (runQueueAmount + gradePoolSize - 1)
              where gradePoolSize = gradeQueueAmount * 2
```

Example with `runQueueAmount=5, gradeQueueAmount=10`:
- Run boxes: 0-4 (5 boxes)
- Grade boxes: 5-24 (20 boxes for parallel test case execution)
- Total: 25 boxes

## IsolateService Implementation

### Creating Instances

```go
// From IsolateService (in isolate.go:53-81)
service := NewIsolateService(logger, runQueueAmount, gradeQueueAmount)

// Allocate from run pool
runInstance := service.NewRunInstance()    // Gets box ID from runBoxIds channel

// Allocate from grade pool
gradeInstance := service.NewGradeInstance() // Gets box ID from gradeBoxIds channel
```

**Important:** Box IDs are blocking channel operations. If all boxes are in use, allocation will block until one is returned to the pool.

### Instance Lifecycle

```go
// 1. Initialize the sandbox
instance.Init(ctx)

// 2. Create files in sandbox
instance.CreateFile("solution.cpp", code, 0644)
instance.CreateDir("src", 0755)

// 3. Compile if needed
if needsCompile {
    output, err := instance.Compile(ctx)        // Uses default build_script.sh
    // OR
    output, err := instance.CompileUsing(ctx, scriptDir)  // Custom script path
}

// 4. Run the code
output, err := instance.Run(ctx, scriptDir, input, limits)
// OR with custom path
output, err := instance.RunFromDir(ctx, scriptDir, input, limits)

// 5. Get metadata
metadata, err := instance.GetMetadata()  // Read from metadata file

// 6. Cleanup (MUST ALWAYS DO THIS)
instance.Cleanup()  // Returns box ID to pool, must use background context
```

**Critical:** Always call `Cleanup()` in a defer, even if errors occur. It returns the box ID to the pool for reuse.

## Resource Limits

Limits are defined as a struct and passed to `Run()` or `RunFromDir()`:

```go
type Limit struct {
    TimeLimit    int   `arg:"--time"`       // CPU time in seconds
    WallTimeLimit int   `arg:"--wall-time"` // Wall-clock time in seconds
    Memory       int   `arg:"--mem"`        // Memory in KB
    Stack        int   `arg:"--stack"`      // Stack size in KB
    FileSizeLimit int   `arg:"--fsize"`     // File size limit in bytes
    DiskQuota    int   `arg:"--quota"`      // Disk quota in MB
}
```

Limit flags are dynamically generated via reflection (see `getLimitArgs()` in isolate.go:302-335). Zero values are skipped.

Example:
```go
limits := &models.Limit{
    TimeLimit: 5,        // 5 seconds CPU time
    Memory: 262144,      // 256 MB
    FileSizeLimit: 1048576,  // 1 MB
}

output, err := instance.RunFromDir(ctx, scriptDir, input, limits)
```

## Execution Flow

### Simple Run (without grading)

```go
// From run_test.go (TestRunPassed)
executor, status := executorService.NewExecutor().
    RunnerID("python_test").
    Files([]models.File{
        {Name: "main.py", Content: `print("Hello World")`},
    }).
    Build()

result, err := executor.Run(context.Background())
// Returns RunResult with Status, Output, WallTime, Memory
```

**Execution steps:**
1. Get run instance from pool
2. Init sandbox
3. Create user files
4. Compile if needed (check runner.NeedCompile)
5. Run with RunFromDir()
6. Extract metadata
7. Cleanup and return box to pool

### Grade with Test Cases (parallel execution)

```go
// From executor.go Grade() method
result, err := executor.Grade(ctx)
// Returns GradeResult with TestCaseGroupResults, Score, AvgWallTime, AvgMemory
```

**Execution flow:**
1. For each TestCaseGroup (parallel via errgroup):
   - For each TestCase (parallel via errgroup):
     - Get grade instance
     - Init, create files, compile, run with test input
     - Get metadata
     - Compare output against expected output
     - Cleanup and return box
2. Aggregate results and calculate total score
3. Return GradeResult

**Parallelism:** Test cases within a group run concurrently. Grade pool (2x larger) handles this concurrency.

## Metadata Extraction

After execution, extract results via metadata file:

```go
metadata, err := instance.GetMetadata()

// Available fields:
// - WallTime (float32): Real elapsed time in seconds
// - Memory (int32): Peak memory usage in KB
// - FailedStatus (string): Execution error, if any
//   "TO" = timeout
//   "RE" = runtime error
//   "SG" = signal error
//   "XX" = other error
```

Interpretation in executor.go:390-423:
```go
status := execution.RUN_PASSED
if metadata.FailedStatus != "" {
    switch metadata.FailedStatus {
    case "TO": status = execution.TIME_LIMIT_EXCEEDED
    case "RE": status = execution.RUNTIME_ERROR
    case "SG": status = execution.SIGNAL_ERROR
    case "XX": status = execution.GRADER_ERROR
    }
}

// Check memory limit separately
if limits.Memory != 0 && metadata.Memory > limits.Memory {
    status = execution.MEMORY_LIMIT_EXCEEDED
}
```

## ExecutorBuilder Pattern

The executor uses a builder pattern for flexible configuration:

```go
executor, err := executorService.NewExecutor().
    RunnerID("python_test").                    // Runner type (defines compile/run scripts)
    Files([]models.File{...}).                  // Source files to copy
    Input("test input").                         // Stdin for program
    Limits(&models.Limit{...}).                 // Resource constraints
    TestCaseGroups([]models.TestCaseGroup{...}). // For grading
    CompareID("exact_match").                   // For comparing outputs
    Build()

if err != nil {
    // Handle build error (runner not found, compare not found, etc.)
}

// Then either:
result, err := executor.Run(ctx)      // Simple execution
// OR
result, err := executor.Grade(ctx)    // Grading with test cases
```

## Isolate-Docker Integration

The isolate-docker repository provides the Docker image:

```bash
# Build the isolate image
docker build -t ioi/isolate .

# Run with config mount
docker run -v ./config:/usr/local/etc/isolate -it ioi/isolate
```

The `with-compilers/` variant includes language toolchains (gcc, python, etc.) for the image. Worker containers run with:
- `privileged: true` (required for Isolate)
- Isolate binary available in PATH
- Config mounted from `isolate-config/`

## Testing Integration

Integration tests show real usage patterns:

```go
// Test 1: Simple execution (run_test.go:11-35)
TestRunPassed() - Hello World via Python

// Test 2: With input (run_test.go:37-67)
TestRunWithInput() - Echo program with stdin

// Test 3: Compilation errors (run_test.go:69-98)
TestRunCompileFailed() - Invalid C++ syntax

// Test 4: Runtime errors (run_test.go:100-129)
TestRunFailed() - Python syntax error
```

Run tests via:
```bash
cd go-grader
go test ./tests/integration -v
```

## Common Patterns

### Pattern 1: Simple Code Execution

```go
executor, _ := executorService.NewExecutor().
    RunnerID("python_test").
    Files(files).
    Input(input).
    Build()

result, _ := executor.Run(ctx)
// Handle result.Status, result.Output
```

### Pattern 2: Grading with Limits

```go
executor, _ := executorService.NewExecutor().
    RunnerID("cpp_test").
    Files(userFiles).
    Limits(&models.Limit{TimeLimit: 5, Memory: 262144}).
    TestCaseGroups(testGroups).
    CompareID("exact_match").
    Build()

result, _ := executor.Grade(ctx)
// Handle result.Score, result.TestCaseGroupResults
```

### Pattern 3: Custom Compile Script

```go
instance := service.NewRunInstance()
instance.Init(ctx)
defer instance.Cleanup()

instance.CreateFile("solution.cpp", code, 0644)

// Use custom compilation script
output, err := instance.CompileUsing(ctx, "/path/to/custom/scripts")
output, err := instance.RunFromDir(ctx, "/path/to/custom/scripts", input, limits)
```

## Error Handling

Exit code 127 indicates the command passed to isolate doesn't exist:

```go
output, err := instance.Run(ctx, ...)
if err != nil {
    var exitErr *exec.ExitError
    if errors.As(err, &exitErr) {
        if exitErr.ExitCode() == 127 {
            // Command (e.g., run_script.sh) not found in sandbox
        }
    }
}
```

## Troubleshooting

### Box Pool Exhaustion

If all boxes are in use, `NewRunInstance()` or `NewGradeInstance()` will block. Monitor:
- Pool size configuration (runQueueAmount, gradeQueueAmount)
- Cleanup calls (ensure defer statements execute)
- Hanging instances (check logs for incomplete cleanups)

### Compilation Failures

Check compilation output:
```go
output, err := instance.Compile(ctx)
if err != nil {
    // output contains compiler error messages
}
```

Build script must exist at expected path in sandbox.

### Memory/Time Limit Exceeded

Verify limits are set and metadata is extracted correctly:
```go
metadata, _ := instance.GetMetadata()
if metadata.FailedStatus == "TO" { // Timeout
    // Time limit exceeded
}
```

### File Creation Errors

Box path must exist after Init():
```go
err := instance.CreateFile(name, content, 0644)
// Verifies: instance.boxPath/<name> can be written
```

---

**When to use this skill:** Use when working on go-grader's executor, isolate wrapper, improving parallelism, or debugging code execution issues.
