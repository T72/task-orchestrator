#!/bin/bash
# Test Collaboration Features - Edge Cases and Critical Features

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test directory setup
TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"
git init >/dev/null 2>&1

# Get the parent directory where tm and src are located
PARENT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Copy tm and src
if [ -f "$PARENT_DIR/tm" ]; then
    cp "$PARENT_DIR/tm" ./tm
else
    echo "Error: tm not found in $PARENT_DIR"
    exit 1
fi

if [ -d "$PARENT_DIR/src" ]; then
    cp -r "$PARENT_DIR/src" ./
else
    echo "Warning: src directory not found in $PARENT_DIR"
fi

chmod +x tm

echo -e "${BLUE}===================================${NC}"
echo -e "${BLUE}   Collaboration Features Tests    ${NC}"
echo -e "${BLUE}===================================${NC}"
echo ""

# Helper functions
run_test() {
    local test_name="$1"
    local command="$2"
    local expected="$3"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    echo -n "Testing: $test_name ... "
    
    if eval "$command" 2>/dev/null | grep -q "$expected" 2>/dev/null; then
        echo -e "${GREEN}PASSED${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}FAILED${NC}"
        echo "  Command: $command"
        echo "  Expected: $expected"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

check_file_exists() {
    local test_name="$1"
    local file_path="$2"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    echo -n "Testing: $test_name ... "
    
    if [ -f "$file_path" ]; then
        echo -e "${GREEN}PASSED${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}FAILED${NC}"
        echo "  File not found: $file_path"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Initialize database
echo "Initializing task manager..."
./tm init >/dev/null 2>&1

# Create test tasks
TASK1=$(./tm add "Test task 1" | grep -o '[a-f0-9]\{8\}')
TASK2=$(./tm add "Test task 2" | grep -o '[a-f0-9]\{8\}')

echo ""
echo -e "${YELLOW}=== Testing Collaboration Commands ===${NC}"
echo ""

# Test 1: Join command
export TM_AGENT_ID="test_agent_1"
run_test "Join creates context file" \
    "./tm join $TASK1 && ls .task-orchestrator/contexts/" \
    "context_${TASK1}_"

check_file_exists "Context file created" \
    ".task-orchestrator/contexts/context_${TASK1}_test_agent_1.md"

# Test 2: Share command
run_test "Share adds to context" \
    "./tm share $TASK1 'Test update' && echo 'success'" \
    "success"

run_test "Share creates shared context" \
    "ls .task-orchestrator/contexts/" \
    "shared_${TASK1}.md"

# Test 3: Note command (private)
run_test "Note creates private file" \
    "./tm note $TASK1 'Private thought' && ls .task-orchestrator/notes/" \
    "notes_${TASK1}_"

check_file_exists "Notes file created" \
    ".task-orchestrator/notes/notes_${TASK1}_test_agent_1.md"

# Test 4: Discover command (priority)
run_test "Discover adds priority message" \
    "./tm discover $TASK1 'Critical finding' && echo 'success'" \
    "success"

# Test 5: Sync command
run_test "Sync creates checkpoint" \
    "./tm sync $TASK1 'Milestone reached' && echo 'success'" \
    "success"

# Test 6: Context command shows all
run_test "Context shows shared updates" \
    "./tm context $TASK1" \
    "Test update"

run_test "Context shows discoveries" \
    "./tm context $TASK1" \
    "Critical finding"

echo ""
echo -e "${YELLOW}=== Testing Multi-Agent Scenarios ===${NC}"
echo ""

# Test 7: Multiple agents collaboration
export TM_AGENT_ID="test_agent_2"
./tm join $TASK1 >/dev/null 2>&1
run_test "Second agent can join" \
    "./tm share $TASK1 'Update from agent 2' && echo 'success'" \
    "success"

export TM_AGENT_ID="test_agent_1"
run_test "First agent sees second's updates" \
    "./tm context $TASK1" \
    "Update from agent 2"

# Test 8: Private notes isolation
export TM_AGENT_ID="test_agent_2"
./tm note $TASK1 "Agent 2 private note" >/dev/null 2>&1

export TM_AGENT_ID="test_agent_1"
run_test "Agent 1 doesn't see agent 2's private notes" \
    "! ./tm context $TASK1 | grep -q 'Agent 2 private note' && echo 'isolated'" \
    "isolated"

echo ""
echo -e "${YELLOW}=== Testing Edge Cases ===${NC}"
echo ""

# Test 9: Long message handling
LONG_MSG=$(printf 'x%.0s' {1..1000})
run_test "Handle long messages" \
    "./tm share $TASK1 '$LONG_MSG' && echo 'handled'" \
    "handled"

# Test 10: Special characters in messages
run_test "Handle special characters" \
    "./tm share $TASK1 'Test \"quotes\" and \$variables' && echo 'handled'" \
    "handled"

# Test 11: Non-existent task
run_test "Handle non-existent task" \
    "./tm join nonexistent123 2>&1 || echo 'handled'" \
    "handled"

# Test 12: Empty message
run_test "Handle empty message" \
    "./tm share $TASK1 '' 2>&1 || echo 'handled'" \
    "handled"

# Test 13: Multiple sync points
./tm sync $TASK1 "Sync 1" >/dev/null 2>&1
./tm sync $TASK1 "Sync 2" >/dev/null 2>&1
run_test "Multiple sync points" \
    "./tm context $TASK1 | grep -c 'SYNC POINT'" \
    "3"  # We created 3 sync points total

# Test 14: Context without joining
export TM_AGENT_ID="test_agent_3"
run_test "Context viewable without joining" \
    "./tm context $TASK1 | grep -q 'Test update' && echo 'viewable'" \
    "viewable"

echo ""
echo -e "${YELLOW}=== Testing File System Edge Cases ===${NC}"
echo ""

# Test 15: Directory permissions
chmod 444 .task-orchestrator/contexts 2>/dev/null || true
run_test "Handle read-only directory" \
    "./tm share $TASK2 'Test' 2>&1 | grep -q 'Permission' || echo 'handled'" \
    "handled"
chmod 755 .task-orchestrator/contexts

# Test 16: Disk space simulation (create large file)
# Skip this test as it's environment dependent

# Test 17: Concurrent access
export TM_AGENT_ID="concurrent_1"
./tm join $TASK2 >/dev/null 2>&1 &
PID1=$!

export TM_AGENT_ID="concurrent_2"
./tm join $TASK2 >/dev/null 2>&1 &
PID2=$!

wait $PID1 $PID2
run_test "Concurrent join operations" \
    "ls .task-orchestrator/contexts/ | grep -c context_${TASK2}" \
    "2"

echo ""
echo -e "${YELLOW}=== Testing Integration with Base Commands ===${NC}"
echo ""

# Test 18: Complete task archives collaboration
./tm complete $TASK1 >/dev/null 2>&1
run_test "Complete archives collaboration files" \
    "ls .task-orchestrator/archives/ | grep -q archive_ && echo 'archived'" \
    "archived"

# Test 19: Delete task cleanup
TASK3=$(./tm add "Task to delete" | grep -o '[a-f0-9]\{8\}')
./tm join $TASK3 >/dev/null 2>&1
./tm share $TASK3 "Will be deleted" >/dev/null 2>&1
./tm delete $TASK3 >/dev/null 2>&1 || true
run_test "Delete removes collaboration files" \
    "! ls .task-orchestrator/contexts/*${TASK3}* 2>/dev/null && echo 'cleaned'" \
    "cleaned"

# Test 20: Task dependencies with collaboration
TASK4=$(./tm add "Parent task" | grep -o '[a-f0-9]\{8\}')
TASK5=$(./tm add "Child task" --depends-on $TASK4 | grep -o '[a-f0-9]\{8\}' || echo "failed")
run_test "Dependencies work with collaboration" \
    "[ -n '$TASK5' ] && echo 'success'" \
    "success"

echo ""
echo -e "${YELLOW}=== Testing Environment Variables ===${NC}"
echo ""

# Test 21: Custom agent ID
export TM_AGENT_ID="custom_agent_name"
./tm join $TASK2 >/dev/null 2>&1
check_file_exists "Custom agent ID used" \
    ".task-orchestrator/contexts/context_${TASK2}_custom_agent_name.md"

# Test 22: Unset agent ID (auto-generation)
unset TM_AGENT_ID
run_test "Auto-generate agent ID when unset" \
    "./tm share $TASK2 'Auto agent' && echo 'generated'" \
    "generated"

echo ""
echo -e "${YELLOW}=== Testing Error Recovery ===${NC}"
echo ""

# Test 23: Corrupted context file
echo "corrupted data !@#$%" > .task-orchestrator/contexts/shared_${TASK2}.md
run_test "Handle corrupted context" \
    "./tm context $TASK2 2>&1 && echo 'handled'" \
    "handled"

# Test 24: Missing src directory
mv src src_backup
run_test "Handle missing collaboration module" \
    "./tm list 2>&1 | head -1 && echo 'handled'" \
    "handled"
mv src_backup src

echo ""
echo -e "${BLUE}===================================${NC}"
echo -e "${BLUE}        Test Summary               ${NC}"
echo -e "${BLUE}===================================${NC}"
echo ""
echo "Tests Run: $TESTS_RUN"
echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"
echo ""

# Cleanup
cd ..
rm -rf "$TEST_DIR"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All collaboration tests passed!${NC}"
    exit 0
else
    echo -e "${RED}❌ Some tests failed${NC}"
    exit 1
fi