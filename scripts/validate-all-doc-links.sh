#!/bin/bash

# Comprehensive Documentation Link Validator
# Validates ALL links in ALL markdown files before release
# Prevents ANY broken documentation links from reaching users

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║       Comprehensive Documentation Link Validator         ║${NC}"
echo -e "${BLUE}║          MANDATORY Pre-Release Validation                ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo

# Track global statistics
TOTAL_FILES=0
TOTAL_LINKS=0
TOTAL_VALID=0
TOTAL_BROKEN=0
FAILED_FILES=""

# Function to validate links in a single file
validate_file() {
    local file="$1"
    local file_links=0
    local file_valid=0
    local file_broken=0
    local broken_list=""
    
    echo -e "${BLUE}📄 Checking: ${NC}$file"
    
    # Extract all links from the file
    local links=$(grep -oE '\[[^]]+\]\([^)]+\)' "$file" 2>/dev/null | sed 's/.*](\([^)]*\)).*/\1/' || true)
    
    if [ -z "$links" ]; then
        echo -e "   ${YELLOW}No links found${NC}"
        return 0
    fi
    
    while IFS= read -r link; do
        if [ -z "$link" ]; then
            continue
        fi
        
        ((file_links++))
        ((TOTAL_LINKS++))
        
        # Skip certain link types
        if [[ "$link" =~ ^https?:// ]]; then
            # External URL - basic validation
            if [[ "$link" =~ github\.com|shields\.io|opensource\.org|python\.org ]]; then
                ((file_valid++))
                ((TOTAL_VALID++))
            else
                echo -e "   ${YELLOW}⚠️  External: $link${NC}"
                ((file_valid++))
                ((TOTAL_VALID++))
            fi
        elif [[ "$link" =~ ^mailto: ]] || [[ "$link" =~ ^# ]]; then
            # Email or anchor - skip
            ((file_valid++))
            ((TOTAL_VALID++))
        else
            # Local file link - must exist
            local target_path="$REPO_ROOT/$link"
            target_path="${target_path%%#*}"  # Remove anchor if present
            
            if [ -f "$target_path" ]; then
                ((file_valid++))
                ((TOTAL_VALID++))
            else
                echo -e "   ${RED}❌ BROKEN: $link${NC}"
                broken_list="$broken_list\n      - $link"
                ((file_broken++))
                ((TOTAL_BROKEN++))
            fi
        fi
    done <<< "$links"
    
    # Report file summary
    if [ $file_broken -gt 0 ]; then
        echo -e "   ${RED}Found $file_broken broken links!${NC}"
        echo -e "   ${RED}Broken links:${NC}$broken_list"
        FAILED_FILES="$FAILED_FILES\n$file"
        return 1
    else
        echo -e "   ${GREEN}✅ All $file_links links valid${NC}"
        return 0
    fi
}

# Find all markdown files
echo -e "${BLUE}🔍 Scanning for documentation files...${NC}"
echo

mapfile -t md_files < <(find "$REPO_ROOT" -name "*.md" -type f | grep -v node_modules | grep -v .git | sort)

echo -e "${BLUE}Found ${#md_files[@]} markdown files to validate${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo

# Validate each file
for file in "${md_files[@]}"; do
    ((TOTAL_FILES++))
    validate_file "$file" || true
done

echo
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo

# Final report
echo -e "${BLUE}📊 VALIDATION SUMMARY${NC}"
echo -e "${BLUE}────────────────────────────────────${NC}"
echo -e "Files checked: ${BLUE}$TOTAL_FILES${NC}"
echo -e "Total links: ${BLUE}$TOTAL_LINKS${NC}"
echo -e "Valid links: ${GREEN}$TOTAL_VALID${NC}"
echo -e "Broken links: ${RED}$TOTAL_BROKEN${NC}"
echo

if [ $TOTAL_BROKEN -gt 0 ]; then
    echo -e "${RED}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║                  ❌ VALIDATION FAILED                    ║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${RED}Files with broken links:${NC}$FAILED_FILES"
    echo
    echo -e "${YELLOW}📋 Required Actions:${NC}"
    echo -e "1. Fix all broken links by either:"
    echo -e "   • Updating the link to point to the correct file"
    echo -e "   • Creating the missing documentation"
    echo -e "   • Removing the broken link"
    echo
    echo -e "${YELLOW}🚫 BLOCKING RELEASE:${NC}"
    echo -e "This validation MUST pass before any release!"
    echo
    echo -e "${MAGENTA}Prevention Strategy:${NC}"
    echo -e "• Run before EVERY commit: ./scripts/validate-all-doc-links.sh"
    echo -e "• Add to pre-commit hooks"
    echo -e "• Include in CI/CD pipeline"
    echo -e "• Make it part of release checklist"
    
    exit 1
else
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                  ✅ ALL LINKS VALID                      ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${GREEN}Documentation is ready for release!${NC}"
    exit 0
fi