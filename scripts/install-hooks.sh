#!/bin/bash

# Task Orchestrator Hooks Installation Script for Claude Code

echo "╔══════════════════════════════════════════════════════╗"
echo "║   Task Orchestrator Hooks Installation for Claude Code   ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""

# Check if we're in the task-orchestrator directory
if [ ! -f "tm" ]; then
    echo "❌ Error: Please run this script from the task-orchestrator directory"
    echo "   Current directory: $(pwd)"
    exit 1
fi

# Initialize task orchestrator if needed
if [ ! -d ".task-orchestrator" ]; then
    echo "📦 Initializing task orchestrator database..."
    ./tm init
    if [ $? -eq 0 ]; then
        echo "✓ Task orchestrator initialized"
    else
        echo "❌ Failed to initialize task orchestrator"
        exit 1
    fi
else
    echo "✓ Task orchestrator already initialized"
fi

# Make scripts executable
echo ""
echo "🔧 Setting up hook scripts..."

# Make tm executable
chmod +x tm
echo "✓ Made tm executable"

# Make all hook scripts executable
if [ -d "hooks" ]; then
    chmod +x hooks/*.py 2>/dev/null
    echo "✓ Made hook scripts executable"
else
    echo "⚠️  hooks directory not found"
fi

# Make test and example scripts executable
chmod +x test_tm.sh 2>/dev/null
chmod +x example_workflow.sh 2>/dev/null
chmod +x agent_helper.sh 2>/dev/null
echo "✓ Made helper scripts executable"

# Check for Claude settings
echo ""
echo "📋 Checking Claude Code settings..."

SETTINGS_FILE=".claude/settings.json"

if [ -f "$SETTINGS_FILE" ]; then
    echo "✓ Claude settings file exists"
    echo ""
    echo "Current hooks configuration:"
    echo "──────────────────────────────"
    python3 -c "
import json
with open('$SETTINGS_FILE') as f:
    data = json.load(f)
    hooks = data.get('hooks', {})
    for event, configs in hooks.items():
        print(f'  {event}:')
        for config in configs:
            matcher = config.get('matcher', 'all')
            for hook in config.get('hooks', []):
                cmd = hook.get('command', '').split('/')[-1]
                print(f'    - {matcher} → {cmd}')
" 2>/dev/null || cat "$SETTINGS_FILE"
else
    echo "⚠️  No Claude settings file found"
    echo "   Expected location: $SETTINGS_FILE"
fi

# Test task orchestrator
echo ""
echo "🧪 Testing task orchestrator..."

# Create a test task
TEST_OUTPUT=$(./tm add "Test task - can be deleted" 2>&1)
if echo "$TEST_OUTPUT" | grep -q "Created task"; then
    TEST_ID=$(echo "$TEST_OUTPUT" | grep -o '[a-f0-9]\{8\}')
    echo "✓ Successfully created test task: $TEST_ID"
    
    # Complete the test task
    ./tm complete "$TEST_ID" > /dev/null 2>&1
    echo "✓ Successfully completed test task"
else
    echo "⚠️  Could not create test task"
fi

# Display usage instructions
echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║                Installation Complete!                ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""
echo "📚 Quick Start Guide:"
echo ""
echo "1. Test the task orchestrator:"
echo "   ./tm list"
echo ""
echo "2. Run the test suite:"
echo "   ./test_tm.sh"
echo ""
echo "3. See example workflow:"
echo "   ./example_workflow.sh"
echo ""
echo "4. To use with Claude Code:"
echo "   - The .claude/settings.json file configures the hooks"
echo "   - Start Claude Code in this directory"
echo "   - Use '/hooks' command to verify hooks are loaded"
echo ""
echo "5. Key commands:"
echo "   tm add \"Task description\"     - Create a task"
echo "   tm list                       - List all tasks"
echo "   tm show <id>                  - Show task details"
echo "   tm complete <id>              - Complete a task"
echo "   tm watch                      - Check notifications"
echo ""
echo "🎯 Hook Features:"
echo "   • SessionStart: Loads task context at startup"
echo "   • PreToolUse→Task: Tracks all delegated tasks"
echo "   • Stop: Ensures tasks are completed"
echo ""
echo "For more information, see:"
echo "   - README.md"
echo "   - claude-integration.md"
echo "   - claude-hooks-integration.md"
echo ""

# Check if running in Claude Code
if [ -n "$CLAUDE_PROJECT_DIR" ]; then
    echo "✨ Detected Claude Code environment!"
    echo "   Hooks should be active. Use '/hooks' to verify."
fi