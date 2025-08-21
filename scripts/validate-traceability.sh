#!/bin/bash
# Requirements Traceability Validation Script
# @implements FR-022: Automated traceability validation
# @implements FR-023: Pre-commit traceability checks
# @implements FR-024: Continuous traceability monitoring

set -e

echo "========================================="
echo "    REQUIREMENTS TRACEABILITY VALIDATION"
echo "========================================="
echo ""

# Configuration
MIN_FORWARD_TRACEABILITY=70
MIN_BACKWARD_TRACEABILITY=85
MIN_TEST_COVERAGE=60

# Counters
TOTAL_REQUIREMENTS=0
IMPLEMENTED_REQUIREMENTS=0
TOTAL_SOURCE_FILES=0
ANNOTATED_FILES=0
TESTED_REQUIREMENTS=0

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "🔍 SCANNING PROJECT FOR REQUIREMENTS..."

# Find all requirement documents
REQ_FILES=$(find docs/specifications/requirements -name "*.md" -not -path "*/archive/*" | sort)

echo "Found requirement documents:"
for file in $REQ_FILES; do
    echo "  - $file"
done
echo ""

# Extract requirements from PRD documents
echo "📋 EXTRACTING REQUIREMENTS..."

# Pattern matching for different requirement formats
FR_PATTERN="FR-[0-9][0-9][0-9]"
NFR_PATTERN="NFR-[0-9][0-9][0-9]"
CORE_PATTERN="FR-CORE-[0-9]"

# Count total requirements
for file in $REQ_FILES; do
    FR_COUNT=$(grep -oE "$FR_PATTERN" "$file" | sort | uniq | wc -l)
    NFR_COUNT=$(grep -oE "$NFR_PATTERN" "$file" | sort | uniq | wc -l)
    CORE_COUNT=$(grep -oE "$CORE_PATTERN" "$file" | sort | uniq | wc -l)
    
    FILE_TOTAL=$((FR_COUNT + NFR_COUNT + CORE_COUNT))
    TOTAL_REQUIREMENTS=$((TOTAL_REQUIREMENTS + FILE_TOTAL))
    
    if [ $FILE_TOTAL -gt 0 ]; then
        echo "  $file: $FILE_TOTAL requirements"
    fi
done

echo "Total requirements found: $TOTAL_REQUIREMENTS"
echo ""

# Check implementation status
echo "🔧 CHECKING IMPLEMENTATION STATUS..."

# Find all source files
SOURCE_FILES=$(find src -name "*.py" | sort)
TOTAL_SOURCE_FILES=$(echo "$SOURCE_FILES" | wc -l)

echo "Scanning $TOTAL_SOURCE_FILES source files:"

# Extract all unique requirements mentioned in code
IMPLEMENTED_REQS=$(grep -hoE "@implements [^:]*" src/*.py 2>/dev/null | sed 's/@implements //' | sed 's/:.*$//' | sort | uniq)

# Count implemented requirements
for req in $IMPLEMENTED_REQS; do
    # Check if this is a valid requirement format
    if echo "$req" | grep -qE "(FR-[0-9]{3}|NFR-[0-9]{3}|FR-CORE-[0-9])"; then
        IMPLEMENTED_REQUIREMENTS=$((IMPLEMENTED_REQUIREMENTS + 1))
    fi
done

# Count files with annotations
ANNOTATED_FILES=$(grep -l "@implements" src/*.py 2>/dev/null | wc -l)

echo "  Files with @implements annotations: $ANNOTATED_FILES/$TOTAL_SOURCE_FILES"
echo "  Unique requirements implemented: $IMPLEMENTED_REQUIREMENTS"
echo ""

# Check test coverage
echo "🧪 CHECKING TEST COVERAGE..."

if [ -d "tests" ]; then
    TEST_FILES=$(find tests -name "*.py" -o -name "*.sh" | grep -v __pycache__ | sort)
    
    # Count requirements mentioned in tests
    TESTED_REQS=$(grep -hoE "@implements [^:]*" tests/*.py 2>/dev/null | sed 's/@implements //' | sed 's/:.*$//' | sort | uniq | wc -l)
    TESTED_REQUIREMENTS=$TESTED_REQS
    
    echo "  Test files found: $(echo "$TEST_FILES" | wc -l)"
    echo "  Requirements covered by tests: $TESTED_REQUIREMENTS"
else
    echo "  No tests directory found"
fi
echo ""

# Calculate metrics
echo "📊 CALCULATING TRACEABILITY METRICS..."

if [ $TOTAL_REQUIREMENTS -gt 0 ]; then
    FORWARD_TRACEABILITY=$(( (IMPLEMENTED_REQUIREMENTS * 100) / TOTAL_REQUIREMENTS ))
else
    FORWARD_TRACEABILITY=0
fi

if [ $TOTAL_SOURCE_FILES -gt 0 ]; then
    BACKWARD_TRACEABILITY=$(( (ANNOTATED_FILES * 100) / TOTAL_SOURCE_FILES ))
else
    BACKWARD_TRACEABILITY=0
fi

if [ $IMPLEMENTED_REQUIREMENTS -gt 0 ]; then
    TEST_COVERAGE=$(( (TESTED_REQUIREMENTS * 100) / IMPLEMENTED_REQUIREMENTS ))
else
    TEST_COVERAGE=0
fi

OVERALL_SCORE=$(( (FORWARD_TRACEABILITY + BACKWARD_TRACEABILITY) / 2 ))

echo "  Forward Traceability:  $FORWARD_TRACEABILITY% ($IMPLEMENTED_REQUIREMENTS/$TOTAL_REQUIREMENTS requirements)"
echo "  Backward Traceability: $BACKWARD_TRACEABILITY% ($ANNOTATED_FILES/$TOTAL_SOURCE_FILES files)"
echo "  Test Coverage:         $TEST_COVERAGE% ($TESTED_REQUIREMENTS/$IMPLEMENTED_REQUIREMENTS requirements)"
echo "  Overall Score:         $OVERALL_SCORE%"
echo ""

# Generate detailed report
echo "📝 DETAILED ANALYSIS..."

# Find orphaned code (files without @implements)
ORPHANED_FILES=$(find src -name "*.py" -exec grep -L "@implements" {} \; 2>/dev/null | sort)
ORPHANED_COUNT=$(echo "$ORPHANED_FILES" | grep -v '^$' | wc -l)

if [ $ORPHANED_COUNT -gt 0 ] && [ "$ORPHANED_FILES" != "" ]; then
    echo -e "${YELLOW}⚠️  Orphaned Code Files ($ORPHANED_COUNT):${NC}"
    for file in $ORPHANED_FILES; do
        if [ -f "$file" ]; then
            echo "  - $file"
        fi
    done
else
    echo -e "${GREEN}✅ No orphaned code files found${NC}"
fi
echo ""

# Find unimplemented requirements
echo "❌ UNIMPLEMENTED REQUIREMENTS:"
UNIMPLEMENTED=0

for file in $REQ_FILES; do
    # Extract all requirements from this file
    ALL_REQS=$(grep -oE "(FR-[0-9]{3}|NFR-[0-9]{3}|FR-CORE-[0-9])" "$file" | sort | uniq)
    
    for req in $ALL_REQS; do
        # Check if requirement is implemented
        if ! grep -q "@implements.*$req" src/*.py 2>/dev/null; then
            echo "  - $req (from $(basename "$file"))"
            UNIMPLEMENTED=$((UNIMPLEMENTED + 1))
        fi
    done
done

if [ $UNIMPLEMENTED -eq 0 ]; then
    echo -e "${GREEN}  None - all requirements implemented!${NC}"
fi
echo ""

# Status assessment
echo "🎯 TRACEABILITY ASSESSMENT:"

if [ $OVERALL_SCORE -ge 95 ]; then
    echo -e "${GREEN}🎉 EXCELLENT: >95% traceability achieved!${NC}"
elif [ $OVERALL_SCORE -ge 85 ]; then
    echo -e "${GREEN}✅ GOOD: 85%+ traceability - focus on remaining gaps${NC}"
elif [ $OVERALL_SCORE -ge 70 ]; then
    echo -e "${YELLOW}⚠️  FAIR: 70%+ traceability - improvement needed${NC}"
else
    echo -e "${RED}❌ POOR: <70% traceability - critical gaps exist${NC}"
fi
echo ""

# Recommendations
echo "💡 RECOMMENDATIONS:"

if [ $FORWARD_TRACEABILITY -lt $MIN_FORWARD_TRACEABILITY ]; then
    echo "  1. Implement missing requirements (currently $FORWARD_TRACEABILITY%, target $MIN_FORWARD_TRACEABILITY%+)"
fi

if [ $BACKWARD_TRACEABILITY -lt $MIN_BACKWARD_TRACEABILITY ]; then
    echo "  2. Add @implements annotations to $ORPHANED_COUNT source files"
fi

if [ $TEST_COVERAGE -lt $MIN_TEST_COVERAGE ]; then
    echo "  3. Enhance test coverage (currently $TEST_COVERAGE%, target $MIN_TEST_COVERAGE%+)"
fi

if [ $OVERALL_SCORE -ge 95 ]; then
    echo "  - Maintain excellent discipline with regular validation"
    echo "  - Consider adding more advanced requirements"
elif [ $OVERALL_SCORE -ge 85 ]; then
    echo "  - Focus on highest-priority gaps first"
    echo "  - Automate validation in CI/CD pipeline"
else
    echo "  - Address critical gaps immediately"
    echo "  - Review development process for traceability"
fi

echo ""

# Exit codes for CI/CD integration
if [ $OVERALL_SCORE -ge 85 ]; then
    echo -e "${GREEN}✅ Traceability validation PASSED${NC}"
    exit 0
elif [ $OVERALL_SCORE -ge 70 ]; then
    echo -e "${YELLOW}⚠️  Traceability validation WARNING${NC}"
    exit 1
else
    echo -e "${RED}❌ Traceability validation FAILED${NC}"
    exit 2
fi