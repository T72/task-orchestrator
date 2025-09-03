#!/bin/bash
# Run all PRD validation tests in sequence
# Created: 2025-08-21
# Purpose: Comprehensive validation across all PRD versions

set -e

echo "========================================="
echo "    COMPLETE PRD VALIDATION SUITE"
echo "========================================="
echo ""

# Track overall results
TOTAL_PASSED=0
TOTAL_FAILED=0
TOTAL_VERSIONS=0

# Function to extract results from test output
extract_results() {
    local output="$1"
    local passed=$(echo "$output" | grep "✅ PASSED:" | tail -1 | grep -o '[0-9]\+')
    local failed=$(echo "$output" | grep "❌ FAILED:" | tail -1 | grep -o '[0-9]\+')
    local rate=$(echo "$output" | grep "Success Rate:" | tail -1 | grep -o '[0-9]\+%')
    
    echo "    Results: $passed passed, $failed failed ($rate)"
    
    TOTAL_PASSED=$((TOTAL_PASSED + passed))
    TOTAL_FAILED=$((TOTAL_FAILED + failed))
    TOTAL_VERSIONS=$((TOTAL_VERSIONS + 1))
}

echo "Running validation tests for all PRD versions..."
echo ""

# Test v1.0
echo "🔍 Testing PRD v1.0 (Original Vision)..."
v1_output=$(./test_v1.0_requirements.sh 2>&1)
extract_results "$v1_output"
echo ""

# Test v2.0
echo "🔍 Testing PRD v2.0 (Hook-based Implementation)..."
v2_0_output=$(./test_v2.0_requirements.sh 2>&1)
extract_results "$v2_0_output"
echo ""

# Test v2.1
echo "🔍 Testing PRD v2.1 (Foundation Layer)..."
v2_1_output=$(./test_v2.1_requirements.sh 2>&1)
extract_results "$v2_1_output"
echo ""

# Test v2.2
echo "🔍 Testing PRD v2.2 (Rename & Public Release)..."
v2_2_output=$(./test_v2.2_requirements.sh 2>&1)
extract_results "$v2_2_output"
echo ""

# Test v2.3
echo "🔍 Testing PRD v2.3 (Core Loop Enhancement)..."
v2_3_output=$(./test_v2.3_requirements.sh 2>&1)
extract_results "$v2_3_output"
echo ""

# Summary
echo "========================================="
echo "        COMPREHENSIVE SUMMARY"
echo "========================================="
echo ""
echo "Total Versions Tested: $TOTAL_VERSIONS"
echo "Total Requirements: $((TOTAL_PASSED + TOTAL_FAILED))"
echo "✅ Total Passed: $TOTAL_PASSED"
echo "❌ Total Failed: $TOTAL_FAILED"

OVERALL_RATE=$(( (TOTAL_PASSED * 100) / (TOTAL_PASSED + TOTAL_FAILED) ))
echo "📊 Overall Success Rate: $OVERALL_RATE%"

echo ""
echo "Individual Version Performance:"
echo "- v1.0: Original orchestration vision (Foundation)"
echo "- v2.0: Hook-based implementation (Architecture)"  
echo "- v2.1: Foundation Layer addition (Integration)"
echo "- v2.2: Rename & public release (Polish)"
echo "- v2.3: Core Loop enhancement (Quality)"

if [ $OVERALL_RATE -ge 75 ]; then
    echo ""
    echo "🎉 OVERALL ASSESSMENT: STRONG"
    echo "Task Orchestrator shows solid requirements satisfaction across evolution"
elif [ $OVERALL_RATE -ge 65 ]; then
    echo ""
    echo "⚠️  OVERALL ASSESSMENT: MODERATE"  
    echo "Some capability gaps identified across PRD evolution"
else
    echo ""
    echo "❌ OVERALL ASSESSMENT: NEEDS ATTENTION"
    echo "Significant requirements gaps require investigation"
fi

echo ""
echo "For detailed analysis, see: comprehensive_requirements_evolution_analysis.md"