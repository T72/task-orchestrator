#!/bin/bash

# README Excellence Validator
# Ensures README follows Golden Circle + LEAN principles
# Usage: ./validate-readme.sh [README_FILE]

set -e

README_FILE="${1:-README.md}"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
README_PATH="$REPO_ROOT/$README_FILE"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Scoring system
TOTAL_SCORE=0
MAX_SCORE=100
CRITICAL_FAILURES=0

echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║          README Excellence Validator v1.0                ║${NC}"
echo -e "${BLUE}║     Golden Circle + LEAN Principles Compliance          ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo

if [ ! -f "$README_PATH" ]; then
    echo -e "${RED}❌ FATAL: README file not found at $README_PATH${NC}"
    exit 1
fi

echo -e "${BLUE}📄 Analyzing: $README_PATH${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo

# Function to check and score
check_element() {
    local test_name="$1"
    local search_pattern="$2"
    local score_value="$3"
    local is_critical="$4"
    local description="$5"
    
    if grep -qi "$search_pattern" "$README_PATH"; then
        echo -e "${GREEN}✅ $test_name${NC}"
        echo -e "   └─ $description"
        ((TOTAL_SCORE += score_value))
        return 0
    else
        if [ "$is_critical" = "true" ]; then
            echo -e "${RED}❌ $test_name (CRITICAL)${NC}"
            echo -e "   └─ ${RED}$description${NC}"
            ((CRITICAL_FAILURES++))
        else
            echo -e "${YELLOW}⚠️  $test_name${NC}"
            echo -e "   └─ $description"
        fi
        return 1
    fi
}

# Function to check structure
check_structure() {
    local structure_name="$1"
    local patterns=("${@:2}")
    local all_found=true
    
    for pattern in "${patterns[@]}"; do
        if ! grep -qi "$pattern" "$README_PATH"; then
            all_found=false
            break
        fi
    done
    
    if [ "$all_found" = true ]; then
        echo -e "${GREEN}✅ $structure_name${NC}"
        return 0
    else
        echo -e "${RED}❌ $structure_name${NC}"
        return 1
    fi
}

# Count sections for complexity check
count_sections() {
    local h2_count=$(grep -c "^##" "$README_PATH" || true)
    echo "$h2_count"
}

# 1. USER VALUE FOCUS (40 points)
echo -e "${BLUE}🎯 User Value Focus Analysis${NC}"
echo -e "${BLUE}────────────────────────────────────${NC}"

# Check for problem statement (not labeled WHY)
if grep -qi "problem\|waste.*time\|struggle\|pain\|challenge" "$README_PATH" && ! grep -qi "WHY:" "$README_PATH"; then
    echo -e "${GREEN}✅ Problem Statement (No Label)${NC}"
    echo -e "   └─ Focuses on user problem without framework labels"
    ((TOTAL_SCORE += 15))
else
    if grep -qi "WHY:" "$README_PATH"; then
        echo -e "${RED}❌ Framework Label Visible${NC}"
        echo -e "   └─ ${RED}Remove WHY/HOW/WHAT labels - users don't care${NC}"
        ((CRITICAL_FAILURES++))
    else
        echo -e "${YELLOW}⚠️  Weak Problem Statement${NC}"
        echo -e "   └─ Should clearly state user's problem"
        ((TOTAL_SCORE += 5))
    fi
fi

check_element "HOW Section" \
    "how.*our approach\|how.*we achieve\|how.*methodology" \
    10 false \
    "Should explain unique approach and principles"

check_element "WHAT Section" \
    "what.*the.*\|features\|capabilities" \
    10 false \
    "Should describe tangible deliverables"

check_element "Mission Statement" \
    "we believe\|our mission\|our purpose\|we exist to" \
    5 true \
    "Core belief that drives the project"

echo

# 2. LEAN PRINCIPLES (30 points)
echo -e "${BLUE}♻️  LEAN Principles Compliance${NC}"
echo -e "${BLUE}────────────────────────────────────${NC}"

# Check for waste elimination
SECTION_COUNT=$(count_sections)
if [ "$SECTION_COUNT" -lt 15 ]; then
    echo -e "${GREEN}✅ Minimal Structure (No Waste)${NC}"
    echo -e "   └─ $SECTION_COUNT sections found (optimal: 8-12)"
    ((TOTAL_SCORE += 10))
else
    echo -e "${YELLOW}⚠️  Potential Bloat Detected${NC}"
    echo -e "   └─ $SECTION_COUNT sections found (recommended: 8-12)"
fi

# Quick Start validation
if grep -qi "quick start\|getting started" "$README_PATH"; then
    # Check if quick start is actually quick (less than 5 commands)
    quick_start_commands=$(sed -n '/[Qq]uick [Ss]tart\|[Gg]etting [Ss]tarted/,/^##/p' "$README_PATH" | grep -c '^\(```\|$\|#\)' || true)
    if [ "$quick_start_commands" -lt 20 ]; then
        echo -e "${GREEN}✅ Quick Start (Value Delivery)${NC}"
        echo -e "   └─ Rapid time to first value"
        ((TOTAL_SCORE += 10))
    else
        echo -e "${YELLOW}⚠️  Quick Start Too Complex${NC}"
        echo -e "   └─ Should be <5 commands for immediate value"
        ((TOTAL_SCORE += 5))
    fi
else
    echo -e "${RED}❌ No Quick Start Section${NC}"
    echo -e "   └─ ${RED}Users need immediate value demonstration${NC}"
fi

check_element "Examples Section" \
    "\`\`\`" \
    10 false \
    "Working examples demonstrate value"

echo

# 3. USER EXPERIENCE (20 points)
echo -e "${BLUE}👥 User Experience Quality${NC}"
echo -e "${BLUE}────────────────────────────────────${NC}"

check_element "Badges/Status" \
    "\[!\[.*\]\(.*\)\]" \
    5 false \
    "Build status and project health indicators"

check_element "Documentation Links" \
    "documentation\|docs.*guide\|api.*reference" \
    5 false \
    "Clear paths to detailed documentation"

check_element "Contributing Guide" \
    "contribut" \
    5 false \
    "Instructions for community participation"

check_element "License" \
    "license" \
    5 true \
    "Legal clarity is essential"

echo

# 4. TECHNICAL QUALITY (10 points)
echo -e "${BLUE}⚙️  Technical Quality Checks${NC}"
echo -e "${BLUE}────────────────────────────────────${NC}"

# Check for code blocks with language specification
if grep -q '```[a-z]' "$README_PATH"; then
    echo -e "${GREEN}✅ Syntax Highlighted Code${NC}"
    echo -e "   └─ Code blocks include language identifiers"
    ((TOTAL_SCORE += 5))
else
    echo -e "${YELLOW}⚠️  No Syntax Highlighting${NC}"
    echo -e "   └─ Add language identifiers to code blocks"
fi

# Check for broken links (basic check)
broken_links=$(grep -o '\[.*\](.*"*.*"*)' "$README_PATH" | grep -c '()' || true)
if [ "$broken_links" -eq 0 ]; then
    echo -e "${GREEN}✅ No Empty Links Detected${NC}"
    echo -e "   └─ All markdown links appear valid"
    ((TOTAL_SCORE += 5))
else
    echo -e "${YELLOW}⚠️  Potential Empty Links${NC}"
    echo -e "   └─ Found $broken_links potentially broken links"
fi

echo

# 5. INSPIRATIONAL ELEMENTS (Bonus)
echo -e "${BLUE}✨ Inspirational Quality (Bonus)${NC}"
echo -e "${BLUE}────────────────────────────────────${NC}"

if grep -qi "join.*movement\|join.*community\|get.*involved\|star.*us" "$README_PATH"; then
    echo -e "${GREEN}✅ Call to Action${NC}"
    echo -e "   └─ Inspiring readers to participate"
    ((TOTAL_SCORE += 5))
fi

if grep -q '".*"' "$README_PATH" | tail -1; then
    echo -e "${GREEN}✅ Memorable Tagline${NC}"
    echo -e "   └─ Closing with impact"
    ((TOTAL_SCORE += 5))
fi

echo
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo

# Calculate percentage
PERCENTAGE=$((TOTAL_SCORE * 100 / MAX_SCORE))

# Determine grade
if [ $PERCENTAGE -ge 90 ]; then
    GRADE="A+"
    GRADE_COLOR=$GREEN
elif [ $PERCENTAGE -ge 80 ]; then
    GRADE="A"
    GRADE_COLOR=$GREEN
elif [ $PERCENTAGE -ge 70 ]; then
    GRADE="B"
    GRADE_COLOR=$YELLOW
elif [ $PERCENTAGE -ge 60 ]; then
    GRADE="C"
    GRADE_COLOR=$YELLOW
else
    GRADE="F"
    GRADE_COLOR=$RED
fi

# Final Report
echo -e "${BLUE}📊 Final Assessment${NC}"
echo -e "${BLUE}────────────────────────────────────${NC}"
echo -e "Score: ${GRADE_COLOR}$TOTAL_SCORE/$MAX_SCORE ($PERCENTAGE%)${NC}"
echo -e "Grade: ${GRADE_COLOR}$GRADE${NC}"
echo -e "Critical Failures: ${RED}$CRITICAL_FAILURES${NC}"
echo

# Recommendations
if [ $CRITICAL_FAILURES -gt 0 ] || [ $PERCENTAGE -lt 70 ]; then
    echo -e "${BLUE}💡 Priority Improvements${NC}"
    echo -e "${BLUE}────────────────────────────────────${NC}"
    
    if ! grep -qi "why.*our mission\|why.*we exist" "$README_PATH"; then
        echo -e "1. ${RED}Add WHY section:${NC} Start with purpose and belief"
    fi
    
    if ! grep -qi "we believe\|our mission" "$README_PATH"; then
        echo -e "2. ${RED}Add mission statement:${NC} Clear belief that drives the project"
    fi
    
    if ! grep -qi "quick start\|getting started" "$README_PATH"; then
        echo -e "3. ${YELLOW}Add Quick Start:${NC} 2-minute path to first value"
    fi
    
    if ! grep -q '```' "$README_PATH"; then
        echo -e "4. ${YELLOW}Add examples:${NC} Show, don't just tell"
    fi
    
    echo
fi

# Exit code based on critical failures
if [ $CRITICAL_FAILURES -gt 0 ]; then
    echo -e "${RED}❌ README needs critical improvements${NC}"
    echo -e "   Run: ${BLUE}cat docs/guides/readme-best-practices.md${NC} for guidelines"
    exit 1
elif [ $PERCENTAGE -ge 80 ]; then
    echo -e "${GREEN}✅ README meets excellence standards!${NC}"
    exit 0
elif [ $PERCENTAGE -ge 60 ]; then
    echo -e "${YELLOW}⚠️  README is acceptable but could be improved${NC}"
    exit 0
else
    echo -e "${RED}❌ README needs significant improvements${NC}"
    exit 1
fi