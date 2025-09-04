# Claude Code Task Manager Integration via Hooks

## Status: Guide
## Last Verified: August 23, 2025
Against version: v2.7.2

## Overview
This guide shows how to integrate the task manager (`tm`) with Claude Code's hooks system for seamless multi-agent orchestration.

## Hook-Based Integration Architecture

The task manager can be integrated at multiple hook points to provide automatic task tracking, dependency management, and agent coordination.

## Core Hook Implementations

### 1. Task Tool Integration (PreToolUse Hook)

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Task",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/task-manager/hooks/pre-task-hook.py"
          }
        ]
      }
    ]
  }
}
```

**pre-task-hook.py:**
```python
#!/usr/bin/env python3
import json
import sys
import subprocess
import re

def extract_task_info(prompt):
    """Extract task information from agent prompt"""
    # Look for task patterns in the prompt
    dependencies = re.findall(r'depends on: ([\w,\s]+)', prompt, re.I)
    files = re.findall(r'(?:file|path): ([^\s,]+)', prompt, re.I)
    priority = 'high' if 'critical' in prompt.lower() else 'medium'
    
    return {
        'dependencies': dependencies,
        'files': files,
        'priority': priority
    }

try:
    input_data = json.load(sys.stdin)
except json.JSONDecodeError as e:
    print(f"Error: Invalid JSON input: {e}", file=sys.stderr)
    sys.exit(1)

tool_name = input_data.get("tool_name", "")
tool_input = input_data.get("tool_input", {})

if tool_name == "Task":
    description = tool_input.get("description", "")
    prompt = tool_input.get("prompt", "")
    subagent_type = tool_input.get("subagent_type", "")
    
    # Extract task information
    task_info = extract_task_info(prompt)
    
    # Create task in task manager
    cmd = ["./tm", "add", description, "-p", task_info['priority'], "--tag", subagent_type]
    
    # Add file references
    for file_ref in task_info['files']:
        cmd.extend(["--file", file_ref])
    
    # Execute task creation
    result = subprocess.run(cmd, capture_output=True, text=True, cwd=input_data.get("cwd"))
    
    if result.returncode == 0:
        # Extract task ID from output
        task_id = re.search(r'[a-f0-9]{8}', result.stdout)
        if task_id:
            task_id = task_id.group()
            
            # Update agent prompt with task ID
            enhanced_prompt = f"""
TASK_MANAGER_ID: {task_id}

{prompt}

IMPORTANT: 
- Start by running: tm show {task_id}
- Update status: tm update {task_id} --status in_progress
- When complete: tm complete {task_id} --impact-review
- If blocked: tm update {task_id} --status blocked --impact "reason"
"""
            
            # Return modified tool input
            output = {
                "hookSpecificOutput": {
                    "hookEventName": "PreToolUse",
                    "permissionDecision": "allow",
                    "permissionDecisionReason": f"Task {task_id} created and tracked"
                },
                "modifiedToolInput": {
                    "description": description,
                    "prompt": enhanced_prompt,
                    "subagent_type": subagent_type
                }
            }
            
            print(json.dumps(output))
            sys.exit(0)

# Let normal flow continue
sys.exit(0)
```

### 2. File Operation Tracking (PostToolUse Hook)

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/task-manager/hooks/track-file-changes.py"
          }
        ]
      }
    ]
  }
}
```

**track-file-changes.py:**
```python
#!/usr/bin/env python3
import json
import sys
import subprocess
import os

try:
    input_data = json.load(sys.stdin)
except json.JSONDecodeError as e:
    print(f"Error: Invalid JSON input: {e}", file=sys.stderr)
    sys.exit(1)

tool_name = input_data.get("tool_name", "")
tool_input = input_data.get("tool_input", {})
tool_response = input_data.get("tool_response", {})
session_id = input_data.get("session_id", "")

# Get file path from tool input
file_path = tool_input.get("file_path", "")

if file_path and tool_response.get("success"):
    # Check if any tasks reference this file
    result = subprocess.run(
        ["./tm", "export", "--format", "json"],
        capture_output=True, text=True,
        cwd=input_data.get("cwd")
    )
    
    if result.returncode == 0:
        tasks = json.loads(result.stdout)
        
        # Find tasks that reference this file
        affected_tasks = []
        for task in tasks:
            if task.get('status') in ['pending', 'in_progress']:
                # Check file_refs
                for ref in task.get('file_refs', []):
                    if ref.get('file_path') == file_path:
                        affected_tasks.append(task)
                        break
        
        if affected_tasks:
            # Create notifications for affected tasks
            for task in affected_tasks:
                subprocess.run([
                    "./tm", "update", task['id'],
                    "--impact", f"File {file_path} modified by {session_id}"
                ], cwd=input_data.get("cwd"))
            
            # Provide feedback
            print(f"Notified {len(affected_tasks)} task(s) about changes to {file_path}")

sys.exit(0)
```

### 3. Session Start Context Loading

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/task-manager/hooks/load-context.py"
          }
        ]
      }
    ]
  }
}
```

**load-context.py:**
```python
#!/usr/bin/env python3
import json
import sys
import subprocess

try:
    input_data = json.load(sys.stdin)
except json.JSONDecodeError as e:
    print(f"Error: Invalid JSON input: {e}", file=sys.stderr)
    sys.exit(1)

source = input_data.get("source", "")
cwd = input_data.get("cwd", "")

# Get current task status
result = subprocess.run(
    ["./tm", "list"],
    capture_output=True, text=True,
    cwd=cwd
)

if result.returncode == 0:
    task_summary = result.stdout
    
    # Get notifications
    notif_result = subprocess.run(
        ["./tm", "watch"],
        capture_output=True, text=True,
        cwd=cwd
    )
    
    notifications = notif_result.stdout if notif_result.returncode == 0 else ""
    
    # Build context
    context = f"""
## Task Manager Status

### Current Tasks
{task_summary}

### Notifications
{notifications}

### Task Management Commands
- View task details: tm show <task_id>
- Update status: tm update <task_id> --status <status>
- Complete task: tm complete <task_id> --impact-review
- Add new task: tm add "description" [options]

Remember to track all significant work items using the task manager.
"""
    
    # Return context to be added to session
    output = {
        "hookSpecificOutput": {
            "hookEventName": "SessionStart",
            "additionalContext": context
        }
    }
    
    print(json.dumps(output))

sys.exit(0)
```

### 4. Stop Hook for Task Completion Check

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/task-manager/hooks/check-incomplete.py"
          }
        ]
      }
    ]
  }
}
```

**check-incomplete.py:**
```python
#!/usr/bin/env python3
import json
import sys
import subprocess

try:
    input_data = json.load(sys.stdin)
except json.JSONDecodeError as e:
    print(f"Error: Invalid JSON input: {e}", file=sys.stderr)
    sys.exit(1)

stop_hook_active = input_data.get("stop_hook_active", False)

# Don't create infinite loops
if stop_hook_active:
    sys.exit(0)

# Check for in-progress tasks
result = subprocess.run(
    ["./tm", "list", "--status", "in_progress"],
    capture_output=True, text=True,
    cwd=input_data.get("cwd")
)

if result.returncode == 0 and result.stdout.strip():
    # Found in-progress tasks
    tasks = result.stdout.strip()
    
    output = {
        "decision": "block",
        "reason": f"You have in-progress tasks that should be completed or updated:\n{tasks}\n\nPlease complete or update these tasks before stopping."
    }
    
    print(json.dumps(output))

sys.exit(0)
```

### 5. User Prompt Enhancement

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/task-manager/hooks/enhance-prompt.py"
          }
        ]
      }
    ]
  }
}
```

**enhance-prompt.py:**
```python
#!/usr/bin/env python3
import json
import sys
import subprocess
import re

try:
    input_data = json.load(sys.stdin)
except json.JSONDecodeError as e:
    print(f"Error: Invalid JSON input: {e}", file=sys.stderr)
    sys.exit(1)

prompt = input_data.get("prompt", "")
cwd = input_data.get("cwd", "")

# Check if prompt mentions task IDs
task_ids = re.findall(r'\b[a-f0-9]{8}\b', prompt)

if task_ids:
    # Get details for mentioned tasks
    task_details = []
    for task_id in task_ids:
        result = subprocess.run(
            ["./tm", "show", task_id],
            capture_output=True, text=True,
            cwd=cwd
        )
        if result.returncode == 0:
            task_details.append(result.stdout)
    
    if task_details:
        context = f"""
## Referenced Task Details
{"".join(task_details)}
"""
        output = {
            "hookSpecificOutput": {
                "hookEventName": "SessionStart",
                "additionalContext": context
            }
        }
        print(json.dumps(output))

# Check for task-related keywords
if any(keyword in prompt.lower() for keyword in ['task', 'todo', 'status', 'progress']):
    # Provide current task summary
    result = subprocess.run(
        ["./tm", "list"],
        capture_output=True, text=True,
        cwd=cwd
    )
    
    if result.returncode == 0:
        context = f"""
## Current Task Status
{result.stdout}

Use 'tm' commands to manage tasks throughout our conversation.
"""
        print(context)

sys.exit(0)
```

## Advanced Integration Patterns

### 1. Dependency-Aware Agent Launching

```python
#!/usr/bin/env python3
# dependency-launcher.py
import json
import subprocess
import sys

def get_ready_tasks():
    """Get all pending tasks with no blocking dependencies"""
    result = subprocess.run(
        ["./tm", "export", "--format", "json"],
        capture_output=True, text=True
    )
    
    if result.returncode != 0:
        return []
    
    tasks = json.loads(result.stdout)
    ready = []
    
    for task in tasks:
        if task['status'] == 'pending':
            # Check if all dependencies are completed
            deps_complete = True
            for dep_id in task.get('dependencies', []):
                dep_task = next((t for t in tasks if t['id'] == dep_id), None)
                if dep_task and dep_task['status'] != 'completed':
                    deps_complete = False
                    break
            
            if deps_complete:
                ready.append(task)
    
    return ready

# This would be called from a PreToolUse hook for Task
ready_tasks = get_ready_tasks()
if ready_tasks:
    # Inject available tasks into agent context
    task_list = "\n".join([f"- {t['id']}: {t['title']}" for t in ready_tasks])
    print(f"Available tasks to work on:\n{task_list}")
```

### 2. Automatic Task Creation from Errors

```python
#!/usr/bin/env python3
# error-to-task.py
import json
import sys
import subprocess
import re

try:
    input_data = json.load(sys.stdin)
except json.JSONDecodeError:
    sys.exit(1)

tool_name = input_data.get("tool_name", "")
tool_response = input_data.get("tool_response", {})

# Check for errors in tool responses
if not tool_response.get("success", True):
    error_msg = tool_response.get("error", "Unknown error")
    
    # Extract file information from error
    file_match = re.search(r'(?:file|path)[:\s]+([^\s]+)', error_msg, re.I)
    file_ref = file_match.group(1) if file_match else None
    
    # Create remediation task
    cmd = [
        "./tm", "add",
        f"Fix error: {error_msg[:50]}...",
        "-p", "high",
        "--tag", "error",
        "--tag", "auto-generated"
    ]
    
    if file_ref:
        cmd.extend(["--file", file_ref])
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    
    if result.returncode == 0:
        task_id = re.search(r'[a-f0-9]{8}', result.stdout)
        if task_id:
            print(f"Created error remediation task: {task_id.group()}")

sys.exit(0)
```

### 3. Intelligent Task Assignment

```python
#!/usr/bin/env python3
# smart-assign.py
import json
import subprocess

def get_agent_expertise(subagent_type):
    """Map agent types to their expertise areas"""
    expertise = {
        "general-purpose": ["research", "analysis", "documentation"],
        "code-writer": ["implementation", "refactoring", "optimization"],
        "test-runner": ["testing", "validation", "qa"],
        "debugger": ["debugging", "error-fixing", "troubleshooting"],
        "reviewer": ["review", "audit", "security"]
    }
    return expertise.get(subagent_type, [])

def assign_task_to_best_agent(task_id, task_title):
    """Assign task to most suitable agent type"""
    
    # Determine best agent type based on task title
    title_lower = task_title.lower()
    
    if any(word in title_lower for word in ['test', 'spec', 'validate']):
        agent_type = "test-runner"
    elif any(word in title_lower for word in ['debug', 'fix', 'error', 'bug']):
        agent_type = "debugger"
    elif any(word in title_lower for word in ['implement', 'create', 'build', 'add']):
        agent_type = "code-writer"
    elif any(word in title_lower for word in ['review', 'audit', 'check']):
        agent_type = "reviewer"
    else:
        agent_type = "general-purpose"
    
    # Assign task
    subprocess.run(["./tm", "assign", task_id, agent_type])
    
    return agent_type
```

## Complete Settings Configuration

Here's a complete `.claude/settings.json` configuration for full task manager integration:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/task-manager/hooks/load-context.py",
            "timeout": 5
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "TodoWrite",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/task-manager/hooks/enhance-prompt.py",
            "timeout": 5
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Task",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/task-manager/hooks/pre-task-hook.py",
            "timeout": 10
          }
        ]
      },
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/task-manager/hooks/validate-bash.py",
            "timeout": 5
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write|Edit|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/task-manager/hooks/track-file-changes.py",
            "timeout": 5
          }
        ]
      },
      {
        "matcher": "Task",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/task-manager/hooks/post-task-hook.py",
            "timeout": 5
          }
        ]
      }
    ],
    "SubagentStop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/task-manager/hooks/subagent-complete.py",
            "timeout": 10
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/task-manager/hooks/check-incomplete.py",
            "timeout": 5
          }
        ]
      }
    ],
    "Notification": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/task-manager/hooks/log-notification.py",
            "timeout": 2
          }
        ]
      }
    ]
  }
}
```

## Installation Script

```bash
#!/bin/bash
# install-hooks.sh

echo "Installing Task Manager Hooks for Claude Code"

# Create hooks directory
mkdir -p task-manager/hooks

# Make all hook scripts executable
chmod +x task-manager/hooks/*.py

# Create or update Claude settings
SETTINGS_FILE=".claude/settings.json"
mkdir -p .claude

if [ ! -f "$SETTINGS_FILE" ]; then
    echo "Creating new settings file..."
    cat > "$SETTINGS_FILE" << 'EOF'
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/task-manager/hooks/load-context.py"
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Task",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/task-manager/hooks/pre-task-hook.py"
          }
        ]
      }
    ]
  }
}
EOF
else
    echo "Settings file exists. Please manually add hooks configuration."
fi

echo "Installation complete!"
echo "Run 'claude' and use '/hooks' to verify installation"
```

## Benefits of Hook Integration

1. **Automatic Task Tracking**: Every Task tool invocation creates a tracked task
2. **Context Preservation**: Task details automatically injected into agent prompts
3. **Dependency Management**: Agents see only tasks they can work on
4. **Impact Analysis**: File changes trigger notifications to affected tasks
5. **Progress Monitoring**: Stop hooks ensure tasks are properly completed
6. **Error Recovery**: Failed operations automatically create remediation tasks
7. **Session Continuity**: Task status loaded at session start

## Usage Example

With hooks properly configured, Claude Code's workflow becomes:

```python
# User: "Refactor the authentication system"

# Claude Code automatically:
# 1. Creates main task via hook
# 2. When using Task tool, pre-hook creates tracked subtask
# 3. Agent receives task ID and instructions
# 4. File changes trigger impact notifications
# 5. Stop hook ensures all tasks are addressed
# 6. Next session loads current task status

# The user sees:
"I'll refactor the authentication system. Let me break this down into tasks..."
[Task 1a2b3c4d created and assigned to analyzer]
[Task 5e6f7g8h created with dependency on 1a2b3c4d]
"The analyzer is examining the current implementation..."
```

## Troubleshooting

1. **Hooks not firing**: Check `/hooks` in Claude Code
2. **Permission denied**: Ensure scripts are executable
3. **Task manager not found**: Use absolute paths or `$CLAUDE_PROJECT_DIR`
4. **JSON errors**: Validate hook output with `jq`
5. **Infinite loops**: Check `stop_hook_active` flag

## Conclusion

By integrating the task manager through Claude Code's hooks system, you achieve:
- Seamless multi-agent orchestration
- Automatic dependency resolution
- Complete task lifecycle management
- Zero manual intervention required
- Full visibility into parallel agent work

The hooks act as the nervous system connecting Claude Code's brain to the task manager's coordination capabilities.