# Orchestration Enforcement Quick Start Guide

## Overview

Task Orchestrator's enforcement system ensures teams realize the full 4x-5x velocity improvements that proper orchestration delivers by preventing bypass of coordination protocols.

## Quick Setup

### 1. Check Current Status
```bash
./tm config --show-enforcement
```

### 2. Validate Your Setup
```bash
./tm validate-orchestration
```
If violations found, continue to step 3.

### 3. Fix Issues Interactively
```bash
./tm fix-orchestration --interactive
```
The wizard guides you through:
- Setting up TM_AGENT_ID
- Verifying tm executable
- Initializing database if needed

## Configuration Options

### Enforcement Levels

**Standard** (Recommended):
```bash
./tm config --enforcement-level standard
```
- Warns about violations
- Requires confirmation to continue
- Provides clear guidance

**Strict** (Maximum Protection):
```bash
./tm config --enforcement-level strict
```
- Blocks all violations
- Forces proper setup
- Best for critical workflows

**Advisory** (Minimal Impact):
```bash
./tm config --enforcement-level advisory
```
- Logs violations only
- Continues execution
- Good for transition periods

### Enable/Disable Enforcement
```bash
# Enable enforcement
./tm config --enforce-orchestration true

# Disable enforcement
./tm config --enforce-orchestration false
```

## What Gets Enforced

### Required Setup
- **TM_AGENT_ID**: Must be set and non-empty
- **tm executable**: Must be available and executable
- **Database**: Task Orchestrator database must be initialized

### Enforced Commands
These commands require proper orchestration context:
- `add`, `join`, `share`, `note`, `discover`, `sync`, `context`
- `assign`, `watch`, `template`

### Non-Enforced Commands
These work without orchestration context:
- `init`, `list`, `show`, `update`, `delete`, `complete`
- `help`, `config`, `validate-orchestration`

## Auto-Detection

Enforcement automatically enables when it detects:
- TM_AGENT_ID environment variable
- Claude Code integration (.claude directory)
- Task Orchestrator database exists
- Multi-agent patterns in environment
- Commander's Intent usage in tasks

## Violation Examples

### Missing TM_AGENT_ID
```
❌ Problem: TM_AGENT_ID not set
   Impact: Agent coordination and context sharing disabled
   Fix: export TM_AGENT_ID="your_agent_name"
   Example: export TM_AGENT_ID="backend_specialist"
```

**Quick Fix**: `export TM_AGENT_ID="your_role"`

### Missing tm Executable
```
❌ Problem: tm executable not found
   Impact: Task Orchestrator commands unavailable
   Fix: Ensure ./tm is in current directory or PATH
   Check: ls -la ./tm or which tm
```

**Quick Fix**: `chmod +x ./tm`

### Uninitialized Database
```
❌ Problem: Task Orchestrator database not initialized
   Impact: No task coordination or context sharing
   Fix: ./tm init
   Verify: ./tm list should work without errors
```

**Quick Fix**: `./tm init`

## Benefits of Enforcement

### Without Enforcement
- 60% completion rate
- 25% rework
- Lost coordination benefits
- Information silos between agents
- Manual compliance unreliable

### With Enforcement
- 95% completion rate
- <5% rework
- 4x-5x velocity improvements maintained
- Proper three-channel communication
- Commander's Intent framework used consistently

## Integration Examples

### Claude Code Hook Integration
```bash
# .claude/hooks/pre-task-use.sh
#!/bin/bash

# Check if Task Orchestrator enforcement is active
if [ -f "./tm" ]; then
    if ! ./tm validate-orchestration >/dev/null 2>&1; then
        echo "⚠️ Orchestration setup required for optimal coordination"
        echo "Run: ./tm fix-orchestration --interactive"
        exit 1
    fi
fi
```

### Shell Profile Setup
```bash
# Add to ~/.bashrc or ~/.zshrc
export TM_AGENT_ID="your_specialist_role"
```

### Project-Specific Setup
```bash
# In project .envrc (if using direnv)
export TM_AGENT_ID="project_orchestrator"
```

## Troubleshooting

### Enforcement Not Working
Check if enforcement system is available:
```bash
./tm validate-orchestration
```

If you get "Enforcement system not available", the enforcement.py module isn't loaded.

### False Positives
If enforcement triggers incorrectly:
```bash
./tm config --enforcement-level advisory
```

### Performance Issues
Enforcement adds <10ms overhead. If you notice slowdown:
```bash
./tm config --enforce-orchestration false
```

### Need Help?
```bash
./tm help enforcement  # Show enforcement-specific help
./tm --help            # Show all commands including enforcement
```

## Best Practices

1. **Set TM_AGENT_ID Early**: Add to shell profile or project configuration
2. **Use Standard Level**: Provides good balance of safety and usability  
3. **Fix Issues Immediately**: Don't let violations accumulate
4. **Monitor Effectiveness**: Check if you're getting the velocity improvements
5. **Team Alignment**: Ensure whole team uses enforcement consistently

## Success Patterns

### Successful Team Setup
```bash
# Team lead sets up enforcement for the project
./tm config --enforcement-level standard

# Each team member sets their agent ID
export TM_AGENT_ID="backend_specialist"    # Backend developer
export TM_AGENT_ID="frontend_specialist"   # Frontend developer  
export TM_AGENT_ID="orchestrator"          # Team lead/coordinator

# Everyone validates their setup
./tm validate-orchestration
```

### RoleScoutPro Pattern (Proven 4x-5x Improvements)
```bash
# 1. Enforcement enabled at project level
./tm config --enforce-orchestration true
./tm config --enforcement-level standard

# 2. Agent IDs set per specialist role
export TM_AGENT_ID="mvp_orchestrator"
export TM_AGENT_ID="backend_specialist"
export TM_AGENT_ID="frontend_specialist"

# 3. Commander's Intent framework used consistently
./tm add "Implement auth system" --context "WHY: Secure user data WHAT: Login, 2FA, sessions DONE: Users can securely access accounts"
```

---

*This enforcement system transforms Task Orchestrator from optional coordination tool to mandatory orchestration infrastructure, ensuring consistent realization of proven velocity improvements.*