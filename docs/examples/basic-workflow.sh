#!/bin/bash
# Basic Task Orchestrator Workflow Example

echo "=== Basic Task Workflow ==="

# Create a feature with dependencies
BACKEND=$(./tm add "Build API endpoints" | grep -o '[a-f0-9]\{8\}')
echo "Created backend task: $BACKEND"

FRONTEND=$(./tm add "Build UI components" --depends-on $BACKEND | grep -o '[a-f0-9]\{8\}')
echo "Created frontend task: $FRONTEND"

TESTS=$(./tm add "Write integration tests" --depends-on $FRONTEND | grep -o '[a-f0-9]\{8\}')
echo "Created test task: $TESTS"

# Show current status
echo -e "\n=== Current Tasks ==="
./tm list

# Complete backend work
echo -e "\n=== Completing backend ==="
./tm complete $BACKEND

# Show how frontend is now unblocked
echo -e "\n=== Tasks after backend completion ==="
./tm list

echo -e "\nNotice how the frontend task is now unblocked!"