#!/bin/bash

# Safe Test Runner for Task Orchestrator
# Runs all tests with proper isolation and WSL safety measures
# Prevents system crashes by running tests sequentially with resource limits

set -e

# Detect WSL environment
IS_WSL=0
if grep -qi microsoft /proc/version 2>/dev/null; then
    IS_WSL=1
    echo "========================================="
    echo "WSL environment detected"
    echo "Running tests with enhanced safety measures"
    echo "========================================="
fi

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Define all test scripts
TESTS=(
    "test_tm.sh"
    "test_edge_cases.sh"
    "additional_edge_tests.sh"
    "test_context_sharing.sh"
    "stress_test.sh"
    "test_collaboration.sh"
    "test_agent_specialization.sh"
    "test_durability.sh"
    "test_event_driven.sh"
    "test_hooks.sh"
    "test_isolation.sh"
    "test_orchestration_integration.sh"
)

# Track results
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0
RESULTS_FILE="/tmp/test_results_$(date +%Y%m%d_%H%M%S).log"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "========================================="
echo "Task Orchestrator Test Suite"
echo "Running ${#TESTS[@]} test suites"
echo "Results will be saved to: $RESULTS_FILE"
echo "========================================="
echo ""

# Function to run a single test with safety measures
run_test_safe() {
    local test_name="$1"
    local test_path="$SCRIPT_DIR/$test_name"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    # Check if test exists
    if [ ! -f "$test_path" ]; then
        echo -e "${YELLOW}[$TOTAL_TESTS/${#TESTS[@]}] SKIP: $test_name (not found)${NC}"
        echo "SKIP: $test_name - File not found" >> "$RESULTS_FILE"
        SKIPPED_TESTS=$((SKIPPED_TESTS + 1))
        return
    fi
    
    echo -e "${BLUE}[$TOTAL_TESTS/${#TESTS[@]}] Running: $test_name${NC}"
    echo "----------------------------------------"
    
    # Create a subshell for test execution
    (
        # Note: Resource limits removed as they were too restrictive
        # WSL safety is now handled through timeouts and cleanup
        
        # Run the test with timeout
        if [ $IS_WSL -eq 1 ]; then
            timeout 60 bash "$test_path" 2>&1
        else
            timeout 120 bash "$test_path" 2>&1
        fi
    )
    
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        echo -e "${GREEN}✓ PASS: $test_name${NC}"
        echo "PASS: $test_name" >> "$RESULTS_FILE"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    elif [ $exit_code -eq 124 ]; then
        echo -e "${RED}✗ TIMEOUT: $test_name${NC}"
        echo "TIMEOUT: $test_name" >> "$RESULTS_FILE"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    else
        echo -e "${RED}✗ FAIL: $test_name (exit code: $exit_code)${NC}"
        echo "FAIL: $test_name (exit code: $exit_code)" >> "$RESULTS_FILE"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    
    echo ""
    
    # Clean up any leftover processes
    pkill -f "tm.*test" 2>/dev/null || true
    
    # Add delay between tests for WSL
    if [ $IS_WSL -eq 1 ]; then
        echo "Waiting 2 seconds before next test (WSL safety)..."
        sleep 2
        sync
    else
        sleep 0.5
    fi
    
    # Clean up temp directories
    find /tmp -maxdepth 1 -type d -name "tm_*test*" -mmin +5 -exec rm -rf {} \; 2>/dev/null || true
}

# Main test execution
echo "Starting test execution at $(date)" >> "$RESULTS_FILE"
echo "WSL Mode: $IS_WSL" >> "$RESULTS_FILE"
echo "=========================================" >> "$RESULTS_FILE"

for test in "${TESTS[@]}"; do
    run_test_safe "$test"
done

# Summary
echo "========================================="
echo "Test Suite Complete"
echo "========================================="
echo -e "Total:   $TOTAL_TESTS"
echo -e "${GREEN}Passed:  $PASSED_TESTS${NC}"
echo -e "${RED}Failed:  $FAILED_TESTS${NC}"
echo -e "${YELLOW}Skipped: $SKIPPED_TESTS${NC}"

# Calculate success rate
if [ $((PASSED_TESTS + FAILED_TESTS)) -gt 0 ]; then
    SUCCESS_RATE=$(( (PASSED_TESTS * 100) / (PASSED_TESTS + FAILED_TESTS) ))
    echo -e "Success Rate: ${SUCCESS_RATE}%"
else
    echo "No tests were executed successfully"
fi

echo "========================================="
echo "Results saved to: $RESULTS_FILE"

# Final cleanup
echo ""
echo "Performing final cleanup..."
find /tmp -maxdepth 1 -type d -name "tm_*test*" -exec rm -rf {} \; 2>/dev/null || true
pkill -f "tm.*test" 2>/dev/null || true

# Exit with appropriate code
if [ $FAILED_TESTS -eq 0 ] && [ $PASSED_TESTS -gt 0 ]; then
    echo -e "${GREEN}All tests passed successfully!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed. Please review the results.${NC}"
    exit 1
fi