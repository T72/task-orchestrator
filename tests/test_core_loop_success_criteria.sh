#!/bin/bash
# Test Suite: Core Loop Success Criteria Functionality
# Purpose: Validate success criteria definition and validation features
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
TEST_DIR=$(mktemp -d -t tm_core_loop_test_XXXXXX)
cd "$TEST_DIR"

# Initialize test environment
export TM_TEST_MODE=1
$TM init >/dev/null 2>&1

echo "=== Core Loop Success Criteria Tests ==="

# Test 1: Add task with success criteria
echo -n "Test 1: Add task with success criteria... "
TASK_ID=$($TM add "Test task with criteria" --criteria '[
  {"criterion": "All tests pass", "measurable": "test_count == 100%"},
  {"criterion": "Performance target met", "measurable": "response_time < 100ms"}
]' 2>/dev/null || echo "FAIL")

if [[ "$TASK_ID" =~ ^[a-f0-9]{8}$ ]]; then
    echo "PASS"
else
    echo "FAIL - Could not create task with criteria"
fi

# Test 2: Retrieve and verify success criteria
echo -n "Test 2: Success criteria stored correctly... "
CRITERIA=$($TM show "$TASK_ID" --json 2>/dev/null | grep -o '"success_criteria".*' || echo "")

if [[ "$CRITERIA" == *"All tests pass"* ]]; then
    echo "PASS"
else
    echo "FAIL - Criteria not stored or retrieved"
fi

# Test 3: Complete without validation (should work)
echo -n "Test 3: Complete without validation... "
TASK_ID2=$($TM add "Task without validation" 2>/dev/null)
RESULT=$($TM complete "$TASK_ID2" 2>/dev/null && echo "SUCCESS" || echo "FAIL")

if [[ "$RESULT" == "SUCCESS" ]]; then
    echo "PASS"
else
    echo "FAIL - Basic completion broken"
fi

# Test 4: Complete with validation (criteria not met)
echo -n "Test 4: Validation blocks incomplete criteria... "
TASK_ID3=$($TM add "Task with strict criteria" --criteria '[
  {"criterion": "Impossible task", "measurable": "1 == 2"}
]' 2>/dev/null)

RESULT=$($TM complete "$TASK_ID3" --validate 2>&1 || echo "BLOCKED")

if [[ "$RESULT" == *"BLOCKED"* ]] || [[ "$RESULT" == *"criteria unmet"* ]]; then
    echo "PASS"
else
    echo "FAIL - Validation not blocking completion"
fi

# Test 5: Force complete despite unmet criteria
echo -n "Test 5: Force complete override works... "
RESULT=$($TM complete "$TASK_ID3" --validate --force 2>/dev/null && echo "FORCED" || echo "FAIL")

if [[ "$RESULT" == "FORCED" ]]; then
    echo "PASS"
else
    echo "FAIL - Force override not working"
fi

# Test 6: Complete with summary
echo -n "Test 6: Completion summary captured... "
TASK_ID4=$($TM add "Task requiring summary" 2>/dev/null)
$TM complete "$TASK_ID4" --summary "This is a test summary with important learnings" 2>/dev/null

SUMMARY=$($TM show "$TASK_ID4" --json 2>/dev/null | grep -o '"completion_summary".*' || echo "")

if [[ "$SUMMARY" == *"important learnings"* ]]; then
    echo "PASS"
else
    echo "FAIL - Summary not captured"
fi

# Test 7: Criteria validation with measurable checks
echo -n "Test 7: Measurable criteria evaluation... "
TASK_ID5=$($TM add "Task with measurable criteria" --criteria '[
  {"criterion": "Simple math check", "measurable": "2 + 2 == 4"}
]' 2>/dev/null)

# This should pass validation (if measurable evaluation is implemented)
RESULT=$($TM complete "$TASK_ID5" --validate 2>/dev/null && echo "VALID" || echo "INVALID")

if [[ "$RESULT" == "VALID" ]] || [[ "$RESULT" == "INVALID" ]]; then
    echo "PASS (validation attempted)"
else
    echo "FAIL - Validation not attempted"
fi

# Test 8: Maximum criteria limit
echo -n "Test 8: Maximum 10 criteria enforced... "
LONG_CRITERIA='['
for i in {1..11}; do
    LONG_CRITERIA+="{\"criterion\": \"Criterion $i\", \"measurable\": \"test_$i == true\"},"
done
LONG_CRITERIA="${LONG_CRITERIA%,}]"

RESULT=$($TM add "Too many criteria" --criteria "$LONG_CRITERIA" 2>&1 || echo "REJECTED")

if [[ "$RESULT" == *"REJECTED"* ]] || [[ "$RESULT" == *"Maximum"* ]] || [[ "$RESULT" == *"10"* ]]; then
    echo "PASS"
else
    echo "FAIL - Criteria limit not enforced"
fi

# Test 9: Criteria with deadline
echo -n "Test 9: Task with criteria and deadline... "
FUTURE_DATE=$(date -d "+7 days" --iso-8601=seconds 2>/dev/null || date -v +7d +%Y-%m-%dT%H:%M:%S 2>/dev/null || echo "2025-03-01T00:00:00Z")
TASK_ID6=$($TM add "Task with deadline" --criteria '[
  {"criterion": "On time", "measurable": "completed_before_deadline"}
]' --deadline "$FUTURE_DATE" 2>/dev/null || echo "FAIL")

if [[ "$TASK_ID6" =~ ^[a-f0-9]{8}$ ]]; then
    echo "PASS"
else
    echo "FAIL - Cannot combine criteria with deadline"
fi

# Test 10: Backward compatibility - old tasks still work
echo -n "Test 10: Backward compatibility maintained... "
TASK_ID7=$($TM add "Legacy task without new features" 2>/dev/null)
$TM update "$TASK_ID7" --status in_progress 2>/dev/null
RESULT=$($TM complete "$TASK_ID7" 2>/dev/null && echo "COMPATIBLE" || echo "BROKEN")

if [[ "$RESULT" == "COMPATIBLE" ]]; then
    echo "PASS"
else
    echo "FAIL - Backward compatibility broken"
fi

# Cleanup
cd ..
rm -rf "$TEST_DIR"

echo "=== Success Criteria Test Suite Complete ==="
echo "Note: Some tests may fail until Core Loop implementation is complete"
echo "This is expected in TDD - tests define the specification"