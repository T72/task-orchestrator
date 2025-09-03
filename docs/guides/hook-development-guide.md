# Hook Development Guide

**A practical guide to building robust hooks for Task Orchestrator and Claude Code**

## Overview

This guide teaches you how to build hooks that work reliably with both Claude Code's TodoWrite tool and Task Orchestrator's event system. Follow these patterns to avoid the most common pitfalls and ensure your hooks handle all input variations gracefully.

## Quick Start

### Minimal Hook Template

```python
#!/usr/bin/env python3
"""Minimal robust hook template"""
import json
import sys

def process_event(event):
    """Process incoming event with defensive programming"""
    # Check if this hook should handle this event
    if event.get("tool_name") != "TodoWrite":
        return {"decision": "approve"}
    
    # Safely extract todos with defaults
    todos = event.get("tool_input", {}).get("todos", [])
    
    # Process each todo safely
    for i, todo in enumerate(todos):
        # Handle variable structures
        task_id = todo.get("id", f"task_{i}")
        content = todo.get("content", "")
        status = todo.get("status", "pending")
        metadata = todo.get("metadata", {})
        
        # Your hook logic here
        if status == "completed":
            print(f"Task {task_id} completed: {content}", file=sys.stderr)
    
    return {"decision": "approve"}

if __name__ == "__main__":
    try:
        event = json.load(sys.stdin)
        result = process_event(event)
        print(json.dumps(result))
    except Exception as e:
        # Never crash - always return valid response
        print(json.dumps({"decision": "approve", "error": str(e)}))
```

## Core Principles

### 1. Never Assume Structure

❌ **Bad: Assumes fields exist**
```python
task_id = todo["id"]  # KeyError if no id!
metadata = todo["metadata"]["progress"]  # Nested KeyError!
```

✅ **Good: Defensive access**
```python
task_id = todo.get("id", f"task_{index}")  # Fallback to generated ID
progress = todo.get("metadata", {}).get("progress", "")  # Safe nested access
```

### 2. Handle All Input Variations

Your hook will receive different structures:

```python
# Minimal (Claude Code TodoWrite)
{"content": "Task description", "status": "pending"}

# Standard (with ID)
{"id": "task_001", "content": "Task", "status": "pending"}

# Extended (with metadata)
{"id": "task_001", "content": "Task", "status": "pending", 
 "metadata": {"phase": 1, "specialist": "backend"}}

# Malformed (missing fields)
{}  # Yes, this can happen!
```

### 3. Always Return Valid JSON

```python
# Every path must return valid response
if error_condition:
    return {"decision": "block", "reason": "Invalid input"}
else:
    return {"decision": "approve"}
```

### 4. Add Timeout Protection

```python
import signal

def timeout_handler(signum, frame):
    raise TimeoutError("Hook execution timeout")

# Set 5-second timeout
signal.signal(signal.SIGALRM, timeout_handler)
signal.alarm(5)

try:
    # Your hook logic
    result = process_event(event)
finally:
    signal.alarm(0)  # Cancel timeout
```

## Common Patterns

### Pattern 1: Task Status Change Detection

```python
def detect_status_changes(event):
    """Detect and react to status changes"""
    if event.get("tool_name") != "TodoWrite":
        return {"decision": "approve"}
    
    todos = event.get("tool_input", {}).get("todos", [])
    
    for i, todo in enumerate(todos):
        task_id = todo.get("id", f"task_{i}")
        status = todo.get("status", "pending")
        
        if status == "completed":
            trigger_completion_actions(task_id)
        elif status == "blocked":
            notify_blocker(task_id)
        elif status == "in_progress":
            create_checkpoint(task_id)
    
    return {"decision": "approve"}
```

### Pattern 2: Dependency Management

```python
def check_dependencies(event):
    """Validate dependencies before allowing changes"""
    todos = event.get("tool_input", {}).get("todos", [])
    
    for todo in todos:
        if todo.get("status") == "in_progress":
            deps = todo.get("metadata", {}).get("depends_on", [])
            
            for dep_id in deps:
                if not is_completed(dep_id):
                    return {
                        "decision": "block",
                        "reason": f"Dependency {dep_id} not completed"
                    }
    
    return {"decision": "approve"}
```

### Pattern 3: Event Broadcasting

```python
def broadcast_events(event):
    """Convert todo changes into system events"""
    todos = event.get("tool_input", {}).get("todos", [])
    events_to_emit = []
    
    for todo in todos:
        if todo.get("status") == "completed":
            events_to_emit.append({
                "type": "task_completed",
                "task_id": todo.get("id", "unknown"),
                "timestamp": time.time()
            })
    
    # Write events to event bus
    if events_to_emit:
        with open(".claude/events/queue.json", "a") as f:
            for evt in events_to_emit:
                f.write(json.dumps(evt) + "\n")
    
    return {"decision": "approve"}
```

## Testing Your Hooks

### 1. Structure Variation Tests

```bash
# Test with minimal structure
echo '{"tool_name":"TodoWrite","tool_input":{"todos":[{"content":"Test","status":"pending"}]}}' | python3 your_hook.py

# Test with extended structure  
echo '{"tool_name":"TodoWrite","tool_input":{"todos":[{"id":"123","content":"Test","status":"pending","metadata":{"key":"value"}}]}}' | python3 your_hook.py

# Test with empty input
echo '{"tool_name":"TodoWrite","tool_input":{"todos":[]}}' | python3 your_hook.py

# Test with malformed input
echo '{"tool_name":"TodoWrite","tool_input":{"todos":[{}]}}' | python3 your_hook.py
```

### 2. Performance Test

```bash
# Measure execution time
time echo '{"tool_name":"TodoWrite","tool_input":{"todos":[{"content":"Test","status":"pending"}]}}' | python3 your_hook.py

# Should complete in <100ms
```

### 3. Automated Test Suite

```python
#!/usr/bin/env python3
"""Test suite for hooks"""
import subprocess
import json
import time

def test_hook(hook_path, test_cases):
    """Test a hook with various inputs"""
    results = []
    
    for name, test_input in test_cases:
        start = time.time()
        try:
            proc = subprocess.run(
                ["python3", hook_path],
                input=json.dumps(test_input),
                capture_output=True,
                text=True,
                timeout=5
            )
            duration = time.time() - start
            
            output = json.loads(proc.stdout)
            results.append({
                "test": name,
                "passed": "decision" in output,
                "duration": duration
            })
        except Exception as e:
            results.append({
                "test": name,
                "passed": False,
                "error": str(e)
            })
    
    return results

# Define test cases
test_cases = [
    ("minimal", {"tool_name": "TodoWrite", "tool_input": {"todos": [{"content": "Test", "status": "pending"}]}}),
    ("extended", {"tool_name": "TodoWrite", "tool_input": {"todos": [{"id": "123", "content": "Test", "status": "pending", "metadata": {}}]}}),
    ("empty", {"tool_name": "TodoWrite", "tool_input": {"todos": []}}),
    ("malformed", {"tool_name": "TodoWrite", "tool_input": {"todos": [{}]}})
]

# Run tests
results = test_hook("your_hook.py", test_cases)
for r in results:
    status = "✓" if r["passed"] else "✗"
    print(f"{status} {r['test']}: {r.get('duration', 'N/A'):.3f}s")
```

## Debugging Guide

### Common Issues and Solutions

#### Issue 1: KeyError on missing fields
**Symptom**: `KeyError: 'id'`  
**Solution**: Use `.get()` with defaults
```python
# Bad
task_id = todo["id"]

# Good  
task_id = todo.get("id", f"task_{index}")
```

#### Issue 2: Hook hanging
**Symptom**: Hook never returns  
**Solution**: Add timeout protection
```python
import signal
signal.alarm(5)  # 5-second timeout
```

#### Issue 3: Silent failures
**Symptom**: Hook fails but returns nothing  
**Solution**: Always return valid JSON
```python
try:
    # Hook logic
except Exception as e:
    return {"decision": "approve", "error": str(e)}
```

### Debug Mode

Enable debug logging:
```python
import os
import sys

DEBUG = os.environ.get("HOOK_DEBUG") == "1"

def debug_log(msg):
    if DEBUG:
        print(f"[DEBUG] {msg}", file=sys.stderr)

# Usage
debug_log(f"Processing {len(todos)} todos")
```

Run with debug enabled:
```bash
HOOK_DEBUG=1 echo '{"tool_name":"TodoWrite","tool_input":{"todos":[]}}' | python3 your_hook.py
```

## Integration Examples

### Example 1: Checkpoint System

```python
#!/usr/bin/env python3
"""Auto-checkpoint on task progress"""
import json
import sys
import time
from pathlib import Path

CHECKPOINT_DIR = Path(".claude/checkpoints")

def save_checkpoint(task_id, state):
    """Save task state for recovery"""
    CHECKPOINT_DIR.mkdir(parents=True, exist_ok=True)
    
    checkpoint = {
        "task_id": task_id,
        "timestamp": time.time(),
        "state": state,
        "resumable": True
    }
    
    checkpoint_file = CHECKPOINT_DIR / f"{task_id}.json"
    checkpoint_file.write_text(json.dumps(checkpoint, indent=2))

def process_event(event):
    if event.get("tool_name") != "TodoWrite":
        return {"decision": "approve"}
    
    todos = event.get("tool_input", {}).get("todos", [])
    
    for i, todo in enumerate(todos):
        if todo.get("status") == "in_progress":
            task_id = todo.get("id", f"task_{i}")
            state = {
                "content": todo.get("content", ""),
                "progress": todo.get("metadata", {}).get("progress", ""),
                "artifacts": todo.get("metadata", {}).get("artifacts", [])
            }
            save_checkpoint(task_id, state)
    
    return {"decision": "approve"}

if __name__ == "__main__":
    try:
        event = json.load(sys.stdin)
        print(json.dumps(process_event(event)))
    except Exception as e:
        print(json.dumps({"decision": "approve", "error": str(e)}))
```

### Example 2: Dependency Validator

```python
#!/usr/bin/env python3
"""Validate task dependencies before execution"""
import json
import sys
import sqlite3

def get_task_status(task_id):
    """Check task status from database"""
    try:
        conn = sqlite3.connect(".task-orchestrator/tasks.db")
        cursor = conn.cursor()
        cursor.execute("SELECT status FROM tasks WHERE id = ?", (task_id,))
        result = cursor.fetchone()
        conn.close()
        return result[0] if result else None
    except:
        return None

def process_event(event):
    if event.get("tool_name") != "TodoWrite":
        return {"decision": "approve"}
    
    todos = event.get("tool_input", {}).get("todos", [])
    
    for todo in todos:
        # Check if trying to start a task
        if todo.get("status") == "in_progress":
            deps = todo.get("metadata", {}).get("depends_on", [])
            
            # Validate all dependencies are completed
            for dep_id in deps:
                dep_status = get_task_status(dep_id)
                if dep_status != "completed":
                    return {
                        "decision": "block",
                        "reason": f"Cannot start: dependency {dep_id} is {dep_status}"
                    }
    
    return {"decision": "approve"}

if __name__ == "__main__":
    try:
        event = json.load(sys.stdin)
        print(json.dumps(process_event(event)))
    except Exception as e:
        print(json.dumps({"decision": "approve", "error": str(e)}))
```

## Best Practices Checklist

Before deploying any hook:

- [ ] **Structure Handling**
  - [ ] Uses `.get()` for all field access
  - [ ] Provides sensible defaults
  - [ ] Handles empty/malformed input

- [ ] **Error Handling**
  - [ ] Never crashes (try/except wrapper)
  - [ ] Always returns valid JSON
  - [ ] Logs errors for debugging

- [ ] **Performance**
  - [ ] Completes in <100ms
  - [ ] Has timeout protection
  - [ ] Minimizes I/O operations

- [ ] **Testing**
  - [ ] Tested with minimal structure
  - [ ] Tested with extended structure
  - [ ] Tested with malformed input
  - [ ] Tested with actual runtime data

- [ ] **Documentation**
  - [ ] Purpose clearly stated
  - [ ] Input/output documented
  - [ ] Failure modes described

## Troubleshooting

### Hook Not Triggering
1. Check hook file permissions: `chmod +x hook.py`
2. Verify shebang line: `#!/usr/bin/env python3`
3. Check registration in `.claude/hooks/`
4. Ensure returns valid JSON

### Performance Issues
1. Profile with `cProfile`
2. Cache frequently accessed data
3. Use async I/O for external calls
4. Batch database operations

### State Synchronization
1. Use file locks for concurrent access
2. Implement idempotent operations
3. Add versioning to state files
4. Use atomic file operations

## Resources

- [Hook Robustness Implementation Report](../reference/hook-robustness-implementation.md)
- [Test Suite](../../tests/test_hook_robustness.sh)
- [Example Hooks](../../.claude/hooks/)
- [CLAUDE.md Standards](../../CLAUDE.md#hook-development-standards)

---

*Last Updated: August 21, 2025*  
*Version: 1.0.0*