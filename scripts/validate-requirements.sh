#!/bin/bash
# Requirements Traceability Validation Script
# Detects broken traceability between requirements and implementation

set -e

echo "========================================"
echo "  REQUIREMENTS TRACEABILITY VALIDATOR  "  
echo "========================================"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
TOTAL_REQUIREMENTS=0
IMPLEMENTED_REQUIREMENTS=0
ORPHANED_FILES=0
TOTAL_CODE_FILES=0

# Find requirement documents
echo "📋 Scanning for requirement documents..."
REQUIREMENT_DOCS=$(find . -name "*.md" -path "*/docs/*" -exec grep -l "FR-\|COLLAB-\|API-\|SEC-\|PERF-" {} \; 2>/dev/null || true)

if [ -z "$REQUIREMENT_DOCS" ]; then
    echo "⚠️  No requirement documents found"
    echo "   Expected locations: docs/requirements/, docs/specifications/"
    echo ""
else
    echo "✅ Found requirement documents:"
    for doc in $REQUIREMENT_DOCS; do
        echo "   - $doc"
    done
    echo ""
fi

# Extract all requirement IDs from documents (updated for v2.3)
echo "🔍 Extracting requirement IDs..."
ALL_REQ_IDS=""
if [ -n "$REQUIREMENT_DOCS" ]; then
    # Include v2.3 requirements: FR-027 to FR-039, SR-001 to SR-003, EX-001 to EX-006
    ALL_REQ_IDS=$(grep -hoE "(FR-[0-9A-Z-]+|SR-[0-9]+|EX-[0-9]+|COLLAB-[0-9]+|API-[0-9]+|SEC-[0-9]+|PERF-[0-9]+|NFR-[0-9]+|UX-[0-9]+|TECH-[0-9]+)" $REQUIREMENT_DOCS 2>/dev/null | sort -u)
    TOTAL_REQUIREMENTS=$(echo "$ALL_REQ_IDS" | wc -l)
    echo "📊 Total requirements found: $TOTAL_REQUIREMENTS (including v2.3 Core Loop features)"
else
    echo "⚠️  No requirement IDs found - using implemented annotations as reference"
fi

# Find source code files
echo ""
echo "📁 Scanning source code files..."
CODE_FILES=$(find src/ .claude/hooks/ -name "*.py" 2>/dev/null | head -20)  # Include hooks
CODE_FILES="$CODE_FILES
README.md"  # Include README for FR-026

if [ -z "$CODE_FILES" ]; then
    echo "⚠️  No source files found"
    exit 1
fi

TOTAL_CODE_FILES=$(echo "$CODE_FILES" | wc -l)
echo "📊 Total code files to analyze: $TOTAL_CODE_FILES"

# Check forward traceability (requirements → implementation)
echo ""
echo "🔄 Checking forward traceability (requirements → implementation)..."
echo ""

if [ -n "$ALL_REQ_IDS" ]; then
    for req_id in $ALL_REQ_IDS; do
        # Search for requirement implementation in code (include hooks and README)
        if grep -r "@implements.*$req_id" src/ .claude/hooks/ README.md >/dev/null 2>&1; then
            echo -e "✅ $req_id: ${GREEN}IMPLEMENTED${NC}"
            IMPLEMENTED_REQUIREMENTS=$((IMPLEMENTED_REQUIREMENTS + 1))
        else
            # Check for exclusion requirements (EX-*) - these should NOT have implementations
            if echo "$req_id" | grep -q "^EX-"; then
                echo -e "✅ $req_id: ${GREEN}EXCLUDED (as designed)${NC}"
                IMPLEMENTED_REQUIREMENTS=$((IMPLEMENTED_REQUIREMENTS + 1))
            else
                echo -e "❌ $req_id: ${RED}NOT IMPLEMENTED${NC}"
            fi
        fi
    done
else
    echo "⚠️  Skipping forward traceability - no requirements documents found"
fi

# Check backward traceability (implementation → requirements)
echo ""
echo "🔄 Checking backward traceability (implementation → requirements)..."
echo ""

for file in $CODE_FILES; do
    # Check if file has any requirement annotations
    if grep -q "@implements" "$file" 2>/dev/null; then
        echo -e "✅ $(basename "$file"): ${GREEN}HAS REQUIREMENTS${NC}"
        # List the requirements
        grep "@implements" "$file" | sed 's/.*@implements \([^:]*\):.*/  → \1/' 2>/dev/null || true
    else
        echo -e "⚠️  $(basename "$file"): ${YELLOW}NO REQUIREMENTS${NC}"
        ORPHANED_FILES=$((ORPHANED_FILES + 1))
    fi
done

# Calculate metrics
echo ""
echo "📊 TRACEABILITY METRICS"
echo "========================================"

if [ $TOTAL_REQUIREMENTS -gt 0 ]; then
    FORWARD_PERCENTAGE=$(( (IMPLEMENTED_REQUIREMENTS * 100) / TOTAL_REQUIREMENTS ))
    echo "Forward Traceability: $IMPLEMENTED_REQUIREMENTS/$TOTAL_REQUIREMENTS ($FORWARD_PERCENTAGE%)"
else
    echo "Forward Traceability: No requirements to trace"
    FORWARD_PERCENTAGE=100  # If no requirements, consider it complete
fi

TRACED_FILES=$((TOTAL_CODE_FILES - ORPHANED_FILES))
BACKWARD_PERCENTAGE=$(( (TRACED_FILES * 100) / TOTAL_CODE_FILES ))
echo "Backward Traceability: $TRACED_FILES/$TOTAL_CODE_FILES ($BACKWARD_PERCENTAGE%)"

OVERALL_SCORE=$(( (FORWARD_PERCENTAGE + BACKWARD_PERCENTAGE) / 2 ))
echo ""
echo -n "Overall Traceability Score: "
if [ $OVERALL_SCORE -ge 85 ]; then
    echo -e "${GREEN}$OVERALL_SCORE% (EXCELLENT)${NC}"
elif [ $OVERALL_SCORE -ge 70 ]; then
    echo -e "${YELLOW}$OVERALL_SCORE% (GOOD)${NC}"
else
    echo -e "${RED}$OVERALL_SCORE% (POOR)${NC}"
fi

# Recommendations
echo ""
echo "💡 RECOMMENDATIONS"
echo "========================================"

if [ $ORPHANED_FILES -gt 0 ]; then
    echo "1. Add @implements annotations to $ORPHANED_FILES orphaned files"
fi

if [ -n "$ALL_REQ_IDS" ] && [ $IMPLEMENTED_REQUIREMENTS -lt $TOTAL_REQUIREMENTS ]; then
    MISSING=$((TOTAL_REQUIREMENTS - IMPLEMENTED_REQUIREMENTS))
    echo "2. Implement $MISSING missing requirements in code"
fi

if [ $OVERALL_SCORE -lt 70 ]; then
    echo "3. URGENT: Traceability below acceptable threshold"
    echo "   - Focus on adding requirement annotations to core features"
    echo "   - Review PRD and identify implementation gaps"
fi

echo "4. Use this annotation format in your code:"
echo '   """'
echo '   Method description'
echo '   '
echo '   @implements FR-001: Feature description'
echo '   @implements COLLAB-002: Collaboration feature'
echo '   """'

# Success/failure
echo ""
if [ $OVERALL_SCORE -ge 70 ]; then
    echo -e "${GREEN}🎉 Requirements traceability validation PASSED${NC}"
    exit 0
else
    echo -e "${RED}⚠️  Requirements traceability validation FAILED${NC}"
    echo "Please address the gaps above before release"
    exit 1
fi