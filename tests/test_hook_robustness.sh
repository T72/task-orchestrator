#!/bin/bash
# Hook Robustness Test Suite
# Tests all hooks with various input structures per our new standards

set -e

echo "========================================="
echo "    Hook Robustness Test Suite          "
echo "========================================="
echo
echo "Testing hooks with variable input structures..."
echo

HOOKS_DIR=".claude/hooks"
PASSED=0
FAILED=0

# Test data patterns
MINIMAL_TODO='{"tool_name":"TodoWrite","tool_input":{"todos":[{"content":"Test","status":"pending"}]}}'
STANDARD_TODO='{"tool_name":"TodoWrite","tool_input":{"todos":[{"content":"Test","status":"pending"},{"content":"Test2","status":"in_progress"}]}}'
EXTENDED_TODO='{"tool_name":"TodoWrite","tool_input":{"todos":[{"id":"task_123","content":"Test","status":"completed","metadata":{"progress":"Done","artifacts":["file.txt"]}}]}}'
MALFORMED_TODO='{"tool_name":"TodoWrite","tool_input":{"todos":[{}]}}'
EMPTY_TODO='{"tool_name":"TodoWrite","tool_input":{"todos":[]}}'

# Function to test a hook
test_hook() {
    local hook_file=$1
    local test_name=$2
    local test_data=$3
    
    echo -n "  Testing $test_name... "
    
    # Run with timeout (5 seconds max per our standards)
    if timeout 5 echo "$test_data" | python3 "$hook_file" 2>/dev/null | grep -q '"decision"'; then
        echo "✓"
        ((PASSED++))
        return 0
    else
        echo "✗"
        ((FAILED++))
        return 1
    fi
}

# Test each hook that handles TodoWrite
for hook in checkpoint-manager.py event-flows.py task-dependencies.py; do
    hook_path="$HOOKS_DIR/$hook"
    
    if [ -f "$hook_path" ]; then
        echo "Testing: $hook"
        echo "----------------------------------------"
        
        # Test with various input structures
        test_hook "$hook_path" "minimal structure" "$MINIMAL_TODO" || true
        test_hook "$hook_path" "standard structure" "$STANDARD_TODO" || true
        test_hook "$hook_path" "extended structure" "$EXTENDED_TODO" || true
        test_hook "$hook_path" "malformed input" "$MALFORMED_TODO" || true
        test_hook "$hook_path" "empty todos" "$EMPTY_TODO" || true
        
        echo
    fi
done

# PRD parser removed in v2.5 - feature deprecated for simplification

# Performance test - ensure hooks complete within 100ms
echo "Performance Testing"
echo "----------------------------------------"

for hook in checkpoint-manager.py event-flows.py; do
    hook_path="$HOOKS_DIR/$hook"
    
    if [ -f "$hook_path" ]; then
        echo -n "  $hook response time... "
        
        start_time=$(date +%s%3N)
        echo "$STANDARD_TODO" | python3 "$hook_path" >/dev/null 2>&1
        end_time=$(date +%s%3N)
        
        duration=$((end_time - start_time))
        
        if [ $duration -lt 100 ]; then
            echo "✓ (${duration}ms)"
            ((PASSED++))
        else
            echo "✗ (${duration}ms - exceeds 100ms target)"
            ((FAILED++))
        fi
    fi
done

echo
echo "========================================="
echo "            Test Summary                "
echo "========================================="
echo "Passed: $PASSED"
echo "Failed: $FAILED"

if [ $FAILED -eq 0 ]; then
    echo "✅ All hook robustness tests passed!"
    exit 0
else
    echo "❌ Some tests failed. Review hook implementations."
    exit 1
fi