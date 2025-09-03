#!/bin/bash
# Test script to verify .claude/ exclusion

# Copy the EXCLUDE_PATTERNS from sync-to-public.sh
EXCLUDE_PATTERNS=(
    "CLAUDE.md"
    ".claude/"
    "*.md"
    "*/.claude/*"
)

# Function to check if path should be excluded
should_exclude() {
    local path="$1"
    for pattern in "${EXCLUDE_PATTERNS[@]}"; do
        # Check exact match
        if [[ "$path" == "$pattern" ]]; then
            return 0
        fi
        # Check if path starts with pattern
        if [[ "$path" == "$pattern"* ]]; then
            return 0
        fi
        # Check glob patterns
        if [[ "$path" == $pattern ]]; then
            return 0
        fi
    done
    return 1
}

# Test paths
test_paths=(
    ".claude/"
    ".claude/hooks/test.py"
    ".claude/agents/test.md"
    "docs/.claude/test.md"
    "CLAUDE.md"
    "src/tm_production.py"
    "README.md"
)

echo "Testing exclusion patterns for .claude/ directory:"
echo "=================================================="
for path in "${test_paths[@]}"; do
    if should_exclude "$path"; then
        echo "✅ EXCLUDED: $path"
    else
        echo "❌ INCLUDED: $path"
    fi
done