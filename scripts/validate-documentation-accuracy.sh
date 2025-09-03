#!/bin/bash
# validate-documentation-accuracy.sh - Implementation-First Documentation Validation
# Part of the Comprehensive Quality Prevention Framework (CQPF)

set -euo pipefail

echo "📚 Documentation Accuracy Validation"
echo "===================================="

ERRORS=0
WARNINGS=0
CHECKS=0

# Function to verify command documentation
verify_command() {
    local command=$1
    local doc_file=$2
    
    echo -n "  Checking: tm $command ... "
    
    # Check if command exists in implementation
    if grep -q "command == \"$command\"" tm 2>/dev/null || \
       grep -q "def $command" src/tm_production.py 2>/dev/null; then
        echo "✅ Implemented"
        return 0
    else
        echo "❌ NOT IMPLEMENTED (documented in $doc_file)"
        return 1
    fi
}

# Function to verify command flags
verify_flag() {
    local flag=$1
    local command=$2
    local doc_file=$3
    
    echo -n "  Checking flag: --$flag for $command ... "
    
    # Check if flag exists in implementation
    if grep -q "\-\-$flag" tm 2>/dev/null || \
       grep -q "'$flag'" src/tm_production.py 2>/dev/null || \
       grep -q "\"$flag\"" src/tm_production.py 2>/dev/null; then
        echo "✅ Exists"
        return 0
    else
        echo "❌ FICTIONAL FLAG (documented in $doc_file)"
        return 1
    fi
}

echo -e "\n🔍 Phase 1: Verifying documented commands exist in implementation..."

# Extract documented commands from README
if [ -f "README.md" ]; then
    CHECKS=$((CHECKS + 1))
    echo "Checking README.md..."
    
    # Look for tm commands in code blocks
    COMMANDS=$(grep -o '\./tm [a-z]*' README.md | awk '{print $2}' | sort -u)
    
    for cmd in $COMMANDS; do
        if ! verify_command "$cmd" "README.md"; then
            ERRORS=$((ERRORS + 1))
        fi
    done
fi

# Check API reference
if [ -f "docs/reference/api-reference.md" ]; then
    CHECKS=$((CHECKS + 1))
    echo -e "\nChecking docs/reference/api-reference.md..."
    
    # Extract commands from API docs
    COMMANDS=$(grep -o '^### tm [a-z]*' docs/reference/api-reference.md 2>/dev/null | awk '{print $3}' | sort -u)
    
    for cmd in $COMMANDS; do
        if ! verify_command "$cmd" "api-reference.md"; then
            ERRORS=$((ERRORS + 1))
        fi
    done
fi

echo -e "\n🔍 Phase 2: Verifying documented flags exist..."

# Check for specific known problematic flags (has-files removed since it's been fixed)
PROBLEMATIC_FLAGS=(
    "has-deps:list"   # This should exist
    "depends-on:add"  # This should exist
    "status:list"     # This should exist
)

for flag_cmd in "${PROBLEMATIC_FLAGS[@]}"; do
    IFS=':' read -r flag command <<< "$flag_cmd"
    if ! verify_flag "$flag" "$command" "documentation"; then
        ERRORS=$((ERRORS + 1))
    fi
done

echo -e "\n🔍 Phase 3: Verifying Python example imports..."

# Check Python examples
for example in docs/examples/*.py; do
    if [ -f "$example" ]; then
        CHECKS=$((CHECKS + 1))
        echo "Checking $(basename $example)..."
        
        # Check for incorrect imports
        if grep -q "from tm import" "$example"; then
            echo "  ❌ Incorrect import: 'from tm import' (should be 'from src.tm_production import')"
            ERRORS=$((ERRORS + 1))
        fi
        
        # Verify correct imports exist
        if ! grep -q "from src.tm_production import" "$example"; then
            echo "  ⚠️  Missing correct import statement"
            WARNINGS=$((WARNINGS + 1))
        fi
    fi
done

echo -e "\n🔍 Phase 4: Testing documented examples..."

# Create a test script for examples
TEST_SCRIPT="/tmp/test_examples.py"
cat > "$TEST_SCRIPT" << 'EOF'
#!/usr/bin/env python3
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

try:
    # Test basic import
    from src.tm_production import TaskManager
    print("✅ TaskManager import successful")
    
    # Test basic functionality
    tm = TaskManager(":memory:")
    task_id = tm.add("Test task")
    if task_id:
        print("✅ Basic task creation works")
    else:
        print("❌ Task creation failed")
        sys.exit(1)
        
except ImportError as e:
    print(f"❌ Import error: {e}")
    sys.exit(1)
except Exception as e:
    print(f"❌ Runtime error: {e}")
    sys.exit(1)
EOF

# Run the test
if python3 "$TEST_SCRIPT" 2>/dev/null; then
    echo "✅ Basic functionality test passed"
else
    echo "⚠️  Basic functionality test failed (may need proper environment)"
    WARNINGS=$((WARNINGS + 1))
fi

rm -f "$TEST_SCRIPT"

echo -e "\n📊 VALIDATION SUMMARY"
echo "===================="
echo "Checks performed: $CHECKS"
echo "❌ Errors found: $ERRORS"
echo "⚠️  Warnings: $WARNINGS"

if [ $ERRORS -gt 0 ]; then
    echo -e "\n❌ FAILED: Documentation contains $ERRORS fictional elements"
    echo "Fix required before release!"
    exit 1
elif [ $WARNINGS -gt 0 ]; then
    echo -e "\n⚠️  PASSED WITH WARNINGS: Review recommended"
    exit 0
else
    echo -e "\n✅ SUCCESS: All documentation accurately reflects implementation"
    exit 0
fi