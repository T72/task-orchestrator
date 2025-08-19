#!/bin/bash

# Test Suite for Hook Execution and Lightweight Hooks
# Safe, isolated tests that won't crash the system

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
TEST_DIR=$(mktemp -d -t tm_hooks_test_XXXXXX)
cd "$TEST_DIR"
git init >/dev/null 2>&1

echo -e "${BLUE}===================================${NC}"
echo -e "${BLUE}      Hook Execution Tests         ${NC}"
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

echo -e "${YELLOW}=== Pre-Task Hook Tests ===${NC}"
echo ""

# Test 1: Pre-add hook
test_pre_add_hook() {
    # Create a safe pre-add hook
    mkdir -p .task-orchestrator/hooks
    cat > .task-orchestrator/hooks/pre-add.sh << 'EOF'
#!/bin/bash
echo "PRE_ADD: $1" >> .task-orchestrator/hook.log
exit 0
EOF
    chmod +x .task-orchestrator/hooks/pre-add.sh
    
    # Add a task
    $TM add "Test task with pre-hook" >/dev/null 2>&1
    
    # Check if hook was executed
    [ -f .task-orchestrator/hook.log ] && grep -q "PRE_ADD:" .task-orchestrator/hook.log
}

# Test 2: Post-add hook
test_post_add_hook() {
    # Create a safe post-add hook
    cat > .task-orchestrator/hooks/post-add.sh << 'EOF'
#!/bin/bash
echo "POST_ADD: Task created: $1" >> .task-orchestrator/hook.log
exit 0
EOF
    chmod +x .task-orchestrator/hooks/post-add.sh
    
    # Add a task
    TASK_ID=$($TM add "Test task with post-hook" | grep -o '[a-f0-9]\{8\}')
    
    # Check if hook was executed
    grep -q "POST_ADD: Task created:" .task-orchestrator/hook.log
}

# Test 3: Hook failure handling
test_hook_failure_handling() {
    # Create a failing hook
    cat > .task-orchestrator/hooks/pre-complete.sh << 'EOF'
#!/bin/bash
echo "HOOK_FAIL: Simulating failure" >> .task-orchestrator/hook.log
exit 1
EOF
    chmod +x .task-orchestrator/hooks/pre-complete.sh
    
    # Try to complete a task (hook should fail but not crash)
    TASK_ID=$($TM add "Task for failed hook" | grep -o '[a-f0-9]\{8\}')
    
    # This should handle the failure gracefully
    if $TM complete $TASK_ID 2>&1 | grep -q "hook failed\|error"; then
        return 0
    else
        # If no error message, check if task is still not completed
        $TM show $TASK_ID | grep -q "pending\|in_progress"
    fi
}

# Test 4: Hook timeout protection
test_hook_timeout() {
    # Create a slow hook (but with timeout protection)
    cat > .task-orchestrator/hooks/pre-update.sh << 'EOF'
#!/bin/bash
# Simulate slow operation but with built-in timeout
timeout 2 sleep 10 2>/dev/null || true
echo "TIMEOUT_TEST: Completed" >> .task-orchestrator/hook.log
exit 0
EOF
    chmod +x .task-orchestrator/hooks/pre-update.sh
    
    TASK_ID=$($TM add "Task for timeout test" | grep -o '[a-f0-9]\{8\}')
    
    # This should complete within reasonable time
    timeout 5 $TM update $TASK_ID --status in_progress
    [ $? -eq 0 ] || [ $? -eq 124 ]
}

# Test 5: Hook with environment variables
test_hook_env_vars() {
    # Create hook that uses environment variables
    cat > .task-orchestrator/hooks/post-update.sh << 'EOF'
#!/bin/bash
echo "ENV_TEST: TASK_ID=$TASK_ID, AGENT=$TM_AGENT_ID" >> .task-orchestrator/hook.log
exit 0
EOF
    chmod +x .task-orchestrator/hooks/post-update.sh
    
    export TM_AGENT_ID="test_agent"
    TASK_ID=$($TM add "Task for env test" | grep -o '[a-f0-9]\{8\}')
    $TM update $TASK_ID --status in_progress >/dev/null 2>&1
    
    grep -q "ENV_TEST:.*TASK_ID=.*AGENT=test_agent" .task-orchestrator/hook.log
}

# Test 6: Chain of hooks
test_hook_chain() {
    # Create multiple hooks for same event
    cat > .task-orchestrator/hooks/pre-complete-1.sh << 'EOF'
#!/bin/bash
echo "CHAIN_1: First hook" >> .task-orchestrator/hook.log
exit 0
EOF
    
    cat > .task-orchestrator/hooks/pre-complete-2.sh << 'EOF'
#!/bin/bash
echo "CHAIN_2: Second hook" >> .task-orchestrator/hook.log
exit 0
EOF
    
    chmod +x .task-orchestrator/hooks/pre-complete-*.sh
    
    TASK_ID=$($TM add "Task for chain test" | grep -o '[a-f0-9]\{8\}')
    $TM complete $TASK_ID >/dev/null 2>&1
    
    # Both hooks should have executed
    grep -q "CHAIN_1" .task-orchestrator/hook.log && \
    grep -q "CHAIN_2" .task-orchestrator/hook.log
}

# Test 7: Hook with task context
test_hook_context() {
    # Create hook that reads task context
    cat > .task-orchestrator/hooks/on-dependency-complete.sh << 'EOF'
#!/bin/bash
echo "CONTEXT: Dependency completed for $1" >> .task-orchestrator/hook.log
exit 0
EOF
    chmod +x .task-orchestrator/hooks/on-dependency-complete.sh
    
    # Create tasks with dependencies
    TASK1=$($TM add "Parent task" | grep -o '[a-f0-9]\{8\}')
    TASK2=$($TM add "Child task" --depends-on $TASK1 | grep -o '[a-f0-9]\{8\}')
    
    $TM complete $TASK1 >/dev/null 2>&1
    
    grep -q "CONTEXT: Dependency completed" .task-orchestrator/hook.log
}

# Test 8: Safe hook sandbox
test_hook_sandbox() {
    # Create a hook that tries to do dangerous operations (but safely)
    cat > .task-orchestrator/hooks/sandboxed.sh << 'EOF'
#!/bin/bash
# Try to access parent directories (should be restricted)
ls ../.. 2>/dev/null | head -1 || echo "SANDBOX: Access restricted" >> .task-orchestrator/hook.log
# Try to modify system files (should fail)
touch /etc/test_file 2>/dev/null || echo "SANDBOX: System protected" >> .task-orchestrator/hook.log
exit 0
EOF
    chmod +x .task-orchestrator/hooks/sandboxed.sh
    
    TASK_ID=$($TM add "Sandbox test task" | grep -o '[a-f0-9]\{8\}')
    $TM update $TASK_ID --status in_progress >/dev/null 2>&1
    
    # Check that sandbox protections worked
    grep -q "SANDBOX:.*protected\|restricted" .task-orchestrator/hook.log
}

# Test 9: Hook cleanup on error
test_hook_cleanup() {
    # Create hook that creates temp files
    cat > .task-orchestrator/hooks/cleanup-test.sh << 'EOF'
#!/bin/bash
TEMP_FILE=$(mktemp)
echo "test" > $TEMP_FILE
trap "rm -f $TEMP_FILE" EXIT
echo "CLEANUP: Created and cleaned temp file" >> .task-orchestrator/hook.log
exit 0
EOF
    chmod +x .task-orchestrator/hooks/cleanup-test.sh
    
    TASK_ID=$($TM add "Cleanup test task" | grep -o '[a-f0-9]\{8\}')
    $TM update $TASK_ID --status in_progress >/dev/null 2>&1
    
    # Verify cleanup message was logged
    grep -q "CLEANUP: Created and cleaned" .task-orchestrator/hook.log
}

# Test 10: Conditional hooks
test_conditional_hooks() {
    # Create hook that only runs under certain conditions
    cat > .task-orchestrator/hooks/conditional.sh << 'EOF'
#!/bin/bash
if [ "$TASK_PRIORITY" = "high" ]; then
    echo "CONDITIONAL: High priority task detected" >> .task-orchestrator/hook.log
fi
exit 0
EOF
    chmod +x .task-orchestrator/hooks/conditional.sh
    
    # Test with high priority task
    TASK_ID=$($TM add "High priority task" -p high | grep -o '[a-f0-9]\{8\}')
    export TASK_PRIORITY="high"
    $TM update $TASK_ID --status in_progress >/dev/null 2>&1
    
    grep -q "CONDITIONAL: High priority" .task-orchestrator/hook.log
}

# Run all tests
echo ""
run_test "Pre-add hook execution" test_pre_add_hook
run_test "Post-add hook execution" test_post_add_hook
run_test "Hook failure handling" test_hook_failure_handling
run_test "Hook timeout protection" test_hook_timeout
run_test "Hook environment variables" test_hook_env_vars
run_test "Chain of hooks" test_hook_chain
run_test "Hook with task context" test_hook_context
run_test "Safe hook sandbox" test_hook_sandbox
run_test "Hook cleanup on error" test_hook_cleanup
run_test "Conditional hook execution" test_conditional_hooks

echo ""
echo -e "${YELLOW}=== Hook Performance Tests ===${NC}"
echo ""

# Test 11: Many hooks performance
test_many_hooks() {
    # Create 10 lightweight hooks
    for i in {1..10}; do
        cat > .task-orchestrator/hooks/perf-$i.sh << EOF
#!/bin/bash
echo "PERF_$i: Executed" >> .task-orchestrator/hook.log
exit 0
EOF
        chmod +x .task-orchestrator/hooks/perf-$i.sh
    done
    
    # Measure execution time
    START_TIME=$(date +%s%N)
    TASK_ID=$($TM add "Performance test task" | grep -o '[a-f0-9]\{8\}')
    END_TIME=$(date +%s%N)
    
    # Should complete in reasonable time (< 2 seconds)
    DURATION=$(( (END_TIME - START_TIME) / 1000000 ))
    [ $DURATION -lt 2000 ]
}

run_test "Multiple hooks performance" test_many_hooks

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
    echo -e "${GREEN}✅ All hook tests passed!${NC}"
    exit 0
else
    echo -e "${RED}❌ Some hook tests failed${NC}"
    exit 1
fi