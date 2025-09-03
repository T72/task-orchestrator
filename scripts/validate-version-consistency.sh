#!/bin/bash
# validate-version-consistency.sh - Single Source of Truth Enforcement
# Part of the Comprehensive Quality Prevention Framework (CQPF)

set -euo pipefail

echo "🔍 Version Consistency Validation"
echo "================================="

# Define the single source of truth
VERSION_FILE="VERSION"
if [ ! -f "$VERSION_FILE" ]; then
    echo "⚠️  Creating VERSION file as single source of truth..."
    echo "2.6.0" > "$VERSION_FILE"
fi

CURRENT_VERSION=$(cat "$VERSION_FILE")
echo "📌 Single Source of Truth Version: $CURRENT_VERSION"

# Files that should contain version references
VERSION_FILES=(
    "README.md"
    "CHANGELOG.md"
    "docs/examples/*.py"
    "docs/guides/*.md"
    "docs/reference/*.md"
    "tests/*.sh"
    "src/tm_production.py"
)

INCONSISTENCIES=0
CHECKED=0

echo -e "\n📊 Checking version consistency across all files..."

for pattern in "${VERSION_FILES[@]}"; do
    for file in $pattern; do
        if [ -f "$file" ]; then
            CHECKED=$((CHECKED + 1))
            
            # Look for version patterns
            if grep -q "v[0-9]\+\.[0-9]\+\.[0-9]\+" "$file" 2>/dev/null; then
                # Extract all version references
                VERSIONS=$(grep -o "v[0-9]\+\.[0-9]\+\.[0-9]\+" "$file" | sort -u)
                
                for version in $VERSIONS; do
                    if [ "$version" != "v$CURRENT_VERSION" ]; then
                        echo "❌ $file: Found inconsistent version $version (should be v$CURRENT_VERSION)"
                        INCONSISTENCIES=$((INCONSISTENCIES + 1))
                    fi
                done
            fi
        fi
    done
done

echo -e "\n📈 Results:"
echo "- Files checked: $CHECKED"
echo "- Inconsistencies found: $INCONSISTENCIES"

if [ $INCONSISTENCIES -gt 0 ]; then
    echo -e "\n🛠️  Auto-fix available. Run with --fix to update all versions:"
    echo "   $0 --fix"
    
    if [ "${1:-}" == "--fix" ]; then
        echo -e "\n🔧 Fixing all version inconsistencies..."
        for pattern in "${VERSION_FILES[@]}"; do
            for file in $pattern; do
                if [ -f "$file" ]; then
                    # Update all version references to current version
                    sed -i "s/v[0-9]\+\.[0-9]\+\.[0-9]\+/v$CURRENT_VERSION/g" "$file"
                    echo "✅ Updated: $file"
                fi
            done
        done
        echo "✨ All versions updated to v$CURRENT_VERSION"
        exit 0
    fi
    
    exit 1
else
    echo -e "\n✅ SUCCESS: All version references consistent with v$CURRENT_VERSION"
    exit 0
fi