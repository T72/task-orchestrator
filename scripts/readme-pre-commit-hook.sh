#!/bin/bash

# README Pre-commit Hook
# Validates README changes before allowing commit
# Install: cp scripts/readme-pre-commit-hook.sh .git/hooks/pre-commit

# Check if README.md is being modified
if git diff --cached --name-only | grep -q "README.md"; then
    echo "📝 README.md changes detected - validating..."
    echo
    
    # Run validation
    ./scripts/validate-readme.sh README.md
    VALIDATION_RESULT=$?
    
    if [ $VALIDATION_RESULT -ne 0 ]; then
        echo
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "❌ README validation failed!"
        echo
        echo "Please address the issues above before committing."
        echo "Reference: docs/guides/readme-best-practices.md"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        exit 1
    fi
    
    echo
    echo "✅ README validation passed - proceeding with commit"
fi

exit 0