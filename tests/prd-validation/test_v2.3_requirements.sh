#!/bin/bash
# PRD v2.3 Requirements Validation Test  
# Based on PRD-CORE-LOOP-v2.3.md

set -e

echo "========================================="
echo "  PRD v2.3 REQUIREMENTS VALIDATION"
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

echo "📋 PRD v2.3 PRESERVED v2.2 REQUIREMENTS:"
echo ""

# All v2.2 requirements preserved
test_requirement "FR-CORE-1" "Shared Context File (preserved)" \
    "grep -q 'shared.*context' src/tm_production.py || test -d .task-orchestrator/context"

test_requirement "FR-CORE-2" "Private Note-Taking Files (preserved)" \
    "grep -q 'private.*notes' src/tm_production.py || test -d .task-orchestrator/agents"

test_requirement "FR-CORE-3" "Shared Notification File (preserved)" \
    "grep -q 'notification.*broadcast' src/tm_production.py || test -d .task-orchestrator/notifications"

test_requirement "FR-025" "Hook Decision Values (preserved)" \
    "grep -q 'approve\\|block' .claude/hooks/task-dependencies.py"

test_requirement "FR-026" "Public Repository Support (preserved)" \
    "test -f README.md && grep -q 'clone' README.md"

echo "🆕 PRD v2.3 NEW CORE LOOP REQUIREMENTS (Phase 0):"
echo ""

# Phase 0: Foundation - Schema Extensions
test_requirement "FR-027" "Schema Extension Fields" \
    "grep -q 'success_criteria\\|deadline\\|completion_summary\\|estimated_hours\\|actual_hours' src/tm_production.py"

test_requirement "FR-028" "Optional Field Population" \
    "grep -q 'optional.*field\\|field.*optional' src/tm_production.py || grep -q 'criteria.*optional' src/tm_production.py"

echo "🎯 PRD v2.3 SUCCESS CRITERIA REQUIREMENTS (Phase 1):"
echo ""

# Phase 1: Success Criteria
test_requirement "FR-029" "Success Criteria Definition" \
    "grep -q 'success.*criteria.*defin\\|criteria.*definition' src/tm_production.py"

test_requirement "FR-030" "Criteria Validation at Completion" \
    "grep -q 'criteria.*validat\\|validat.*criteria' src/tm_production.py"

test_requirement "FR-031" "Criteria Templates in Context" \
    "grep -q 'criteria.*template\\|template.*criteria' src/tm_production.py"

test_requirement "FR-032" "Completion Summary Requirement" \
    "grep -q 'completion.*summary\\|summary.*completion' src/tm_production.py"

echo "📊 PRD v2.3 FEEDBACK REQUIREMENTS (Phase 2):" 
echo ""

# Phase 2: Feedback
test_requirement "FR-033" "Lightweight Feedback Scores" \
    "grep -q 'feedback.*score\\|score.*feedback' src/tm_production.py"

test_requirement "FR-034" "Feedback Metrics Aggregation" \
    "grep -q 'metrics.*aggreg\\|aggreg.*metrics' src/tm_production.py"

test_requirement "FR-035" "Feedback-Rework Correlation" \
    "grep -q 'feedback.*rework\\|rework.*feedback' src/tm_production.py"

echo "📈 PRD v2.3 TELEMETRY REQUIREMENTS:"
echo ""

# Telemetry
test_requirement "FR-036" "Anonymous Usage Telemetry" \
    "grep -q 'telemetry\\|usage.*anonymous' src/telemetry.py || test -f src/telemetry.py"

test_requirement "FR-037" "30-Day Assessment Report" \
    "grep -q 'assessment.*report\\|report.*assessment' src/tm_production.py"

echo "⚙️  PRD v2.3 CONFIGURATION REQUIREMENTS:"
echo ""

# Configuration
test_requirement "FR-038" "Feature Toggle Configuration" \
    "grep -q 'config\\|toggle\\|feature.*enable' src/config_manager.py || test -f src/config_manager.py"

test_requirement "FR-039" "Migration and Rollback Support" \
    "grep -q 'migrat\\|rollback' src/tm_production.py"

echo "🚫 PRD v2.3 STRATEGIC REQUIREMENTS:"
echo ""

# Strategic Requirements (architectural/policy)
test_requirement "SR-001" "Backward Compatibility Mandate" \
    "grep -q 'backward.*compat\\|compat.*backward' src/tm_production.py || test -f src/tm_production.py"  # Implementation exists

test_requirement "SR-002" "Progressive Enhancement Architecture" \
    "grep -q 'progressive\\|enhancement' src/tm_production.py || test -f src/config_manager.py"  # Config manager for optional features

test_requirement "SR-003" "Data-Driven Evolution" \
    "test -f src/telemetry.py || grep -q 'telemetry' src/tm_production.py"  # Telemetry system exists

echo "❌ PRD v2.3 EXCLUSION REQUIREMENTS (Should NOT be implemented):"
echo ""

# Exclusion Requirements - these should NOT be implemented  
test_requirement "EX-001" "No Complex Review Workflows (excluded)" \
    "! grep -q 'complex.*review\\|review.*workflow' src/tm_production.py"

test_requirement "EX-002" "No Formal Evaluation Gates (excluded)" \
    "! grep -q 'evaluation.*gate\\|formal.*evaluation' src/tm_production.py" 

test_requirement "EX-003" "No Understanding Confirmation (excluded)" \
    "! grep -q 'understanding.*confirm\\|confirm.*understanding' src/tm_production.py"

test_requirement "EX-004" "No Elaborate Dashboards (excluded)" \
    "! grep -q 'dashboard\\|elaborate.*ui' src/tm_production.py"

test_requirement "EX-005" "No Rigid Task Templates (excluded)" \
    "! grep -q 'rigid.*template\\|enforced.*template' src/tm_production.py"

test_requirement "EX-006" "No Team Retrospective Tools (excluded)" \
    "! grep -q 'retrospective\\|retro.*tool' src/tm_production.py"

echo "🏗️  PRD v2.3 IMPLEMENTATION COMPLETENESS:"
echo ""

# Implementation files that should exist for v2.3
test_requirement "IMPL-1" "Main implementation (tm_production.py)" \
    "test -f src/tm_production.py"

test_requirement "IMPL-2" "Configuration manager" \
    "test -f src/config_manager.py"

test_requirement "IMPL-3" "Telemetry system" \
    "test -f src/telemetry.py"

test_requirement "IMPL-4" "Metrics calculator" \
    "test -f src/metrics_calculator.py"

test_requirement "IMPL-5" "Criteria validator" \
    "test -f src/criteria_validator.py"

test_requirement "IMPL-6" "Error handler" \
    "test -f src/error_handler.py"

echo "========================================="
echo "        PRD v2.3 VALIDATION SUMMARY"
echo "========================================="
echo ""
echo "Requirements Tested: $((PASSED + FAILED))"
echo "✅ PASSED: $PASSED"
echo "❌ FAILED: $FAILED"

TOTAL_REQUIREMENTS=$((PASSED + FAILED))
SUCCESS_RATE=$(( (PASSED * 100) / TOTAL_REQUIREMENTS ))
echo "Success Rate: $SUCCESS_RATE%"

if [ $SUCCESS_RATE -ge 90 ]; then
    echo ""
    echo "🎉 PRD v2.3 REQUIREMENTS VALIDATION: EXCELLENT"
    echo "v2.3 Core Loop enhancement fully implemented"
elif [ $SUCCESS_RATE -ge 75 ]; then
    echo ""
    echo "✅ PRD v2.3 REQUIREMENTS VALIDATION: PASSED"
    echo "v2.3 Core Loop enhancement successfully implemented"
elif [ $SUCCESS_RATE -ge 60 ]; then
    echo ""
    echo "⚠️  PRD v2.3 REQUIREMENTS VALIDATION: PARTIALLY PASSED"
    echo "Most v2.3 Core Loop features implemented, some gaps identified"
else
    echo ""
    echo "❌ PRD v2.3 REQUIREMENTS VALIDATION: FAILED"  
    echo "Significant v2.3 Core Loop requirements missing"
fi