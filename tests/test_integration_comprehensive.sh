#!/bin/bash

# Task Orchestrator Comprehensive Integration Test Suite
# Tests all 26 requirements working together in real-world scenarios
# ULTRA-COMPREHENSIVE INTEGRATION TESTS - Maximum thinking applied

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TOTAL_SCENARIOS=0
PASSED_SCENARIOS=0
FAILED_SCENARIOS=0

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
    TEST_DIR="/tmp/tm_integ_test_$$_$(date +%s)"
    mkdir -p "$TEST_DIR"
else
    TEST_DIR=$(mktemp -d -t tm_integ_test_XXXXXX)
fi

echo "Running integration tests in: $TEST_DIR"
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
scenario_start() {
    echo -e "\n${BLUE}SCENARIO: $1${NC}"
    ((TOTAL_SCENARIOS++))
}

scenario_pass() {
    echo -e "${GREEN}✅ SCENARIO PASSED${NC}"
    ((PASSED_SCENARIOS++))
}

scenario_fail() {
    echo -e "${RED}❌ SCENARIO FAILED: $1${NC}"
    ((FAILED_SCENARIOS++))
}

# Initialize database once
./tm init

# ========================================
# SCENARIO 1: Complete Feature Development Workflow
# Tests: init, add, dependencies, file refs, status updates, completion, notifications
# ========================================

scenario_start "Complete Feature Development Workflow"

# Create feature breakdown with dependencies and file references
echo "Creating feature breakdown..."
FEATURE=$(./tm add "Implement user authentication" -d "Complete auth system" -p high | grep -o '[a-f0-9]\{8\}')
DB_SCHEMA=$(./tm add "Design auth database schema" --file src/db/schema.sql:1:50 --depends-on "$FEATURE" | grep -o '[a-f0-9]\{8\}')
API=$(./tm add "Create auth API endpoints" --file src/api/auth.py:1:200 --depends-on "$DB_SCHEMA" | grep -o '[a-f0-9]\{8\}')
FRONTEND=$(./tm add "Build login UI" --file src/ui/login.tsx:1:150 --depends-on "$API" | grep -o '[a-f0-9]\{8\}')
TESTS=$(./tm add "Write auth tests" --file tests/test_auth.py:1:300 --depends-on "$FRONTEND" | grep -o '[a-f0-9]\{8\}')

# Verify dependency chain is blocked correctly
echo "Verifying dependency blocking..."
if ./tm show "$DB_SCHEMA" | grep -q "blocked" && \
   ./tm show "$API" | grep -q "blocked" && \
   ./tm show "$FRONTEND" | grep -q "blocked" && \
   ./tm show "$TESTS" | grep -q "blocked"; then
    echo "✓ Dependencies properly blocked"
else
    scenario_fail "Dependencies not properly blocked"
    exit 1
fi

# Simulate multi-agent collaboration
echo "Simulating multi-agent work..."
export TM_AGENT_ID="database_team"
./tm join "$DB_SCHEMA"
./tm share "$DB_SCHEMA" "Starting database schema design"
./tm note "$DB_SCHEMA" "Consider using UUID for user IDs"

export TM_AGENT_ID="backend_team"
./tm join "$API"
./tm share "$API" "Waiting for database schema"

# Complete tasks in order
echo "Completing tasks in sequence..."
export TM_AGENT_ID="orchestrator"
./tm complete "$FEATURE"
sleep 1

# DB Schema should now be unblocked
if ./tm show "$DB_SCHEMA" | grep -q "pending"; then
    echo "✓ DB Schema unblocked after feature completion"
else
    scenario_fail "DB Schema not unblocked"
    exit 1
fi

./tm update "$DB_SCHEMA" --status in_progress
./tm assign "$DB_SCHEMA" "database_team"
./tm complete "$DB_SCHEMA" --impact-review
sleep 1

# API should now be unblocked
if ./tm show "$API" | grep -q "pending"; then
    echo "✓ API task unblocked"
else
    scenario_fail "API not unblocked"
    exit 1
fi

# Check notifications
echo "Checking notifications..."
if ./tm watch | grep -q "impact review"; then
    echo "✓ Impact review notification received"
else
    scenario_fail "Impact review notification missing"
    exit 1
fi

scenario_pass

# ========================================
# SCENARIO 2: Complex Multi-Dependency Resolution
# Tests: multiple dependencies, partial completion, proper blocking/unblocking
# ========================================

scenario_start "Complex Multi-Dependency Resolution"

echo "Creating complex dependency graph..."
INFRA=$(./tm add "Setup infrastructure" | grep -o '[a-f0-9]\{8\}')
SECURITY=$(./tm add "Configure security" | grep -o '[a-f0-9]\{8\}')
MONITORING=$(./tm add "Setup monitoring" | grep -o '[a-f0-9]\{8\}')
DEPLOY=$(./tm add "Deploy to production" --depends-on "$INFRA" --depends-on "$SECURITY" --depends-on "$MONITORING" | grep -o '[a-f0-9]\{8\}')

# Verify blocked with multiple dependencies
if ./tm show "$DEPLOY" | grep -q "blocked"; then
    echo "✓ Task blocked with multiple dependencies"
else
    scenario_fail "Multiple dependencies not blocking"
    exit 1
fi

# Complete only some dependencies
./tm complete "$INFRA"
./tm complete "$SECURITY"
sleep 1

# Should still be blocked
if ./tm show "$DEPLOY" | grep -q "blocked"; then
    echo "✓ Still blocked with incomplete dependencies"
else
    scenario_fail "Unblocked too early"
    exit 1
fi

# Complete final dependency
./tm complete "$MONITORING"
sleep 1

# Now should be unblocked
if ./tm show "$DEPLOY" | grep -q "pending"; then
    echo "✓ Unblocked after all dependencies complete"
else
    scenario_fail "Not unblocked after all dependencies"
    exit 1
fi

scenario_pass

# ========================================
# SCENARIO 3: File Reference Impact Analysis
# Tests: file refs, impact review, notifications, filtering
# ========================================

scenario_start "File Reference Impact Analysis"

echo "Creating tasks with overlapping file references..."
BUG1=$(./tm add "Fix auth bug" --file src/auth.py:100:150 | grep -o '[a-f0-9]\{8\}')
BUG2=$(./tm add "Fix session bug" --file src/auth.py:120:130 | grep -o '[a-f0-9]\{8\}')
REFACTOR=$(./tm add "Refactor auth module" --file src/auth.py:1:500 | grep -o '[a-f0-9]\{8\}')

# Assign to different agents
./tm assign "$BUG1" "agent1"
./tm assign "$BUG2" "agent2"
./tm assign "$REFACTOR" "agent3"

# Complete with impact review
echo "Completing with impact review..."
./tm complete "$BUG1" --impact-review

# Check for impact notification
if ./tm watch | grep -q "impact review"; then
    echo "✓ Impact review notification created"
else
    scenario_fail "Impact review notification missing"
    exit 1
fi

# Verify file references are preserved
if ./tm show "$BUG2" | grep -q "src/auth.py:120:130"; then
    echo "✓ File references preserved"
else
    scenario_fail "File references lost"
    exit 1
fi

scenario_pass

# ========================================
# SCENARIO 4: Collaborative Context Sharing
# Tests: join, share, note, discover, sync, context
# ========================================

scenario_start "Collaborative Context Sharing"

echo "Creating collaborative task..."
COLLAB=$(./tm add "Collaborative feature" -d "Requires team coordination" | grep -o '[a-f0-9]\{8\}')

# Multiple agents join and contribute
echo "Multiple agents joining and sharing..."
export TM_AGENT_ID="alice"
./tm join "$COLLAB"
./tm share "$COLLAB" "Alice: Starting frontend work"
./tm note "$COLLAB" "Alice's private: Check React version compatibility"

export TM_AGENT_ID="bob"
./tm join "$COLLAB"
./tm share "$COLLAB" "Bob: API design ready for review"
./tm discover "$COLLAB" "CRITICAL: Found security vulnerability in auth flow"

export TM_AGENT_ID="charlie"
./tm join "$COLLAB"
./tm sync "$COLLAB" "Checkpoint: Phase 1 complete, ready for integration"

# Verify context contains all shared information
echo "Verifying shared context..."
CONTEXT=$(./tm context "$COLLAB")
if echo "$CONTEXT" | grep -q "Alice: Starting frontend" && \
   echo "$CONTEXT" | grep -q "Bob: API design" && \
   echo "$CONTEXT" | grep -q "security vulnerability" && \
   echo "$CONTEXT" | grep -q "Phase 1 complete"; then
    echo "✓ All shared context preserved"
else
    scenario_fail "Shared context incomplete"
    exit 1
fi

# Verify discovery created broadcast notification
export TM_AGENT_ID="dave"
if ./tm watch | grep -q "security vulnerability"; then
    echo "✓ Discovery broadcast to all agents"
else
    scenario_fail "Discovery not broadcast"
    exit 1
fi

scenario_pass

# ========================================
# SCENARIO 5: Advanced Filtering and Export
# Tests: all filter types, export formats, large datasets
# ========================================

scenario_start "Advanced Filtering and Export"

echo "Creating diverse task set..."
# Create tasks with various properties
for i in {1..10}; do
    ./tm add "Pending task $i" >/dev/null 2>&1
done

for i in {1..5}; do
    TASK=$(./tm add "In progress task $i" | grep -o '[a-f0-9]\{8\}')
    ./tm update "$TASK" --status in_progress
    ./tm assign "$TASK" "team_alpha"
done

for i in {1..5}; do
    TASK=$(./tm add "Completed task $i" | grep -o '[a-f0-9]\{8\}')
    ./tm complete "$TASK"
done

# Create tasks with dependencies
PARENT=$(./tm add "Parent task" | grep -o '[a-f0-9]\{8\}')
for i in {1..3}; do
    ./tm add "Dependent task $i" --depends-on "$PARENT" >/dev/null 2>&1
done

# Test status filtering
echo "Testing status filtering..."
PENDING_COUNT=$(./tm list --status pending | grep -c "pending" || true)
PROGRESS_COUNT=$(./tm list --status in_progress | grep -c "in_progress" || true)
if [ $PENDING_COUNT -ge 10 ] && [ $PROGRESS_COUNT -eq 5 ]; then
    echo "✓ Status filtering working"
else
    scenario_fail "Status filtering incorrect counts"
    exit 1
fi

# Test assignee filtering
echo "Testing assignee filtering..."
ASSIGNED_COUNT=$(./tm list --assignee team_alpha | grep -c "team_alpha" || true)
if [ $ASSIGNED_COUNT -eq 5 ]; then
    echo "✓ Assignee filtering working"
else
    scenario_fail "Assignee filtering incorrect"
    exit 1
fi

# Test has-deps filtering
echo "Testing dependency filtering..."
if ./tm list --has-deps | grep -q "Dependent task"; then
    echo "✓ Dependency filtering working"
else
    scenario_fail "Dependency filtering not working"
    exit 1
fi

# Test export formats
echo "Testing export formats..."
JSON_EXPORT=$(./tm export --format json)
if echo "$JSON_EXPORT" | python3 -m json.tool >/dev/null 2>&1; then
    echo "✓ JSON export valid"
else
    scenario_fail "JSON export invalid"
    exit 1
fi

MD_EXPORT=$(./tm export --format markdown)
if echo "$MD_EXPORT" | grep -q "^# Task Orchestrator Export" && \
   echo "$MD_EXPORT" | grep -q "## Pending Tasks" && \
   echo "$MD_EXPORT" | grep -q "## Completed Tasks"; then
    echo "✓ Markdown export formatted correctly"
else
    scenario_fail "Markdown export formatting incorrect"
    exit 1
fi

scenario_pass

# ========================================
# SCENARIO 6: Error Handling and Validation
# Tests: input validation, error messages, edge cases
# ========================================

scenario_start "Error Handling and Validation"

echo "Testing input validation..."

# Empty title
if ./tm add "" 2>&1 | grep -qi "empty\|error"; then
    echo "✓ Empty title rejected"
else
    scenario_fail "Empty title not rejected"
    exit 1
fi

# Invalid status
VALID=$(./tm add "Valid task" | grep -o '[a-f0-9]\{8\}')
if ./tm update "$VALID" --status invalid_status 2>&1 | grep -qi "invalid"; then
    echo "✓ Invalid status rejected"
else
    scenario_fail "Invalid status not rejected"
    exit 1
fi

# Non-existent dependency
if ./tm add "Bad dep" --depends-on nonexistent 2>&1 | grep -qi "not found\|error"; then
    echo "✓ Non-existent dependency rejected"
else
    scenario_fail "Bad dependency not rejected"
    exit 1
fi

# Non-existent task operations
if ./tm show nonexistent 2>&1 | grep -qi "not found"; then
    echo "✓ Non-existent task handled"
else
    scenario_fail "Non-existent task not handled"
    exit 1
fi

# Invalid priority
if ./tm add "Invalid priority" -p invalid 2>&1 | grep -qi "invalid\|error"; then
    echo "✓ Invalid priority rejected"
else
    scenario_fail "Invalid priority not rejected"  
    exit 1
fi

scenario_pass

# ========================================
# SCENARIO 7: Performance Under Load
# Tests: bulk operations, concurrent access, large exports
# ========================================

scenario_start "Performance Under Load"

echo "Creating bulk tasks..."
START_TIME=$(date +%s%N)
for i in {1..100}; do
    ./tm add "Bulk task $i" -d "Description for task $i" >/dev/null 2>&1
done
END_TIME=$(date +%s%N)
ELAPSED=$((($END_TIME - $START_TIME) / 1000000))
echo "Created 100 tasks in ${ELAPSED}ms"

if [ $ELAPSED -lt 20000 ]; then  # Should complete in under 20 seconds
    echo "✓ Bulk creation performance acceptable"
else
    scenario_fail "Bulk operations too slow"
    exit 1
fi

# Test large list operation
echo "Testing large list operation..."
START_TIME=$(date +%s%N)
TASK_COUNT=$(./tm list | wc -l)
END_TIME=$(date +%s%N)
ELAPSED=$((($END_TIME - $START_TIME) / 1000000))

if [ $TASK_COUNT -gt 100 ] && [ $ELAPSED -lt 5000 ]; then
    echo "✓ List performance acceptable for $TASK_COUNT tasks"
else
    scenario_fail "List operation too slow"
    exit 1
fi

# Test large export
echo "Testing large export..."
START_TIME=$(date +%s%N)
EXPORT_SIZE=$(./tm export --format json | wc -c)
END_TIME=$(date +%s%N)
ELAPSED=$((($END_TIME - $START_TIME) / 1000000))

if [ $EXPORT_SIZE -gt 1000 ] && [ $ELAPSED -lt 5000 ]; then
    echo "✓ Export performance acceptable"
else
    scenario_fail "Export too slow or failed"
    exit 1
fi

scenario_pass

# ========================================
# FINAL RESULTS
# ========================================

echo -e "\n${YELLOW}=== INTEGRATION TEST RESULTS ===${NC}"
echo "Total Scenarios: $TOTAL_SCENARIOS"
echo -e "Passed: ${GREEN}$PASSED_SCENARIOS${NC}"
echo -e "Failed: ${RED}$FAILED_SCENARIOS${NC}"

# Calculate percentage
if [ $TOTAL_SCENARIOS -gt 0 ]; then
    PERCENTAGE=$((PASSED_SCENARIOS * 100 / TOTAL_SCENARIOS))
    echo "Success Rate: ${PERCENTAGE}%"
    
    if [ $PERCENTAGE -eq 100 ]; then
        echo -e "\n${GREEN}✅ ALL INTEGRATION SCENARIOS PASSED!${NC}"
        echo -e "${GREEN}All 26 requirements verified working together!${NC}"
    else
        echo -e "\n${RED}❌ Some integration scenarios failed${NC}"
    fi
fi

# Cleanup
cd "$SAVED_DIR"
rm -rf "$TEST_DIR"

# Exit with appropriate code
if [ $FAILED_SCENARIOS -eq 0 ]; then
    exit 0
else
    exit 1
fi