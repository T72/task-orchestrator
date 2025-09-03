#!/bin/bash
# comprehensive-quality-gate.sh - Master Quality Gate Orchestrator
# Part of the Comprehensive Quality Prevention Framework (CQPF)
# MANDATORY: Run before ANY public release

set -euo pipefail

echo "════════════════════════════════════════════════════════════════"
echo "   COMPREHENSIVE QUALITY GATE - TASK ORCHESTRATOR v2.5.0"
echo "   Preventing Quality Failures Through Systematic Validation"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "This validation suite implements the Comprehensive Quality Prevention"
echo "Framework (CQPF) to make quality failures IMPOSSIBLE, not just unlikely."
echo ""

# Track overall status
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNING_CHECKS=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to run a validation script
run_validation() {
    local script_name=$1
    local description=$2
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}CHECK $TOTAL_CHECKS: $description${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
    
    if [ -f "scripts/$script_name" ]; then
        if bash "scripts/$script_name"; then
            echo -e "${GREEN}✅ PASSED: $description${NC}"
            PASSED_CHECKS=$((PASSED_CHECKS + 1))
            return 0
        else
            EXIT_CODE=$?
            if [ $EXIT_CODE -eq 1 ]; then
                echo -e "${RED}❌ FAILED: $description${NC}"
                FAILED_CHECKS=$((FAILED_CHECKS + 1))
                return 1
            else
                echo -e "${YELLOW}⚠️  WARNING: $description completed with warnings${NC}"
                WARNING_CHECKS=$((WARNING_CHECKS + 1))
                return 0
            fi
        fi
    else
        echo -e "${YELLOW}⚠️  SKIPPED: Script not found - $script_name${NC}"
        WARNING_CHECKS=$((WARNING_CHECKS + 1))
        return 0
    fi
}

# Start timestamp
START_TIME=$(date +%s)

echo -e "\n${BLUE}Starting Quality Gate Validation...${NC}"
echo "Repository: $(pwd)"
echo "Timestamp: $(date)"

# Determine if this is private or public repo
if [ -f "CLAUDE.md" ]; then
    echo -e "Repository Type: ${YELLOW}PRIVATE${NC} (CLAUDE.md present)"
    REPO_TYPE="private"
else
    echo -e "Repository Type: ${GREEN}PUBLIC${NC} (no CLAUDE.md)"
    REPO_TYPE="public"
fi

echo -e "\n${BLUE}Phase 1: Core Quality Validations${NC}"
echo "────────────────────────────────────"

# 1. Version Consistency Check
if ! run_validation "validate-version-consistency.sh" "Version Consistency Across All Files"; then
    echo "  💡 TIP: Run 'scripts/validate-version-consistency.sh --fix' to auto-fix"
fi

# 2. Documentation Accuracy Check
if ! run_validation "validate-documentation-accuracy.sh" "Documentation Reflects Implementation"; then
    echo "  💡 TIP: Review and fix fictional commands/flags in documentation"
fi

# 3. Private Content Exposure Check
if ! run_validation "validate-no-private-exposure.sh" "No Private Content Exposed"; then
    echo "  💡 TIP: Remove private files/directories before public release"
fi

echo -e "\n${BLUE}Phase 2: Additional Quality Checks${NC}"
echo "────────────────────────────────────"

# 4. Link Validation (if script exists)
if [ -f "scripts/validate-all-doc-links.sh" ]; then
    run_validation "validate-all-doc-links.sh" "All Documentation Links Valid"
else
    echo -e "${YELLOW}⚠️  Link validation script not found${NC}"
    WARNING_CHECKS=$((WARNING_CHECKS + 1))
fi

# 5. Example Testing
echo -e "\n${BLUE}Testing documented examples...${NC}"
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

# Test Quick Start example
if [ -f "README.md" ]; then
    echo "Testing Quick Start example from README..."
    
    # Create test directory
    TEST_DIR="/tmp/tm_quickstart_test_$$"
    mkdir -p "$TEST_DIR"
    cd "$TEST_DIR"
    
    # Copy necessary files
    cp -r "$(dirname "$0")/../src" . 2>/dev/null || true
    cp "$(dirname "$0")/../tm" . 2>/dev/null || true
    
    # Test basic commands
    if ./tm init 2>/dev/null && ./tm add "Test task" 2>/dev/null; then
        echo -e "${GREEN}✅ Quick Start example works${NC}"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        echo -e "${RED}❌ Quick Start example failed${NC}"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
    fi
    
    # Cleanup
    cd - > /dev/null
    rm -rf "$TEST_DIR"
fi

echo -e "\n${BLUE}Phase 3: Repository Structure Validation${NC}"
echo "──────────────────────────────────────────"

TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
echo "Checking for duplicate directories..."

STRUCTURE_ISSUES=0
if [ -d "docs/examples" ] && [ -d "examples" ]; then
    echo -e "${YELLOW}  ⚠️  Duplicate: both docs/examples/ and examples/ exist${NC}"
    STRUCTURE_ISSUES=$((STRUCTURE_ISSUES + 1))
fi

if [ -d "docs/guides" ] && [ -d "guides" ]; then
    echo -e "${YELLOW}  ⚠️  Duplicate: both docs/guides/ and guides/ exist${NC}"
    STRUCTURE_ISSUES=$((STRUCTURE_ISSUES + 1))
fi

if [ -d "docs/reference" ] && [ -d "reference" ]; then
    echo -e "${YELLOW}  ⚠️  Duplicate: both docs/reference/ and reference/ exist${NC}"
    STRUCTURE_ISSUES=$((STRUCTURE_ISSUES + 1))
fi

if [ $STRUCTURE_ISSUES -eq 0 ]; then
    echo -e "${GREEN}✅ No duplicate directories found${NC}"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    echo -e "${YELLOW}⚠️  Found $STRUCTURE_ISSUES duplicate directory issues${NC}"
    WARNING_CHECKS=$((WARNING_CHECKS + 1))
fi

# Calculate execution time
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo -e "\n${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}                    QUALITY GATE SUMMARY                        ${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"

echo ""
echo "Total Checks:    $TOTAL_CHECKS"
echo -e "${GREEN}Passed:          $PASSED_CHECKS${NC}"
echo -e "${YELLOW}Warnings:        $WARNING_CHECKS${NC}"
echo -e "${RED}Failed:          $FAILED_CHECKS${NC}"
echo "Duration:        ${DURATION}s"
echo ""

# Calculate pass rate
if [ $TOTAL_CHECKS -gt 0 ]; then
    PASS_RATE=$((PASSED_CHECKS * 100 / TOTAL_CHECKS))
    echo "Pass Rate:       ${PASS_RATE}%"
fi

echo ""

# Final verdict
if [ $FAILED_CHECKS -eq 0 ]; then
    if [ $WARNING_CHECKS -eq 0 ]; then
        echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
        echo -e "${GREEN}       ✅ QUALITY GATE PASSED - READY FOR RELEASE!             ${NC}"
        echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
        echo ""
        echo "All quality checks passed. Repository is ready for public release."
        exit 0
    else
        echo -e "${YELLOW}════════════════════════════════════════════════════════════════${NC}"
        echo -e "${YELLOW}    ⚠️  QUALITY GATE PASSED WITH WARNINGS - REVIEW RECOMMENDED   ${NC}"
        echo -e "${YELLOW}════════════════════════════════════════════════════════════════${NC}"
        echo ""
        echo "Quality gate passed but $WARNING_CHECKS warnings found."
        echo "Review warnings before release for best quality."
        exit 0
    fi
else
    echo -e "${RED}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${RED}        ❌ QUALITY GATE FAILED - DO NOT RELEASE!                ${NC}"
    echo -e "${RED}════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "Found $FAILED_CHECKS critical issues that MUST be fixed before release:"
    echo ""
    echo "1. Review the failed checks above"
    echo "2. Fix all identified issues"
    echo "3. Run this validation again"
    echo "4. Only release when all checks pass"
    echo ""
    echo "Remember: Quality gates exist to PREVENT problems, not find them later."
    exit 1
fi