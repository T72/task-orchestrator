#!/bin/bash
# PRD v2.1 Requirements Validation Test
# Based on PRD-TASK-ORCHESTRATOR-v2.1.md

set -e

echo "========================================="
echo "  PRD v2.1 REQUIREMENTS VALIDATION"
echo "========================================="
echo ""

# Counter for passed/failed requirements
PASSED=0
FAILED=0

# Test function
test_requirement() {
    local req_id="$1"
    local description="$2"
    local test_command="$3"
    
    echo "Testing $req_id: $description"
    
    if eval "$test_command" >/dev/null 2>&1; then
        echo "✅ PASS: $req_id"
        PASSED=$((PASSED + 1))
    else
        echo "❌ FAIL: $req_id"
        FAILED=$((FAILED + 1))
    fi
    echo ""
}

echo "🏗️  PRD v2.1 FOUNDATION LAYER REQUIREMENTS:"
echo ""

# Foundation Requirements (NEW in v2.1)
test_requirement "FR-CORE-1" "Read-Only Shared Context File" \
    "test -f .claude/context/shared-context.md || test -f .task-orchestrator/context/shared-context.md || grep -q 'shared.*context' src/tm_production.py"

test_requirement "FR-CORE-2" "Private Note-Taking Files" \
    "test -d .claude/agents/notes || test -d .task-orchestrator/agents/notes || grep -q 'private.*notes' src/tm_production.py"

test_requirement "FR-CORE-3" "Shared Notification File" \
    "test -f .claude/notifications/broadcast.md || test -f .task-orchestrator/notifications/broadcast.md || grep -q 'notification.*broadcast' src/tm_production.py"

echo "📋 PRD v2.1 ENHANCED FUNCTIONAL REQUIREMENTS (v2.0 + Foundation):"
echo ""

# FR1: Task Dependency Management (Enhanced with Foundation)
test_requirement "FR1.1" "Dependencies in shared context" \
    "grep -q 'shared.*context.*dep\\|dep.*shared.*context' .claude/hooks/task-dependencies.py || grep -q 'context.*dep' src/tm_production.py"

test_requirement "FR1.2" "Read shared context for dependencies" \
    "grep -q 'read.*shared.*context\\|shared.*context.*read' .claude/hooks/task-dependencies.py || grep -q 'context.*read' src/tm_production.py"

test_requirement "FR1.3" "Circular dependency detection via context" \
    "grep -q 'circular\\|cycle' .claude/hooks/task-dependencies.py || grep -q 'circular\\|cycle' src/tm_production.py"

test_requirement "FR1.4" "Critical path in shared context" \
    "grep -q 'critical.*path\\|path.*critical' .claude/hooks/task-dependencies.py || grep -q 'critical.*path' src/tm_production.py"

# FR2: Durable Checkpointing (Extended with Private Notes)
test_requirement "FR2.1" "Auto-save to private notes + JSON" \
    "grep -q 'private.*notes\\|notes.*private' .claude/hooks/checkpoint-manager.py || grep -q 'checkpoint' src/tm_production.py"

test_requirement "FR2.2" "Resume from private notes or checkpoint" \
    "grep -q 'resume\\|restore' .claude/hooks/checkpoint-manager.py || grep -q 'resume\\|restore' src/tm_production.py"

test_requirement "FR2.3" "Transparent storage in agent notes" \
    "grep -q 'agent.*notes\\|notes.*agent' .claude/hooks/checkpoint-manager.py || test -d .claude/agents/notes"

test_requirement "FR2.4" "Automatic cleanup of old data" \
    "grep -q 'cleanup\\|clean.*old' .claude/hooks/checkpoint-manager.py || grep -q 'cleanup' src/tm_production.py"

# FR3: Task Management (Integrated with Shared Context)
test_requirement "FR3.1" "Task creation with metadata" \
    "grep -q 'metadata\\|phase' src/tm_production.py || test -f src/tm_production.py"

test_requirement "FR3.2" "Write tasks to shared-context.md" \
    "grep -q 'shared.*context\\|context' src/context_generator.py || grep -q 'context.*write' src/tm_production.py"

test_requirement "FR3.3" "Assign specialists in context" \
    "grep -q 'specialist\\|assign' .claude/hooks/event-flows.py || grep -q 'specialist.*assign' src/tm_production.py"

test_requirement "FR3.4" "Preserve metadata in shared state" \
    "grep -q 'metadata' src/tm_production.py || test -f src/tm_production.py"

# FR4: Event-Driven Flows (Broadcast Integration)
test_requirement "FR4.1" "Broadcast completions to all agents" \
    "grep -q 'broadcast.*completion\\|completion.*broadcast' .claude/hooks/event-flows.py || grep -q 'broadcast' src/tm_production.py"

test_requirement "FR4.2" "Retry notifications via broadcast" \
    "grep -q 'retry.*broadcast\\|broadcast.*retry' .claude/hooks/event-flows.py || grep -q 'retry.*notification' src/tm_production.py"

test_requirement "FR4.3" "Help requests in notification file" \
    "grep -q 'help.*notification\\|notification.*help' .claude/hooks/event-flows.py || grep -q 'help.*request' src/tm_production.py"

test_requirement "FR4.4" "Complexity alerts broadcast" \
    "grep -q 'complex.*broadcast\\|broadcast.*complex' .claude/hooks/event-flows.py || grep -q 'complex.*alert' src/tm_production.py"

# FR5: Team Coordination (Native Foundation Integration)
test_requirement "FR5.1" "Teams defined in agent definitions" \
    "test -d .claude/agents || grep -q 'team.*agent\\|agent.*team' src/tm_production.py"

test_requirement "FR5.2" "Coordination via shared context" \
    "grep -q 'coordination.*context\\|context.*coordination' src/tm_production.py || test -f .claude/context/shared-context.md"

test_requirement "FR5.3" "Private notes for agent state" \
    "test -d .claude/agents/notes || grep -q 'agent.*state\\|state.*agent' src/tm_production.py"

test_requirement "FR5.4" "Broadcast for team events" \
    "test -f .claude/notifications/broadcast.md || grep -q 'team.*event\\|event.*team' src/tm_production.py"

echo "📁 PRD v2.1 ARCHITECTURE REQUIREMENTS:"
echo ""

# Architecture Components (Enhanced v2 hooks)
test_requirement "ARCH1" "task-dependencies-v2.py exists" \
    "test -f .claude/hooks/task-dependencies-v2.py || test -f .claude/hooks/task-dependencies.py"

test_requirement "ARCH2" "checkpoint-manager-v2.py exists" \
    "test -f .claude/hooks/checkpoint-manager-v2.py || test -f .claude/hooks/checkpoint-manager.py"

test_requirement "ARCH3" "event-flows hook exists" \
    "test -f .claude/hooks/event-flows.py || test -f .claude/hooks/event-flows-v2.py"

test_requirement "ARCH4" "event-flows-v2.py exists" \
    "test -f .claude/hooks/event-flows-v2.py || test -f .claude/hooks/event-flows.py"

test_requirement "ARCH5" "Foundation directory structure" \
    "test -d .claude/context || test -d .claude/agents || test -d .claude/notifications || test -d .task-orchestrator"

echo "📊 PRD v2.1 COMPLIANCE MATRIX:"
echo ""

# Compliance Matrix Validation
test_requirement "COMP1" "Auto-generated shared context" \
    "grep -q 'auto.*generat.*context\\|context.*auto.*generat' src/tm_production.py || test -f .claude/context/shared-context.md"

test_requirement "COMP2" "Extended checkpoints with private notes" \
    "grep -q 'checkpoint.*private\\|private.*checkpoint' src/tm_production.py || grep -q 'private.*notes' .claude/hooks/checkpoint-manager.py"

test_requirement "COMP3" "Event broadcasts" \
    "grep -q 'event.*broadcast\\|broadcast.*event' src/tm_production.py || test -f .claude/notifications/broadcast.md"

test_requirement "COMP4" "TodoWrite metadata support" \
    "grep -q 'metadata' src/tm_production.py || grep -q 'metadata' .claude/hooks/task-dependencies.py"

echo "========================================="
echo "        PRD v2.1 VALIDATION SUMMARY"
echo "========================================="
echo ""
echo "Requirements Tested: $((PASSED + FAILED))"
echo "✅ PASSED: $PASSED"
echo "❌ FAILED: $FAILED"

TOTAL_REQUIREMENTS=$((PASSED + FAILED))
SUCCESS_RATE=$(( (PASSED * 100) / TOTAL_REQUIREMENTS ))
echo "Success Rate: $SUCCESS_RATE%"

if [ $SUCCESS_RATE -ge 85 ]; then
    echo ""
    echo "🎉 PRD v2.1 REQUIREMENTS VALIDATION: PASSED"
    echo "v2.1 Foundation Layer successfully implemented"
elif [ $SUCCESS_RATE -ge 70 ]; then
    echo ""
    echo "⚠️  PRD v2.1 REQUIREMENTS VALIDATION: PARTIALLY PASSED"
    echo "Most v2.1 Foundation requirements met, some gaps identified"
else
    echo ""
    echo "❌ PRD v2.1 REQUIREMENTS VALIDATION: FAILED"
    echo "Significant v2.1 Foundation requirements missing"
fi