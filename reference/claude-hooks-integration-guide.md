# Claude Code Hook Integration Guide for Task Orchestrator

## Status: Example Implementation Guide
**This document provides example hook implementations for integrating Task Orchestrator with Claude Code. These are templates and examples, not pre-built implementations.**

## Overview
This guide demonstrates how to create hooks that integrate Task Orchestrator (`tm`) with Claude Code's hooks system for seamless multi-agent orchestration.

## Prerequisites
- Task Orchestrator installed and accessible via `tm` command
- Claude Code with hooks support enabled
- Python 3.8+ for hook scripts

## Hook Integration Points

### 1. TodoWrite Tool Integration

Monitor when Claude uses the TodoWrite tool and sync with Task Orchestrator.

**Configuration (.claude/settings.json):**
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "TodoWrite",
        "hooks": [
          {
            "type": "command",
            "command": "python .claude/hooks/sync-todos.py"
          }
        ]
      }
    ]
  }
}
```

**Example Hook Script (.claude/hooks/sync-todos.py):**
```python
#!/usr/bin/env python3
import json
import sys
import subprocess

def main():
    try:
        # Read input from Claude
        input_data = json.load(sys.stdin)
        tool_input = input_data.get("tool_input", {})
        todos = tool_input.get("todos", [])
        
        # Convert todos to tm tasks
        for todo in todos:
            if todo.get("status") == "pending":
                title = todo.get("content", "")
                # Create task in tm
                result = subprocess.run(
                    ["tm", "add", title],
                    capture_output=True,
                    text=True
                )
                if result.returncode == 0:
                    task_id = result.stdout.strip()
                    print(f"Created task {task_id}: {title}", file=sys.stderr)
        
        # Pass through the original input
        json.dump(input_data, sys.stdout)
        
    except Exception as e:
        print(f"Error in hook: {e}", file=sys.stderr)
        # Pass through on error
        json.dump(input_data, sys.stdout)

if __name__ == "__main__":
    main()
```

### 2. Session Start Context Loading

Load task context when Claude Code session starts.

**Configuration:**
```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "python .claude/hooks/load-tasks.py"
          }
        ]
      }
    ]
  }
}
```

**Example Hook Script (.claude/hooks/load-tasks.py):**
```python
#!/usr/bin/env python3
import json
import sys
import subprocess

def main():
    try:
        input_data = json.load(sys.stdin)
        
        # Get pending tasks
        result = subprocess.run(
            ["tm", "list", "--status", "pending", "--format", "json"],
            capture_output=True,
            text=True
        )
        
        if result.returncode == 0:
            tasks = json.loads(result.stdout)
            if tasks:
                # Add task context to prompt
                task_context = f"\n\nPending tasks:\n"
                for task in tasks[:5]:  # Limit to 5 tasks
                    task_context += f"- [{task['id']}] {task['title']}\n"
                
                # Append to user prompt
                if "source" in input_data:
                    input_data["source"] += task_context
        
        json.dump(input_data, sys.stdout)
        
    except Exception as e:
        print(f"Error loading tasks: {e}", file=sys.stderr)
        json.dump(input_data, sys.stdout)

if __name__ == "__main__":
    main()
```

### 3. File Change Tracking

Track file modifications and update related tasks.

**Configuration:**
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "python .claude/hooks/track-changes.py"
          }
        ]
      }
    ]
  }
}
```

**Example Hook Script (.claude/hooks/track-changes.py):**
```python
#!/usr/bin/env python3
import json
import sys
import subprocess
import os

def main():
    try:
        input_data = json.load(sys.stdin)
        tool_name = input_data.get("tool_name", "")
        tool_input = input_data.get("tool_input", {})
        
        if tool_name in ["Edit", "Write", "MultiEdit"]:
            file_path = tool_input.get("file_path", "")
            if file_path:
                # Get current task from environment or config
                task_id = os.environ.get("TM_CURRENT_TASK")
                if task_id:
                    # Update task progress
                    message = f"Modified {os.path.basename(file_path)}"
                    subprocess.run(
                        ["tm", "progress", task_id, message],
                        capture_output=True
                    )
        
        json.dump(input_data, sys.stdout)
        
    except Exception as e:
        print(f"Error tracking changes: {e}", file=sys.stderr)
        json.dump(input_data, sys.stdout)

if __name__ == "__main__":
    main()
```

### 4. Task Status Updates

Update task status based on Claude's actions.

**Configuration:**
```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "python .claude/hooks/task-status.py"
          }
        ]
      }
    ]
  }
}
```

**Example Hook Script (.claude/hooks/task-status.py):**
```python
#!/usr/bin/env python3
import json
import sys
import subprocess
import re

def main():
    try:
        input_data = json.load(sys.stdin)
        prompt = input_data.get("source", "")
        
        # Detect task-related commands
        if "complete task" in prompt.lower():
            # Extract task ID
            match = re.search(r'\b([a-f0-9]{8})\b', prompt)
            if match:
                task_id = match.group(1)
                subprocess.run(
                    ["tm", "complete", task_id],
                    capture_output=True
                )
                print(f"Marked task {task_id} as complete", file=sys.stderr)
        
        elif "start task" in prompt.lower():
            match = re.search(r'\b([a-f0-9]{8})\b', prompt)
            if match:
                task_id = match.group(1)
                subprocess.run(
                    ["tm", "update", task_id, "--status", "in_progress"],
                    capture_output=True
                )
                # Set environment for file tracking
                os.environ["TM_CURRENT_TASK"] = task_id
        
        json.dump(input_data, sys.stdout)
        
    except Exception as e:
        print(f"Error updating task status: {e}", file=sys.stderr)
        json.dump(input_data, sys.stdout)

if __name__ == "__main__":
    main()
```

## Installation Steps

1. **Create hooks directory:**
   ```bash
   mkdir -p .claude/hooks
   ```

2. **Copy hook scripts:**
   Save the example scripts above to `.claude/hooks/` directory.

3. **Make scripts executable:**
   ```bash
   chmod +x .claude/hooks/*.py
   ```

4. **Configure Claude settings:**
   Add hook configurations to `.claude/settings.json`.

5. **Test integration:**
   ```bash
   # Test a hook manually
   echo '{"source": "test prompt"}' | python .claude/hooks/load-tasks.py
   ```

## Hook Best Practices

### Error Handling
- Always pass through input data on error
- Log errors to stderr, not stdout
- Use try/except blocks around all logic

### Performance
- Keep hooks fast (<100ms execution time)
- Limit API calls and subprocess executions
- Cache frequently accessed data

### Security
- Validate all input data
- Use subprocess with caution
- Never execute user-provided code

### Debugging
```bash
# Enable debug logging
export HOOK_DEBUG=1

# Test hook with sample data
cat sample_input.json | python .claude/hooks/sync-todos.py
```

## Advanced Integration Ideas

### 1. Dependency Resolution
Monitor task completions and automatically unblock dependent tasks.

### 2. Context Switching
Save and restore task context when switching between tasks.

### 3. Progress Visualization
Generate progress reports and visualizations from task data.

### 4. Multi-Agent Coordination
Share task state between multiple Claude instances.

## Troubleshooting

### Common Issues

**Hook not triggering:**
- Check matcher pattern in settings.json
- Verify hook script is executable
- Check Claude Code logs for errors

**Task creation fails:**
- Ensure `tm` is in PATH
- Verify database is initialized (`tm init`)
- Check file permissions

**Performance issues:**
- Profile hook execution time
- Reduce subprocess calls
- Implement caching where appropriate

## Example Workflow

1. Claude starts session → loads pending tasks
2. User asks to work on feature → Claude creates tasks via TodoWrite
3. Hook syncs todos to Task Orchestrator
4. Claude modifies files → hook tracks changes
5. User says "complete" → hook marks task done
6. Session ends → final status saved

## Resources

- [Task Orchestrator API Reference](./api-reference.md)
- [Claude Code Hooks Documentation](https://docs.anthropic.com/claude-code/hooks)
- [Database Schema Reference](./database-schema.md)

---

*Last Updated: 2025-08-21*
*Status: Guide/Template - Not Pre-Built Implementation*
*Version: 1.0.0*