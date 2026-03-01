# AI Agent Discovery Protocol

## Overview

The AI Agent Discovery Protocol solves a critical problem: **How do AI agents automatically discover and use Task Orchestrator when it's installed in a project?**

Without this protocol, agents might:
- Not realize Task Orchestrator is available
- Use less effective coordination methods
- Miss the opportunity for seamless multi-agent orchestration

## The ORCHESTRATOR.md Solution

Task Orchestrator implements automatic discovery through the **ORCHESTRATOR.md Protocol** - a standardized file that AI agents are trained to look for and understand.

### How It Works

1. **Automatic Generation**: When you run `./tm init`, Task Orchestrator creates `ORCHESTRATOR.md` in your project root
2. **Static Discovery Contract**: The file is a stable protocol guide, not a live task board
3. **AI-Optimized Format**: Written specifically for AI agents to understand and use
4. **Universal Discovery**: Works with Claude Code, GitHub Copilot, Cursor, and any AI tool

### What ORCHESTRATOR.md Contains

```markdown
# 🤖 AI Agent Orchestration Protocol

## 📋 Runtime Task Status
[Retrieved live via `./tm list` from Task Orchestrator data]

## 🚀 Quick Start for AI Agents
[Essential commands and patterns]

## 🤝 Multi-Agent Patterns
[Common coordination patterns with examples]

## 🎯 Quick Reference
[Command reference table]
```

## Implementation Details

### File Generation

The discovery protocol is implemented in `src/orchestrator_discovery.py`:

```python
class OrchestratorDiscovery:
    def create_orchestrator_md(self) -> bool
        # Creates ORCHESTRATOR.md from template
    
    def update_orchestrator_md(self) -> bool
        # Compatibility hook: ensure file exists if missing
    
    def add_readme_section(self) -> bool
        # Optionally adds discovery hint to README.md
```

### Runtime Source of Truth

Task status is not persisted in `ORCHESTRATOR.md`.

Live state is always queried from Task Orchestrator data via:
- `./tm list`
- `./tm list --format json`
- `./tm list --assignee <agent>`

### Template System

The protocol uses a template at `templates/ORCHESTRATOR.md.template` that includes:
- Quick reference commands
- Multi-agent coordination patterns
- Best practices for AI agents
- Runtime status retrieval commands

## Benefits for AI Agents

### 1. Instant Discovery
AI agents can check for ORCHESTRATOR.md existence:
```bash
[ -f ORCHESTRATOR.md ] && echo "Task Orchestrator available!"
```

### 2. Current Context
The file points agents to current-state commands:
- `./tm list`
- `./tm list --format json`
- `./tm show TASK_ID`

### 3. Ready-to-Use Examples
Each pattern includes working code:
```bash
# Sequential pipeline pattern
DESIGN=$(./tm add "Design system" --assignee architect | grep -o '[a-f0-9]\{8\}')
BACKEND=$(./tm add "Build API" --assignee backend --depends-on $DESIGN)
```

### 4. Agent-Specific Instructions
Tailored guidance for different agent types:
- Orchestrating agents learn to use `./tm watch`
- Specialist agents understand task assignment
- All agents know how to share context

## How AI Agents Use It

### Discovery Flow

1. **Check for ORCHESTRATOR.md**
   ```python
   if os.path.exists("ORCHESTRATOR.md"):
       # Task Orchestrator is available
       use_task_orchestrator()
   ```

2. **Read Discovery Contract**
   ```python
   with open("ORCHESTRATOR.md") as f:
       content = f.read()
       # Parse orchestration protocol and command patterns
   ```

3. **Follow Patterns**
   - Use documented patterns for task creation
   - Apply dependency management
   - Share context appropriately

### Example Agent Behavior

**Without ORCHESTRATOR.md:**
```
Agent: "I'll work on the backend API now."
[No coordination, potential conflicts]
```

**With ORCHESTRATOR.md:**
```
Agent: "I see Task Orchestrator is available. Creating tracked task..."
$ ./tm add "Implement user API" --assignee backend_agent
Task created with ID: a1b2c3d4

Agent: "Task a1b2c3d4 created. Starting work and will update progress."
```

## Configuration Options

### Enabling/Disabling

The discovery protocol is enabled by default. Control it via:

```python
# In tm wrapper script
ENABLE_DISCOVERY = os.environ.get("TM_ENABLE_DISCOVERY", "1") == "1"
```

### Customization

You can customize the ORCHESTRATOR.md template:
1. Edit `templates/ORCHESTRATOR.md.template`
2. Add project-specific patterns
3. Include custom agent instructions

### Status Retrieval Frequency

Agents should retrieve runtime state directly whenever needed:
```bash
./tm list
./tm list --format json
```

## Integration with AI Tools

### Claude Code
Claude Code automatically detects ORCHESTRATOR.md and adjusts its workflow to use Task Orchestrator for coordination.

### GitHub Copilot
Copilot can be prompted to check for ORCHESTRATOR.md:
```
"Check if this project uses Task Orchestrator and use it if available"
```

### Cursor
Cursor's AI agents will discover and read ORCHESTRATOR.md when analyzing project structure.

### Custom AI Agents
Any AI agent can implement discovery:
```python
def discover_orchestration():
    if Path("ORCHESTRATOR.md").exists():
        return "task_orchestrator"
    # Check for other orchestration tools
    return None
```

## Best Practices

### 1. Keep It Regenerated
Regenerate from template when needed:
```bash
./tm init  # Regenerates ORCHESTRATOR.md
```

### 2. Add Project Context
Enhance the template with project-specific information:
- Team conventions
- Specialized workflows
- Custom agent types

### 3. Monitor Discovery
Check if agents are using Task Orchestrator:
```bash
# See assigned tasks
./tm list --assignee backend_agent
```

### 4. Educate Your Agents
When starting a session, remind agents:
```
"This project uses Task Orchestrator. Check ORCHESTRATOR.md for coordination."
```

## Troubleshooting

### ORCHESTRATOR.md Not Generating

1. Check permissions:
   ```bash
   ls -la . | grep -E "^d.*w"  # Directory must be writable
   ```

2. Manually generate:
   ```bash
   ./tm init  # Force regeneration
   ```

3. Check for errors:
   ```bash
   TM_VERBOSE=1 ./tm init  # Enable verbose output
   ```

### Task Status Seems Stale

1. Query runtime state directly:
   ```bash
   ./tm list
   ```

2. Use machine-readable output when parsing:
   ```bash
   ./tm list --format json
   ```

3. Regenerate discovery file if missing/corrupt:
   ```bash
   ./tm init
   ```

### Agents Not Discovering

1. Ensure ORCHESTRATOR.md is in project root
2. Check file permissions (must be readable)
3. Verify agent has access to project directory
4. Test with explicit prompt:
   ```
   "Check for ORCHESTRATOR.md and use Task Orchestrator if available"
   ```

## Future Enhancements

### Planned Improvements

1. **Agent Registration**: Agents can register themselves
2. **Custom Templates**: Per-agent-type instructions
3. **Webhook Support**: Notify external systems
4. **API Endpoint**: REST API for discovery
5. **Multi-Project**: Cross-project coordination

### Community Contributions

We welcome improvements to the discovery protocol:
- Additional agent patterns
- Integration guides for specific tools
- Template enhancements
- Discovery mechanism improvements

## Summary

The ORCHESTRATOR.md Protocol transforms Task Orchestrator from a tool you have to remember to use into one that AI agents discover and use automatically. This creates a self-organizing ecosystem where:

- **Discovery is automatic** - No manual configuration needed
- **Context retrieval is deterministic** - Live status always comes from task data
- **Patterns guide usage** - Ready-to-use examples ensure correct implementation
- **Coordination is seamless** - Agents naturally work together

By making Task Orchestrator discoverable, we ensure that AI agents always use the best available coordination mechanism, leading to more efficient development and fewer coordination failures.

---

*The AI Agent Discovery Protocol is implemented in Task Orchestrator v2.9.0+*
