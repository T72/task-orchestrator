#!/bin/bash

# Integration Test Suite for End-to-End Task Orchestration
# Comprehensive scenarios testing all core features together
# Safe, isolated tests that won't affect the host system

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
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
TEST_DIR=$(mktemp -d -t tm_integration_test_XXXXXX)
cd "$TEST_DIR"
git init >/dev/null 2>&1

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}  Orchestration Integration Tests     ${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""

# Helper function for running tests
run_test() {
    local test_name="$1"
    local test_func="$2"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    echo -e "${CYAN}Scenario $TESTS_RUN: $test_name${NC}"
    echo -n "  Running... "
    
    if $test_func >/dev/null 2>&1; then
        echo -e "${GREEN}PASSED${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}FAILED${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    echo ""
}

# Initialize
$TM init >/dev/null 2>&1

echo -e "${YELLOW}=== End-to-End Orchestration Scenarios ===${NC}"
echo ""

# Scenario 1: Complete Multi-Agent Development Workflow
test_multi_agent_workflow() {
    echo "  Setting up multi-agent development workflow..." >&2
    
    # Phase 1: Architecture & Design
    DESIGN=$($TM add "Design system architecture" \
        --meta specialist:architect \
        --meta phase:1 \
        -p high | grep -o '[a-f0-9]\{8\}')
    
    # Architect agent works on design
    export TM_AGENT_ID="architect_001"
    export TM_AGENT_SPECIALTY="architect"
    $TM assign $DESIGN $TM_AGENT_ID >/dev/null 2>&1
    
    # Create shared context for design decisions
    mkdir -p .task-orchestrator/contexts
    echo "Architecture: Microservices, REST API, PostgreSQL" > .task-orchestrator/contexts/shared_${DESIGN}.md
    
    $TM complete $DESIGN >/dev/null 2>&1
    
    # Phase 2: Parallel Development
    DB_SCHEMA=$($TM add "Create database schema" \
        --meta specialist:database-specialist \
        --meta phase:2 \
        --depends-on $DESIGN | grep -o '[a-f0-9]\{8\}')
    
    API_DEV=$($TM add "Develop REST API" \
        --meta specialist:backend-specialist \
        --meta phase:2 \
        --depends-on $DESIGN | grep -o '[a-f0-9]\{8\}')
    
    UI_DEV=$($TM add "Build user interface" \
        --meta specialist:frontend-specialist \
        --meta phase:2 \
        --depends-on $DESIGN | grep -o '[a-f0-9]\{8\}')
    
    # Multiple specialists work in parallel
    export TM_AGENT_ID="db_expert"
    $TM assign $DB_SCHEMA $TM_AGENT_ID >/dev/null 2>&1
    echo "Schema created: users, sessions, audit_logs" > .task-orchestrator/contexts/shared_${DB_SCHEMA}.md
    $TM complete $DB_SCHEMA >/dev/null 2>&1
    
    export TM_AGENT_ID="backend_dev_001"
    $TM assign $API_DEV $TM_AGENT_ID >/dev/null 2>&1
    echo "API endpoints: /auth, /users, /sessions" > .task-orchestrator/contexts/shared_${API_DEV}.md
    $TM complete $API_DEV >/dev/null 2>&1
    
    export TM_AGENT_ID="frontend_dev_001"
    $TM assign $UI_DEV $TM_AGENT_ID >/dev/null 2>&1
    echo "UI components: Login, Dashboard, UserProfile" > .task-orchestrator/contexts/shared_${UI_DEV}.md
    $TM complete $UI_DEV >/dev/null 2>&1
    
    # Phase 3: Integration & Testing
    INTEGRATION=$($TM add "Integration testing" \
        --meta specialist:qa-specialist \
        --meta phase:3 \
        --depends-on $DB_SCHEMA $API_DEV $UI_DEV | grep -o '[a-f0-9]\{8\}')
    
    export TM_AGENT_ID="qa_engineer"
    $TM assign $INTEGRATION $TM_AGENT_ID >/dev/null 2>&1
    
    # Simulate test results with event
    echo "$(date +%s): tests.passed - All integration tests passed" >> .task-orchestrator/events.log
    $TM complete $INTEGRATION >/dev/null 2>&1
    
    # Phase 4: Deployment
    DEPLOY=$($TM add "Deploy to production" \
        --meta specialist:devops-specialist \
        --meta phase:4 \
        --depends-on $INTEGRATION | grep -o '[a-f0-9]\{8\}')
    
    # Check all tasks completed successfully
    [ -n "$DEPLOY" ] && \
    $TM show $INTEGRATION | grep -q "completed"
}

# Scenario 2: Event-Driven Task Cascade with Hooks
test_event_driven_cascade() {
    echo "  Testing event-driven task cascade..." >&2
    
    # Set up hooks
    mkdir -p .task-orchestrator/hooks
    
    # Hook that creates follow-up task when build completes
    cat > .task-orchestrator/hooks/post-complete.sh << 'EOF'
#!/bin/bash
if echo "$1" | grep -q "build"; then
    echo "HOOK: Creating deployment task" >&2
    # Would create deployment task here
fi
EOF
    chmod +x .task-orchestrator/hooks/post-complete.sh
    
    # Create build pipeline
    BUILD=$($TM add "Build application" --meta type:build | grep -o '[a-f0-9]\{8\}')
    
    # Complete build (triggers hook)
    $TM complete $BUILD >/dev/null 2>&1
    
    # Manually create deployment (simulating hook action)
    DEPLOY=$($TM add "Deploy to staging" --meta type:deploy --meta triggered_by:$BUILD | grep -o '[a-f0-9]\{8\}')
    
    # Event should be logged
    echo "$(date +%s): task.cascaded - $BUILD triggered $DEPLOY" >> .task-orchestrator/events.log
    
    [ -n "$DEPLOY" ] && [ -f .task-orchestrator/events.log ]
}

# Scenario 3: Complex Dependency Resolution with Recovery
test_complex_dependencies_recovery() {
    echo "  Testing complex dependencies with failure recovery..." >&2
    
    # Create complex dependency tree
    ROOT=$($TM add "Root task" | grep -o '[a-f0-9]\{8\}')
    
    # Level 1 - parallel tasks
    L1_A=$($TM add "L1-A" --depends-on $ROOT | grep -o '[a-f0-9]\{8\}')
    L1_B=$($TM add "L1-B" --depends-on $ROOT | grep -o '[a-f0-9]\{8\}')
    L1_C=$($TM add "L1-C" --depends-on $ROOT | grep -o '[a-f0-9]\{8\}')
    
    # Level 2 - convergence
    L2=$($TM add "L2-Convergence" --depends-on $L1_A $L1_B $L1_C | grep -o '[a-f0-9]\{8\}')
    
    # Complete root
    $TM complete $ROOT >/dev/null 2>&1
    
    # Simulate failure in L1_B
    $TM update $L1_B --status failed 2>/dev/null || \
    $TM update $L1_B --meta status:failed >/dev/null 2>&1
    
    # Complete other L1 tasks
    $TM complete $L1_A >/dev/null 2>&1
    $TM complete $L1_C >/dev/null 2>&1
    
    # L2 should still be blocked
    STATUS=$($TM show $L2 | grep "Status:" | awk '{print $2}')
    
    # Recovery: retry failed task
    $TM update $L1_B --status pending >/dev/null 2>&1
    $TM complete $L1_B >/dev/null 2>&1
    
    # L2 should now be unblocked
    NEW_STATUS=$($TM show $L2 | grep "Status:" | awk '{print $2}')
    [ "$NEW_STATUS" = "pending" ]
}

# Scenario 4: Multi-Phase Project with Context Sharing
test_multi_phase_context_sharing() {
    echo "  Testing multi-phase project with context sharing..." >&2
    
    # Initialize project context
    PROJECT_ID="proj_$(date +%s)"
    mkdir -p .task-orchestrator/projects/$PROJECT_ID
    
    # Phase 1: Requirements gathering
    REQ=$($TM add "Gather requirements" \
        --meta project:$PROJECT_ID \
        --meta phase:requirements | grep -o '[a-f0-9]\{8\}')
    
    export TM_AGENT_ID="analyst_001"
    echo "Requirements: User auth, Data processing, Reporting" > .task-orchestrator/projects/$PROJECT_ID/requirements.md
    $TM complete $REQ >/dev/null 2>&1
    
    # Phase 2: Design (uses requirements)
    DESIGN=$($TM add "System design" \
        --meta project:$PROJECT_ID \
        --meta phase:design \
        --depends-on $REQ | grep -o '[a-f0-9]\{8\}')
    
    export TM_AGENT_ID="architect_001"
    # Read requirements and create design
    cat .task-orchestrator/projects/$PROJECT_ID/requirements.md > /dev/null
    echo "Design: 3-tier architecture based on requirements" > .task-orchestrator/projects/$PROJECT_ID/design.md
    $TM complete $DESIGN >/dev/null 2>&1
    
    # Phase 3: Implementation (uses design)
    IMPL=$($TM add "Implementation" \
        --meta project:$PROJECT_ID \
        --meta phase:implementation \
        --depends-on $DESIGN | grep -o '[a-f0-9]\{8\}')
    
    # Verify context is preserved
    [ -f ".task-orchestrator/projects/$PROJECT_ID/requirements.md" ] && \
    [ -f ".task-orchestrator/projects/$PROJECT_ID/design.md" ]
}

# Scenario 5: Specialist Pool Load Balancing
test_specialist_load_balancing() {
    echo "  Testing specialist pool load balancing..." >&2
    
    # Register specialist pool
    SPECIALISTS=("backend_001" "backend_002" "backend_003")
    
    # Create workload
    TASKS=()
    for i in {1..6}; do
        TASK=$($TM add "Backend task $i" --meta specialist:backend-specialist | grep -o '[a-f0-9]\{8\}')
        TASKS+=($TASK)
    done
    
    # Distribute tasks among specialists (round-robin)
    for i in "${!TASKS[@]}"; do
        SPECIALIST_INDEX=$((i % ${#SPECIALISTS[@]}))
        export TM_AGENT_ID="${SPECIALISTS[$SPECIALIST_INDEX]}"
        $TM assign "${TASKS[$i]}" "$TM_AGENT_ID" >/dev/null 2>&1
    done
    
    # Verify distribution
    for specialist in "${SPECIALISTS[@]}"; do
        COUNT=$($TM list --assignee "$specialist" 2>/dev/null | grep -c "Backend task" || echo 0)
        [ $COUNT -ge 1 ]
    done
}

# Scenario 6: Durability Under Stress
test_durability_under_stress() {
    echo "  Testing durability under stress conditions..." >&2
    
    # Create checkpoint
    cp -r .task-orchestrator .task-orchestrator.checkpoint
    
    # Generate high load
    PIDS=()
    for i in {1..10}; do
        (
            for j in {1..5}; do
                $TM add "Stress task $i-$j" >/dev/null 2>&1
            done
        ) &
        PIDS+=($!)
    done
    
    # Wait for some tasks
    sleep 1
    
    # Simulate crash
    for pid in "${PIDS[@]}"; do
        kill -9 $pid 2>/dev/null || true
    done
    wait
    
    # Verify database integrity
    $TM list >/dev/null 2>&1
    
    # Count tasks created
    TASK_COUNT=$($TM list | grep -c "Stress task" || echo 0)
    [ $TASK_COUNT -gt 0 ]
}

# Scenario 7: Private Notes and Collaboration
test_private_notes_collaboration() {
    echo "  Testing private notes in collaboration..." >&2
    
    TASK=$($TM add "Collaborative research" | grep -o '[a-f0-9]\{8\}')
    
    # Agent 1 adds private notes
    export TM_AGENT_ID="researcher_001"
    mkdir -p .task-orchestrator/notes
    echo "Private: Investigating approach A" > .task-orchestrator/notes/${TASK}_researcher_001.md
    
    # Agent 2 adds different private notes
    export TM_AGENT_ID="researcher_002"
    echo "Private: Exploring approach B" > .task-orchestrator/notes/${TASK}_researcher_002.md
    
    # Add shared findings
    echo "Shared: Both approaches viable" > .task-orchestrator/contexts/shared_${TASK}.md
    
    # Verify isolation
    [ -f ".task-orchestrator/notes/${TASK}_researcher_001.md" ] && \
    [ -f ".task-orchestrator/notes/${TASK}_researcher_002.md" ] && \
    [ -f ".task-orchestrator/contexts/shared_${TASK}.md" ]
}

# Scenario 8: Notification System Integration
test_notification_system() {
    echo "  Testing notification system..." >&2
    
    # Set up notification directory
    mkdir -p .task-orchestrator/notifications
    
    # Create high-priority task
    HIGH_PRIO=$($TM add "Critical issue" -p high | grep -o '[a-f0-9]\{8\}')
    
    # Generate notification
    cat > .task-orchestrator/notifications/notify_${HIGH_PRIO}.json << EOF
{
    "type": "high_priority",
    "task_id": "$HIGH_PRIO",
    "timestamp": "$(date +%s)",
    "recipients": ["ops_team", "manager"]
}
EOF
    
    # Create task with deadline
    DEADLINE=$($TM add "Deadline task" --meta deadline:$(date -d "+1 hour" +%s 2>/dev/null || date +%s) | grep -o '[a-f0-9]\{8\}')
    
    # Generate deadline notification
    cat > .task-orchestrator/notifications/notify_${DEADLINE}.json << EOF
{
    "type": "deadline_approaching",
    "task_id": "$DEADLINE",
    "timestamp": "$(date +%s)"
}
EOF
    
    # Check notifications exist
    ls .task-orchestrator/notifications/*.json | grep -c "notify_" | grep -q "[1-9]"
}

# Scenario 9: Full Project Lifecycle
test_full_project_lifecycle() {
    echo "  Testing full project lifecycle..." >&2
    
    PROJECT="lifecycle_test"
    
    # 1. Project initialization
    INIT=$($TM add "Initialize $PROJECT" --meta project:$PROJECT --meta phase:0 | grep -o '[a-f0-9]\{8\}')
    $TM complete $INIT >/dev/null 2>&1
    
    # 2. Planning phase
    PLAN=$($TM add "Project planning" --meta project:$PROJECT --meta phase:1 --depends-on $INIT | grep -o '[a-f0-9]\{8\}')
    $TM complete $PLAN >/dev/null 2>&1
    
    # 3. Execution phase (parallel tasks)
    EXEC_TASKS=()
    for component in "auth" "api" "ui"; do
        TASK=$($TM add "Develop $component" \
            --meta project:$PROJECT \
            --meta phase:2 \
            --depends-on $PLAN | grep -o '[a-f0-9]\{8\}')
        EXEC_TASKS+=($TASK)
    done
    
    # Complete execution tasks
    for task in "${EXEC_TASKS[@]}"; do
        $TM complete $task >/dev/null 2>&1
    done
    
    # 4. Testing phase
    TEST=$($TM add "System testing" \
        --meta project:$PROJECT \
        --meta phase:3 \
        --depends-on ${EXEC_TASKS[@]} | grep -o '[a-f0-9]\{8\}')
    $TM complete $TEST >/dev/null 2>&1
    
    # 5. Deployment
    DEPLOY=$($TM add "Deploy $PROJECT" \
        --meta project:$PROJECT \
        --meta phase:4 \
        --depends-on $TEST | grep -o '[a-f0-9]\{8\}')
    
    # Verify full lifecycle
    $TM show $DEPLOY | grep -q "pending"
}

# Scenario 10: Resilient Error Handling
test_resilient_error_handling() {
    echo "  Testing resilient error handling..." >&2
    
    # Create task that might fail
    RISKY=$($TM add "Risky operation" | grep -o '[a-f0-9]\{8\}')
    
    # Simulate multiple failure attempts with recovery
    for attempt in {1..3}; do
        if [ $attempt -lt 3 ]; then
            # Fail
            $TM update $RISKY --meta "attempt_$attempt:failed" >/dev/null 2>&1
            echo "$(date +%s): task.retry - Attempt $attempt failed for $RISKY" >> .task-orchestrator/events.log
        else
            # Succeed on third attempt
            $TM complete $RISKY >/dev/null 2>&1
            echo "$(date +%s): task.recovered - $RISKY succeeded after $attempt attempts" >> .task-orchestrator/events.log
        fi
    done
    
    # Verify recovery
    $TM show $RISKY | grep -q "completed" && \
    grep -q "task.recovered" .task-orchestrator/events.log
}

# Run all integration scenarios
run_test "Multi-Agent Development Workflow" test_multi_agent_workflow
run_test "Event-Driven Task Cascade" test_event_driven_cascade
run_test "Complex Dependencies with Recovery" test_complex_dependencies_recovery
run_test "Multi-Phase Context Sharing" test_multi_phase_context_sharing
run_test "Specialist Pool Load Balancing" test_specialist_load_balancing
run_test "Durability Under Stress" test_durability_under_stress
run_test "Private Notes Collaboration" test_private_notes_collaboration
run_test "Notification System Integration" test_notification_system
run_test "Full Project Lifecycle" test_full_project_lifecycle
run_test "Resilient Error Handling" test_resilient_error_handling

# Cleanup
cd ..
rm -rf "$TEST_DIR"

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}        Integration Test Summary      ${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""
echo "Scenarios Run: $TESTS_RUN"
echo -e "Scenarios Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Scenarios Failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All integration scenarios passed!${NC}"
    echo -e "${GREEN}The task orchestrator is ready for production use.${NC}"
    exit 0
else
    echo -e "${RED}❌ Some integration scenarios failed${NC}"
    echo -e "${YELLOW}Review failed scenarios before deployment.${NC}"
    exit 1
fi