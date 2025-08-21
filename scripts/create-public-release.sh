#!/bin/bash
# create-public-release.sh - Create a new public release
# 
# This script automates the complete process of creating a public release
# from the private development repository.

set -e

VERSION="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRIVATE_REPO="$(dirname "$SCRIPT_DIR")"

if [ -z "$VERSION" ]; then
    echo "❌ Error: Version required"
    echo "Usage: $0 <version>"
    echo "Example: $0 v2.0.1"
    exit 1
fi

echo "🚀 Creating Task Orchestrator Public Release $VERSION"
echo

# Validate version format
if [[ ! "$VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "⚠️  Warning: Version format should be vX.Y.Z (e.g., v2.0.1)"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check if we're in the private repository
cd "$PRIVATE_REPO"
if [ ! -f "CLAUDE.md" ]; then
    echo "❌ Error: Not in private development repository (CLAUDE.md not found)"
    exit 1
fi

# Check if working directory is clean
if ! git diff --quiet || ! git diff --staged --quiet; then
    echo "⚠️  Warning: Working directory has uncommitted changes"
    git status --short
    echo
    read -p "Continue with uncommitted changes? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Please commit or stash changes before creating release"
        exit 1
    fi
fi

# Ensure we're on the right branch
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "develop" ] && [ "$CURRENT_BRANCH" != "master" ]; then
    echo "⚠️  Warning: Currently on branch '$CURRENT_BRANCH'"
    echo "Recommended to be on 'develop' or 'master' for releases"
    read -p "Continue from current branch? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Update version in README.md if it exists
if [ -f "README.md" ] && grep -q "version-.*-blue" README.md; then
    echo "📝 Updating version in README.md..."
    sed -i "s/version-[^-]*-blue/version-${VERSION#v}-blue/g" README.md
    git add README.md
fi

# Update version in tm_enhanced.py if it exists and has version
if [ -f "tm_enhanced.py" ] && grep -q "__version__" tm_enhanced.py; then
    echo "📝 Updating version in tm_enhanced.py..."
    sed -i "s/__version__ = ['\"][^'\"]*['\"]/__version__ = \"${VERSION#v}\"/g" tm_enhanced.py
    git add tm_enhanced.py
fi

# Commit version updates if any
if ! git diff --staged --quiet; then
    git commit -m "chore: Bump version to $VERSION for release

🤖 Generated with Task Orchestrator release script

Co-Authored-By: Claude <noreply@anthropic.com>"
fi

# Create tag in private repository
if git tag | grep -q "^$VERSION$"; then
    echo "⚠️  Tag $VERSION already exists"
    read -p "Overwrite existing tag? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git tag -d "$VERSION"
    else
        exit 1
    fi
fi

echo "🏷️  Creating tag $VERSION..."
git tag -a "$VERSION" -m "Release $VERSION

Production-ready release of Task Orchestrator with:
- Complete feature implementation
- Comprehensive documentation  
- Full test coverage
- Public release optimization

🤖 Generated with Task Orchestrator release script

Co-Authored-By: Claude <noreply@anthropic.com>"

# Sync to public repository
echo "🔄 Syncing to public repository..."
"$SCRIPT_DIR/sync-to-public.sh" "$VERSION"

# Navigate to public repository
PUBLIC_REPO="../task-orchestrator-public"
cd "$PUBLIC_REPO"

# Create tag in public repository
echo "🏷️  Creating tag in public repository..."
git tag -a "$VERSION" -m "Task Orchestrator $VERSION

Professional task management and orchestration for developers.

Features:
- Zero dependencies - built with Python standard library
- Smart dependency resolution with circular prevention
- Concurrent-safe database operations
- File reference tracking for code-related tasks
- Export capabilities (JSON, Markdown)
- Cross-platform compatibility

🤖 Generated with Task Orchestrator release script"

echo
echo "✅ Release $VERSION created successfully!"
echo
echo "📁 Public repository: $PUBLIC_REPO"
echo "🏷️  Tag created: $VERSION"
echo
echo "Next steps:"
echo "1. Review public repository: cd $PUBLIC_REPO"
echo "2. Push to GitHub: git push origin main && git push origin $VERSION"
echo "3. Create GitHub release with release notes"
echo "4. Update any external documentation"
echo
echo "🔒 Private development repository remains unchanged"
echo "📋 Continue development in private repo as normal"