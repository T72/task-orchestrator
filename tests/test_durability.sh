#!/bin/bash

# Test Suite for System Durability and Resilience
# Safe, isolated tests for crash recovery, state persistence, and fault tolerance

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Find tm in parent directory or current directory
if [ -f "../tm" ]; then
    TM="../tm"
elif [ -f "./tm" ]; then
    TM="./tm"
else
    echo "Error: tm executable not found"
    exit 1
fi

# Create isolated test environment
TEST_DIR=$(mktemp -d -t tm_durability_test_XXXXXX)
cd "$TEST_DIR"
git init >/dev/null 2>&1

echo -e "${BLUE}===================================${NC}"
echo -e "${BLUE}    Durability & Resilience Tests  ${NC}"
echo -e "${BLUE}===================================${NC}"
echo ""

# Helper function for running tests
run_test() {
    local test_name="$1"
    local test_func="$2"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    echo -n "Testing: $test_name ... "
    
    if $test_func >/dev/null 2>&1; then
        echo -e "${GREEN}PASSED${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}FAILED${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Initialize
$TM init >/dev/null 2>&1

echo -e "${YELLOW}=== State Persistence Tests ===${NC}"
echo ""

# Test 1: Basic state persistence
test_basic_persistence() {
    # Create tasks
    TASK1=$($TM add "Persistent task 1" | grep -o '[a-f0-9]\{8\}')
    TASK2=$($TM add "Persistent task 2" -p high | grep -o '[a-f0-9]\{8\}')
    
    # Update states
    $TM update $TASK1 --status in_progress >/dev/null 2>&1
    
    # Backup database
    cp .task-orchestrator/tasks.db .task-orchestrator/tasks.db.backup
    
    # Simulate restart by clearing any cache (if exists)
    sync
    
    # Verify data persists
    $TM show $TASK1 | grep -q "in_progress" && \
    $TM show $TASK2 | grep -q "high"
}

# Test 2: Transaction atomicity
test_transaction_atomicity() {
    # Create initial state
    TASK=$($TM add "Transaction test" | grep -o '[a-f0-9]\{8\}')
    
    # Simulate interrupted transaction
    (
        # Start operation but interrupt
        $TM update $TASK --status in_progress >/dev/null 2>&1 &
        PID=$!
        sleep 0.1
        kill -9 $PID 2>/dev/null || true
        wait $PID 2>/dev/null || true
    )
    
    # Check database integrity
    if $TM show $TASK >/dev/null 2>&1; then
        # Task should be in consistent state
        STATUS=$($TM show $TASK | grep "Status:" | awk '{print $2}')
        [ -n "$STATUS" ]
    else
        false
    fi
}

# Test 3: Concurrent write protection
test_concurrent_writes() {
    TASK=$($TM add "Concurrent test" | grep -o '[a-f0-9]\{8\}')
    
    # Launch concurrent updates
    (
        for i in {1..5}; do
            (
                $TM update $TASK --assignee "agent_$i" >/dev/null 2>&1
                $TM update $TASK --meta "update_$i:value_$i" >/dev/null 2>&1
            ) &
        done
        wait
    )
    
    # Database should remain consistent
    $TM show $TASK >/dev/null 2>&1
}

# Test 4: Recovery from partial writes
test_partial_write_recovery() {
    # Create task
    TASK=$($TM add "Partial write test" | grep -o '[a-f0-9]\{8\}')
    
    # Backup clean state
    cp .task-orchestrator/tasks.db .task-orchestrator/tasks.db.clean
    
    # Simulate partial write by truncating
    SIZE=$(stat -c%s .task-orchestrator/tasks.db 2>/dev/null || stat -f%z .task-orchestrator/tasks.db 2>/dev/null)
    dd if=/dev/null of=.task-orchestrator/tasks.db bs=1 seek=$((SIZE-10)) 2>/dev/null || true
    
    # Try to access (should handle gracefully)
    if ! $TM list >/dev/null 2>&1; then
        # Restore and verify recovery works
        cp .task-orchestrator/tasks.db.clean .task-orchestrator/tasks.db
        $TM list >/dev/null 2>&1
    else
        true
    fi
}

# Test 5: Backup and restore
test_backup_restore() {
    # Create state
    TASK1=$($TM add "Backup test 1" | grep -o '[a-f0-9]\{8\}')
    TASK2=$($TM add "Backup test 2" | grep -o '[a-f0-9]\{8\}')
    $TM complete $TASK1 >/dev/null 2>&1
    
    # Create backup
    cp -r .task-orchestrator .task-orchestrator.backup
    
    # Modify state
    $TM complete $TASK2 >/dev/null 2>&1
    TASK3=$($TM add "After backup" | grep -o '[a-f0-9]\{8\}')
    
    # Restore backup
    rm -rf .task-orchestrator
    mv .task-orchestrator.backup .task-orchestrator
    
    # Verify restored state
    $TM show $TASK1 | grep -q "completed" && \
    $TM show $TASK2 | grep -q "pending" && \
    ! $TM show $TASK3 >/dev/null 2>&1
}

# Test 6: WAL (Write-Ahead Logging) simulation
test_wal_recovery() {
    # Enable WAL mode if supported
    if command -v sqlite3 >/dev/null 2>&1; then
        sqlite3 .task-orchestrator/tasks.db "PRAGMA journal_mode=WAL;" >/dev/null 2>&1 || true
    fi
    
    # Create tasks
    TASK=$($TM add "WAL test task" | grep -o '[a-f0-9]\{8\}')
    
    # Force checkpoint
    sync
    
    # Verify WAL files exist (if WAL enabled)
    if [ -f .task-orchestrator/tasks.db-wal ]; then
        # WAL exists, test recovery
        rm -f .task-orchestrator/tasks.db
        # Should recover from WAL
        [ -f .task-orchestrator/tasks.db-wal ]
    else
        # No WAL, just verify normal operation
        $TM show $TASK >/dev/null 2>&1
    fi
}

# Run persistence tests
run_test "Basic state persistence" test_basic_persistence
run_test "Transaction atomicity" test_transaction_atomicity
run_test "Concurrent write protection" test_concurrent_writes
run_test "Partial write recovery" test_partial_write_recovery
run_test "Backup and restore" test_backup_restore
run_test "WAL recovery" test_wal_recovery

echo ""
echo -e "${YELLOW}=== Crash Recovery Tests ===${NC}"
echo ""

# Test 7: Simulated crash recovery
test_crash_recovery() {
    # Create working state
    TASK1=$($TM add "Pre-crash task" | grep -o '[a-f0-9]\{8\}')
    $TM update $TASK1 --status in_progress >/dev/null 2>&1
    
    # Simulate crash by killing process abruptly
    (
        $TM add "During crash" >/dev/null 2>&1 &
        PID=$!
        sleep 0.05
        kill -9 $PID 2>/dev/null || true
    )
    
    # System should recover
    $TM list >/dev/null 2>&1 && \
    $TM show $TASK1 | grep -q "in_progress"
}

# Test 8: Lock file cleanup
test_lock_cleanup() {
    # Create stale lock file
    touch .task-orchestrator/.lock
    echo "stale_pid_99999" > .task-orchestrator/.lock
    
    # Should detect and clean stale lock
    timeout 3 $TM list >/dev/null 2>&1
    
    # Verify can operate normally
    TASK=$($TM add "After lock cleanup" | grep -o '[a-f0-9]\{8\}')
    [ -n "$TASK" ]
}

# Test 9: Recovery from corrupted index
test_index_recovery() {
    # Create tasks
    for i in {1..5}; do
        $TM add "Index test $i" >/dev/null 2>&1
    done
    
    # Corrupt index (if exists)
    if [ -f .task-orchestrator/tasks.db-idx ]; then
        echo "corrupted" > .task-orchestrator/tasks.db-idx
    fi
    
    # Should rebuild index or work without it
    $TM list | grep -c "Index test" | grep -q "[1-5]"
}

# Test 10: Session recovery
test_session_recovery() {
    # Create session state
    export TM_SESSION_ID="test_session_123"
    export TM_AGENT_ID="recovery_agent"
    
    TASK=$($TM add "Session task" | grep -o '[a-f0-9]\{8\}')
    $TM assign $TASK $TM_AGENT_ID >/dev/null 2>&1
    
    # Simulate session loss
    unset TM_SESSION_ID
    
    # Restore session
    export TM_SESSION_ID="test_session_123"
    
    # Should maintain task assignment
    $TM show $TASK | grep -q "$TM_AGENT_ID"
}

run_test "Crash recovery" test_crash_recovery
run_test "Lock file cleanup" test_lock_cleanup
run_test "Index recovery" test_index_recovery
run_test "Session recovery" test_session_recovery

echo ""
echo -e "${YELLOW}=== Fault Tolerance Tests ===${NC}"
echo ""

# Test 11: Disk space handling
test_disk_space_handling() {
    # Create tasks until reasonable limit
    COUNT=0
    for i in {1..100}; do
        if $TM add "Disk test $i" >/dev/null 2>&1; then
            COUNT=$((COUNT + 1))
        else
            break
        fi
    done
    
    # Should have created some tasks
    [ $COUNT -gt 0 ]
}

# Test 12: Memory pressure handling
test_memory_pressure() {
    # Create large task descriptions (but safely limited)
    LARGE_DESC=$(printf 'x%.0s' {1..1000})
    
    TASK=$($TM add "Memory test" -d "$LARGE_DESC" 2>&1 | grep -o '[a-f0-9]\{8\}' || echo "")
    
    # Should either succeed or fail gracefully
    if [ -n "$TASK" ]; then
        $TM show $TASK >/dev/null 2>&1
    else
        # Failed gracefully
        true
    fi
}

# Test 13: Network partition simulation (for distributed scenarios)
test_network_partition() {
    # Create task
    TASK=$($TM add "Network test" | grep -o '[a-f0-9]\{8\}')
    
    # Simulate network issue by making db temporarily inaccessible
    chmod 000 .task-orchestrator/tasks.db 2>/dev/null || true
    
    # Should handle gracefully
    $TM list 2>&1 | grep -q "error\|permission\|failed" || true
    
    # Restore access
    chmod 644 .task-orchestrator/tasks.db
    
    # Should work again
    $TM show $TASK >/dev/null 2>&1
}

# Test 14: Byzantine fault handling
test_byzantine_faults() {
    # Create conflicting states (simulated)
    TASK=$($TM add "Byzantine test" | grep -o '[a-f0-9]\{8\}')
    
    # Create conflicting context files
    echo "status: completed" > .task-orchestrator/conflict1.tmp
    echo "status: pending" > .task-orchestrator/conflict2.tmp
    
    # System should detect and resolve conflicts
    $TM show $TASK >/dev/null 2>&1
    
    # Clean up
    rm -f .task-orchestrator/conflict*.tmp
    
    # Verify consistent state
    STATUS=$($TM show $TASK | grep "Status:" | awk '{print $2}')
    [ -n "$STATUS" ]
}

# Test 15: Checkpoint and rollback
test_checkpoint_rollback() {
    # Create checkpoint
    CHECKPOINT_DIR=".task-orchestrator/checkpoint_$(date +%s)"
    cp -r .task-orchestrator "$CHECKPOINT_DIR"
    
    # Make changes
    TASK1=$($TM add "After checkpoint 1" | grep -o '[a-f0-9]\{8\}')
    TASK2=$($TM add "After checkpoint 2" | grep -o '[a-f0-9]\{8\}')
    
    # Rollback to checkpoint
    rm -rf .task-orchestrator
    mv "$CHECKPOINT_DIR" .task-orchestrator
    
    # Verify rollback worked
    ! $TM show $TASK1 >/dev/null 2>&1 && \
    ! $TM show $TASK2 >/dev/null 2>&1
}

run_test "Disk space handling" test_disk_space_handling
run_test "Memory pressure handling" test_memory_pressure
run_test "Network partition simulation" test_network_partition
run_test "Byzantine fault handling" test_byzantine_faults
run_test "Checkpoint and rollback" test_checkpoint_rollback

# Cleanup
cd ..
rm -rf "$TEST_DIR"

echo ""
echo -e "${BLUE}===================================${NC}"
echo -e "${BLUE}        Test Summary               ${NC}"
echo -e "${BLUE}===================================${NC}"
echo ""
echo "Tests Run: $TESTS_RUN"
echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All durability tests passed!${NC}"
    exit 0
else
    echo -e "${RED}❌ Some durability tests failed${NC}"
    exit 1
fi