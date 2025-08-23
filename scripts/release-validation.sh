#!/bin/bash
# Release Validation Script
# Created: 2025-08-21
# Purpose: Automated pre-release validation to prevent common issues

set -e

echo "==================================="
echo "    RELEASE VALIDATION STARTING    "
echo "==================================="

# Track validation results
ERRORS=0

# Function to report errors
report_error() {
    echo "❌ FAILED: $1"
    ERRORS=$((ERRORS + 1))
}

# Function to report success
report_success() {
    echo "✅ PASSED: $1"
}

# 1. Check for private repository markers
echo ""
echo "1. Checking repository type..."
if [ -f CLAUDE.md ]; then
    report_error "Private repository detected! CLAUDE.md exists"
    echo "   This appears to be the private development repository."
    echo "   Releases should only be made from task-orchestrator-public"
else
    report_success "No CLAUDE.md found - appears to be public repository"
fi

# 2. Validate README quality
echo ""
echo "2. Validating README quality..."
if [ -f ./scripts/validate-readme.sh ]; then
    if ./scripts/validate-readme.sh README.md > /dev/null 2>&1; then
        report_success "README validation passed"
    else
        report_error "README validation failed"
        echo "   Run: ./scripts/validate-readme.sh README.md for details"
    fi
else
    echo "⚠️  WARNING: validate-readme.sh not found - skipping README validation"
fi

# 3. Check documentation links
echo ""
echo "3. Checking documentation links..."
if [ -f ./scripts/validate-all-doc-links.sh ]; then
    if ./scripts/validate-all-doc-links.sh > /dev/null 2>&1; then
        report_success "All documentation links valid"
    else
        report_error "Broken documentation links detected"
        echo "   Run: ./scripts/validate-all-doc-links.sh for details"
    fi
else
    echo "⚠️  WARNING: validate-all-doc-links.sh not found - skipping link validation"
fi

# 4. Check for outdated year in LICENSE
echo ""
echo "4. Checking LICENSE year..."
CURRENT_YEAR=$(date +%Y)
if grep -q "2024" LICENSE 2>/dev/null; then
    report_error "LICENSE contains outdated year (2024)"
    echo "   Current year is $CURRENT_YEAR"
elif grep -q "$CURRENT_YEAR" LICENSE 2>/dev/null; then
    report_success "LICENSE has current year ($CURRENT_YEAR)"
else
    echo "⚠️  WARNING: Could not verify LICENSE year"
fi

# 5. Check for old version references
echo ""
echo "5. Checking for outdated version references..."
OLD_VERSIONS=$(grep -r "v2\.0\|v2\.1\|v1\." --include="*.md" 2>/dev/null | head -5 || true)
if [ -n "$OLD_VERSIONS" ]; then
    report_error "Found references to old versions:"
    echo "$OLD_VERSIONS" | head -5
    echo "   Update to current version (v2.3.x)"
else
    report_success "No outdated version references found"
fi

# 6. Check branch name
echo ""
echo "6. Checking Git branch..."
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
if [ "$CURRENT_BRANCH" = "main" ] || [ "$CURRENT_BRANCH" = "master" ]; then
    report_success "On correct branch: $CURRENT_BRANCH"
elif [ "$CURRENT_BRANCH" = "develop" ]; then
    report_error "On develop branch - should only release from main/master"
else
    echo "⚠️  WARNING: On branch '$CURRENT_BRANCH' - verify this is intentional"
fi

# 7. Check for uncommitted changes
echo ""
echo "7. Checking for uncommitted changes..."
if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
    report_error "Uncommitted changes detected"
    echo "   Commit or stash changes before release"
else
    report_success "Working directory clean"
fi

# 8. Check file naming conventions
echo ""
echo "8. Checking documentation naming conventions..."
UPPERCASE_DOCS=$(find docs guides -name "*[A-Z_]*" -type f 2>/dev/null | grep -v README | head -5 || true)
if [ -n "$UPPERCASE_DOCS" ]; then
    report_error "Found documentation files violating kebab-case naming:"
    echo "$UPPERCASE_DOCS" | head -5
else
    report_success "All documentation follows kebab-case naming"
fi

# 9. Check for private development artifacts
echo ""
echo "9. Checking for private development artifacts..."
PRIVATE_PATTERNS=(".task-orchestrator" "archive/" "*-notes.md" "docs/architecture/" "docs/protocols/")
for pattern in "${PRIVATE_PATTERNS[@]}"; do
    if ls $pattern 2>/dev/null | head -1 > /dev/null; then
        report_error "Found private artifact: $pattern"
    fi
done
if [ $ERRORS -eq 0 ]; then
    report_success "No private development artifacts found"
fi

# 10. Verify critical files exist
echo ""
echo "10. Verifying critical files..."
CRITICAL_FILES=("README.md" "LICENSE" "CHANGELOG.md" "CONTRIBUTING.md" "tm" "src/tm_production.py")
for file in "${CRITICAL_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        report_error "Missing critical file: $file"
    fi
done
if [ $ERRORS -eq 0 ]; then
    report_success "All critical files present"
fi

# Summary
echo ""
echo "==================================="
echo "    VALIDATION SUMMARY             "
echo "==================================="

if [ $ERRORS -eq 0 ]; then
    echo "✅ ALL CHECKS PASSED - Ready for release!"
    exit 0
else
    echo "❌ VALIDATION FAILED - $ERRORS issue(s) found"
    echo ""
    echo "Fix all issues before proceeding with release."
    exit 1
fi