#!/bin/bash
# Public Repository Content Validation
# Ensures only appropriate content is included in public repository

set -e

echo "🔍 Task Orchestrator - Public Repository Validation"
echo "=================================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

VIOLATIONS_FOUND=0
WARNINGS_FOUND=0

# Function to report violation
report_violation() {
    echo -e "${RED}❌ VIOLATION:${NC} $1"
    VIOLATIONS_FOUND=1
}

# Function to report warning
report_warning() {
    echo -e "${YELLOW}⚠️ WARNING:${NC} $1"
    WARNINGS_FOUND=1
}

# Function to report success
report_success() {
    echo -e "${GREEN}✅${NC} $1"
}

echo -e "${BLUE}1. Checking for private development files...${NC}"

# Check for explicitly forbidden files/directories
FORBIDDEN_ITEMS=(
    "CLAUDE.md"
    ".claude"
    "scripts"
    "docs/architecture"
    "docs/protocols"
    "docs/developer/development"
    "archive"
    "analysis"
    "planning"
    "internal"
    "private"
)

for item in "${FORBIDDEN_ITEMS[@]}"; do
    if [ -e "$item" ]; then
        report_violation "Found forbidden item: $item"
    fi
done

# Check for private file patterns
if find . -name "*-notes.md" -o -name "*-notes.txt" -o -name "session-*.md" -o -name "SESSION-*.md" | grep -q .; then
    report_violation "Found private note files"
    find . -name "*-notes.md" -o -name "*-notes.txt" -o -name "session-*.md" -o -name "SESSION-*.md" | sed 's/^/  /'
fi

if [ $VIOLATIONS_FOUND -eq 0 ]; then
    report_success "No forbidden files found"
fi

echo ""
echo -e "${BLUE}2. Checking file contents for private markers...${NC}"

# Check for private content markers in files
PRIVATE_MARKERS=(
    "scripts/validate-.*\.sh"
    "scripts/extract-schema\.py"
    "scripts/.*pre-commit.*hook"
)

for marker in "${PRIVATE_MARKERS[@]}"; do
    if grep -r "$marker" . --exclude-dir=.git --exclude="validate-public-repo.sh" >/dev/null 2>&1; then
        report_violation "Found private marker: $marker"
        grep -r "$marker" . --exclude-dir=.git --exclude="validate-public-repo.sh" | head -3 | sed 's/^/  /'
    fi
done

if [ $VIOLATIONS_FOUND -eq 0 ]; then
    report_success "No private content markers found"
fi

echo ""
echo -e "${BLUE}3. Validating public repository structure...${NC}"

# Check for required public files
REQUIRED_FILES=(
    "README.md"
    "LICENSE"
    "tm"
    "src/tm_production.py"
    ".gitignore"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        report_violation "Missing required file: $file"
    else
        report_success "Found required file: $file"
    fi
done

echo ""
echo -e "${BLUE}4. Checking documentation quality...${NC}"

# Check README completeness
if ! grep -q "Quick Start" README.md; then
    report_warning "README missing Quick Start section"
fi

if ! grep -q "AI Agent Orchestration" README.md; then
    report_warning "README missing AI Agent Orchestration value proposition"
fi

if [ $WARNINGS_FOUND -eq 0 ]; then
    report_success "Documentation structure looks good"
fi

echo ""
echo "=================================================="

if [ $VIOLATIONS_FOUND -eq 0 ]; then
    echo -e "${GREEN}🎉 VALIDATION PASSED${NC}"
    echo -e "${GREEN}Repository is safe for public release${NC}"
    
    if [ $WARNINGS_FOUND -gt 0 ]; then
        echo -e "${YELLOW}Note: $WARNINGS_FOUND warnings found (non-blocking)${NC}"
    fi
    
    exit 0
else
    echo -e "${RED}🚫 VALIDATION FAILED${NC}"
    echo -e "${RED}Found $VIOLATIONS_FOUND violations that must be fixed${NC}"
    echo ""
    echo "To fix violations:"
    echo "1. Remove private files: git rm <file>"
    echo "2. Update .gitignore to prevent future inclusion"
    echo "3. Use private repository for internal development"
    echo ""
    exit 1
fi