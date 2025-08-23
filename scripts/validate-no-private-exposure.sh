#!/bin/bash
# validate-no-private-exposure.sh - Prevent Private Content Exposure
# Part of the Comprehensive Quality Prevention Framework (CQPF)

set -euo pipefail

echo "🔒 Private Content Exposure Prevention"
echo "======================================"

VIOLATIONS=0
WARNINGS=0
CHECKS=0

# Detect repository context
REPO_TYPE="PUBLIC"
if [ -f "CLAUDE.md" ]; then
    REPO_TYPE="PRIVATE"
    echo "ℹ️  Running in PRIVATE repository - checking for content that would block public sync"
else
    echo "ℹ️  Running in PUBLIC repository - enforcing strict content rules"
fi
echo

# Define private patterns that should NEVER appear in public repo
PRIVATE_PATTERNS=(
    "CLAUDE.md"
    "CLAUDE\.md"
    "traceability-analysis"
    "traceability-improvement"
    "INTERNAL"
    "PRIVATE"
    "CONFIDENTIAL"
    "@implements FR-INTERNAL"
    "internal-notes"
    "private-notes"
    "MACPS"
    "DFSS"
    "think ultrahard"
    "think-ultrahard"
)

# Define directories that should NEVER be in public
PRIVATE_DIRS=(
    "scripts"  # Internal validation scripts
    ".claude"  # Claude Code specific files
    "archive"  # Old development artifacts
    "docs/developer/development"  # Internal dev docs
    "docs/protocols"  # Internal protocols
    "docs/architecture"  # Internal architecture
    "tests/prd-validation"  # Internal PRD tests
)

# Define files that should NEVER be in public
PRIVATE_FILES=(
    "CLAUDE.md"
    "RELEASE-CHECKLIST.md"
    "DOCUMENTATION-AUDIT-REPORT.md"
    "ROOT-CAUSE-*.md"
    "traceability-*.md"
    "*-INTERNAL.md"
    "*-PRIVATE.md"
    "MACPS-*.md"
    "DFSS-*.md"
)

echo -e "\n🔍 Phase 1: Checking for private content patterns in files..."

# Function to check file for private content
check_file_content() {
    local file=$1
    local found_issues=0
    
    # Skip binary files
    if file "$file" | grep -q "binary"; then
        return 0
    fi
    
    for pattern in "${PRIVATE_PATTERNS[@]}"; do
        if grep -q "$pattern" "$file" 2>/dev/null; then
            echo "  ❌ Found private pattern '$pattern' in: $file"
            VIOLATIONS=$((VIOLATIONS + 1))
            found_issues=1
        fi
    done
    
    return $found_issues
}

# Check all text files
# In private repos, skip files that will be excluded by sync
for file in $(find . -type f -name "*.md" -o -name "*.py" -o -name "*.sh" -o -name "*.txt" 2>/dev/null | grep -v ".git"); do
    if [ -f "$file" ]; then
        # Skip .claude directory in private repos as it's excluded during sync
        if [[ "$REPO_TYPE" == "PRIVATE" ]] && [[ "$file" == *"/.claude/"* ]]; then
            continue
        fi
        CHECKS=$((CHECKS + 1))
        check_file_content "$file"
    fi
done

echo -e "\n🔍 Phase 2: Checking for private directories..."

for dir in "${PRIVATE_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        if [[ "$REPO_TYPE" == "PRIVATE" ]]; then
            # In private repo, just note it will be excluded
            echo "  ℹ️  Private directory exists: $dir (will be excluded during sync)"
        else
            # In public repo, this is a violation
            echo "  ❌ Private directory exists: $dir"
            echo "     This should NOT be in public repository!"
            VIOLATIONS=$((VIOLATIONS + 1))
            
            # Count files in the directory
            FILE_COUNT=$(find "$dir" -type f 2>/dev/null | wc -l)
            echo "     Contains $FILE_COUNT files that would be exposed"
        fi
    fi
done

echo -e "\n🔍 Phase 3: Checking for private files..."

for pattern in "${PRIVATE_FILES[@]}"; do
    for file in $pattern; do
        if [ -f "$file" ]; then
            echo "  ❌ Private file exists: $file"
            echo "     This should NOT be in public repository!"
            VIOLATIONS=$((VIOLATIONS + 1))
        fi
    done
done

echo -e "\n🔍 Phase 4: Validating sync configuration..."

# Check if this is the private repo (has CLAUDE.md)
if [ -f "CLAUDE.md" ]; then
    echo "  ℹ️  Running in PRIVATE repository (CLAUDE.md present)"
    
    # Check sync script configuration
    if [ -f "scripts/sync-to-public.sh" ]; then
        echo "  Checking sync script configuration..."
        
        # Check if scripts/ is in INCLUDE_PATTERNS (it shouldn't be)
        if grep -q '"scripts/"' scripts/sync-to-public.sh 2>/dev/null; then
            echo "  ❌ CRITICAL: scripts/ is in INCLUDE_PATTERNS!"
            echo "     This will expose private validation scripts"
            VIOLATIONS=$((VIOLATIONS + 1))
        else
            echo "  ✅ scripts/ not in sync patterns"
        fi
        
        # Check if proper exclusions are in place
        if ! grep -q "CLAUDE.md" scripts/sync-to-public.sh 2>/dev/null; then
            echo "  ⚠️  Warning: CLAUDE.md not explicitly excluded"
            WARNINGS=$((WARNINGS + 1))
        fi
    fi
else
    echo "  ℹ️  Running in PUBLIC repository (no CLAUDE.md)"
    
    # This should be the public repo - extra strict checking
    echo "  Performing strict public repository validation..."
    
    # No references to private repo should exist
    if grep -r "task-orchestrator-private" . 2>/dev/null | grep -v ".git"; then
        echo "  ❌ Found references to private repository"
        VIOLATIONS=$((VIOLATIONS + 1))
    fi
fi

echo -e "\n🔍 Phase 5: Checking for duplicate directories (poor boundaries)..."

# Check for duplicate content structure (indicates sync issues)
if [ -d "docs/examples" ] && [ -d "examples" ]; then
    echo "  ⚠️  Warning: Duplicate structure - both docs/examples/ and examples/ exist"
    echo "     This indicates poor architectural boundaries"
    WARNINGS=$((WARNINGS + 1))
fi

if [ -d "docs/guides" ] && [ -d "guides" ]; then
    echo "  ⚠️  Warning: Duplicate structure - both docs/guides/ and guides/ exist"
    WARNINGS=$((WARNINGS + 1))
fi

echo -e "\n📊 VALIDATION SUMMARY"
echo "===================="
echo "Files checked: $CHECKS"
echo "❌ Security violations: $VIOLATIONS"
echo "⚠️  Warnings: $WARNINGS"

if [ $VIOLATIONS -gt 0 ]; then
    echo -e "\n❌ FAILED: Found $VIOLATIONS private content exposures!"
    echo "CRITICAL: Fix these issues before ANY public release!"
    echo ""
    echo "Recommended fixes:"
    echo "1. Remove all private directories from public repo"
    echo "2. Remove all private files from public repo"
    echo "3. Fix sync script to exclude private content"
    echo "4. Scan for and remove private content references"
    exit 1
elif [ $WARNINGS -gt 0 ]; then
    echo -e "\n⚠️  PASSED WITH WARNINGS: Review recommended"
    echo "No critical exposures, but structure could be improved"
    exit 0
else
    echo -e "\n✅ SUCCESS: No private content exposure detected"
    echo "Repository is safe for public release"
    exit 0
fi