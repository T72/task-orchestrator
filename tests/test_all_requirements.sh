#!/bin/bash

# Task Orchestrator - Test All 26 Requirements
# Comprehensive test ensuring 100% coverage with ultra-careful thinking

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "Task Orchestrator - Testing All 26 Requirements"
echo "================================================"

# Detect WSL
IS_WSL=0
if grep -qi microsoft /proc/version 2>/dev/null; then
    IS_WSL=1
    echo "WSL environment detected"
fi

# Setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
TEST_DIR="/tmp/tm_all_req_$$"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

# Copy executable
cp "$PROJECT_DIR/tm" ./tm
chmod +x ./tm
if [ -d "$PROJECT_DIR/src" ]; then
    cp -r "$PROJECT_DIR/src" ./src
fi

# Test counter
TESTS=0
PASSED=0

# Test function
test_requirement() {
    local REQ_NUM=$1
    local DESC=$2
    local CMD=$3
    local CHECK=$4
    
    ((TESTS++))
    echo -n "[$REQ_NUM] $DESC: "
    
    if eval "$CMD" >/dev/null 2>&1; then
        if eval "$CHECK" >/dev/null 2>&1; then
            echo -e "${GREEN}✓${NC}"
            ((PASSED++))
        else
            echo -e "${RED}✗${NC} (check failed)"
        fi
    else
        echo -e "${RED}✗${NC} (command failed)"
    fi
}

echo -e "\n${YELLOW}Testing 26 Requirements:${NC}\n"

# Initialize
./tm init >/dev/null 2>&1

# CORE COMMANDS (9)
test_requirement "1" "Initialize database" \
    "true" \
    "test -f .task-orchestrator/tasks.db"

TASK1=$(./tm add "Test task 1" 2>/dev/null | grep -o '[a-f0-9]\{8\}' || echo "failed")
test_requirement "2" "Add simple task" \
    "test -n '$TASK1'" \
    "test '$TASK1' != 'failed'"

TASK2=$(./tm add "Detailed" -d "Description" -p high 2>/dev/null | grep -o '[a-f0-9]\{8\}' || echo "failed")
test_requirement "3" "Add with details" \
    "test -n '$TASK2'" \
    "./tm show '$TASK2' | grep -q 'Description'"

test_requirement "4" "List tasks" \
    "./tm list" \
    "./tm list | grep -q '$TASK1'"

test_requirement "5" "Show task details" \
    "./tm show '$TASK1'" \
    "./tm show '$TASK1' | grep -q 'Test task 1'"

test_requirement "6" "Update status" \
    "./tm update '$TASK1' --status in_progress" \
    "./tm show '$TASK1' | grep -q 'in_progress'"

test_requirement "7" "Complete task" \
    "./tm complete '$TASK1'" \
    "./tm show '$TASK1' | grep -q 'completed'"

test_requirement "8" "Assign to agent" \
    "./tm assign '$TASK2' alice" \
    "./tm show '$TASK2' | grep -q 'alice'"

TASK_DEL=$(./tm add "To delete" 2>/dev/null | grep -o '[a-f0-9]\{8\}')
test_requirement "9" "Delete task" \
    "./tm delete '$TASK_DEL'" \
    "! ./tm show '$TASK_DEL' 2>/dev/null | grep -q 'To delete'"

# DEPENDENCIES (3)
PARENT=$(./tm add "Parent" 2>/dev/null | grep -o '[a-f0-9]\{8\}')
CHILD=$(./tm add "Child" --depends-on "$PARENT" 2>/dev/null | grep -o '[a-f0-9]\{8\}')

test_requirement "10" "Add with dependency" \
    "test -n '$CHILD'" \
    "test '$CHILD' != ''"

test_requirement "11" "Auto-blocking" \
    "true" \
    "./tm show '$CHILD' | grep -q 'blocked'"

test_requirement "12" "Auto-unblocking" \
    "./tm complete '$PARENT' && sleep 1" \
    "./tm show '$CHILD' | grep -q 'pending'"

# FILE REFERENCES (2)
FILE_TASK=$(./tm add "File bug" --file src/auth.py:42 2>/dev/null | grep -o '[a-f0-9]\{8\}')
test_requirement "13" "File reference" \
    "test -n '$FILE_TASK'" \
    "./tm show '$FILE_TASK' | grep -q 'src/auth.py:42'"

RANGE_TASK=$(./tm add "Range ref" --file src/utils.py:100:150 2>/dev/null | grep -o '[a-f0-9]\{8\}')
test_requirement "14" "File range" \
    "test -n '$RANGE_TASK'" \
    "./tm show '$RANGE_TASK' | grep -q 'src/utils.py:100:150'"

# NOTIFICATIONS (2)
NOTIF_TASK=$(./tm add "Notif task" 2>/dev/null | grep -o '[a-f0-9]\{8\}')
test_requirement "15" "Watch notifications" \
    "./tm discover '$NOTIF_TASK' 'Test discovery'" \
    "./tm watch | grep -q 'Test discovery'"

IMPACT_TASK=$(./tm add "Impact" --file src/test.py:1 2>/dev/null | grep -o '[a-f0-9]\{8\}')
test_requirement "16" "Impact review" \
    "./tm complete '$IMPACT_TASK' --impact-review" \
    "./tm watch | grep -q 'impact'"

# FILTERING (3)
PEND=$(./tm add "Pending filter test" 2>/dev/null | grep -o '[a-f0-9]\{8\}')
PROG=$(./tm add "Progress filter test" 2>/dev/null | grep -o '[a-f0-9]\{8\}')
./tm update "$PROG" --status in_progress >/dev/null 2>&1

test_requirement "17" "Filter by status" \
    "./tm list --status pending" \
    "./tm list --status pending | grep -q '$PEND' && ! ./tm list --status pending | grep -q '$PROG'"

ASSIGNED=$(./tm add "Assigned filter" 2>/dev/null | grep -o '[a-f0-9]\{8\}')
./tm assign "$ASSIGNED" bob >/dev/null 2>&1
test_requirement "18" "Filter by assignee" \
    "./tm list --assignee bob" \
    "./tm list --assignee bob | grep -q '$ASSIGNED'"

P_DEPS=$(./tm add "Parent for deps" 2>/dev/null | grep -o '[a-f0-9]\{8\}')
C_DEPS=$(./tm add "Has deps" --depends-on "$P_DEPS" 2>/dev/null | grep -o '[a-f0-9]\{8\}')
test_requirement "19" "Filter has-deps" \
    "./tm list --has-deps" \
    "./tm list --has-deps | grep -q '$C_DEPS'"

# EXPORT (2)
test_requirement "20" "Export JSON" \
    "./tm export --format json" \
    "./tm export --format json | python3 -m json.tool"

test_requirement "21" "Export Markdown" \
    "./tm export --format markdown" \
    "./tm export --format markdown | grep -q '^#'"

# COLLABORATION (6)
COLLAB=$(./tm add "Collab task" 2>/dev/null | grep -o '[a-f0-9]\{8\}')

test_requirement "22" "Join task" \
    "./tm join '$COLLAB'" \
    "test -f .task-orchestrator/contexts/${COLLAB}.yaml"

test_requirement "23" "Share update" \
    "./tm share '$COLLAB' 'Shared message'" \
    "./tm context '$COLLAB' | grep -q 'Shared message'"

test_requirement "24" "Private note" \
    "./tm note '$COLLAB' 'Private note'" \
    "test -f .task-orchestrator/notes/${COLLAB}_*.md"

test_requirement "25" "Discover" \
    "./tm discover '$COLLAB' 'Discovery'" \
    "./tm watch | grep -q 'Discovery'"

test_requirement "26" "Sync point" \
    "./tm sync '$COLLAB' 'Checkpoint'" \
    "./tm context '$COLLAB' | grep -q 'Checkpoint'"

# Bonus: Context viewing is implicitly tested above

# RESULTS
echo -e "\n${YELLOW}=== TEST RESULTS ===${NC}"
echo "Total Requirements: 26"
echo -e "Tests Passed: ${GREEN}$PASSED${NC}/$TESTS"

COVERAGE=$((PASSED * 100 / 26))
echo "Coverage: ${COVERAGE}%"

if [ $PASSED -eq 26 ]; then
    echo -e "\n${GREEN}✅ PERFECT! All 26 requirements fully tested and working!${NC}"
elif [ $PASSED -ge 24 ]; then
    echo -e "\n${YELLOW}⚠️ Almost there! $((26 - PASSED)) requirements need attention${NC}"
else
    echo -e "\n${RED}❌ Gaps found! $((26 - PASSED)) requirements failing${NC}"
fi

# Cleanup
cd /tmp
rm -rf "$TEST_DIR"

exit $((26 - PASSED))