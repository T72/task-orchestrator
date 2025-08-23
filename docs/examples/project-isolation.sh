#!/bin/bash
# Project Isolation Example
# Shows how each project maintains its own task database

echo "=== Project Isolation Demo ==="
echo "Working on multiple client projects without confusion"
echo

# Save current directory
ORIGINAL_DIR=$(pwd)

# Create temporary demo projects
DEMO_DIR="/tmp/task-orchestrator-demo-$$"
mkdir -p "$DEMO_DIR/client-a"
mkdir -p "$DEMO_DIR/client-b"
mkdir -p "$DEMO_DIR/internal"

echo "=== Client A Project ==="
cd "$DEMO_DIR/client-a"
$ORIGINAL_DIR/tm init
$ORIGINAL_DIR/tm add "Client A: Fix login bug" -p critical
$ORIGINAL_DIR/tm add "Client A: Update dashboard"
echo "Tasks in Client A:"
$ORIGINAL_DIR/tm list
echo "Database location: $(pwd)/.task-orchestrator/"
echo

echo "=== Client B Project ==="
cd "$DEMO_DIR/client-b"
$ORIGINAL_DIR/tm init
$ORIGINAL_DIR/tm add "Client B: API integration" -p high
$ORIGINAL_DIR/tm add "Client B: Data migration"
echo "Tasks in Client B:"
$ORIGINAL_DIR/tm list
echo "Database location: $(pwd)/.task-orchestrator/"
echo

echo "=== Internal Project ==="
cd "$DEMO_DIR/internal"
$ORIGINAL_DIR/tm init
$ORIGINAL_DIR/tm add "Internal: Refactor codebase"
$ORIGINAL_DIR/tm add "Internal: Update documentation"
echo "Tasks in Internal project:"
$ORIGINAL_DIR/tm list
echo "Database location: $(pwd)/.task-orchestrator/"
echo

echo "=== Switching Back to Client A ==="
cd "$DEMO_DIR/client-a"
echo "Client A still has only its tasks:"
$ORIGINAL_DIR/tm list
echo

echo "💡 Key Benefits:"
echo "   • Each project has isolated .task-orchestrator/ directory"
echo "   • No task contamination between projects"
echo "   • Switch projects without cleanup"
echo "   • Work on multiple clients safely"

# Cleanup
cd "$ORIGINAL_DIR"
rm -rf "$DEMO_DIR"

echo
echo "Demo complete! (Temporary files cleaned up)"