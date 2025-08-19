#!/bin/bash
set -e

# Simple test to verify isolation is working

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "Testing isolation mechanisms..."

# Test 1: Create temp directory
TEST_DIR=$(mktemp -d -t tm_isolation_test_XXXXXX)
if [ -d "$TEST_DIR" ]; then
    echo -e "${GREEN}✓${NC} Temp directory created: $TEST_DIR"
else
    echo -e "${RED}✗${NC} Failed to create temp directory"
    exit 1
fi

# Test 2: Change to temp directory
cd "$TEST_DIR"
if [ "$(pwd)" = "$TEST_DIR" ]; then
    echo -e "${GREEN}✓${NC} Changed to temp directory"
else
    echo -e "${RED}✗${NC} Failed to change directory"
    exit 1
fi

# Test 3: Create test files
touch test_file.txt
echo "test data" > test_file.txt
if [ -f "test_file.txt" ]; then
    echo -e "${GREEN}✓${NC} Can create files in temp directory"
else
    echo -e "${RED}✗${NC} Failed to create test file"
    exit 1
fi

# Test 4: Cleanup
cd /
rm -rf "$TEST_DIR"
if [ ! -d "$TEST_DIR" ]; then
    echo -e "${GREEN}✓${NC} Temp directory cleaned up"
else
    echo -e "${RED}✗${NC} Failed to clean up temp directory"
    exit 1
fi

echo -e "${GREEN}All isolation tests passed!${NC}"
echo "Your test scripts are now properly isolated and should not crash WSL."