#!/bin/bash
# Master runner for all Core Loop edge case tests
# Executes all edge case test suites and provides summary

set -e

echo "========================================="
echo "   Core Loop Edge Case Test Runner      "
echo "========================================="
echo
echo "This will run all edge case test suites for the Core Loop functionality."
echo "Tests cover boundary conditions, error scenarios, and unusual inputs."
echo

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
TOTAL_SUITES=0
PASSED_SUITES=0
FAILED_SUITES=0

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Function to run a test suite
run_test_suite() {
    local test_file=$1
    local test_name=$2
    
    if [ ! -f "$test_file" ]; then
        echo -e "${YELLOW}⚠ SKIP:${NC} $test_name (file not found)"
        return
    fi
    
    echo "----------------------------------------"
    echo "Running: $test_name"
    echo "----------------------------------------"
    
    # Make executable
    chmod +x "$test_file" 2>/dev/null || true
    
    # Run test and capture exit code
    if "$test_file"; then
        echo -e "${GREEN}✓ SUITE PASSED:${NC} $test_name"
        ((PASSED_SUITES++))
    else
        local exit_code=$?
        echo -e "${RED}✗ SUITE FAILED:${NC} $test_name (failed tests: $exit_code)"
        ((FAILED_SUITES++))
    fi
    
    ((TOTAL_SUITES++))
    echo
}

# Check if specific test requested
if [ "$1" != "" ]; then
    case "$1" in
        "criteria")
            run_test_suite "$SCRIPT_DIR/test_validation_edge_cases.sh" "Validation Logic Edge Cases"
            ;;
        "general")
            run_test_suite "$SCRIPT_DIR/test_core_loop_edge_cases.sh" "General Core Loop Edge Cases"
            ;;
        "telemetry")
            run_test_suite "$SCRIPT_DIR/test_telemetry_metrics_edge_cases.sh" "Telemetry & Metrics Edge Cases"
            ;;
        *)
            echo "Unknown test suite: $1"
            echo "Available: criteria, general, telemetry"
            exit 1
            ;;
    esac
else
    # Run all edge case test suites
    echo "Executing all edge case test suites..."
    echo
    
    # Run each test suite
    run_test_suite "$SCRIPT_DIR/test_core_loop_edge_cases.sh" "1. General Core Loop Edge Cases"
    run_test_suite "$SCRIPT_DIR/test_validation_edge_cases.sh" "2. Validation Logic Edge Cases"
    run_test_suite "$SCRIPT_DIR/test_telemetry_metrics_edge_cases.sh" "3. Telemetry & Metrics Edge Cases"
fi

# Final Summary
echo "========================================="
echo "      Edge Case Test Suite Summary      "
echo "========================================="
echo -e "Total Test Suites: $TOTAL_SUITES"
echo -e "${GREEN}Passed Suites:${NC} $PASSED_SUITES"
echo -e "${RED}Failed Suites:${NC} $FAILED_SUITES"
echo

if [ $FAILED_SUITES -eq 0 ]; then
    echo -e "${GREEN}✅ All edge case test suites passed!${NC}"
    echo "The Core Loop implementation handles edge cases robustly."
else
    echo -e "${YELLOW}⚠️ Some edge case test suites had failures${NC}"
    echo "Review the failed tests above for details."
fi

echo
echo "Edge case testing helps ensure robustness in:"
echo "• Boundary conditions (empty, zero, maximum values)"
echo "• Error scenarios (malformed input, missing data)"
echo "• Concurrent operations (race conditions, locks)"
echo "• Performance limits (large datasets, complex operations)"
echo "• Recovery scenarios (corruption, failures)"
echo

# Provide test coverage summary
echo "Coverage Areas Tested:"
echo "✓ Success criteria with special characters, Unicode, malformed JSON"
echo "✓ Feedback scores out of range, negative values"
echo "✓ Deadlines in past/future, invalid formats"
echo "✓ Time tracking with zero, negative, fractional hours"
echo "✓ Progress updates with empty, rapid, concurrent submissions"
echo "✓ Completion validation without criteria, double completion"
echo "✓ Configuration with invalid features, minimal mode"
echo "✓ Migration idempotency, rollback without backup"
echo "✓ Metrics with no data, extreme values, NULL fields"
echo "✓ Telemetry with disabled state, disk pressure, corruption"
echo "✓ Concurrent access, file locking, SQL injection protection"
echo

# Exit with number of failed suites
exit $FAILED_SUITES