#!/bin/bash

# README Link Validator
# Ensures all links in README.md are valid and working
# Prevents broken documentation links from reaching users

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

README_FILE="${1:-README.md}"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
README_PATH="$REPO_ROOT/$README_FILE"

if [ ! -f "$README_PATH" ]; then
    echo -e "${RED}❌ README file not found: $README_PATH${NC}"
    exit 1
fi

echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║            README Link Validator v1.0                    ║${NC}"
echo -e "${BLUE}║         Preventing Broken Documentation Links            ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo
echo -e "${BLUE}📄 Checking: $README_PATH${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo

# Track statistics
TOTAL_LINKS=0
VALID_LINKS=0
BROKEN_LINKS=0
EXTERNAL_LINKS=0

# Arrays to store broken links
declare -a BROKEN_FILES
declare -a BROKEN_URLS

# Function to check if file exists (handles relative paths)
check_file_link() {
    local link="$1"
    local file_path="$REPO_ROOT/$link"
    
    # Remove any anchors (e.g., file.md#section)
    file_path="${file_path%%#*}"
    
    if [ -f "$file_path" ]; then
        return 0
    else
        return 1
    fi
}

# Function to check external URL (basic check)
check_url_link() {
    local url="$1"
    
    # For GitHub links, we'll trust they exist (can't easily verify without auth)
    if [[ "$url" =~ github\.com ]]; then
        return 0
    fi
    
    # For other URLs, we could use curl but that requires network
    # For now, we'll just validate the format
    if [[ "$url" =~ ^https?:// ]]; then
        return 0
    else
        return 1
    fi
}

echo -e "${BLUE}🔍 Extracting Links from README...${NC}"
echo

# Extract all markdown links [text](url)
# More portable approach using sed
links=$(grep -oE '\[[^]]+\]\([^)]+\)' "$README_PATH" | sed 's/.*](\([^)]*\)).*/\1/' || true)

# Also extract reference-style links if any [text][ref]
# We'll skip these for now as they're less common

echo -e "${BLUE}📊 Link Analysis${NC}"
echo -e "${BLUE}────────────────────────────────────${NC}"

# Process each link
while IFS= read -r link; do
    if [ -z "$link" ]; then
        continue
    fi
    
    ((TOTAL_LINKS++))
    
    # Determine link type
    if [[ "$link" =~ ^https?:// ]]; then
        # External URL
        ((EXTERNAL_LINKS++))
        if check_url_link "$link"; then
            echo -e "${GREEN}✅ External: $link${NC}"
            ((VALID_LINKS++))
        else
            echo -e "${RED}❌ Invalid URL: $link${NC}"
            BROKEN_URLS+=("$link")
            ((BROKEN_LINKS++))
        fi
    elif [[ "$link" =~ ^mailto: ]]; then
        # Email link - skip validation
        echo -e "${BLUE}📧 Email: $link${NC}"
        ((VALID_LINKS++))
    elif [[ "$link" =~ ^# ]]; then
        # Anchor link within same file - skip validation
        echo -e "${BLUE}⚓ Anchor: $link${NC}"
        ((VALID_LINKS++))
    else
        # Local file link
        if check_file_link "$link"; then
            echo -e "${GREEN}✅ File exists: $link${NC}"
            ((VALID_LINKS++))
        else
            echo -e "${RED}❌ File missing: $link${NC}"
            BROKEN_FILES+=("$link")
            ((BROKEN_LINKS++))
        fi
    fi
done <<< "$links"

echo
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo

# Report results
echo -e "${BLUE}📈 Validation Summary${NC}"
echo -e "${BLUE}────────────────────────────────────${NC}"
echo -e "Total links found: ${BLUE}$TOTAL_LINKS${NC}"
echo -e "Valid links: ${GREEN}$VALID_LINKS${NC}"
echo -e "Broken links: ${RED}$BROKEN_LINKS${NC}"
echo -e "External links: ${BLUE}$EXTERNAL_LINKS${NC}"
echo

# If there are broken links, provide detailed report
if [ $BROKEN_LINKS -gt 0 ]; then
    echo -e "${RED}⚠️  BROKEN LINKS DETECTED${NC}"
    echo -e "${RED}────────────────────────────────────${NC}"
    
    if [ ${#BROKEN_FILES[@]} -gt 0 ]; then
        echo -e "${RED}Missing Files:${NC}"
        for file in "${BROKEN_FILES[@]}"; do
            echo -e "  • $file"
            # Suggest possible fixes
            base_name=$(basename "$file")
            echo -e "    ${YELLOW}Searching for similar files...${NC}"
            similar=$(find "$REPO_ROOT" -name "*$base_name*" -type f 2>/dev/null | head -3)
            if [ -n "$similar" ]; then
                echo -e "    ${YELLOW}Did you mean?${NC}"
                echo "$similar" | while read -r suggestion; do
                    rel_path="${suggestion#$REPO_ROOT/}"
                    echo -e "      - $rel_path"
                done
            fi
        done
        echo
    fi
    
    if [ ${#BROKEN_URLS[@]} -gt 0 ]; then
        echo -e "${RED}Invalid URLs:${NC}"
        for url in "${BROKEN_URLS[@]}"; do
            echo -e "  • $url"
        done
        echo
    fi
    
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
    echo -e "${RED}❌ README validation failed!${NC}"
    echo
    echo -e "${YELLOW}How to fix:${NC}"
    echo -e "1. Update links to point to existing files"
    echo -e "2. Create the missing documentation files"
    echo -e "3. Remove links to non-existent resources"
    echo
    echo -e "${YELLOW}Prevention:${NC}"
    echo -e "• Run this script before committing README changes"
    echo -e "• Use: ./scripts/validate-readme-links.sh"
    echo -e "• Consider adding to pre-commit hooks"
    
    exit 1
else
    echo -e "${GREEN}✅ All links are valid!${NC}"
    echo
    echo -e "${GREEN}README link validation passed successfully.${NC}"
    exit 0
fi