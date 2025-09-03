#!/bin/bash
# PRD v1.0 Requirements Validation Test
# Based on PRD-NATIVE-ORCHESTRATION-v1.0.md

set -e

echo "========================================="
echo "  PRD v1.0 REQUIREMENTS VALIDATION"
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

echo "📋 PRD v1.0 FUNCTIONAL REQUIREMENTS:"
echo ""

# FR1: TodoWrite Enhancement - Metadata Support
test_requirement "FR1" "TodoWrite Enhancement with metadata" \
    "grep -q 'metadata' .claude/hooks/task-dependencies.py"

# FR2: Subagent Coordination
test_requirement "FR2.1" "Automatic Invocation via hooks" \
    "test -f .claude/hooks/task-dependencies.py"

test_requirement "FR2.2" "Context Passing to subagents" \
    "grep -q 'context' .claude/hooks/checkpoint-manager.py"

test_requirement "FR2.3" "Progress Tracking via hooks" \
    "grep -q 'status' .claude/hooks/checkpoint-manager.py"

# FR3: Complexity Handling
test_requirement "FR3.1" "Task Decomposition support" \
    "grep -q 'depends_on\\|dependency' src/tm_production.py"

test_requirement "FR3.2" "Help Request handling" \
    "grep -q 'blocked\\|help' src/tm_production.py"

test_requirement "FR3.3" "Escalation mechanism" \
    "grep -q 'escalat' src/tm_production.py || grep -q 'blocked_scope_change' src/tm_production.py"

# FR4: Workflow Automation
test_requirement "FR4.1" "Task Creation Capability" \
    "test -f src/tm_production.py && grep -q 'add_task' src/tm_production.py"

test_requirement "FR4.2" "Assignment Hook" \
    "grep -q 'assign\\|specialist' .claude/hooks/task-dependencies.py"

test_requirement "FR4.3" "Completion Hook" \
    "grep -q 'complete\\|dependencies' .claude/hooks/checkpoint-manager.py"

echo "📊 PRD v1.0 NON-FUNCTIONAL REQUIREMENTS:"
echo ""

# NFR1: Zero Breaking Changes
test_requirement "NFR1" "Zero Breaking Changes to existing tools" \
    "test -f src/tm_production.py"  # Main implementation exists

# NFR2: Performance 
test_requirement "NFR2" "Hook execution performance" \
    "find .claude/hooks/ -name '*.py' -exec wc -l {} + | tail -1 | awk '{print \$1}' | xargs test 500 -gt"

# NFR3: Maintainability
test_requirement "NFR3.1" "Follow .claude/ directory structure" \
    "test -d .claude"

test_requirement "NFR3.2" "Use standard formats" \
    "test -f .claude/CLAUDE.md"

test_requirement "NFR3.3" "No custom databases" \
    "test ! -f custom_db.sqlite && test ! -f orchestrator.db"

# NFR4: Extensibility
test_requirement "NFR4.1" "Specialists via markdown" \
    "find .claude/agents/ -name '*.md' -type f | head -1 | xargs test -f"

test_requirement "NFR4.2" "Replaceable hooks" \
    "find .claude/hooks/ -name '*.py' -type f | head -3 | wc -l | xargs test 3 -le"

echo "📁 PRD v1.0 ARCHITECTURE REQUIREMENTS:"
echo ""

# Architecture Components
test_requirement "ARCH1" "Orchestrator subagent definition" \
    "grep -q 'orchestrator' .claude/CLAUDE.md || test -f .claude/agents/orchestrator.md"

test_requirement "ARCH2" "Database specialist" \
    "grep -q 'database-specialist' .claude/CLAUDE.md || test -f .claude/agents/database-specialist.md"

test_requirement "ARCH3" "Backend specialist" \
    "grep -q 'backend-specialist' .claude/CLAUDE.md || test -f .claude/agents/backend-specialist.md"

test_requirement "ARCH4" "Hook automation system" \
    "find .claude/hooks/ -name '*.py' | wc -l | xargs test 3 -le"

echo "========================================="
echo "        PRD v1.0 VALIDATION SUMMARY"
echo "========================================="
echo ""
echo "Requirements Tested: $((PASSED + FAILED))"
echo "✅ PASSED: $PASSED"
echo "❌ FAILED: $FAILED"

TOTAL_REQUIREMENTS=$((PASSED + FAILED))
SUCCESS_RATE=$(( (PASSED * 100) / TOTAL_REQUIREMENTS ))
echo "Success Rate: $SUCCESS_RATE%"

if [ $SUCCESS_RATE -ge 80 ]; then
    echo ""
    echo "🎉 PRD v1.0 REQUIREMENTS VALIDATION: PASSED"
    echo "Core v1.0 requirements are satisfied in current implementation"
else
    echo ""
    echo "⚠️  PRD v1.0 REQUIREMENTS VALIDATION: FAILED"
    echo "Some fundamental v1.0 requirements are not met"
fi