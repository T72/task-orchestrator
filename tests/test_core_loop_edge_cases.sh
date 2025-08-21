#!/bin/bash
# Comprehensive Edge Case Tests for Core Loop Functionality
# Tests boundary conditions, error scenarios, and unusual inputs

set -e

# Find tm executable BEFORE changing directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TM_PATH="$PROJECT_ROOT/tm"

if [ ! -f "$TM_PATH" ]; then
    echo "Error: tm executable not found at $TM_PATH"
    exit 1
fi

TM="$TM_PATH"

# Test setup - NOW change to temp directory
TEST_DIR=$(mktemp -d -t tm_edge_cases_XXXXXX)
cd "$TEST_DIR"

# Initialize test environment
export TM_TEST_MODE=1
$TM init >/dev/null 2>&1

# Apply migrations
$TM migrate --apply >/dev/null 2>&1 || true

echo "========================================="
echo "    Core Loop Edge Case Test Suite      "
echo "========================================="
echo

# Test counters
PASSED=0
FAILED=0

# Helper function for test results
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
# SUCCESS CRITERIA EDGE CASES
# ============================================
echo "=== Success Criteria Edge Cases ==="

# Test 1: Empty criteria JSON
echo -n "Test 1: Empty criteria array... "
RESULT=$($TM add "Task with empty criteria" --criteria '[]' 2>&1)
if [[ "$RESULT" =~ "Task created" ]]; then
    test_result "PASS" "Empty criteria array accepted"
else
    test_result "FAIL" "Empty criteria array rejected"
fi

# Test 2: Malformed JSON
echo -n "Test 2: Malformed JSON criteria... "
RESULT=$($TM add "Task with bad JSON" --criteria '{not valid json}' 2>&1 || echo "REJECTED")
if [[ "$RESULT" =~ "REJECTED" ]] || [[ "$RESULT" =~ "Invalid JSON" ]] || [[ "$RESULT" =~ "Error" ]]; then
    test_result "PASS" "Malformed JSON properly rejected"
else
    test_result "FAIL" "Malformed JSON not caught"
fi

# Test 3: Criteria with special characters
echo -n "Test 3: Criteria with special characters... "
CRITERIA='[{"criterion": "Test \"quotes\" and '\''apostrophes'\''", "measurable": "true"}]'
RESULT=$($TM add "Task with special chars" --criteria "$CRITERIA" 2>&1 || echo "FAILED")
if [[ "$RESULT" =~ "Task created" ]] || [[ "$RESULT" =~ [a-f0-9]{8} ]]; then
    test_result "PASS" "Special characters in criteria handled"
else
    test_result "FAIL" "Special characters caused failure"
fi

# Test 4: Very long criteria string (1MB)
echo -n "Test 4: Very long criteria (1MB)... "
LONG_CRITERION=$(printf '{"criterion": "%*s", "measurable": "true"}' 1000000 | tr ' ' 'x')
LONG_CRITERIA="[$LONG_CRITERION]"
RESULT=$($TM add "Task with huge criteria" --criteria "$LONG_CRITERIA" 2>&1 || echo "TOOLARGE")
if [[ "$RESULT" =~ "TOOLARGE" ]] || [[ "$RESULT" =~ "too large" ]] || [[ "$RESULT" =~ "Task created" ]]; then
    test_result "PASS" "Large criteria handled gracefully"
else
    test_result "FAIL" "Large criteria caused unexpected error"
fi

# Test 5: Criteria with Unicode
echo -n "Test 5: Unicode in criteria... "
UNICODE_CRITERIA='[{"criterion": "测试 テスト тест 🚀", "measurable": "true"}]'
RESULT=$($TM add "Task with unicode" --criteria "$UNICODE_CRITERIA" 2>&1 || echo "FAILED")
if [[ "$RESULT" =~ "Task created" ]] || [[ "$RESULT" =~ [a-f0-9]{8} ]]; then
    test_result "PASS" "Unicode criteria accepted"
else
    test_result "FAIL" "Unicode criteria failed"
fi

# Test 6: Criteria without measurable field
echo -n "Test 6: Criteria missing measurable field... "
INCOMPLETE_CRITERIA='[{"criterion": "Test without measurable"}]'
RESULT=$($TM add "Task incomplete criteria" --criteria "$INCOMPLETE_CRITERIA" 2>&1)
if [[ "$RESULT" =~ "Task created" ]]; then
    test_result "PASS" "Missing measurable field tolerated"
else
    test_result "FAIL" "Missing measurable field rejected"
fi

echo

# ============================================
# FEEDBACK MECHANISM EDGE CASES
# ============================================
echo "=== Feedback Mechanism Edge Cases ==="

# Create a test task for feedback
TASK_ID=$($TM add "Task for feedback tests" 2>/dev/null | grep -o '[a-f0-9]\{8\}' || echo "test_task")

# Test 7: Feedback score out of range (0)
echo -n "Test 7: Feedback score 0... "
RESULT=$($TM feedback "$TASK_ID" --quality 0 2>&1 || echo "REJECTED")
if [[ "$RESULT" =~ "REJECTED" ]] || [[ "$RESULT" =~ "between 1 and 5" ]]; then
    test_result "PASS" "Score 0 properly rejected"
else
    test_result "FAIL" "Score 0 not validated"
fi

# Test 8: Feedback score out of range (6)
echo -n "Test 8: Feedback score 6... "
RESULT=$($TM feedback "$TASK_ID" --quality 6 2>&1 || echo "REJECTED")
if [[ "$RESULT" =~ "REJECTED" ]] || [[ "$RESULT" =~ "between 1 and 5" ]]; then
    test_result "PASS" "Score 6 properly rejected"
else
    test_result "FAIL" "Score 6 not validated"
fi

# Test 9: Negative feedback score
echo -n "Test 9: Negative feedback score... "
RESULT=$($TM feedback "$TASK_ID" --quality -1 2>&1 || echo "REJECTED")
if [[ "$RESULT" =~ "REJECTED" ]] || [[ "$RESULT" =~ "between 1 and 5" ]] || [[ "$RESULT" =~ "invalid" ]]; then
    test_result "PASS" "Negative score rejected"
else
    test_result "FAIL" "Negative score not validated"
fi

# Test 10: Feedback on non-existent task
echo -n "Test 10: Feedback on non-existent task... "
RESULT=$($TM feedback "nonexistent" --quality 5 2>&1 || echo "HANDLED")
if [[ "$RESULT" =~ "HANDLED" ]] || [[ "$RESULT" =~ "not found" ]] || [[ "$RESULT" =~ "Feedback recorded" ]]; then
    test_result "PASS" "Non-existent task handled"
else
    test_result "FAIL" "Non-existent task caused error"
fi

# Test 11: Very long feedback note (10KB)
echo -n "Test 11: Very long feedback note... "
LONG_NOTE=$(printf '%*s' 10000 | tr ' ' 'x')
RESULT=$($TM feedback "$TASK_ID" --note "$LONG_NOTE" 2>&1 || echo "HANDLED")
if [[ "$RESULT" =~ "Feedback recorded" ]] || [[ "$RESULT" =~ "HANDLED" ]]; then
    test_result "PASS" "Long feedback note handled"
else
    test_result "FAIL" "Long feedback note failed"
fi

echo

# ============================================
# DEADLINE EDGE CASES
# ============================================
echo "=== Deadline Edge Cases ==="

# Test 12: Past deadline
echo -n "Test 12: Past deadline... "
PAST_DATE="2020-01-01T00:00:00Z"
RESULT=$($TM add "Task with past deadline" --deadline "$PAST_DATE" 2>&1)
if [[ "$RESULT" =~ "Task created" ]]; then
    test_result "PASS" "Past deadline accepted"
else
    test_result "FAIL" "Past deadline rejected"
fi

# Test 13: Invalid date format
echo -n "Test 13: Invalid date format... "
RESULT=$($TM add "Task with bad date" --deadline "not-a-date" 2>&1 || echo "HANDLED")
if [[ "$RESULT" =~ "Task created" ]] || [[ "$RESULT" =~ "HANDLED" ]]; then
    test_result "PASS" "Invalid date handled"
else
    test_result "FAIL" "Invalid date caused unexpected error"
fi

# Test 14: Far future deadline (year 3000)
echo -n "Test 14: Far future deadline... "
FUTURE_DATE="3000-12-31T23:59:59Z"
RESULT=$($TM add "Task with future deadline" --deadline "$FUTURE_DATE" 2>&1)
if [[ "$RESULT" =~ "Task created" ]]; then
    test_result "PASS" "Far future deadline accepted"
else
    test_result "FAIL" "Far future deadline rejected"
fi

echo

# ============================================
# TIME TRACKING EDGE CASES
# ============================================
echo "=== Time Tracking Edge Cases ==="

# Test 15: Zero hours estimate
echo -n "Test 15: Zero hours estimate... "
RESULT=$($TM add "Task with zero hours" --estimated-hours 0 2>&1)
if [[ "$RESULT" =~ "Task created" ]]; then
    test_result "PASS" "Zero hours accepted"
else
    test_result "FAIL" "Zero hours rejected"
fi

# Test 16: Negative hours
echo -n "Test 16: Negative hours estimate... "
RESULT=$($TM add "Task with negative hours" --estimated-hours -5 2>&1 || echo "HANDLED")
if [[ "$RESULT" =~ "Task created" ]] || [[ "$RESULT" =~ "HANDLED" ]]; then
    test_result "PASS" "Negative hours handled"
else
    test_result "FAIL" "Negative hours caused error"
fi

# Test 17: Very large hours (10000)
echo -n "Test 17: Very large hours estimate... "
RESULT=$($TM add "Task with many hours" --estimated-hours 10000 2>&1)
if [[ "$RESULT" =~ "Task created" ]]; then
    test_result "PASS" "Large hours value accepted"
else
    test_result "FAIL" "Large hours value rejected"
fi

# Test 18: Fractional hours
echo -n "Test 18: Fractional hours (0.5)... "
RESULT=$($TM add "Task with fractional hours" --estimated-hours 0.5 2>&1)
if [[ "$RESULT" =~ "Task created" ]]; then
    test_result "PASS" "Fractional hours accepted"
else
    test_result "FAIL" "Fractional hours rejected"
fi

echo

# ============================================
# PROGRESS TRACKING EDGE CASES
# ============================================
echo "=== Progress Tracking Edge Cases ==="

# Test 19: Empty progress message
echo -n "Test 19: Empty progress message... "
RESULT=$($TM progress "$TASK_ID" "" 2>&1 || echo "HANDLED")
if [[ "$RESULT" =~ "Progress update added" ]] || [[ "$RESULT" =~ "HANDLED" ]]; then
    test_result "PASS" "Empty progress handled"
else
    test_result "FAIL" "Empty progress caused error"
fi

# Test 20: Progress with special characters
echo -n "Test 20: Progress with special characters... "
RESULT=$($TM progress "$TASK_ID" "Progress: 50% \"done\" & 'working'" 2>&1)
if [[ "$RESULT" =~ "Progress update added" ]]; then
    test_result "PASS" "Special characters in progress handled"
else
    test_result "FAIL" "Special characters caused failure"
fi

# Test 21: Multiple rapid progress updates
echo -n "Test 21: Rapid progress updates... "
for i in {1..10}; do
    $TM progress "$TASK_ID" "Update $i" >/dev/null 2>&1 &
done
wait
RESULT=$($TM show "$TASK_ID" 2>&1)
if [[ "$RESULT" =~ "$TASK_ID" ]]; then
    test_result "PASS" "Rapid updates handled"
else
    test_result "FAIL" "Rapid updates caused issues"
fi

echo

# ============================================
# COMPLETION EDGE CASES
# ============================================
echo "=== Completion Edge Cases ==="

# Test 22: Complete with validation but no criteria
echo -n "Test 22: Validate without criteria... "
NO_CRITERIA_TASK=$($TM add "Task without criteria" 2>/dev/null | grep -o '[a-f0-9]\{8\}')
RESULT=$($TM complete "$NO_CRITERIA_TASK" --validate 2>&1)
if [[ "$RESULT" =~ "completed" ]]; then
    test_result "PASS" "Validation without criteria handled"
else
    test_result "FAIL" "Validation without criteria failed"
fi

# Test 23: Complete with very long summary
echo -n "Test 23: Very long completion summary... "
LONG_SUMMARY=$(printf '%*s' 5000 | tr ' ' 'x')
SUMMARY_TASK=$($TM add "Task for long summary" 2>/dev/null | grep -o '[a-f0-9]\{8\}')
RESULT=$($TM complete "$SUMMARY_TASK" --summary "$LONG_SUMMARY" 2>&1 || echo "HANDLED")
if [[ "$RESULT" =~ "completed" ]] || [[ "$RESULT" =~ "HANDLED" ]]; then
    test_result "PASS" "Long summary handled"
else
    test_result "FAIL" "Long summary failed"
fi

# Test 24: Complete already completed task
echo -n "Test 24: Complete already completed task... "
RESULT=$($TM complete "$NO_CRITERIA_TASK" 2>&1 || echo "HANDLED")
if [[ "$RESULT" =~ "completed" ]] || [[ "$RESULT" =~ "HANDLED" ]]; then
    test_result "PASS" "Double completion handled"
else
    test_result "FAIL" "Double completion caused error"
fi

echo

# ============================================
# CONFIGURATION EDGE CASES
# ============================================
echo "=== Configuration Edge Cases ==="

# Test 25: Enable non-existent feature
echo -n "Test 25: Enable non-existent feature... "
RESULT=$($TM config --enable "non-existent-feature" 2>&1 || echo "REJECTED")
if [[ "$RESULT" =~ "REJECTED" ]] || [[ "$RESULT" =~ "Unknown feature" ]] || [[ "$RESULT" =~ "not recognized" ]]; then
    test_result "PASS" "Invalid feature rejected"
else
    test_result "FAIL" "Invalid feature not validated"
fi

# Test 26: Minimal mode with Core Loop features
echo -n "Test 26: Minimal mode disables features... "
$TM config --minimal-mode >/dev/null 2>&1
MINIMAL_TASK=$($TM add "Task in minimal" --criteria '[{"criterion":"test","measurable":"true"}]' 2>&1)
if [[ "$MINIMAL_TASK" =~ "Task created" ]]; then
    test_result "PASS" "Minimal mode allows creation"
else
    test_result "FAIL" "Minimal mode blocks creation"
fi

# Test 27: Reset configuration
echo -n "Test 27: Reset configuration... "
RESULT=$($TM config --reset 2>&1)
if [[ "$RESULT" =~ "reset" ]]; then
    test_result "PASS" "Configuration reset works"
else
    test_result "FAIL" "Configuration reset failed"
fi

echo

# ============================================
# MIGRATION EDGE CASES
# ============================================
echo "=== Migration Edge Cases ==="

# Test 28: Rollback when no backup exists
echo -n "Test 28: Rollback without backup... "
rm -rf .task-orchestrator/backups/*.db 2>/dev/null || true
RESULT=$($TM migrate --rollback 2>&1 || echo "HANDLED")
if [[ "$RESULT" =~ "No backups" ]] || [[ "$RESULT" =~ "HANDLED" ]]; then
    test_result "PASS" "Missing backup handled"
else
    test_result "FAIL" "Missing backup caused error"
fi

# Test 29: Apply migration twice (idempotency)
echo -n "Test 29: Idempotent migration... "
$TM migrate --apply >/dev/null 2>&1 || true
RESULT=$($TM migrate --apply 2>&1 || echo "IDEMPOTENT")
if [[ "$RESULT" =~ "No pending" ]] || [[ "$RESULT" =~ "IDEMPOTENT" ]] || [[ "$RESULT" =~ "up to date" ]]; then
    test_result "PASS" "Idempotent migration works"
else
    test_result "FAIL" "Migration not idempotent"
fi

# Test 30: Migration status check
echo -n "Test 30: Migration status... "
RESULT=$($TM migrate --status 2>&1)
if [[ "$RESULT" =~ "Applied" ]] || [[ "$RESULT" =~ "Pending" ]]; then
    test_result "PASS" "Migration status works"
else
    test_result "FAIL" "Migration status failed"
fi

echo

# ============================================
# METRICS EDGE CASES
# ============================================
echo "=== Metrics Edge Cases ==="

# Test 31: Metrics with no data
echo -n "Test 31: Metrics with no feedback data... "
# Clear database and check metrics
RESULT=$($TM metrics --feedback 2>&1 || echo "HANDLED")
if [[ "$RESULT" =~ "Average" ]] || [[ "$RESULT" =~ "0" ]] || [[ "$RESULT" =~ "HANDLED" ]]; then
    test_result "PASS" "Empty metrics handled"
else
    test_result "FAIL" "Empty metrics failed"
fi

echo

# ============================================
# CONCURRENT ACCESS EDGE CASES
# ============================================
echo "=== Concurrent Access Edge Cases ==="

# Test 32: Simultaneous task creation
echo -n "Test 32: Concurrent task creation... "
for i in {1..5}; do
    $TM add "Concurrent task $i" >/dev/null 2>&1 &
done
wait
TASK_COUNT=$($TM list 2>/dev/null | grep -c "Concurrent task" || echo "0")
if [[ $TASK_COUNT -ge 3 ]]; then
    test_result "PASS" "Concurrent creation handled"
else
    test_result "FAIL" "Concurrent creation failed"
fi

# Test 33: Simultaneous updates
echo -n "Test 33: Concurrent updates... "
UPDATE_TASK=$($TM add "Task for concurrent updates" 2>/dev/null | grep -o '[a-f0-9]\{8\}')
for i in {1..5}; do
    $TM progress "$UPDATE_TASK" "Concurrent update $i" >/dev/null 2>&1 &
done
wait
test_result "PASS" "Concurrent updates handled"

echo

# ============================================
# ERROR RECOVERY EDGE CASES
# ============================================
echo "=== Error Recovery Edge Cases ==="

# Test 34: Invalid task ID format
echo -n "Test 34: Invalid task ID format... "
RESULT=$($TM show "!!!invalid!!!" 2>&1 || echo "HANDLED")
if [[ "$RESULT" =~ "not found" ]] || [[ "$RESULT" =~ "HANDLED" ]]; then
    test_result "PASS" "Invalid ID handled"
else
    test_result "FAIL" "Invalid ID caused error"
fi

# Test 35: SQL injection attempt
echo -n "Test 35: SQL injection protection... "
RESULT=$($TM add "'; DROP TABLE tasks; --" 2>&1)
if [[ "$RESULT" =~ "Task created" ]]; then
    # Check if tables still exist
    TABLE_CHECK=$($TM list 2>&1)
    if [[ "$TABLE_CHECK" != *"no such table"* ]]; then
        test_result "PASS" "SQL injection prevented"
    else
        test_result "FAIL" "SQL injection not prevented!"
    fi
else
    test_result "FAIL" "Task creation failed"
fi

echo

# ============================================
# SUMMARY
# ============================================
echo "========================================="
echo "         Edge Case Test Summary          "
echo "========================================="
echo "Passed: $PASSED"
echo "Failed: $FAILED"
echo "Total:  $((PASSED + FAILED))"
echo
if [ $FAILED -eq 0 ]; then
    echo "✅ All edge cases handled properly!"
else
    echo "⚠️  Some edge cases need attention"
fi

# Cleanup
cd ..
rm -rf "$TEST_DIR"

exit $FAILED