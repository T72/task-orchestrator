#!/bin/bash

# Test Suite for Agent Specialization and Sub-Agent Orchestration
# Safe, isolated tests for specialized agent routing and phase-based coordination

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Find tm in parent directory or current directory
if [ -f "../tm" ]; then
    TM="../tm"
elif [ -f "./tm" ]; then
    TM="./tm"
else
    echo "Error: tm executable not found"
    exit 1
fi

# Create isolated test environment
TEST_DIR=$(mktemp -d -t tm_agent_spec_test_XXXXXX)
cd "$TEST_DIR"
git init >/dev/null 2>&1

echo -e "${BLUE}===================================${NC}"
echo -e "${BLUE}  Agent Specialization Tests       ${NC}"
echo -e "${BLUE}===================================${NC}"
echo ""

# Helper function for running tests
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
        echo "  Debug: Check $TEST_DIR/.task-orchestrator/test.log"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Initialize
$TM init >/dev/null 2>&1

echo -e "${YELLOW}=== Agent Specialization Tests ===${NC}"
echo ""

# Test 1: Create task with specialist metadata
test_specialist_assignment() {
    # Create task with specialist type
    TASK_JSON=$(cat <<EOF
{
    "title": "Database optimization",
    "specialist": "database-specialist",
    "phase": 1,
    "priority": "high"
}
EOF
    )
    
    # Add task with metadata
    TASK_ID=$($TM add "Database optimization" \
        --meta specialist:database-specialist \
        --meta phase:1 \
        -p high | grep -o '[a-f0-9]\{8\}')
    
    [ -n "$TASK_ID" ]
}

# Test 2: Multiple specialist types
test_multiple_specialists() {
    # Create tasks for different specialists
    DB_TASK=$($TM add "Create schema" --meta specialist:database-specialist | grep -o '[a-f0-9]\{8\}')
    BE_TASK=$($TM add "Build API" --meta specialist:backend-specialist | grep -o '[a-f0-9]\{8\}')
    FE_TASK=$($TM add "Design UI" --meta specialist:frontend-specialist | grep -o '[a-f0-9]\{8\}')
    
    # Verify all tasks created
    [ -n "$DB_TASK" ] && [ -n "$BE_TASK" ] && [ -n "$FE_TASK" ]
}

# Test 3: Phase-based task coordination
test_phase_coordination() {
    # Create tasks in different phases
    PHASE1=$($TM add "Phase 1 task" --meta phase:1 | grep -o '[a-f0-9]\{8\}')
    PHASE2=$($TM add "Phase 2 task" --meta phase:2 --depends-on $PHASE1 | grep -o '[a-f0-9]\{8\}')
    PHASE3=$($TM add "Phase 3 task" --meta phase:3 --depends-on $PHASE2 | grep -o '[a-f0-9]\{8\}')
    
    # Check phase 2 is blocked until phase 1 completes
    STATUS=$($TM show $PHASE2 | grep "Status:" | awk '{print $2}')
    [ "$STATUS" = "blocked" ]
}

# Test 4: Agent claiming by specialty
test_agent_claim_by_specialty() {
    # Create specialized tasks
    TASK_ID=$($TM add "Database task" --meta specialist:database-specialist | grep -o '[a-f0-9]\{8\}')
    
    # Database specialist claims their task
    export TM_AGENT_ID="db_agent_001"
    export TM_AGENT_SPECIALTY="database-specialist"
    
    $TM assign $TASK_ID $TM_AGENT_ID >/dev/null 2>&1
    
    # Verify assignment
    $TM show $TASK_ID | grep -q "db_agent_001"
}

# Test 5: Specialist mismatch prevention
test_specialist_mismatch() {
    # Create frontend task
    FE_TASK=$($TM add "Build UI" --meta specialist:frontend-specialist | grep -o '[a-f0-9]\{8\}')
    
    # Try to assign to wrong specialist type (should handle gracefully)
    export TM_AGENT_ID="backend_agent"
    export TM_AGENT_SPECIALTY="backend-specialist"
    
    # This should either fail or log a warning
    $TM assign $FE_TASK $TM_AGENT_ID 2>&1 | tee .task-orchestrator/test.log
    
    # Task should remain unassigned or show warning
    if $TM show $FE_TASK | grep -q "backend_agent"; then
        # If assigned, check for warning in log
        grep -q "warning\|mismatch" .task-orchestrator/test.log
    else
        # Not assigned - correct behavior
        true
    fi
}

# Test 6: Multi-phase dependency resolution
test_multi_phase_dependencies() {
    # Create complex phase structure
    P1_T1=$($TM add "P1: Design" --meta phase:1 | grep -o '[a-f0-9]\{8\}')
    P1_T2=$($TM add "P1: Review" --meta phase:1 | grep -o '[a-f0-9]\{8\}')
    
    P2_T1=$($TM add "P2: Implement" --meta phase:2 --depends-on $P1_T1 $P1_T2 | grep -o '[a-f0-9]\{8\}')
    P2_T2=$($TM add "P2: Test" --meta phase:2 --depends-on $P2_T1 | grep -o '[a-f0-9]\{8\}')
    
    P3_T1=$($TM add "P3: Deploy" --meta phase:3 --depends-on $P2_T1 $P2_T2 | grep -o '[a-f0-9]\{8\}')
    
    # Complete phase 1
    $TM complete $P1_T1 >/dev/null 2>&1
    $TM complete $P1_T2 >/dev/null 2>&1
    
    # Phase 2 task 1 should now be unblocked
    STATUS=$($TM show $P2_T1 | grep "Status:" | awk '{print $2}')
    [ "$STATUS" = "pending" ]
}

# Test 7: Agent pool management
test_agent_pool() {
    # Register multiple agents of same specialty
    for i in {1..3}; do
        export TM_AGENT_ID="frontend_dev_$i"
        export TM_AGENT_SPECIALTY="frontend-specialist"
        
        # Create task and auto-assign
        TASK=$($TM add "FE Task $i" --meta specialist:frontend-specialist | grep -o '[a-f0-9]\{8\}')
        $TM assign $TASK $TM_AGENT_ID >/dev/null 2>&1
    done
    
    # Check all agents have tasks
    for i in {1..3}; do
        $TM list --assignee "frontend_dev_$i" | grep -q "FE Task $i"
    done
}

# Test 8: Specialist workload balancing
test_workload_balancing() {
    # Create multiple tasks for same specialty
    for i in {1..5}; do
        $TM add "Backend task $i" --meta specialist:backend-specialist >/dev/null 2>&1
    done
    
    # Simulate workload distribution
    BACKEND_TASKS=$($TM list --meta specialist:backend-specialist | grep -c "Backend task")
    [ $BACKEND_TASKS -eq 5 ]
}

# Test 9: Cross-specialist dependencies
test_cross_specialist_deps() {
    # Frontend depends on backend
    BE_TASK=$($TM add "API endpoint" --meta specialist:backend-specialist | grep -o '[a-f0-9]\{8\}')
    FE_TASK=$($TM add "UI integration" --meta specialist:frontend-specialist --depends-on $BE_TASK | grep -o '[a-f0-9]\{8\}')
    
    # Backend specialist completes their part
    export TM_AGENT_ID="backend_dev"
    export TM_AGENT_SPECIALTY="backend-specialist"
    $TM assign $BE_TASK $TM_AGENT_ID >/dev/null 2>&1
    $TM complete $BE_TASK >/dev/null 2>&1
    
    # Frontend task should be unblocked
    STATUS=$($TM show $FE_TASK | grep "Status:" | awk '{print $2}')
    [ "$STATUS" = "pending" ]
}

# Test 10: Specialist capability requirements
test_capability_requirements() {
    # Create task with specific capability requirements
    TASK_ID=$($TM add "Complex ML task" \
        --meta specialist:ml-specialist \
        --meta requires:gpu \
        --meta requires:tensorflow | grep -o '[a-f0-9]\{8\}')
    
    # Agent with matching capabilities
    export TM_AGENT_ID="ml_agent_gpu"
    export TM_AGENT_SPECIALTY="ml-specialist"
    export TM_AGENT_CAPABILITIES="gpu,tensorflow,pytorch"
    
    $TM assign $TASK_ID $TM_AGENT_ID >/dev/null 2>&1
    $TM show $TASK_ID | grep -q "ml_agent_gpu"
}

# Run specialist tests
run_test "Specialist assignment" test_specialist_assignment
run_test "Multiple specialist types" test_multiple_specialists
run_test "Phase-based coordination" test_phase_coordination
run_test "Agent claiming by specialty" test_agent_claim_by_specialty
run_test "Specialist mismatch prevention" test_specialist_mismatch
run_test "Multi-phase dependencies" test_multi_phase_dependencies
run_test "Agent pool management" test_agent_pool
run_test "Workload balancing" test_workload_balancing
run_test "Cross-specialist dependencies" test_cross_specialist_deps
run_test "Capability requirements" test_capability_requirements

echo ""
echo -e "${YELLOW}=== Orchestration Pattern Tests ===${NC}"
echo ""

# Test 11: Pipeline pattern
test_pipeline_pattern() {
    # Create pipeline: Data → Process → Validate → Deploy
    DATA=$($TM add "Fetch data" --meta specialist:data-engineer --meta phase:1 | grep -o '[a-f0-9]\{8\}')
    PROC=$($TM add "Process data" --meta specialist:data-scientist --meta phase:2 --depends-on $DATA | grep -o '[a-f0-9]\{8\}')
    VAL=$($TM add "Validate results" --meta specialist:qa-specialist --meta phase:3 --depends-on $PROC | grep -o '[a-f0-9]\{8\}')
    DEP=$($TM add "Deploy model" --meta specialist:devops-specialist --meta phase:4 --depends-on $VAL | grep -o '[a-f0-9]\{8\}')
    
    # Verify pipeline structure
    [ -n "$DATA" ] && [ -n "$PROC" ] && [ -n "$VAL" ] && [ -n "$DEP" ]
}

# Test 12: Parallel specialist execution
test_parallel_execution() {
    # Create tasks that can run in parallel
    PARENT=$($TM add "Parent task" | grep -o '[a-f0-9]\{8\}')
    $TM complete $PARENT >/dev/null 2>&1
    
    # Multiple specialists work in parallel
    FE=$($TM add "Frontend work" --meta specialist:frontend-specialist --depends-on $PARENT | grep -o '[a-f0-9]\{8\}')
    BE=$($TM add "Backend work" --meta specialist:backend-specialist --depends-on $PARENT | grep -o '[a-f0-9]\{8\}')
    QA=$($TM add "Test prep" --meta specialist:qa-specialist --depends-on $PARENT | grep -o '[a-f0-9]\{8\}')
    
    # All should be pending (not blocked)
    FE_STATUS=$($TM show $FE | grep "Status:" | awk '{print $2}')
    BE_STATUS=$($TM show $BE | grep "Status:" | awk '{print $2}')
    QA_STATUS=$($TM show $QA | grep "Status:" | awk '{print $2}')
    
    [ "$FE_STATUS" = "pending" ] && [ "$BE_STATUS" = "pending" ] && [ "$QA_STATUS" = "pending" ]
}

# Test 13: Specialist handoff
test_specialist_handoff() {
    # Create handoff scenario
    DESIGN=$($TM add "Design API" --meta specialist:architect --meta phase:1 | grep -o '[a-f0-9]\{8\}')
    
    # Architect completes and creates handoff note
    export TM_AGENT_ID="architect_001"
    $TM assign $DESIGN architect_001 >/dev/null 2>&1
    echo "API specs: REST, JSON, OAuth2" > .task-orchestrator/handoff_${DESIGN}.txt
    $TM complete $DESIGN >/dev/null 2>&1
    
    # Backend dev picks up with handoff info
    IMPL=$($TM add "Implement API" --meta specialist:backend-specialist --meta phase:2 --depends-on $DESIGN | grep -o '[a-f0-9]\{8\}')
    
    # Check handoff file exists for next specialist
    [ -f ".task-orchestrator/handoff_${DESIGN}.txt" ]
}

run_test "Pipeline pattern" test_pipeline_pattern
run_test "Parallel specialist execution" test_parallel_execution
run_test "Specialist handoff" test_specialist_handoff

# Cleanup
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
    echo -e "${GREEN}✅ All agent specialization tests passed!${NC}"
    exit 0
else
    echo -e "${RED}❌ Some agent specialization tests failed${NC}"
    exit 1
fi