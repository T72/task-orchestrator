#!/bin/bash
# sync-to-public.sh - Sync curated content to public repository
# 
# This script creates a clean public release from the private development repository
# by excluding all internal development files and personal workflow documentation.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRIVATE_REPO="$(dirname "$SCRIPT_DIR")"
PUBLIC_REPO="${PUBLIC_REPO:-../task-orchestrator-public}"
VERSION="${1:-latest}"

echo "🚀 Task Orchestrator Public Release Sync"
echo "Private repo: $PRIVATE_REPO"
echo "Public repo: $PUBLIC_REPO"
echo "Version: $VERSION"
echo

# Files and directories to include in public release
INCLUDE_PATTERNS=(
    "src/"
    "tests/"
    "docs/guides/"
    "docs/examples/"
    "docs/reference/"
    "docs/releases/"
    "scripts/"
    "deploy/"
    "README.md"
    "LICENSE"
    "CHANGELOG.md"
    "CONTRIBUTING.md"
    "tm"
    "tm_enhanced.py"
)

# Files and directories to EXCLUDE from public release
# These contain private development context and internal decisions
EXCLUDE_PATTERNS=(
    "CLAUDE.md"                          # Private development workflows
    "docs/architecture/"                 # Internal architecture decisions
    "docs/protocols/"                    # Internal development protocols  
    "docs/developer/development/"        # Development session data
    "docs/specifications/"               # Internal requirements
    "*-notes.md"                         # Private agent notes
    "*_VERIFICATION.md"                  # Internal verification reports
    "*_REPORT.md"                        # Internal analysis reports
    "*_SUMMARY.md"                       # Internal summaries
    "*_STATUS.md"                        # Internal status reports
    "*_IMPROVEMENTS.md"                  # Internal improvement analyses
    "*_ANALYSIS.md"                      # Internal technical analyses
    "archive/"                           # Archived development materials
    "development-docs/"                  # Development documentation
    "analysis-reports/"                  # Analysis reports
    "legacy-implementations/"            # Legacy code
    "private/"                           # Private directories
    ".private/"                          # Hidden private directories
    "development-sessions/"              # Development session data
    "session-*.json"                     # Session files
    "*.session"                          # Session files
    ".task-orchestrator/"                # User data directory
    ".task-manager/"                     # Legacy user data
    "*.db"                               # Database files
    "*.sqlite*"                          # SQLite files
    ".claude/"                           # Claude Code configuration
    "*.log"                              # Log files
    "test_debug_log.txt"                 # Debug logs
    "__pycache__/"                       # Python cache
    "*.pyc"                              # Compiled Python
    ".vscode/"                           # IDE settings
    ".idea/"                             # IDE settings
    "*.tmp"                              # Temporary files
    "*.bak"                              # Backup files
    ".env*"                              # Environment files
)

# Function to check if path should be excluded
should_exclude() {
    local path="$1"
    for pattern in "${EXCLUDE_PATTERNS[@]}"; do
        if [[ "$path" == $pattern ]] || [[ "$path" == *"/$pattern" ]] || [[ "$path" == $pattern/* ]]; then
            return 0  # Should exclude
        fi
    done
    return 1  # Should include
}

# Create public repository if it doesn't exist
if [ ! -d "$PUBLIC_REPO" ]; then
    echo "📁 Creating public repository directory..."
    mkdir -p "$PUBLIC_REPO"
    cd "$PUBLIC_REPO"
    git init
    echo "# Task Orchestrator" > README.md
    git add README.md
    git commit -m "Initial commit"
    cd "$PRIVATE_REPO"
fi

# Create temporary staging area
STAGING_DIR=$(mktemp -d -t task-orchestrator-sync-XXXXXX)
echo "📦 Staging content in $STAGING_DIR"

# Copy included files while respecting exclusions
cd "$PRIVATE_REPO"
for pattern in "${INCLUDE_PATTERNS[@]}"; do
    if [ -e "$pattern" ]; then
        # Check if this item should be excluded
        if should_exclude "$pattern"; then
            echo "⚠️  Skipping excluded pattern: $pattern"
            continue
        fi
        
        echo "✅ Including: $pattern"
        
        if [ -d "$pattern" ]; then
            # Handle directories - copy recursively but filter out excluded files
            find "$pattern" -type f | while IFS= read -r file; do
                if ! should_exclude "$file"; then
                    target_dir="$STAGING_DIR/$(dirname "$file")"
                    mkdir -p "$target_dir"
                    cp "$file" "$STAGING_DIR/$file"
                else
                    echo "   🚫 Excluding: $file"
                fi
            done
        elif [ -f "$pattern" ]; then
            # Handle individual files
            target_dir="$STAGING_DIR/$(dirname "$pattern")"
            mkdir -p "$target_dir"
            cp "$pattern" "$STAGING_DIR/$pattern"
        fi
    else
        echo "⚠️  Pattern not found: $pattern"
    fi
done

# Validate kebab-case naming for documentation files
echo "📝 Validating documentation naming conventions..."
if find "$STAGING_DIR/docs" -name "*.md" 2>/dev/null | grep -E '[A-Z_]' | head -5; then
    echo "⚠️  WARNING: Found documentation files not using kebab-case naming"
    echo "   All public documentation must use kebab-case (lowercase with hyphens)"
    echo "   Example: user-guide.md, api-reference.md, troubleshooting.md"
fi

# Create clean .gitignore for public repository
cat > "$STAGING_DIR/.gitignore" << 'EOF'
# Task Orchestrator Public Repository .gitignore
# This is the clean public version - excludes private development files

# ====================
# Runtime Data
# ====================
# User task data - created locally by users
.task-orchestrator/
.task-manager/

# ====================
# Python Runtime
# ====================
__pycache__/
*.py[cod]
*$py.class
*.pyc
*.pyo
*.pyd

# ====================
# Environment Files
# ====================
.env
.env.*
*.env

# ====================
# Database Files
# ====================
*.db
*.sqlite
*.sqlite3
*.db-journal
*.db-wal

# ====================
# Logs and Debug
# ====================
*.log
debug/
logs/

# ====================
# IDE and OS Files
# ====================
.vscode/
.idea/
*.swp
*.swo
*~
.DS_Store
Thumbs.db

# ====================
# Temporary Files
# ====================
*.tmp
*.temp
tmp/
temp/
*.bak
*.backup

# ====================
# Test Coverage
# ====================
.coverage
htmlcov/
.pytest_cache/

# ====================
# Build Artifacts
# ====================
build/
dist/
*.egg-info/
EOF

# Update README.md to remove any references to private development
if [ -f "$STAGING_DIR/README.md" ]; then
    echo "📝 Cleaning README.md for public release..."
    # Remove any CLAUDE.md references
    sed -i '/CLAUDE\.md/d' "$STAGING_DIR/README.md" 2>/dev/null || true
    # Remove development-specific sections if any
    sed -i '/## Internal Development/,/^## /d' "$STAGING_DIR/README.md" 2>/dev/null || true
fi

# Sync content to public repository
echo "🔄 Syncing to public repository..."
cd "$PUBLIC_REPO"

# Remove existing content (except .git)
find . -mindepth 1 -maxdepth 1 ! -name '.git' -exec rm -rf {} +

# Copy staged content
if [ "$(ls -A "$STAGING_DIR")" ]; then
    cp -r "$STAGING_DIR"/* . 2>/dev/null || true
fi
if [ "$(ls -A "$STAGING_DIR"/.*)" ]; then
    cp -r "$STAGING_DIR"/.* . 2>/dev/null || true
fi

# Create commit
git add .
if git diff --staged --quiet; then
    echo "ℹ️  No changes to commit"
else
    if [ "$VERSION" = "latest" ]; then
        COMMIT_MSG="chore: Sync latest changes from private development

🤖 Generated with Task Orchestrator sync script
        
Co-Authored-By: Claude <noreply@anthropic.com>"
    else
        COMMIT_MSG="release: Task Orchestrator $VERSION

🤖 Generated with Task Orchestrator sync script

Co-Authored-By: Claude <noreply@anthropic.com>"
    fi
    
    git commit -m "$COMMIT_MSG"
    echo "✅ Created commit for version: $VERSION"
fi

# Cleanup
rm -rf "$STAGING_DIR"

echo
echo "🎉 Public repository sync complete!"
echo "📁 Public repo location: $PUBLIC_REPO"
echo "🔍 Review changes: cd $PUBLIC_REPO && git log --oneline -5"
echo "🚀 Push to remote: cd $PUBLIC_REPO && git push origin main"
echo

# Summary of what was excluded
echo "🔒 Excluded private content:"
printf '%s\n' "${EXCLUDE_PATTERNS[@]}" | head -10
if [ ${#EXCLUDE_PATTERNS[@]} -gt 10 ]; then
    echo "   ... and $((${#EXCLUDE_PATTERNS[@]} - 10)) more patterns"
fi
echo