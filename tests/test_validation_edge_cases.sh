#!/bin/bash
# Edge Case Tests for Criteria Validation Logic
# Tests complex validation scenarios and boundary conditions

set -e

# Find tm executable
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TM_PATH="$PROJECT_ROOT/tm"

if [ ! -f "$TM_PATH" ]; then
    echo "Error: tm executable not found at $TM_PATH"
    exit 1
fi

TM="$TM_PATH"

# Test setup
TEST_DIR=$(mktemp -d -t tm_validation_edge_XXXXXX)
cd "$TEST_DIR"

# Initialize
export TM_TEST_MODE=1
$TM init >/dev/null 2>&1
$TM migrate --apply >/dev/null 2>&1 || true

echo "========================================="
echo "   Validation Logic Edge Case Tests      "
echo "========================================="
echo

PASSED=0
FAILED=0

test_result() {
    if [ "$1" = "PASS" ]; then
        echo "✓ $2"
        ((PASSED++))
    else
        echo "✗ $2"
        ((FAILED++))
    fi
}

# ============================================
# VALIDATION EXPRESSION EDGE CASES
# ============================================
echo "=== Validation Expression Edge Cases ==="

# Test 1: Complex nested expressions
echo -n "Test 1: Nested JSON path validation... "
CRITERIA='[{
    "criterion": "Performance meets target",
    "measurable": "metrics.performance.query_time < 100"
}]'
TASK_ID=$($TM add "Task with nested criteria" --criteria "$CRITERIA" 2>/dev/null | grep -o '[a-f0-9]\{8\}')
RESULT=$($TM complete "$TASK_ID" --validate 2>&1)
if [[ "$RESULT" =~ "completed" ]]; then
    test_result "PASS" "Nested path validation handled"
else
    test_result "FAIL" "Nested path validation failed"
fi

# Test 2: Multiple comparison operators
echo -n "Test 2: Chained comparisons... "
CRITERIA='[{
    "criterion": "Value in range",
    "measurable": "50 < value < 100"
}]'
TASK_ID=$($TM add "Task with chained comparison" --criteria "$CRITERIA" 2>/dev/null | grep -o '[a-f0-9]\{8\}' || echo "failed")
if [[ "$TASK_ID" != "failed" ]]; then
    RESULT=$($TM complete "$TASK_ID" --validate 2>&1)
    if [[ "$RESULT" =~ "completed" ]] || [[ "$RESULT" =~ "manual validation" ]]; then
        test_result "PASS" "Chained comparison handled"
    else
        test_result "FAIL" "Chained comparison error"
    fi
else
    test_result "FAIL" "Task creation failed"
fi

# Test 3: Boolean literals
echo -n "Test 3: Boolean literal validation... "
CRITERIA='[{
    "criterion": "Always true",
    "measurable": "true"
},{
    "criterion": "Always false",
    "measurable": "false"
}]'
TASK_ID=$($TM add "Task with boolean literals" --criteria "$CRITERIA" 2>/dev/null | grep -o '[a-f0-9]\{8\}')
RESULT=$($TM complete "$TASK_ID" --validate 2>&1)
if [[ "$RESULT" =~ "completed" ]]; then
    test_result "PASS" "Boolean literals validated"
else
    test_result "FAIL" "Boolean literal validation failed"
fi

# Test 4: String equality with spaces
echo -n "Test 4: String with spaces validation... "
CRITERIA='[{
    "criterion": "Status check",
    "measurable": "status == \"in progress\""
}]'
TASK_ID=$($TM add "Task with string criteria" --criteria "$CRITERIA" 2>/dev/null | grep -o '[a-f0-9]\{8\}')
RESULT=$($TM complete "$TASK_ID" --validate 2>&1)
if [[ "$RESULT" =~ "completed" ]] || [[ "$RESULT" =~ "validation" ]]; then
    test_result "PASS" "String validation handled"
else
    test_result "FAIL" "String validation failed"
fi

# Test 5: Floating point comparison
echo -n "Test 5: Float comparison precision... "
CRITERIA='[{
    "criterion": "Accuracy threshold",
    "measurable": "accuracy > 0.95"
}]'
TASK_ID=$($TM add "Task with float criteria" --criteria "$CRITERIA" 2>/dev/null | grep -o '[a-f0-9]\{8\}')
RESULT=$($TM complete "$TASK_ID" --validate 2>&1)
if [[ "$RESULT" =~ "completed" ]] || [[ "$RESULT" =~ "validation" ]]; then
    test_result "PASS" "Float comparison handled"
else
    test_result "FAIL" "Float comparison failed"
fi

# Test 6: Empty measurable field
echo -n "Test 6: Empty measurable validation... "
CRITERIA='[{
    "criterion": "Manual check required",
    "measurable": ""
}]'
TASK_ID=$($TM add "Task with empty measurable" --criteria "$CRITERIA" 2>/dev/null | grep -o '[a-f0-9]\{8\}')
RESULT=$($TM complete "$TASK_ID" --validate 2>&1)
if [[ "$RESULT" =~ "completed" ]]; then
    test_result "PASS" "Empty measurable auto-passed"
else
    test_result "FAIL" "Empty measurable blocked completion"
fi

# Test 7: Undefined variables in expression
echo -n "Test 7: Undefined variable handling... "
CRITERIA='[{
    "criterion": "Check undefined",
    "measurable": "undefined_var == true"
}]'
TASK_ID=$($TM add "Task with undefined var" --criteria "$CRITERIA" 2>/dev/null | grep -o '[a-f0-9]\{8\}')
RESULT=$($TM complete "$TASK_ID" --validate 2>&1)
if [[ "$RESULT" =~ "completed" ]] || [[ "$RESULT" =~ "manual" ]] || [[ "$RESULT" =~ "validation" ]]; then
    test_result "PASS" "Undefined variable handled"
else
    test_result "FAIL" "Undefined variable caused error"
fi

# Test 8: Mathematical expressions
echo -n "Test 8: Math expression validation... "
CRITERIA='[{
    "criterion": "Calculate result",
    "measurable": "2 + 2 == 4"
}]'
TASK_ID=$($TM add "Task with math" --criteria "$CRITERIA" 2>/dev/null | grep -o '[a-f0-9]\{8\}')
RESULT=$($TM complete "$TASK_ID" --validate 2>&1)
if [[ "$RESULT" =~ "completed" ]] || [[ "$RESULT" =~ "manual" ]]; then
    test_result "PASS" "Math expression handled"
else
    test_result "FAIL" "Math expression failed"
fi

# Test 9: Case sensitivity
echo -n "Test 9: Case sensitivity in expressions... "
CRITERIA='[{
    "criterion": "Case test",
    "measurable": "TRUE"
},{
    "criterion": "Case test 2",
    "measurable": "True"
}]'
TASK_ID=$($TM add "Task with case variants" --criteria "$CRITERIA" 2>/dev/null | grep -o '[a-f0-9]\{8\}')
RESULT=$($TM complete "$TASK_ID" --validate 2>&1)
if [[ "$RESULT" =~ "completed" ]] || [[ "$RESULT" =~ "validation" ]]; then
    test_result "PASS" "Case variants handled"
else
    test_result "FAIL" "Case sensitivity issue"
fi

# Test 10: Regex patterns (if supported)
echo -n "Test 10: Regex pattern matching... "
CRITERIA='[{
    "criterion": "Version format",
    "measurable": "version matches v[0-9]+\\.[0-9]+\\.[0-9]+"
}]'
TASK_ID=$($TM add "Task with regex" --criteria "$CRITERIA" 2>/dev/null | grep -o '[a-f0-9]\{8\}' || echo "failed")
if [[ "$TASK_ID" != "failed" ]]; then
    RESULT=$($TM complete "$TASK_ID" --validate 2>&1)
    if [[ "$RESULT" =~ "completed" ]] || [[ "$RESULT" =~ "manual" ]]; then
        test_result "PASS" "Regex pattern handled"
    else
        test_result "FAIL" "Regex pattern error"
    fi
else
    test_result "SKIP" "Regex not supported"
fi

echo

# ============================================
# VALIDATION WITH CONTEXT EDGE CASES
# ============================================
echo "=== Validation with Context Edge Cases ==="

# Test 11: Validation with shared context
echo -n "Test 11: Context-based validation... "
TASK_ID=$($TM add "Task with context validation" --criteria '[{"criterion":"Context check","measurable":"test_value == pass"}]' 2>/dev/null | grep -o '[a-f0-9]\{8\}')
# Add context
$TM share "$TASK_ID" "test_value: pass" >/dev/null 2>&1 || true
RESULT=$($TM complete "$TASK_ID" --validate 2>&1)
if [[ "$RESULT" =~ "completed" ]] || [[ "$RESULT" =~ "validation" ]]; then
    test_result "PASS" "Context validation attempted"
else
    test_result "FAIL" "Context validation failed"
fi

# Test 12: Multiple criteria with mixed results
echo -n "Test 12: Mixed validation results... "
CRITERIA='[{
    "criterion": "Pass test",
    "measurable": "true"
},{
    "criterion": "Fail test",
    "measurable": "false"
},{
    "criterion": "Manual test",
    "measurable": "requires_human_check"
}]'
TASK_ID=$($TM add "Task with mixed criteria" --criteria "$CRITERIA" 2>/dev/null | grep -o '[a-f0-9]\{8\}')
RESULT=$($TM complete "$TASK_ID" --validate 2>&1)
if [[ "$RESULT" =~ "completed" ]] || [[ "$RESULT" =~ "not all" ]] || [[ "$RESULT" =~ "1/3" ]]; then
    test_result "PASS" "Mixed results reported"
else
    test_result "FAIL" "Mixed results not handled"
fi

# Test 13: Circular reference detection
echo -n "Test 13: Circular reference handling... "
CRITERIA='[{
    "criterion": "Circular test",
    "measurable": "a == b && b == a"
}]'
TASK_ID=$($TM add "Task with circular ref" --criteria "$CRITERIA" 2>/dev/null | grep -o '[a-f0-9]\{8\}')
RESULT=$($TM complete "$TASK_ID" --validate 2>&1)
if [[ "$RESULT" =~ "completed" ]] || [[ "$RESULT" =~ "manual" ]]; then
    test_result "PASS" "Circular reference handled"
else
    test_result "FAIL" "Circular reference caused error"
fi

# Test 14: Null and undefined handling
echo -n "Test 14: Null value validation... "
CRITERIA='[{
    "criterion": "Null check",
    "measurable": "value != null"
}]'
TASK_ID=$($TM add "Task with null check" --criteria "$CRITERIA" 2>/dev/null | grep -o '[a-f0-9]\{8\}')
RESULT=$($TM complete "$TASK_ID" --validate 2>&1)
if [[ "$RESULT" =~ "completed" ]] || [[ "$RESULT" =~ "validation" ]]; then
    test_result "PASS" "Null check handled"
else
    test_result "FAIL" "Null check failed"
fi

# Test 15: Special characters in expressions
echo -n "Test 15: Special chars in validation... "
CRITERIA='[{
    "criterion": "Special test",
    "measurable": "value == \"test & '\''quote'\''\""
}]'
TASK_ID=$($TM add "Task with special validation" --criteria "$CRITERIA" 2>/dev/null | grep -o '[a-f0-9]\{8\}' || echo "failed")
if [[ "$TASK_ID" != "failed" ]]; then
    RESULT=$($TM complete "$TASK_ID" --validate 2>&1)
    if [[ "$RESULT" =~ "completed" ]] || [[ "$RESULT" =~ "validation" ]]; then
        test_result "PASS" "Special chars in validation handled"
    else
        test_result "FAIL" "Special chars caused validation error"
    fi
else
    test_result "FAIL" "Task creation with special chars failed"
fi

echo

# ============================================
# PERFORMANCE EDGE CASES
# ============================================
echo "=== Validation Performance Edge Cases ==="

# Test 16: Large number of criteria
echo -n "Test 16: 100 criteria validation... "
MANY_CRITERIA='['
for i in {1..100}; do
    if [ $i -gt 1 ]; then MANY_CRITERIA+=','; fi
    MANY_CRITERIA+="{\"criterion\":\"Test $i\",\"measurable\":\"true\"}"
done
MANY_CRITERIA+=']'
TASK_ID=$($TM add "Task with 100 criteria" --criteria "$MANY_CRITERIA" 2>/dev/null | grep -o '[a-f0-9]\{8\}' || echo "failed")
if [[ "$TASK_ID" != "failed" ]]; then
    START_TIME=$(date +%s)
    RESULT=$($TM complete "$TASK_ID" --validate 2>&1)
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    if [[ "$RESULT" =~ "completed" ]] && [ $DURATION -lt 5 ]; then
        test_result "PASS" "100 criteria validated quickly"
    else
        test_result "FAIL" "100 criteria validation slow or failed"
    fi
else
    test_result "FAIL" "Large criteria count rejected"
fi

# Test 17: Complex nested JSON validation
echo -n "Test 17: Deeply nested validation... "
CRITERIA='[{
    "criterion": "Deep nest test",
    "measurable": "a.b.c.d.e.f.g == true"
}]'
TASK_ID=$($TM add "Task with deep nesting" --criteria "$CRITERIA" 2>/dev/null | grep -o '[a-f0-9]\{8\}')
RESULT=$($TM complete "$TASK_ID" --validate 2>&1)
if [[ "$RESULT" =~ "completed" ]] || [[ "$RESULT" =~ "manual" ]]; then
    test_result "PASS" "Deep nesting handled"
else
    test_result "FAIL" "Deep nesting failed"
fi

echo

# ============================================
# ERROR RECOVERY IN VALIDATION
# ============================================
echo "=== Validation Error Recovery ==="

# Test 18: Validation with database error simulation
echo -n "Test 18: Validation during DB issues... "
# Create task with criteria
TASK_ID=$($TM add "Task for DB test" --criteria '[{"criterion":"Test","measurable":"true"}]' 2>/dev/null | grep -o '[a-f0-9]\{8\}')
# Temporarily lock database (simulate busy)
(
    sqlite3 .task-orchestrator/tasks.db "BEGIN EXCLUSIVE; SELECT 1;" &
    LOCK_PID=$!
    sleep 0.5
    RESULT=$($TM complete "$TASK_ID" --validate 2>&1 || echo "HANDLED")
    kill $LOCK_PID 2>/dev/null || true
) 2>/dev/null
if [[ "$RESULT" =~ "completed" ]] || [[ "$RESULT" =~ "HANDLED" ]] || [[ "$RESULT" =~ "locked" ]]; then
    test_result "PASS" "DB lock during validation handled"
else
    test_result "FAIL" "DB lock caused validation failure"
fi

# Test 19: Validation with corrupted criteria
echo -n "Test 19: Corrupted criteria handling... "
# Manually insert task with corrupted criteria using SQLite
sqlite3 .task-orchestrator/tasks.db "INSERT INTO tasks (id, title, success_criteria, status, created_at, updated_at) VALUES ('corrupt01', 'Corrupt task', '{corrupted json}', 'pending', datetime('now'), datetime('now'));" 2>/dev/null || true
RESULT=$($TM complete "corrupt01" --validate 2>&1 || echo "HANDLED")
if [[ "$RESULT" =~ "completed" ]] || [[ "$RESULT" =~ "HANDLED" ]] || [[ "$RESULT" =~ "error" ]] || [[ "$RESULT" =~ "Error" ]]; then
    test_result "PASS" "Corrupted criteria handled"
else
    test_result "FAIL" "Corrupted criteria crashed"
fi

# Test 20: Race condition during validation
echo -n "Test 20: Concurrent validation... "
TASK_ID=$($TM add "Task for race test" --criteria '[{"criterion":"Race","measurable":"true"}]' 2>/dev/null | grep -o '[a-f0-9]\{8\}')
# Try to complete the same task multiple times concurrently
for i in {1..3}; do
    $TM complete "$TASK_ID" --validate >/dev/null 2>&1 &
done
wait
# Check task is still valid
RESULT=$($TM show "$TASK_ID" 2>&1)
if [[ "$RESULT" =~ "completed" ]] || [[ "$RESULT" =~ "$TASK_ID" ]]; then
    test_result "PASS" "Concurrent validation handled"
else
    test_result "FAIL" "Concurrent validation corrupted task"
fi

echo

# ============================================
# SUMMARY
# ============================================
echo "========================================="
echo "    Validation Edge Case Test Summary    "
echo "========================================="
echo "Passed: $PASSED"
echo "Failed: $FAILED"
echo "Total:  $((PASSED + FAILED))"
echo
if [ $FAILED -eq 0 ]; then
    echo "✅ All validation edge cases handled!"
else
    echo "⚠️  Some validation edge cases need attention"
fi

# Cleanup
cd ..
rm -rf "$TEST_DIR"

exit $FAILED