#!/bin/bash
# validate-public-release.sh - Validate public release content
# 
# This script checks that the public repository contains only appropriate
# content and no private development information has leaked.

set -e

PUBLIC_REPO="${1:-../task-orchestrator-public}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🔍 Validating Task Orchestrator Public Release"
echo "Public repo: $PUBLIC_REPO"
echo

if [ ! -d "$PUBLIC_REPO" ]; then
    echo "❌ Error: Public repository not found at $PUBLIC_REPO"
    exit 1
fi

cd "$PUBLIC_REPO"

# Check if it's a git repository
if [ ! -d ".git" ]; then
    echo "❌ Error: Not a git repository"
    exit 1
fi

VALIDATION_ERRORS=0
VALIDATION_WARNINGS=0

# Function to report error
error() {
    echo "❌ ERROR: $1"
    ((VALIDATION_ERRORS++))
}

# Function to report warning
warning() {
    echo "⚠️  WARNING: $1"
    ((VALIDATION_WARNINGS++))
}

# Function to report success
success() {
    echo "✅ $1"
}

echo "📋 Validation Checklist:"
echo

# Check 1: No private files should exist
echo "🔒 Checking for private development files..."
PRIVATE_FILES_FOUND=0

# Critical private files that should NEVER be in public
CRITICAL_PRIVATE_FILES=(
    "CLAUDE.md"
    ".task-orchestrator/"
    "docs/architecture/"
    "docs/protocols/"
    "docs/developer/development/"
    "*-notes.md"
    "archive/"
    "development-docs/"
    "private/"
    ".private/"
)

for pattern in "${CRITICAL_PRIVATE_FILES[@]}"; do
    if find . -path "./.git" -prune -o -name "$pattern" -print | grep -q .; then
        error "Private file found: $pattern"
        ((PRIVATE_FILES_FOUND++))
    fi
done

if [ $PRIVATE_FILES_FOUND -eq 0 ]; then
    success "No critical private files found"
fi

# Check 2: Required public files exist
echo
echo "📁 Checking for required public files..."
REQUIRED_FILES=(
    "README.md"
    "LICENSE"
    "src/"
    "tm"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -e "$file" ]; then
        success "Required file exists: $file"
    else
        error "Required file missing: $file"
    fi
done

# Check 3: README.md doesn't contain private references
echo
echo "📖 Checking README.md content..."
if [ -f "README.md" ]; then
    if grep -q "CLAUDE\.md" README.md; then
        warning "README.md contains references to CLAUDE.md"
    fi
    
    if grep -qi "private" README.md; then
        warning "README.md contains 'private' references (may be OK)"
    fi
    
    if grep -qi "internal" README.md; then
        warning "README.md contains 'internal' references (may be OK)"
    fi
    
    if grep -q "docs/architecture" README.md; then
        error "README.md references private architecture docs"
    fi
    
    # Check for proper repository URL
    if grep -q "github.com" README.md; then
        if ! grep -q "github.com/T72/task-orchestrator" README.md; then
            warning "README.md may contain incorrect GitHub repository URL"
        else
            success "README.md contains correct GitHub repository URL"
        fi
    fi
fi

# Check 4: .gitignore is appropriate for public repository
echo
echo "🚫 Checking .gitignore..."
if [ -f ".gitignore" ]; then
    if grep -q "CLAUDE\.md" .gitignore; then
        warning ".gitignore contains CLAUDE.md exclusion (not needed in public repo)"
    fi
    
    if grep -q "\.task-orchestrator" .gitignore; then
        success ".gitignore properly excludes user data directory"
    else
        warning ".gitignore should exclude .task-orchestrator/ directory"
    fi
    
    if grep -q "__pycache__" .gitignore; then
        success ".gitignore properly excludes Python cache"
    fi
fi

# Check 5: Source code structure
echo
echo "🐍 Checking source code structure..."
if [ -d "src" ]; then
    success "Source directory exists"
    
    # Check for Python files
    if find src -name "*.py" | grep -q .; then
        success "Python source files found"
    else
        warning "No Python files found in src/"
    fi
fi

if [ -f "tm" ]; then
    if head -1 "tm" | grep -q "#!/"; then
        success "tm script has proper shebang"
    else
        warning "tm script missing shebang line"
    fi
    
    if [ -x "tm" ]; then
        success "tm script is executable"
    else
        warning "tm script is not executable"
    fi
fi

# Check 6: Documentation structure
echo
echo "📚 Checking documentation..."
if [ -d "docs" ]; then
    success "Documentation directory exists"
    
    # Check for user-facing documentation
    if [ -d "docs/guides" ]; then
        success "User guides directory exists"
    fi
    
    if [ -d "docs/examples" ]; then
        success "Examples directory exists"
    fi
    
    # Check that private docs are excluded
    if [ -d "docs/architecture" ]; then
        error "Private architecture docs found in public repository"
    fi
    
    if [ -d "docs/protocols" ]; then
        error "Private protocol docs found in public repository"
    fi
fi

# Check 7: Test structure
echo
echo "🧪 Checking test structure..."
if [ -d "tests" ]; then
    success "Tests directory exists"
    
    if find tests -name "*.sh" | grep -q .; then
        success "Shell test scripts found"
    fi
    
    if find tests -name "*.py" | grep -q .; then
        success "Python test files found"
    fi
fi

# Check 8: Documentation naming conventions
echo
echo "📝 Checking documentation naming conventions..."
NAMING_VIOLATIONS=0

if [ -d "docs" ]; then
    # Check for non-kebab-case documentation files
    NON_KEBAB_FILES=$(find docs -name "*.md" | grep -E '[A-Z_]' | head -10)
    if [ -n "$NON_KEBAB_FILES" ]; then
        error "Documentation files not using kebab-case naming found:"
        echo "$NON_KEBAB_FILES" | while read -r file; do
            echo "   ❌ $file"
        done
        echo "   Required: kebab-case (lowercase with hyphens)"
        echo "   Example: user-guide.md, api-reference.md"
        ((NAMING_VIOLATIONS++))
    else
        success "All documentation files use kebab-case naming"
    fi
fi

# Check 9: Git history cleanliness
echo
echo "📜 Checking git history..."
COMMIT_COUNT=$(git rev-list --count HEAD)
if [ $COMMIT_COUNT -lt 100 ]; then
    success "Git history is clean ($COMMIT_COUNT commits)"
else
    warning "Git history is lengthy ($COMMIT_COUNT commits) - consider squashing"
fi

# Check for any commits that mention private content
if git log --oneline | grep -qi "claude\.md\|private\|internal"; then
    warning "Commit messages reference private content"
fi

# Check 9: File permissions
echo
echo "🔐 Checking file permissions..."
if find . -name "*.sh" | xargs ls -l | grep -q "rwx"; then
    success "Shell scripts have execute permissions"
fi

# Check 10: Repository size
echo
echo "💾 Checking repository size..."
REPO_SIZE=$(du -sh . | cut -f1)
echo "📊 Repository size: $REPO_SIZE"

if du -s . | awk '{print $1}' | (read size; [ $size -lt 102400 ]); then  # 100MB in KB
    success "Repository size is reasonable ($REPO_SIZE)"
else
    warning "Repository size is large ($REPO_SIZE) - consider optimization"
fi

# Summary
echo
echo "📋 Validation Summary"
echo "===================="

if [ $VALIDATION_ERRORS -eq 0 ] && [ $VALIDATION_WARNINGS -eq 0 ]; then
    echo "🎉 Perfect! Public repository validation passed with no issues."
    echo "✅ Ready for public release"
elif [ $VALIDATION_ERRORS -eq 0 ]; then
    echo "✅ Public repository validation passed with $VALIDATION_WARNINGS warning(s)."
    echo "⚠️  Review warnings but safe to proceed"
else
    echo "❌ Public repository validation failed!"
    echo "🚨 $VALIDATION_ERRORS error(s) and $VALIDATION_WARNINGS warning(s) found"
    echo "🔧 Fix errors before proceeding with public release"
fi

echo
echo "🔗 Next steps:"
echo "1. Review any warnings or errors above"
echo "2. Test installation: cd $PUBLIC_REPO && ./tm init"
echo "3. Push to GitHub: git push origin main"
echo "4. Create GitHub release"

exit $VALIDATION_ERRORS