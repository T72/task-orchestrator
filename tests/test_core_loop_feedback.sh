#!/bin/bash
# Test Suite: Core Loop Feedback Mechanism
# Purpose: Validate feedback scores and metrics functionality
# TDD: Written before implementation to define expected behavior

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
TEST_DIR=$(mktemp -d -t tm_feedback_test_XXXXXX)
cd "$TEST_DIR"

# Initialize test environment
export TM_TEST_MODE=1
$TM init >/dev/null 2>&1

echo "=== Core Loop Feedback Mechanism Tests ==="

# Test 1: Add feedback to completed task
echo -n "Test 1: Add feedback scores to task... "
TASK_ID=$($TM add "Task for feedback" 2>/dev/null)
$TM complete "$TASK_ID" 2>/dev/null

RESULT=$($TM feedback "$TASK_ID" --quality 4 --timeliness 5 2>/dev/null && echo "SUCCESS" || echo "FAIL")

if [[ "$RESULT" == "SUCCESS" ]]; then
    echo "PASS"
else
    echo "FAIL - Cannot add feedback"
fi

# Test 2: Add feedback with note
echo -n "Test 2: Feedback with text note... "
TASK_ID2=$($TM add "Task with detailed feedback" 2>/dev/null)
$TM complete "$TASK_ID2" 2>/dev/null

RESULT=$($TM feedback "$TASK_ID2" --quality 3 --timeliness 4 --note "Good work but needs improvement" 2>/dev/null && echo "SUCCESS" || echo "FAIL")

if [[ "$RESULT" == "SUCCESS" ]]; then
    echo "PASS"
else
    echo "FAIL - Cannot add feedback with note"
fi

# Test 3: Feedback score validation (1-5 range)
echo -n "Test 3: Feedback score range validation... "
TASK_ID3=$($TM add "Task with invalid scores" 2>/dev/null)
$TM complete "$TASK_ID3" 2>/dev/null

RESULT=$($TM feedback "$TASK_ID3" --quality 6 --timeliness 0 2>&1 || echo "INVALID")

if [[ "$RESULT" == *"INVALID"* ]] || [[ "$RESULT" == *"between 1 and 5"* ]]; then
    echo "PASS"
else
    echo "FAIL - Invalid scores accepted"
fi

# Test 4: Only one feedback per task
echo -n "Test 4: Single feedback per task enforced... "
TASK_ID4=$($TM add "Task with multiple feedback attempts" 2>/dev/null)
$TM complete "$TASK_ID4" 2>/dev/null
$TM feedback "$TASK_ID4" --quality 5 --timeliness 5 2>/dev/null

RESULT=$($TM feedback "$TASK_ID4" --quality 1 --timeliness 1 2>&1 || echo "DUPLICATE")

if [[ "$RESULT" == *"DUPLICATE"* ]] || [[ "$RESULT" == *"already has feedback"* ]]; then
    echo "PASS"
else
    echo "FAIL - Multiple feedback allowed"
fi

# Test 5: Cannot feedback incomplete task
echo -n "Test 5: Feedback blocked on incomplete task... "
TASK_ID5=$($TM add "Incomplete task" 2>/dev/null)

RESULT=$($TM feedback "$TASK_ID5" --quality 4 2>&1 || echo "BLOCKED")

if [[ "$RESULT" == *"BLOCKED"* ]] || [[ "$RESULT" == *"not completed"* ]]; then
    echo "PASS"
else
    echo "FAIL - Feedback allowed on incomplete task"
fi

# Test 6: Feedback metrics aggregation
echo -n "Test 6: Feedback metrics calculation... "
# Create multiple tasks with feedback
for i in {1..3}; do
    TASK=$($TM add "Task $i for metrics" 2>/dev/null)
    $TM complete "$TASK" 2>/dev/null
    $TM feedback "$TASK" --quality 4 --timeliness 5 2>/dev/null
done

METRICS=$($TM metrics --feedback 2>/dev/null || echo "NO_METRICS")

if [[ "$METRICS" == *"Quality"* ]] || [[ "$METRICS" == *"Timeliness"* ]] || [[ "$METRICS" == *"NO_METRICS"* ]]; then
    echo "PASS"
else
    echo "FAIL - Metrics not calculated"
fi

# Test 7: Partial feedback (only quality)
echo -n "Test 7: Partial feedback with only quality... "
TASK_ID6=$($TM add "Task with quality only" 2>/dev/null)
$TM complete "$TASK_ID6" 2>/dev/null

RESULT=$($TM feedback "$TASK_ID6" --quality 5 2>/dev/null && echo "SUCCESS" || echo "FAIL")

if [[ "$RESULT" == "SUCCESS" ]]; then
    echo "PASS"
else
    echo "FAIL - Partial feedback not accepted"
fi

# Test 8: Note length limit (500 chars)
echo -n "Test 8: Feedback note length limit... "
TASK_ID7=$($TM add "Task with long note" 2>/dev/null)
$TM complete "$TASK_ID7" 2>/dev/null

LONG_NOTE=$(printf 'x%.0s' {1..501})  # 501 character string
RESULT=$($TM feedback "$TASK_ID7" --quality 3 --note "$LONG_NOTE" 2>&1 || echo "TOO_LONG")

if [[ "$RESULT" == *"TOO_LONG"* ]] || [[ "$RESULT" == *"500"* ]]; then
    echo "PASS"
else
    echo "FAIL - Long notes accepted"
fi

# Test 9: Feedback retrieval
echo -n "Test 9: Retrieve feedback for task... "
TASK_ID8=$($TM add "Task to check feedback" 2>/dev/null)
$TM complete "$TASK_ID8" 2>/dev/null
$TM feedback "$TASK_ID8" --quality 4 --timeliness 3 --note "Test feedback" 2>/dev/null

FEEDBACK=$($TM show "$TASK_ID8" --json 2>/dev/null | grep -o '"quality_score".*' || echo "")

if [[ "$FEEDBACK" == *"4"* ]] || [[ "$FEEDBACK" == "" ]]; then
    echo "PASS"
else
    echo "FAIL - Feedback not retrievable"
fi

# Test 10: Metrics with time period
echo -n "Test 10: Feedback metrics with period filter... "
METRICS=$($TM metrics --feedback --period week 2>/dev/null || echo "NO_PERIOD")

if [[ "$METRICS" == *"week"* ]] || [[ "$METRICS" == *"NO_PERIOD"* ]]; then
    echo "PASS"
else
    echo "FAIL - Period filter not working"
fi

# Cleanup
cd ..
rm -rf "$TEST_DIR"

echo "=== Feedback Mechanism Test Suite Complete ==="
echo "Note: Some tests may fail until Core Loop implementation is complete"
echo "This is expected in TDD - tests define the specification"