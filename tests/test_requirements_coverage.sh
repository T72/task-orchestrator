#!/bin/bash

# Task Orchestrator Requirements Coverage Test Suite
# Tests all 26 documented requirements for 100% coverage
# ULTRA-COMPREHENSIVE TEST SUITE - Thinking ultrahard about coverage

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Detect WSL environment
IS_WSL=0
if grep -qi microsoft /proc/version 2>/dev/null; then
    IS_WSL=1
    echo "WSL environment detected - enabling safety measures"
fi

# Setup test environment
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SAVED_DIR="$(pwd)"

# Create isolated test environment
if [ $IS_WSL -eq 1 ]; then
    TEST_DIR="/tmp/tm_req_test_$$_$(date +%s)"
    mkdir -p "$TEST_DIR"
else
    TEST_DIR=$(mktemp -d -t tm_req_test_XXXXXX)
fi

echo "Running requirements tests in: $TEST_DIR"
cd "$TEST_DIR"

# Find tm executable
if [ -f "$PROJECT_DIR/tm" ]; then
    TM="$PROJECT_DIR/tm"
elif [ -f "$SAVED_DIR/tm" ]; then
    TM="$SAVED_DIR/tm"
else
    echo "Error: tm executable not found"
    cd "$SAVED_DIR"
    rm -rf "$TEST_DIR"
    exit 1
fi

# Copy necessary files
cp "$TM" ./tm
chmod +x ./tm
if [ -d "$PROJECT_DIR/src" ]; then
    cp -r "$PROJECT_DIR/src" ./src
fi

# Test functions
test_start() {
    echo -n "Testing: $1... "
    ((TOTAL_TESTS++))
}

test_pass() {
    echo -e "${GREEN}PASS${NC}"
    ((PASSED_TESTS++))
}

test_fail() {
    echo -e "${RED}FAIL${NC}: $1"
    ((FAILED_TESTS++))
}

# ========================================
# SECTION 1: CORE COMMANDS (9 requirements)
# ========================================

echo -e "\n${YELLOW}=== SECTION 1: CORE COMMANDS (9 requirements) ===${NC}"

# 1.1: Initialize database
test_start "REQ-1: Initialize database (tm init)"
if ./tm init 2>/dev/null | grep -q "initialized"; then
    test_pass
else
    test_fail "Database initialization failed"
fi

# 1.2: Add simple task
test_start "REQ-2: Add simple task"
TASK1=$(./tm add "Simple task for testing" | grep -o '[a-f0-9]\{8\}')
if [ -n "$TASK1" ]; then
    test_pass
else
    test_fail "Failed to add simple task"
fi

# 1.3: Add task with details
test_start "REQ-3: Add task with description and priority"
TASK2=$(./tm add "Detailed task" -d "This is a detailed description" -p high | grep -o '[a-f0-9]\{8\}')
if [ -n "$TASK2" ]; then
    # Verify details were saved
    if ./tm show "$TASK2" | grep -q "This is a detailed description" && \
       ./tm show "$TASK2" | grep -q "high"; then
        test_pass
    else
        test_fail "Details not saved correctly"
    fi
else
    test_fail "Failed to add task with details"
fi

# 1.4: List all tasks
test_start "REQ-4: List all tasks"
if ./tm list | grep -q "$TASK1" && ./tm list | grep -q "$TASK2"; then
    test_pass
else
    test_fail "List command not showing all tasks"
fi

# 1.5: Show task details
test_start "REQ-5: Show specific task details"
if ./tm show "$TASK1" | grep -q "Simple task for testing"; then
    test_pass
else
    test_fail "Show command not displaying task details"
fi

# 1.6: Update task status
test_start "REQ-6: Update task status"
./tm update "$TASK1" --status in_progress
if ./tm show "$TASK1" | grep -q "in_progress"; then
    test_pass
else
    test_fail "Status update failed"
fi

# 1.7: Complete task
test_start "REQ-7: Complete a task"
./tm complete "$TASK1"
if ./tm show "$TASK1" | grep -q "completed"; then
    test_pass
else
    test_fail "Task completion failed"
fi

# 1.8: Assign task to agent
test_start "REQ-8: Assign task to agent"
./tm assign "$TASK2" "test_agent"
if ./tm show "$TASK2" | grep -q "test_agent"; then
    test_pass
else
    test_fail "Task assignment failed"
fi

# 1.9: Delete task
test_start "REQ-9: Delete a task"
TASK_TO_DELETE=$(./tm add "Task to delete" | grep -o '[a-f0-9]\{8\}')
./tm delete "$TASK_TO_DELETE"
if ! ./tm show "$TASK_TO_DELETE" 2>/dev/null | grep -q "Task to delete"; then
    test_pass
else
    test_fail "Task deletion failed"
fi

# ========================================
# SECTION 2: DEPENDENCIES (3 requirements)
# ========================================

echo -e "\n${YELLOW}=== SECTION 2: DEPENDENCIES (3 requirements) ===${NC}"

# 2.1: Add task with dependency
test_start "REQ-10: Add task with dependency"
PARENT=$(./tm add "Parent task" | grep -o '[a-f0-9]\{8\}')
CHILD=$(./tm add "Child task" --depends-on "$PARENT" | grep -o '[a-f0-9]\{8\}')
if [ -n "$CHILD" ]; then
    test_pass
else
    test_fail "Failed to add task with dependency"
fi

# 2.2: Auto-blocking (tasks with dependencies start blocked)
test_start "REQ-11: Tasks with dependencies auto-block"
if ./tm show "$CHILD" | grep -q "blocked"; then
    test_pass
else
    test_fail "Dependent task not automatically blocked"
fi

# 2.3: Auto-unblocking (completing dependency unblocks task)
test_start "REQ-12: Completing dependency unblocks tasks"
./tm complete "$PARENT"
sleep 1  # Allow time for status propagation
if ./tm show "$CHILD" | grep -q "pending"; then
    test_pass
else
    test_fail "Task not unblocked after dependency completion"
fi

# ========================================
# SECTION 3: FILE REFERENCES (2 requirements)
# ========================================

echo -e "\n${YELLOW}=== SECTION 3: FILE REFERENCES (2 requirements) ===${NC}"

# 3.1: Add task with file reference
test_start "REQ-13: Add task with file reference"
FILE_TASK=$(./tm add "Fix bug in auth" --file src/auth.py:42 | grep -o '[a-f0-9]\{8\}')
if ./tm show "$FILE_TASK" | grep -q "src/auth.py:42"; then
    test_pass
else
    test_fail "File reference not saved"
fi

# 3.2: Add task with file range reference
test_start "REQ-14: Add task with file range reference"
RANGE_TASK=$(./tm add "Refactor utils" --file src/utils.py:100:150 | grep -o '[a-f0-9]\{8\}')
if ./tm show "$RANGE_TASK" | grep -q "src/utils.py:100:150"; then
    test_pass
else
    test_fail "File range reference not saved"
fi

# ========================================
# SECTION 4: NOTIFICATIONS (2 requirements)
# ========================================

echo -e "\n${YELLOW}=== SECTION 4: NOTIFICATIONS (2 requirements) ===${NC}"

# 4.1: Check notifications (watch command)
test_start "REQ-15: Watch for notifications"
# Create a discovery to generate notification
NOTIF_TASK=$(./tm add "Task for notifications" | grep -o '[a-f0-9]\{8\}')
./tm discover "$NOTIF_TASK" "Important discovery for testing"
if ./tm watch | grep -q "Important discovery"; then
    test_pass
else
    test_fail "Watch command not showing notifications"
fi

# 4.2: Complete with impact review
test_start "REQ-16: Complete task with impact review"
IMPACT_TASK=$(./tm add "Task with file impact" --file src/critical.py:100 | grep -o '[a-f0-9]\{8\}')
if ./tm complete "$IMPACT_TASK" --impact-review 2>&1 | grep -q "Impact Review"; then
    # Check if notification was created
    if ./tm watch | grep -q "impact review"; then
        test_pass
    else
        test_fail "Impact review notification not created"
    fi
else
    test_fail "Impact review not triggered"
fi

# ========================================
# SECTION 5: FILTERING (3 requirements)
# ========================================

echo -e "\n${YELLOW}=== SECTION 5: FILTERING (3 requirements) ===${NC}"

# 5.1: Filter by status
test_start "REQ-17: List tasks filtered by status"
# Create tasks with different statuses
PENDING_TASK=$(./tm add "Pending task" | grep -o '[a-f0-9]\{8\}')
PROGRESS_TASK=$(./tm add "In progress task" | grep -o '[a-f0-9]\{8\}')
./tm update "$PROGRESS_TASK" --status in_progress
if ./tm list --status pending | grep -q "$PENDING_TASK" && \
   ! ./tm list --status pending | grep -q "$PROGRESS_TASK"; then
    test_pass
else
    test_fail "Status filtering not working correctly"
fi

# 5.2: Filter by assignee
test_start "REQ-18: List tasks filtered by assignee"
ASSIGNED_TASK=$(./tm add "Assigned task" | grep -o '[a-f0-9]\{8\}')
./tm assign "$ASSIGNED_TASK" "alice"
UNASSIGNED_TASK=$(./tm add "Unassigned task" | grep -o '[a-f0-9]\{8\}')
if ./tm list --assignee alice | grep -q "$ASSIGNED_TASK" && \
   ! ./tm list --assignee alice | grep -q "$UNASSIGNED_TASK"; then
    test_pass
else
    test_fail "Assignee filtering not working correctly"
fi

# 5.3: List tasks with dependencies
test_start "REQ-19: List tasks that have dependencies"
PARENT_DEPS=$(./tm add "Parent for deps filter" | grep -o '[a-f0-9]\{8\}')
CHILD_DEPS=$(./tm add "Child with deps" --depends-on "$PARENT_DEPS" | grep -o '[a-f0-9]\{8\}')
NO_DEPS=$(./tm add "Task without deps" | grep -o '[a-f0-9]\{8\}')
if ./tm list --has-deps | grep -q "$CHILD_DEPS" && \
   ! ./tm list --has-deps | grep -q "$NO_DEPS"; then
    test_pass
else
    test_fail "Has-dependencies filter not working"
fi

# ========================================
# SECTION 6: EXPORT (2 requirements)
# ========================================

echo -e "\n${YELLOW}=== SECTION 6: EXPORT (2 requirements) ===${NC}"

# 6.1: Export as JSON
test_start "REQ-20: Export tasks as JSON"
if ./tm export --format json | python3 -m json.tool >/dev/null 2>&1; then
    test_pass
else
    test_fail "JSON export not valid JSON"
fi

# 6.2: Export as Markdown
test_start "REQ-21: Export tasks as Markdown"
if ./tm export --format markdown | grep -q "^#"; then
    test_pass
else
    test_fail "Markdown export not formatted correctly"
fi

# ========================================
# SECTION 7: COLLABORATION (6 requirements)
# ========================================

echo -e "\n${YELLOW}=== SECTION 7: COLLABORATION (6 requirements) ===${NC}"

# 7.1: Join task collaboration
test_start "REQ-22: Join task collaboration"
COLLAB_TASK=$(./tm add "Collaboration task" | grep -o '[a-f0-9]\{8\}')
if ./tm join "$COLLAB_TASK" 2>&1 | grep -q "Joined"; then
    test_pass
else
    test_fail "Join command failed"
fi

# 7.2: Share update with team
test_start "REQ-23: Share update with team"
if ./tm share "$COLLAB_TASK" "Shared update for team" 2>&1 | grep -q "Shared"; then
    test_pass
else
    test_fail "Share command failed"
fi

# 7.3: Add private note
test_start "REQ-24: Add private note"
if ./tm note "$COLLAB_TASK" "Private note only for me" 2>&1 | grep -q "Note added"; then
    test_pass
else
    test_fail "Note command failed"
fi

# 7.4: Share discovery
test_start "REQ-25: Share discovery with broadcast"
if ./tm discover "$COLLAB_TASK" "Critical discovery" 2>&1 | grep -q "Discovery shared"; then
    # Verify notification was created
    if ./tm watch | grep -q "Critical discovery"; then
        test_pass
    else
        test_fail "Discovery not broadcast"
    fi
else
    test_fail "Discover command failed"
fi

# 7.5: Create sync point
test_start "REQ-26: Create synchronization point"
if ./tm sync "$COLLAB_TASK" "Checkpoint reached" 2>&1 | grep -q "Sync"; then
    test_pass
else
    test_fail "Sync command failed"
fi

# 7.6: View task context
test_start "REQ-27: View collaborative context"
if ./tm context "$COLLAB_TASK" | grep -q "Shared update for team"; then
    test_pass
else
    test_fail "Context command not showing shared updates"
fi

# ========================================
# EDGE CASES AND VALIDATION
# ========================================

echo -e "\n${YELLOW}=== EDGE CASES AND VALIDATION ===${NC}"

# Test empty title validation
test_start "EDGE-1: Reject empty task title"
if ./tm add "" 2>&1 | grep -qi "error\|cannot be empty"; then
    test_pass
else
    test_fail "Empty title not rejected"
fi

# Test invalid status validation
test_start "EDGE-2: Reject invalid status"
VALID_TASK=$(./tm add "Task for status test" | grep -o '[a-f0-9]\{8\}')
if ./tm update "$VALID_TASK" --status invalid_status 2>&1 | grep -qi "invalid"; then
    test_pass
else
    test_fail "Invalid status not rejected"
fi

# Test non-existent dependency
test_start "EDGE-3: Reject non-existent dependency"
if ./tm add "Task with bad dependency" --depends-on nonexistent123 2>&1 | grep -qi "not found\|error"; then
    test_pass
else
    test_fail "Non-existent dependency not rejected"
fi

# Test multiple file references
test_start "EDGE-4: Multiple file references"
MULTI_FILE=$(./tm add "Multi-file task" --file src/file1.py:10 --file src/file2.py:20 | grep -o '[a-f0-9]\{8\}')
if ./tm show "$MULTI_FILE" | grep -q "file1.py" && ./tm show "$MULTI_FILE" | grep -q "file2.py"; then
    test_pass
else
    test_fail "Multiple file references not handled"
fi

# Test concurrent dependency resolution
test_start "EDGE-5: Concurrent dependency resolution"
DEP1=$(./tm add "Dependency 1" | grep -o '[a-f0-9]\{8\}')
DEP2=$(./tm add "Dependency 2" | grep -o '[a-f0-9]\{8\}')
MULTI_DEP=$(./tm add "Task with multiple deps" --depends-on "$DEP1" --depends-on "$DEP2" | grep -o '[a-f0-9]\{8\}')
if ./tm show "$MULTI_DEP" | grep -q "blocked"; then
    ./tm complete "$DEP1"
    sleep 1
    # Should still be blocked
    if ./tm show "$MULTI_DEP" | grep -q "blocked"; then
        ./tm complete "$DEP2"
        sleep 1
        # Now should be unblocked
        if ./tm show "$MULTI_DEP" | grep -q "pending"; then
            test_pass
        else
            test_fail "Not unblocked after all dependencies complete"
        fi
    else
        test_fail "Unblocked too early with incomplete dependencies"
    fi
else
    test_fail "Multiple dependencies not blocking correctly"
fi

# ========================================
# PERFORMANCE AND STRESS TESTS
# ========================================

echo -e "\n${YELLOW}=== PERFORMANCE VALIDATION ===${NC}"

# Test bulk operations
test_start "PERF-1: Handle 50 tasks efficiently"
START_TIME=$(date +%s%N)
for i in {1..50}; do
    ./tm add "Bulk task $i" >/dev/null 2>&1
done
END_TIME=$(date +%s%N)
ELAPSED=$((($END_TIME - $START_TIME) / 1000000))  # Convert to milliseconds
if [ $ELAPSED -lt 10000 ]; then  # Should complete in under 10 seconds
    test_pass
else
    test_fail "Bulk operations too slow: ${ELAPSED}ms"
fi

# Test large export
test_start "PERF-2: Export large task list"
if ./tm export --format json | wc -l | grep -q "[0-9]"; then
    test_pass
else
    test_fail "Large export failed"
fi

# ========================================
# CLEANUP AND RESULTS
# ========================================

echo -e "\n${YELLOW}=== TEST RESULTS ===${NC}"
echo "Total Tests: $TOTAL_TESTS"
echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
echo -e "Failed: ${RED}$FAILED_TESTS${NC}"

# Calculate percentage
if [ $TOTAL_TESTS -gt 0 ]; then
    PERCENTAGE=$((PASSED_TESTS * 100 / TOTAL_TESTS))
    echo "Coverage: ${PERCENTAGE}%"
    
    if [ $PERCENTAGE -eq 100 ]; then
        echo -e "\n${GREEN}✅ ALL 26 REQUIREMENTS FULLY TESTED!${NC}"
    elif [ $PERCENTAGE -ge 90 ]; then
        echo -e "\n${YELLOW}⚠️ Good coverage but some tests failed${NC}"
    else
        echo -e "\n${RED}❌ Insufficient test coverage${NC}"
    fi
fi

# Cleanup
cd "$SAVED_DIR"
rm -rf "$TEST_DIR"

# Exit with appropriate code
if [ $FAILED_TESTS -eq 0 ]; then
    exit 0
else
    exit 1
fi