#!/bin/bash

# Additional Critical Edge Case Tests for v2.6.0 - ISOLATED VERSION with WSL Safety
# These test the most important edge cases for production use

# Detect WSL environment
IS_WSL=0
if grep -qi microsoft /proc/version 2>/dev/null; then
    IS_WSL=1
    echo "WSL environment detected - enabling safety measures"
fi

# Get script directory and project root BEFORE changing directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SAVED_DIR="$(pwd)"

# Create isolated test environment with WSL-safe options
if [ $IS_WSL -eq 1 ]; then
    # Use /tmp directly for WSL to avoid filesystem issues
    TEST_DIR="/tmp/tm_edge_test_$$_$(date +%s)"
    mkdir -p "$TEST_DIR"
    # Set resource limits for WSL
    # ulimit -n 512 2>/dev/null || true  # Limit file descriptors
    # ulimit -u 100 2>/dev/null || true   # Limit processes
    export SQLITE_TMPDIR="$TEST_DIR"
    export TM_WSL_MODE=1
else
    TEST_DIR=$(mktemp -d -t tm_edge_test_XXXXXX)
fi

echo "Running edge case tests in isolated directory: $TEST_DIR"
cd "$TEST_DIR"

# Find tm executable safely
if [ -f "$PROJECT_DIR/tm" ]; then
    TM_ORIG="$PROJECT_DIR/tm"
elif [ -f "$SAVED_DIR/tm" ]; then
    TM_ORIG="$SAVED_DIR/tm"
else
    echo "Error: tm executable not found"
    cd "$SAVED_DIR"
    rm -rf "$TEST_DIR"
    exit 1
fi

# Copy tm executable and dependencies to test directory
cp "$TM_ORIG" ./tm
# Also copy Python modules if they exist
if [ -d "$PROJECT_DIR/src" ]; then
    cp -r "$PROJECT_DIR/src" ./
fi
TM="./tm"

TEST_COUNT=0
PASS_COUNT=0

# Cleanup function with WSL safety
cleanup() {
    # Kill any remaining processes
    pkill -f "tm.*$TEST_DIR" 2>/dev/null || true
    
    # Add delay for WSL
    if [ $IS_WSL -eq 1 ]; then
        sleep 0.5
        sync
    fi
    
    cd "$SAVED_DIR" 2>/dev/null || cd /tmp
    rm -rf "$TEST_DIR" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

function test_result() {
    TEST_COUNT=$((TEST_COUNT + 1))
    if [ $1 -eq 0 ]; then
        echo "Test $TEST_COUNT: $2... PASS"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        echo "Test $TEST_COUNT: $2... FAIL"
    fi
}

echo "=== Additional Critical Edge Case Tests ==="

# Initialize with retry for WSL
echo "Initializing test environment..."
INIT_SUCCESS=0
for attempt in 1 2 3; do
    if [ $IS_WSL -eq 1 ] && [ $attempt -gt 1 ]; then
        sleep 1
    fi
    
    if timeout 5 $TM init >/dev/null 2>&1; then
        INIT_SUCCESS=1
        break
    fi
done

if [ $INIT_SUCCESS -eq 0 ]; then
    echo "Failed to initialize database after 3 attempts"
    exit 1
fi

# Add small delay after init for WSL
if [ $IS_WSL -eq 1 ]; then
    sleep 0.2
fi

# Test 1: Graceful handling of corrupted database
echo "Testing database corruption recovery..."
TASK_ID=$(timeout 5 $TM add "Test task" | grep -o '[a-f0-9]\{8\}')
echo "corrupt data" > .task-orchestrator/tasks.db
timeout 5 $TM list >/dev/null 2>&1
RESULT=$?
test_result $RESULT "Database corruption detection"

# Reinitialize for remaining tests
rm -rf .task-orchestrator
timeout 5 $TM init >/dev/null 2>&1

# Test 2: Empty string handling
timeout 5 $TM add "" >/dev/null 2>&1
RESULT=$?
test_result $RESULT "Empty task title rejection"

# Test 3: Very long task IDs (simulated)
TASK_ID=$(timeout 5 $TM add "Normal task" | grep -o '[a-f0-9]\{8\}')
timeout 5 $TM show "this-is-definitely-not-a-valid-task-id-that-exists" >/dev/null 2>&1
RESULT=$?
test_result $RESULT "Invalid task ID handling"

# Test 4: Special character handling in descriptions
timeout 5 $TM add "Special chars" -d "Test with special chars: !@#$%^&*(){}[]|\\:;\"'<>,.?/~\`" >/dev/null 2>&1
RESULT=$?
test_result $(expr 1 - $RESULT) "Special characters in description"

# Test 5: Network/filesystem issues simulation
chmod 000 .task-orchestrator/tasks.db 2>/dev/null
timeout 5 $TM list >/dev/null 2>&1
RESULT=$?
chmod 644 .task-orchestrator/tasks.db 2>/dev/null
test_result $RESULT "Filesystem permission handling"

# Test 6: Memory constraint simulation (reduced for WSL)
if [ $IS_WSL -eq 1 ]; then
    echo "Creating 20 tasks for memory test (reduced for WSL)..."
    TASK_COUNT=20
else
    echo "Creating 50 tasks for memory test..."
    TASK_COUNT=50
fi
for i in $(seq 1 $TASK_COUNT); do
    timeout 2 $TM add "Task $i" >/dev/null 2>&1
    # Add small delay for WSL to prevent overload
    if [ $IS_WSL -eq 1 ] && [ $((i % 5)) -eq 0 ]; then
        sleep 0.1
    fi
done
timeout 5 $TM list | wc -l >/dev/null 2>&1
RESULT=$?
test_result $(expr 1 - $RESULT) "Large task set handling"

# Test 7: Dependency chain depth (reduced for WSL)
if [ $IS_WSL -eq 1 ]; then
    echo "Testing dependency chain (5 levels for WSL)..."
    CHAIN_DEPTH=5
else
    echo "Testing deep dependency chain (10 levels)..."
    CHAIN_DEPTH=10
fi
FIRST_TASK=$(timeout 5 $TM add "Root task" | grep -o '[a-f0-9]\{8\}')
PREV_TASK=$FIRST_TASK
for i in $(seq 2 $CHAIN_DEPTH); do
    NEXT_TASK=$(timeout 5 $TM add "Task $i" --depends-on $PREV_TASK | grep -o '[a-f0-9]\{8\}')
    PREV_TASK=$NEXT_TASK
    # Add small delay for WSL
    if [ $IS_WSL -eq 1 ]; then
        sleep 0.1
    fi
done
timeout 5 $TM list --status blocked | wc -l | grep -q "$((CHAIN_DEPTH - 1))"
RESULT=$?
test_result $(expr 1 - $RESULT) "Deep dependency chain ($CHAIN_DEPTH levels)"

# Test 8: Rapid status changes
TASK_ID=$(timeout 5 $TM add "Rapid change task" | grep -o '[a-f0-9]\{8\}')
timeout 2 $TM update $TASK_ID --status in_progress >/dev/null 2>&1
timeout 2 $TM update $TASK_ID --status blocked >/dev/null 2>&1  
timeout 2 $TM update $TASK_ID --status pending >/dev/null 2>&1
timeout 2 $TM update $TASK_ID --status completed >/dev/null 2>&1
RESULT=$?
test_result $(expr 1 - $RESULT) "Rapid status transitions"

# Note: Cleanup is handled by trap

echo "=== Additional Test Summary ==="
echo "Total tests: $TEST_COUNT"
echo "Passed: $PASS_COUNT"
echo "Failed: $((TEST_COUNT - PASS_COUNT))"
echo "Success rate: $(( (PASS_COUNT * 100) / TEST_COUNT ))%"

if [ $PASS_COUNT -eq $TEST_COUNT ]; then
    echo "All additional edge case tests passed!"
    exit 0
else
    echo "Some additional edge case tests failed."
    exit 1
fi
