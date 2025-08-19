#!/bin/bash
set -e

# Test script for context sharing features - ISOLATED VERSION with WSL Safety
# Tests private notes and shared context collaboration

# Detect WSL environment
IS_WSL=0
if grep -qi microsoft /proc/version 2>/dev/null; then
    IS_WSL=1
    echo "WSL environment detected - enabling safety measures"
fi

# Create isolated test environment with WSL-safe options
if [ $IS_WSL -eq 1 ]; then
    # Use /tmp directly for WSL to avoid filesystem issues
    TEST_DIR="/tmp/tm_context_test_$$_$(date +%s)"
    mkdir -p "$TEST_DIR"
    # Set resource limits for WSL
    # ulimit -n 512 2>/dev/null || true  # Limit file descriptors
    # ulimit -u 100 2>/dev/null || true   # Limit processes
    export SQLITE_TMPDIR="$TEST_DIR"
    export TM_WSL_MODE=1
else
    TEST_DIR=$(mktemp -d -t tm_context_test_XXXXXX)
fi

echo "Running context sharing tests in isolated directory: $TEST_DIR"
PASS=0
FAIL=0

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Find tm executable safely
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "${SCRIPT_DIR}")"

if [ -f "$PARENT_DIR/tm" ]; then
    TM_ORIG="$PARENT_DIR/tm"
elif [ -f "./tm" ]; then
    TM_ORIG="./tm"
else
    echo "Error: tm executable not found"
    rm -rf "$TEST_DIR"
    exit 1
fi

# Setup test environment with WSL safety
setup() {
    cd "$TEST_DIR"
    # Copy tm executable to test directory for complete isolation
    cp "$TM_ORIG" ./tm
    # Also copy Python modules if they exist
    if [ -d "$PARENT_DIR/src" ]; then
        cp -r "$PARENT_DIR/src" ./
    fi
    TM="./tm"
    chmod +x "$TM"
    
    # Add WSL-specific delay for filesystem sync
    if [ $IS_WSL -eq 1 ]; then
        sleep 0.5
        sync
    fi
    
    git init > /dev/null 2>&1
    
    # Initialize with retry for WSL
    INIT_SUCCESS=0
    for attempt in 1 2 3; do
        if [ $IS_WSL -eq 1 ] && [ $attempt -gt 1 ]; then
            sleep 1
        fi
        
        if $TM init > /dev/null 2>&1; then
            INIT_SUCCESS=1
            break
        fi
    done
    
    if [ $INIT_SUCCESS -eq 0 ]; then
        echo "Failed to initialize database after 3 attempts"
        exit 1
    fi
    
    # Small delay after init for WSL
    if [ $IS_WSL -eq 1 ]; then
        sleep 0.2
    fi
}

# Cleanup function with trap and WSL safety
cleanup() {
    # Kill any remaining background processes
    jobs -p | xargs -r kill 2>/dev/null || true
    pkill -f "tm.*$TEST_DIR" 2>/dev/null || true
    
    # Add delay for WSL
    if [ $IS_WSL -eq 1 ]; then
        sleep 0.5
        sync
    fi
    
    cd / 2>/dev/null || cd /tmp
    rm -rf "$TEST_DIR" 2>/dev/null || true
}

# Set trap for cleanup on exit with proper signal handling
trap cleanup EXIT INT TERM

# Test function
run_test() {
    local test_name="$1"
    local test_func="$2"
    
    echo -n "Testing $test_name... "
    
    if $test_func > /dev/null 2>&1; then
        echo -e "${GREEN}PASS${NC}"
        ((PASS++))
    else
        echo -e "${RED}FAIL${NC}"
        ((FAIL++))
    fi
}

# Test 1: Initialize context with task
test_init_context() {
    local task_id=$($TM add "Collaborative feature" --with-context | grep "Task ID:" | cut -d' ' -f3)
    [ -n "$task_id" ] && [ -f ".task-orchestrator/contexts/${task_id}_context.yaml" ]
}

# Test 2: Join context as contributor
test_join_context() {
    local task_id=$($TM add "Team task" | grep "Task ID:" | cut -d' ' -f3)
    export TM_AGENT_ID="agent_001"
    $TM context join "$task_id" --role contributor
    unset TM_AGENT_ID
}

# Test 3: Write private notes
test_private_notes() {
    local task_id=$($TM add "Research task" --with-context | grep "Task ID:" | cut -d' ' -f3)
    export TM_AGENT_ID="researcher_001"
    $TM context join "$task_id"
    $TM context update "$task_id" --type private --content "Initial research findings: API needs refactoring"
    [ -f ".task-orchestrator/notes/${task_id}_researcher_001.md" ]
    unset TM_AGENT_ID
}

# Test 4: Update shared context
test_shared_context() {
    local task_id=$($TM add "Shared work" --with-context | grep "Task ID:" | cut -d' ' -f3)
    export TM_AGENT_ID="dev_001"
    $TM context join "$task_id"
    $TM context update "$task_id" --type shared --section agent_sections \
        --content '{"type":"progress","content":"Completed API design"}'
    
    # Check if context was updated
    $TM context read "$task_id" --type shared | grep -q "Completed API design"
    unset TM_AGENT_ID
}

# Test 5: Multiple agents collaborating
test_multi_agent_collab() {
    local task_id=$($TM add "Multi-agent project" --with-context | grep "Task ID:" | cut -d' ' -f3)
    
    # Agent 1 joins and contributes
    export TM_AGENT_ID="frontend_dev"
    $TM context join "$task_id" --role frontend
    $TM context update "$task_id" --type shared --section agent_sections \
        --content '{"type":"update","content":"UI mockups ready"}'
    
    # Agent 2 joins and contributes  
    export TM_AGENT_ID="backend_dev"
    $TM context join "$task_id" --role backend
    $TM context update "$task_id" --type shared --section agent_sections \
        --content '{"type":"update","content":"Database schema defined"}'
    
    # Check both contributions exist
    local context=$($TM context read "$task_id" --type shared)
    echo "$context" | grep -q "UI mockups ready" && \
    echo "$context" | grep -q "Database schema defined"
    
    unset TM_AGENT_ID
}

# Test 6: Share discovery
test_share_discovery() {
    local task_id=$($TM add "Discovery task" --with-context | grep "Task ID:" | cut -d' ' -f3)
    export TM_AGENT_ID="analyst_001"
    $TM context join "$task_id"
    $TM context discover "$task_id" "Found performance bottleneck in query" \
        --impact "30% speed improvement possible" --tags optimization database
    
    # Check discovery was recorded
    $TM context read "$task_id" --type shared | grep -q "performance bottleneck"
    unset TM_AGENT_ID
}

# Test 7: Create sync point
test_sync_point() {
    local task_id=$($TM add "Sync task" --with-context | grep "Task ID:" | cut -d' ' -f3)
    export TM_AGENT_ID="coordinator"
    $TM context join "$task_id" --role orchestrator
    $TM context sync "$task_id" "Phase 1 complete" --ready-for frontend_dev backend_dev
    
    # Check sync point exists
    $TM context read "$task_id" --type shared | grep -q "Phase 1 complete"
    unset TM_AGENT_ID
}

# Test 8: List participants
test_list_participants() {
    local task_id=$($TM add "Team project" --with-context | grep "Task ID:" | cut -d' ' -f3)
    
    # Multiple agents join
    export TM_AGENT_ID="dev1"
    $TM context join "$task_id"
    export TM_AGENT_ID="dev2"
    $TM context join "$task_id"
    export TM_AGENT_ID="tester1"
    $TM context join "$task_id" --role tester
    
    # Get participants
    local participants=$($TM context participants "$task_id")
    echo "$participants" | grep -q "dev1" && \
    echo "$participants" | grep -q "dev2" && \
    echo "$participants" | grep -q "tester1"
    
    unset TM_AGENT_ID
}

# Test 9: Private notes isolation
test_private_notes_isolation() {
    local task_id=$($TM add "Private task" --with-context | grep "Task ID:" | cut -d' ' -f3)
    
    # Agent 1 writes private notes
    export TM_AGENT_ID="agent1"
    $TM context join "$task_id"
    $TM context update "$task_id" --type private --content "Secret plan A"
    
    # Agent 2 writes different private notes
    export TM_AGENT_ID="agent2"
    $TM context join "$task_id"
    $TM context update "$task_id" --type private --content "Secret plan B"
    
    # Verify separate files exist
    [ -f ".task-orchestrator/notes/${task_id}_agent1.md" ] && \
    [ -f ".task-orchestrator/notes/${task_id}_agent2.md" ] && \
    ! grep -q "Secret plan B" ".task-orchestrator/notes/${task_id}_agent1.md"
    
    unset TM_AGENT_ID
}

# Test 10: Global context update
test_global_context() {
    local task_id=$($TM add "Global context task" --with-context | grep "Task ID:" | cut -d' ' -f3)
    export TM_AGENT_ID="architect"
    $TM context join "$task_id" --role orchestrator
    
    $TM context update "$task_id" --type shared --section global_context \
        --content '{"description":"Build microservices architecture","requirements":["REST API","Docker"]}'
    
    # Check global context
    $TM context read "$task_id" --type shared | grep -q "microservices architecture"
    unset TM_AGENT_ID
}

# Main test execution
main() {
    echo "==================================="
    echo "Context Sharing Feature Tests"
    echo "==================================="
    
    # Setup
    setup
    
    # Run tests
    run_test "Initialize context with task" test_init_context
    run_test "Join context as contributor" test_join_context
    run_test "Write private notes" test_private_notes
    run_test "Update shared context" test_shared_context
    run_test "Multi-agent collaboration" test_multi_agent_collab
    run_test "Share discovery" test_share_discovery
    run_test "Create sync point" test_sync_point
    run_test "List participants" test_list_participants
    run_test "Private notes isolation" test_private_notes_isolation
    run_test "Global context update" test_global_context
    
    # Summary (cleanup will be handled by trap)
    echo "==================================="
    echo "Test Summary:"
    echo -e "Passed: ${GREEN}$PASS${NC}"
    echo -e "Failed: ${RED}$FAIL${NC}"
    
    if [ $FAIL -eq 0 ]; then
        echo -e "${GREEN}All tests passed!${NC}"
        EXIT_CODE=0
    else
        echo -e "${RED}Some tests failed${NC}"
        EXIT_CODE=1
    fi
    
    # Cleanup is handled by trap
    exit $EXIT_CODE
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main
fi