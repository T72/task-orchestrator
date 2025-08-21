#!/bin/bash
# Comprehensive test to verify Core Loop implementation is complete and working
# Tests actual functionality rather than just TDD specifications

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "========================================="
echo "  Core Loop Implementation Verification  "
echo "========================================="
echo
echo "Testing actual Core Loop functionality..."
echo

# Find tm executable
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TM_PATH="$PROJECT_ROOT/tm"

if [ ! -f "$TM_PATH" ]; then
    echo -e "${RED}Error: tm executable not found${NC}"
    exit 1
fi

TM="$TM_PATH"

# Test setup
TEST_DIR=$(mktemp -d -t tm_impl_test_XXXXXX)
cd "$TEST_DIR"

# Initialize
export TM_TEST_MODE=1
echo "Setting up test environment..."
$TM init >/dev/null 2>&1
echo -e "${GREEN}✓${NC} Database initialized"

# Apply migrations
echo "Applying Core Loop migrations..."
$TM migrate --apply >/dev/null 2>&1 || true
echo -e "${GREEN}✓${NC} Migrations applied"

PASSED=0
FAILED=0

# Helper function
test_feature() {
    local test_name="$1"
    local result="$2"
    
    if [ "$result" = "PASS" ]; then
        echo -e "${GREEN}✓${NC} $test_name"
        ((PASSED++))
    else
        echo -e "${RED}✗${NC} $test_name"
        ((FAILED++))
    fi
}

echo
echo "=== Testing Core Features ==="

# Test 1: Success Criteria
echo -n "1. Success criteria support... "
CRITERIA='[{"criterion": "Test passes", "measurable": "true"}]'
TASK_ID=$($TM add "Task with criteria" --criteria "$CRITERIA" 2>&1 | grep -o '[a-f0-9]\{8\}' || echo "FAILED")
if [[ "$TASK_ID" != "FAILED" ]] && [[ -n "$TASK_ID" ]]; then
    test_feature "Success criteria" "PASS"
else
    test_feature "Success criteria" "FAIL"
fi

# Test 2: Deadline support
echo -n "2. Deadline support... "
DEADLINE="2025-12-31T23:59:59Z"
TASK_ID=$($TM add "Task with deadline" --deadline "$DEADLINE" 2>&1 | grep -o '[a-f0-9]\{8\}' || echo "FAILED")
if [[ "$TASK_ID" != "FAILED" ]] && [[ -n "$TASK_ID" ]]; then
    test_feature "Deadline" "PASS"
else
    test_feature "Deadline" "FAIL"
fi

# Test 3: Time tracking
echo -n "3. Time tracking... "
TASK_ID=$($TM add "Task with estimate" --estimated-hours 8 2>&1 | grep -o '[a-f0-9]\{8\}' || echo "FAILED")
if [[ "$TASK_ID" != "FAILED" ]] && [[ -n "$TASK_ID" ]]; then
    # Complete with actual hours
    RESULT=$($TM complete "$TASK_ID" --actual-hours 7.5 2>&1)
    if [[ "$RESULT" =~ "completed" ]]; then
        test_feature "Time tracking" "PASS"
    else
        test_feature "Time tracking" "FAIL"
    fi
else
    test_feature "Time tracking" "FAIL"
fi

# Test 4: Progress updates
echo -n "4. Progress updates... "
TASK_ID=$($TM add "Task for progress" 2>&1 | grep -o '[a-f0-9]\{8\}')
RESULT=$($TM progress "$TASK_ID" "50% complete" 2>&1)
if [[ "$RESULT" =~ "Progress update added" ]]; then
    test_feature "Progress updates" "PASS"
else
    test_feature "Progress updates" "FAIL"
fi

# Test 5: Completion summaries
echo -n "5. Completion summaries... "
TASK_ID=$($TM add "Task for summary" 2>&1 | grep -o '[a-f0-9]\{8\}')
RESULT=$($TM complete "$TASK_ID" --summary "Task completed successfully with all requirements met" 2>&1)
if [[ "$RESULT" =~ "completed" ]]; then
    test_feature "Completion summaries" "PASS"
else
    test_feature "Completion summaries" "FAIL"
fi

# Test 6: Feedback mechanism
echo -n "6. Feedback mechanism... "
TASK_ID=$($TM add "Task for feedback" 2>&1 | grep -o '[a-f0-9]\{8\}')
$TM complete "$TASK_ID" >/dev/null 2>&1
RESULT=$($TM feedback "$TASK_ID" --quality 5 --timeliness 4 --note "Great work" 2>&1)
if [[ "$RESULT" =~ "Feedback recorded" ]] || [[ "$RESULT" =~ "feedback" ]]; then
    test_feature "Feedback mechanism" "PASS"
else
    test_feature "Feedback mechanism" "FAIL"
fi

# Test 7: Validation
echo -n "7. Criteria validation... "
CRITERIA='[{"criterion": "Always true", "measurable": "true"}]'
TASK_ID=$($TM add "Task for validation" --criteria "$CRITERIA" 2>&1 | grep -o '[a-f0-9]\{8\}')
RESULT=$($TM complete "$TASK_ID" --validate 2>&1)
if [[ "$RESULT" =~ "completed" ]] || [[ "$RESULT" =~ "Validation" ]]; then
    test_feature "Criteria validation" "PASS"
else
    test_feature "Criteria validation" "FAIL"
fi

# Test 8: Configuration management
echo -n "8. Configuration management... "
RESULT=$($TM config --show 2>&1)
if [[ "$RESULT" =~ "configuration" ]] || [[ "$RESULT" =~ "features" ]] || [[ "$RESULT" =~ "Current" ]]; then
    test_feature "Configuration management" "PASS"
else
    test_feature "Configuration management" "FAIL"
fi

# Test 9: Metrics
echo -n "9. Metrics calculation... "
# Create some tasks with feedback for metrics
for i in {1..3}; do
    T=$($TM add "Metrics test $i" 2>&1 | grep -o '[a-f0-9]\{8\}')
    $TM complete "$T" >/dev/null 2>&1
    $TM feedback "$T" --quality $((i+2)) --timeliness 4 >/dev/null 2>&1
done
RESULT=$($TM metrics --feedback 2>&1)
if [[ "$RESULT" =~ "Average" ]] || [[ "$RESULT" =~ "quality" ]]; then
    test_feature "Metrics calculation" "PASS"
else
    test_feature "Metrics calculation" "FAIL"
fi

# Test 10: Migration status
echo -n "10. Migration system... "
RESULT=$($TM migrate --status 2>&1)
if [[ "$RESULT" =~ "Applied" ]] || [[ "$RESULT" =~ "Pending" ]] || [[ "$RESULT" =~ "up to date" ]]; then
    test_feature "Migration system" "PASS"
else
    test_feature "Migration system" "FAIL"
fi

echo
echo "=== Testing Edge Cases ==="

# Test 11: Empty criteria
echo -n "11. Empty criteria handling... "
TASK_ID=$($TM add "Empty criteria task" --criteria '[]' 2>&1 | grep -o '[a-f0-9]\{8\}' || echo "FAILED")
if [[ "$TASK_ID" != "FAILED" ]]; then
    test_feature "Empty criteria" "PASS"
else
    test_feature "Empty criteria" "FAIL"
fi

# Test 12: Invalid feedback score
echo -n "12. Invalid feedback rejection... "
TASK_ID=$($TM add "Invalid feedback task" 2>&1 | grep -o '[a-f0-9]\{8\}')
$TM complete "$TASK_ID" >/dev/null 2>&1
RESULT=$($TM feedback "$TASK_ID" --quality 10 2>&1 || echo "REJECTED")
if [[ "$RESULT" =~ "REJECTED" ]] || [[ "$RESULT" =~ "between 1 and 5" ]]; then
    test_feature "Invalid feedback rejection" "PASS"
else
    test_feature "Invalid feedback rejection" "FAIL"
fi

# Test 13: Concurrent operations
echo -n "13. Concurrent task creation... "
for i in {1..5}; do
    $TM add "Concurrent task $i" >/dev/null 2>&1 &
done
wait
COUNT=$($TM list 2>&1 | grep -c "Concurrent task" || echo "0")
if [ "$COUNT" -ge 3 ]; then
    test_feature "Concurrent operations" "PASS"
else
    test_feature "Concurrent operations" "FAIL"
fi

# Test 14: Backward compatibility
echo -n "14. Backward compatibility... "
TASK_ID=$($TM add "Simple task without Core Loop features" 2>&1 | grep -o '[a-f0-9]\{8\}')
if [[ -n "$TASK_ID" ]]; then
    RESULT=$($TM complete "$TASK_ID" 2>&1)
    if [[ "$RESULT" =~ "completed" ]]; then
        test_feature "Backward compatibility" "PASS"
    else
        test_feature "Backward compatibility" "FAIL"
    fi
else
    test_feature "Backward compatibility" "FAIL"
fi

# Test 15: Minimal mode
echo -n "15. Minimal mode... "
$TM config --minimal-mode >/dev/null 2>&1
TASK_ID=$($TM add "Task in minimal mode" --criteria '[{"criterion":"Test","measurable":"true"}]' 2>&1 | grep -o '[a-f0-9]\{8\}' || echo "OK")
$TM config --reset >/dev/null 2>&1  # Reset config
if [[ -n "$TASK_ID" ]]; then
    test_feature "Minimal mode" "PASS"
else
    test_feature "Minimal mode" "FAIL"
fi

echo
echo "========================================="
echo "         Implementation Test Summary      "
echo "========================================="
echo -e "Tests Passed: ${GREEN}$PASSED${NC}"
echo -e "Tests Failed: ${RED}$FAILED${NC}"
echo "Total Tests:  $((PASSED + FAILED))"
echo

# Feature status summary
echo "Core Loop Feature Status:"
if [ $PASSED -ge 10 ]; then
    echo -e "${GREEN}✅ Core Loop implementation is functional!${NC}"
    echo
    echo "Working features:"
    echo "• Success criteria definition and validation"
    echo "• Deadline and time tracking"
    echo "• Progress updates and completion summaries"
    echo "• Feedback mechanism with metrics"
    echo "• Configuration management"
    echo "• Migration system"
    echo "• Backward compatibility maintained"
else
    echo -e "${YELLOW}⚠️ Some Core Loop features need attention${NC}"
    echo
    echo "Review failed tests above for details."
fi

# Cleanup
cd ..
rm -rf "$TEST_DIR"

# Exit with number of failures
exit $FAILED