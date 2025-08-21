#!/bin/bash
# Core Loop Test Suite Runner
# Purpose: Execute all Core Loop tests in lightweight TDD fashion
# Usage: ./run_core_loop_tests.sh [test_name]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0

echo "========================================="
echo "     Core Loop Test Suite (TDD)         "
echo "========================================="
echo
echo "Running tests for PRD v2.3 Core Loop Enhancement"
echo "Note: Tests are written BEFORE implementation (TDD)"
echo "Expected: Some tests will fail until features are implemented"
echo

# Function to run a test
run_test() {
    local test_file=$1
    local test_name=$2
    
    if [ ! -f "$test_file" ]; then
        echo -e "${YELLOW}⚠ SKIP:${NC} $test_name (file not found)"
        ((SKIPPED_TESTS++))
        return
    fi
    
    echo "----------------------------------------"
    echo "Running: $test_name"
    echo "----------------------------------------"
    
    # Make executable
    chmod +x "$test_file" 2>/dev/null || true
    
    # Run test and capture result
    if bash "$test_file" 2>&1; then
        echo -e "${GREEN}✓ SUITE EXECUTED:${NC} $test_name"
        ((PASSED_TESTS++))
    else
        echo -e "${RED}✗ SUITE FAILED:${NC} $test_name"
        ((FAILED_TESTS++))
    fi
    
    ((TOTAL_TESTS++))
    echo
}

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Check if specific test requested
if [ "$1" != "" ]; then
    case "$1" in
        "criteria")
            run_test "$SCRIPT_DIR/test_core_loop_success_criteria.sh" "Success Criteria Tests"
            ;;
        "feedback")
            run_test "$SCRIPT_DIR/test_core_loop_feedback.sh" "Feedback Mechanism Tests"
            ;;
        "schema")
            run_test "$SCRIPT_DIR/test_core_loop_schema.sh" "Schema Extensions Tests"
            ;;
        "config")
            run_test "$SCRIPT_DIR/test_core_loop_configuration.sh" "Configuration Management Tests"
            ;;
        "migration")
            run_test "$SCRIPT_DIR/test_core_loop_migration.sh" "Migration Safety Tests"
            ;;
        "integration")
            run_test "$SCRIPT_DIR/test_core_loop_integration.sh" "Integration Tests"
            ;;
        *)
            echo "Unknown test: $1"
            echo "Available: criteria, feedback, schema, config, migration, integration"
            exit 1
            ;;
    esac
else
    # Run all tests in order
    echo "Executing all Core Loop test suites..."
    echo
    
    # Unit tests (isolated functionality)
    run_test "$SCRIPT_DIR/test_core_loop_schema.sh" "1. Schema Extensions"
    run_test "$SCRIPT_DIR/test_core_loop_migration.sh" "2. Migration Safety"
    run_test "$SCRIPT_DIR/test_core_loop_configuration.sh" "3. Configuration Management"
    run_test "$SCRIPT_DIR/test_core_loop_success_criteria.sh" "4. Success Criteria"
    run_test "$SCRIPT_DIR/test_core_loop_feedback.sh" "5. Feedback Mechanism"
    
    # Integration test (end-to-end)
    run_test "$SCRIPT_DIR/test_core_loop_integration.sh" "6. Full Integration"
fi

# Summary
echo "========================================="
echo "           Test Summary                  "
echo "========================================="
echo -e "Total Test Suites: $TOTAL_TESTS"
echo -e "${GREEN}Executed:${NC} $PASSED_TESTS"
echo -e "${RED}Failed:${NC} $FAILED_TESTS"
echo -e "${YELLOW}Skipped:${NC} $SKIPPED_TESTS"
echo

# TDD interpretation
if [ $FAILED_TESTS -gt 0 ]; then
    echo "----------------------------------------"
    echo "TDD Status: Tests Define Specification"
    echo "----------------------------------------"
    echo "Failed tests indicate features not yet implemented."
    echo "This is EXPECTED in Test-Driven Development."
    echo "Implement features to make tests pass."
    echo
    echo "Priority Implementation Order:"
    echo "1. Schema extensions (database fields)"
    echo "2. Migration system (safe upgrades)"
    echo "3. Success criteria (task creation/validation)"
    echo "4. Feedback mechanism (quality scores)"
    echo "5. Configuration (feature toggles)"
    echo "6. Integration (complete workflow)"
else
    echo -e "${GREEN}All test suites executed successfully!${NC}"
    echo "Core Loop implementation is complete."
fi

echo
echo "To run specific test suite:"
echo "  ./run_core_loop_tests.sh [criteria|feedback|schema|config|migration|integration]"
echo

# Exit with appropriate code
if [ $FAILED_TESTS -gt 0 ]; then
    exit 1
else
    exit 0
fi