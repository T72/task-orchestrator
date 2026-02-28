#!/bin/bash

# Test Suite for supported hook tooling commands (`tm hooks ...`)
# Focuses on implemented behavior in admin handler and monitor subsystem.

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

if [ -f "$PROJECT_DIR/tm" ]; then
    TM_ORIG="$PROJECT_DIR/tm"
elif [ -f "./tm" ]; then
    TM_ORIG="./tm"
else
    echo "Error: tm executable not found"
    exit 1
fi

TEST_DIR=$(mktemp -d -t tm_hooks_test_XXXXXX)
cd "$TEST_DIR"
git init >/dev/null 2>&1
cp "$TM_ORIG" ./tm
if [ -d "$PROJECT_DIR/src" ]; then
    cp -r "$PROJECT_DIR/src" ./
fi
chmod +x ./tm
TM="./tm"

echo -e "${BLUE}===================================${NC}"
echo -e "${BLUE}      Hook Tooling Tests           ${NC}"
echo -e "${BLUE}===================================${NC}"
echo ""

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

$TM init >/dev/null 2>&1

echo -e "${YELLOW}=== Command Coverage ===${NC}"
echo ""

test_hooks_report_default() {
    OUT=$($TM hooks report 2>&1)
    echo "$OUT" | grep -q "Hook Performance Report"
}

test_hooks_alerts_default() {
    OUT=$($TM hooks alerts 2>&1)
    echo "$OUT" | grep -q "No alerts in the last"
}

test_hooks_thresholds_show() {
    OUT=$($TM hooks thresholds 2>&1)
    echo "$OUT" | grep -q "Current Performance Thresholds"
}

test_hooks_thresholds_update() {
    OUT=$($TM hooks thresholds 111 222 333 2>&1)
    echo "$OUT" | grep -q "Thresholds updated successfully" && \
    echo "$OUT" | grep -q "Warning: 111ms" && \
    echo "$OUT" | grep -q "Critical: 222ms" && \
    echo "$OUT" | grep -q "Timeout: 333ms"
}

test_hooks_cleanup() {
    OUT=$($TM hooks cleanup 0 2>&1)
    echo "$OUT" | grep -q "Cleaned up"
}

test_hooks_usage_on_missing_subcommand() {
    OUT=$($TM hooks 2>&1 || true)
    echo "$OUT" | grep -q "Usage: tm hooks <subcommand>"
}

test_hooks_unknown_subcommand() {
    OUT=$($TM hooks does-not-exist 2>&1 || true)
    echo "$OUT" | grep -q "Unknown hooks subcommand"
}

test_metrics_db_created() {
    [ -f ".task-orchestrator/metrics/hook_performance.db" ]
}

run_test "hooks report default" test_hooks_report_default
run_test "hooks alerts default" test_hooks_alerts_default
run_test "hooks thresholds show" test_hooks_thresholds_show
run_test "hooks thresholds update" test_hooks_thresholds_update
run_test "hooks cleanup" test_hooks_cleanup
run_test "hooks usage on missing subcommand" test_hooks_usage_on_missing_subcommand
run_test "hooks unknown subcommand" test_hooks_unknown_subcommand
run_test "metrics DB created" test_metrics_db_created

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
    echo -e "${GREEN}All hook tooling tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some hook tooling tests failed${NC}"
    exit 1
fi
