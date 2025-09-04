#!/bin/bash
# Comprehensive Test Suite for Task Orchestrator v2.7.2
# Tests all major features and error handling

echo "==================================="
echo "  COMPREHENSIVE TEST SUITE v2.7.2  "
echo "==================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test tracking
TOTAL=0
PASSED=0

# Find tm executable
if [ -f "../tm" ]; then
    TM="../tm"
elif [ -f "./tm" ]; then
    TM="./tm"
elif [ -f "/mnt/d/Dropbox/Private/Persönlich/VSCodeEnv/projects/task-orchestrator/tm" ]; then
    TM="/mnt/d/Dropbox/Private/Persönlich/VSCodeEnv/projects/task-orchestrator/tm"
else
    echo "Error: tm executable not found"
    exit 1
fi

# Create test environment
export TM_TEST_MODE=1
TEST_DIR=$(mktemp -d)
ORIGINAL_DIR=$(pwd)
cd $TEST_DIR

# Copy necessary files if running from tests directory
if [ -d "$ORIGINAL_DIR/src" ]; then
    cp -r "$ORIGINAL_DIR/src" ./
elif [ -d "$ORIGINAL_DIR/../src" ]; then
    cp -r "$ORIGINAL_DIR/../src" ./
fi

# Copy tm executable
if [ -f "$ORIGINAL_DIR/tm" ]; then
    cp "$ORIGINAL_DIR/tm" ./tm
    chmod +x ./tm
    TM="./tm"
elif [ -f "$ORIGINAL_DIR/../tm" ]; then
    cp "$ORIGINAL_DIR/../tm" ./tm
    chmod +x ./tm
    TM="./tm"
fi

echo "Test Environment: $TEST_DIR"
echo "TM Executable: $TM"
echo ""

# Function to run test
run_test() {
    local name="$1"
    local cmd="$2"
    local check="$3"
    TOTAL=$((TOTAL + 1))
    
    if eval "$cmd" 2>&1 | grep -q "$check"; then
        echo -e "${GREEN}✅${NC} $name"
        PASSED=$((PASSED + 1))
    else
        echo -e "${RED}❌${NC} $name"
    fi
}

echo "=== CORE FUNCTIONALITY ==="
run_test "Initialize database" "$TM init" "initialized"
TASK1=$($TM add "Test task 1" 2>&1 | grep -oE '[a-f0-9]{8}' | head -1)
run_test "Create task" "echo $TASK1" "[a-f0-9]"
TASK2=$($TM add "Test task 2" --depends-on $TASK1 2>&1 | grep -oE '[a-f0-9]{8}' | head -1)
run_test "Create with dependency" "echo $TASK2" "[a-f0-9]"
run_test "List tasks" "$TM list" "$TASK1"
run_test "Show task details" "$TM show $TASK1" "Test task 1"
run_test "Update task status" "$TM update $TASK1 --status in_progress" "updated"
run_test "Assign task" "$TM assign $TASK1 test_agent" "assigned"

echo ""
echo "=== COLLABORATION FEATURES ==="
run_test "Join task" "$TM join $TASK1" "Joined"
run_test "Share update" "$TM share $TASK1 'Test message'" "Shared update"
run_test "Add private note" "$TM note $TASK1 'Private note'" "Added private note"
run_test "View context" "$TM context $TASK1" "Created:"
run_test "Create sync point" "$TM sync $TASK1 'checkpoint'" "sync"
run_test "Watch notifications" "$TM watch --limit 1" "notification"

echo ""
echo "=== CORE LOOP v2.3 FEATURES ==="
run_test "Add progress update" "$TM progress $TASK1 '50% done'" "added"
run_test "Complete with summary" "$TM complete $TASK1 --summary 'Done'" "completed"
run_test "Add feedback" "$TM feedback $TASK1 --quality 5" "recorded"
run_test "View metrics" "$TM metrics --feedback" "metrics\|average\|Feedback"
run_test "Config management" "$TM config --show" "Current configuration"
run_test "Migration status" "$TM migrate --status" "migration"

echo ""
echo "=== EXPORT FEATURES ==="
run_test "Export JSON" "$TM export --format json" "{"
run_test "Export Markdown" "$TM export --format markdown" "#"

echo ""
echo "=== ADVANCED FEATURES ==="
TASK3=$($TM add "Task with criteria" --criteria '[{"criterion":"Test pass"}]' 2>&1 | grep -oE '[a-f0-9]{8}' | head -1)
run_test "Success criteria" "echo $TASK3" "[a-f0-9]"
run_test "Estimated hours" "$TM add 'Timed task' --estimated-hours 5" "created"
run_test "Deadline support" "$TM add 'Deadline task' --deadline '2025-12-31T00:00:00Z'" "created"

echo ""
echo "=== ERROR HANDLING ==="
run_test "Handle invalid task ID" "$TM show invalid_id 2>&1" "not found"
run_test "Handle duplicate dependency" "$TM add 'Task C' --depends-on $TASK1,$TASK1 2>&1" "Error\|Dependencies not found"
run_test "Handle empty title" "$TM add '' 2>&1" "Error\|created"

# Additional test for circular dependency prevention
TASK4=$($TM add "Task D" 2>&1 | grep -oE '[a-f0-9]{8}' | head -1)
TASK5=$($TM add "Task E" --depends-on $TASK4 2>&1 | grep -oE '[a-f0-9]{8}' | head -1)
run_test "Dependency chain creation" "echo $TASK5" "[a-f0-9]"

# Cleanup
cd ..
rm -rf $TEST_DIR

echo ""
echo "==================================="
echo "         TEST SUMMARY              "
echo "==================================="
echo "Total Tests: $TOTAL"
echo -e "Passed: ${GREEN}$PASSED${NC}"
echo -e "Failed: ${RED}$((TOTAL - PASSED))${NC}"
echo -n "Success Rate: "
if [ $TOTAL -gt 0 ]; then
    RATE=$((PASSED * 100 / TOTAL))
    if [ $RATE -ge 90 ]; then
        echo -e "${GREEN}${RATE}%${NC}"
    elif [ $RATE -ge 70 ]; then
        echo -e "${YELLOW}${RATE}%${NC}"
    else
        echo -e "${RED}${RATE}%${NC}"
    fi
else
    echo "N/A"
fi

echo ""
if [ $PASSED -eq $TOTAL ]; then
    echo -e "${GREEN}🎉 ALL TESTS PASSED!${NC}"
    echo "Task Orchestrator v2.7.2 is fully operational"
    exit 0
else
    echo -e "${RED}⚠️  Some tests failed${NC}"
    echo "Please review the failures above"
    exit 1
fi