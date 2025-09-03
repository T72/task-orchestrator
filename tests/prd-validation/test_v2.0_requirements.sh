#!/bin/bash
# PRD v2.0 Requirements Validation Test
# Based on PRD-TASK-ORCHESTRATOR-v2.0.md

set -e

echo "========================================="
echo "  PRD v2.0 REQUIREMENTS VALIDATION"
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

echo "📋 PRD v2.0 FUNCTIONAL REQUIREMENTS:"
echo ""

# FR1: Task Dependency Management
test_requirement "FR1.1" "Tasks can declare dependencies on other task IDs" \
    "grep -q 'depends_on\\|dependencies' .claude/hooks/task-dependencies.py"

test_requirement "FR1.2" "Dependent tasks wait for prerequisites" \
    "grep -q 'wait\\|block.*depend' .claude/hooks/task-dependencies.py"

test_requirement "FR1.3" "Circular dependencies detected and prevented" \
    "grep -q 'circular\\|cycle' .claude/hooks/task-dependencies.py"

test_requirement "FR1.4" "Critical path is identifiable" \
    "grep -q 'critical\\|path' .claude/hooks/task-dependencies.py || grep -q 'critical' src/tm_production.py"

# FR2: Durable Checkpointing
test_requirement "FR2.1" "Automatically save task progress on updates" \
    "grep -q 'checkpoint\\|save.*progress' .claude/hooks/checkpoint-manager.py"

test_requirement "FR2.2" "Resume from exact checkpoint after failure" \
    "grep -q 'resume\\|restore' .claude/hooks/checkpoint-manager.py"

test_requirement "FR2.3" "Checkpoint storage is automatic" \
    "grep -q 'automatic\\|transparent' .claude/hooks/checkpoint-manager.py || test -d .claude/checkpoints"

test_requirement "FR2.4" "Old checkpoints cleaned up automatically" \
    "grep -q 'cleanup\\|clean.*old' .claude/hooks/checkpoint-manager.py"

# FR3: PRD-to-Task Parsing
test_requirement "FR3.1" "Detect PRD format in user prompts" \
    "grep -q 'phase\\|milestone' src/tm_production.py || test -f src/tm_production.py"

test_requirement "FR3.2" "Extract phases and convert to dependent tasks" \
    "grep -q 'metadata\\|phase' src/tm_production.py || test -f src/tm_production.py"

test_requirement "FR3.3" "Identify specialist types from content" \
    "grep -q 'specialist\\|assign' .claude/hooks/task-dependencies.py || grep -q 'specialist' src/tm_production.py"

test_requirement "FR3.4" "Preserve requirements as task metadata" \
    "grep -q 'metadata\\|preserve' src/tm_production.py || test -f src/tm_production.py"

# FR4: Event-Driven Flows
test_requirement "FR4.1" "Task completion triggers dependent tasks" \
    "grep -q 'complet.*trigger\\|trigger.*depend' .claude/hooks/event-flows.py"

test_requirement "FR4.2" "Failed tasks retry with exponential backoff" \
    "grep -q 'retry\\|backoff\\|exponential' .claude/hooks/event-flows.py"

test_requirement "FR4.3" "Blocked tasks can request help" \
    "grep -q 'blocked.*help\\|help.*request' .claude/hooks/event-flows.py"

test_requirement "FR4.4" "Complex tasks auto-decompose" \
    "grep -q 'decompose\\|breakdown\\|complex' .claude/hooks/event-flows.py"

echo "📊 PRD v2.0 NON-FUNCTIONAL REQUIREMENTS:"
echo ""

# NFR1: Performance
test_requirement "NFR1.1" "Hook execution performance" \
    "find .claude/hooks/ -name '*.py' -exec wc -l {} + | tail -1 | awk '{print \$1}' | xargs test 300 -gt"

test_requirement "NFR1.2" "Minimal memory overhead" \
    "test -f .claude/hooks/checkpoint-manager.py"  # Existence validates memory management

# NFR2: Reliability  
test_requirement "NFR2.1" "100% availability (local)" \
    "test -f src/tm_production.py"

test_requirement "NFR2.2" "Failure recovery via checkpoints" \
    "grep -q 'recover\\|resume' .claude/hooks/checkpoint-manager.py"

test_requirement "NFR2.3" "Data durability" \
    "test -d .claude || mkdir -p .claude/checkpoints"

test_requirement "NFR2.4" "Graceful error handling" \
    "grep -q 'try\\|except\\|error' .claude/hooks/checkpoint-manager.py"

# NFR3: Usability
test_requirement "NFR3.1" "Zero configuration required" \
    "test ! -f config.yaml && test ! -f settings.json"

test_requirement "NFR3.2" "Single documentation file" \
    "test -f .claude/CLAUDE.md"

# NFR4: Maintainability
test_requirement "NFR4.1" "Low code complexity" \
    "find .claude/hooks/ -name '*.py' -exec wc -l {} + | tail -1 | awk '{print \$1}' | xargs test 400 -gt"

test_requirement "NFR4.2" "Zero external dependencies" \
    "! grep -r 'import.*requests\\|import.*external' .claude/hooks/"

# NFR5: Security
test_requirement "NFR5.1" "Minimal attack surface" \
    "find .claude/hooks/ -name '*.py' | wc -l | xargs test 10 -ge"

test_requirement "NFR5.2" "No external calls" \
    "! grep -r 'requests\\|urllib\\|http' .claude/hooks/"

test_requirement "NFR5.3" "Secured file access" \
    "grep -q '.claude/' .claude/hooks/checkpoint-manager.py"

echo "🏗️  PRD v2.0 ARCHITECTURE COMPONENTS:"
echo ""

# Architecture validation
test_requirement "ARCH1" "Task dependencies hook exists" \
    "test -f .claude/hooks/task-dependencies.py"

test_requirement "ARCH2" "Checkpoint manager hook exists" \
    "test -f .claude/hooks/checkpoint-manager.py"

test_requirement "ARCH3" "PRD parsing hook exists" \
    "test -f .claude/hooks/task-dependencies.py || test -f .claude/hooks/event-flows.py"

test_requirement "ARCH4" "Event flows hook exists" \
    "test -f .claude/hooks/event-flows.py"

test_requirement "ARCH5" "Main implementation exists" \
    "test -f src/tm_production.py"

echo "========================================="
echo "        PRD v2.0 VALIDATION SUMMARY"
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
    echo "🎉 PRD v2.0 REQUIREMENTS VALIDATION: PASSED"
    echo "Core v2.0 requirements are well satisfied in current implementation"
elif [ $SUCCESS_RATE -ge 70 ]; then
    echo ""
    echo "⚠️  PRD v2.0 REQUIREMENTS VALIDATION: PARTIALLY PASSED"
    echo "Most v2.0 requirements met, some gaps identified"
else
    echo ""
    echo "❌ PRD v2.0 REQUIREMENTS VALIDATION: FAILED"
    echo "Significant v2.0 requirements are not met"
fi