# Claude Code Task Orchestrator Integration Guide

## Overview
This guide explains how Claude Code can leverage the task orchestrator (`tm`) to orchestrate multiple sub-agents efficiently when delegating complex tasks.

## Core Integration Pattern

When Claude Code receives a complex task, it should:
1. Break down the task into subtasks
2. Create tasks with dependencies in the task manager
3. Delegate subtasks to specialized agents
4. Monitor progress and handle completion

## Implementation Strategy

### 1. Task Decomposition Workflow

```python
# Example: Claude Code receives "Refactor authentication system"

# Main orchestrator creates task breakdown
tm add "Refactor authentication system" -p high
# Returns: main_task_id

# Create subtasks with dependencies
tm add "Analyze current auth implementation" --depends-on main_task_id --file src/auth/*.py
tm add "Design new auth architecture" --depends-on analyze_task_id
tm add "Implement JWT tokens" --depends-on design_task_id --file src/auth/jwt.py
tm add "Migrate database schema" --depends-on design_task_id --file migrations/
tm add "Update API endpoints" --depends-on jwt_task_id --file src/api/
tm add "Write tests" --depends-on api_task_id --file tests/
tm add "Update documentation" --depends-on test_task_id --file docs/
```

### 2. Agent Delegation Pattern

```bash
#!/bin/bash
# claude_orchestrator.sh

delegate_to_agent() {
    local TASK_ID=$1
    local AGENT_TYPE=$2
    local WORKTREE=$3
    
    # Assign task to agent
    tm assign $TASK_ID $AGENT_TYPE
    
    # Create agent instruction file
    cat > /tmp/agent_${TASK_ID}.json << EOF
{
    "task_id": "$TASK_ID",
    "agent_type": "$AGENT_TYPE",
    "worktree": "$WORKTREE",
    "instruction": "Check task manager for details: tm show $TASK_ID"
}
EOF
    
    # Launch agent (pseudo-code for actual Claude Code implementation)
    launch_agent --type $AGENT_TYPE --worktree $WORKTREE --task $TASK_ID
}
```

### 3. Progress Monitoring

```bash
#!/bin/bash
# monitor_progress.sh

monitor_delegated_tasks() {
    while true; do
        # Check for completed tasks
        COMPLETED=$(tm list --status completed | grep -c "●")
        PENDING=$(tm list --status pending | grep -c "○")
        IN_PROGRESS=$(tm list --status in_progress | grep -c "◐")
        BLOCKED=$(tm list --status blocked | grep -c "⊘")
        
        echo "Progress: Completed=$COMPLETED, Active=$IN_PROGRESS, Pending=$PENDING, Blocked=$BLOCKED"
        
        # Check for newly unblocked tasks
        tm watch | while read notification; do
            if [[ $notification == *"unblocked"* ]]; then
                TASK_ID=$(echo $notification | grep -o '[a-f0-9]\{8\}')
                echo "Task $TASK_ID unblocked - assigning to next available agent"
                delegate_next_available $TASK_ID
            fi
        done
        
        sleep 5
    done
}
```

## Claude Code Integration Points

### 1. Before Delegating Tasks

```python
def prepare_delegation(main_task_description):
    """Claude Code should call this before using Task tool"""
    
    # Initialize task manager if needed
    subprocess.run(["./tm", "init"])
    
    # Create main task
    result = subprocess.run(
        ["./tm", "add", main_task_description, "-p", "high"],
        capture_output=True, text=True
    )
    main_task_id = extract_task_id(result.stdout)
    
    # Analyze task complexity
    subtasks = analyze_and_decompose(main_task_description)
    
    # Create dependency graph
    task_graph = {}
    for subtask in subtasks:
        task_id = create_subtask(subtask, dependencies=subtask.deps)
        task_graph[task_id] = {
            'description': subtask.description,
            'agent_type': determine_agent_type(subtask),
            'files': subtask.file_refs
        }
    
    return task_graph
```

### 2. When Using Task Tool

```python
def enhanced_task_tool_wrapper(description, prompt, subagent_type):
    """Wrapper around Claude's Task tool with task manager integration"""
    
    # Create task in task manager
    task_id = subprocess.run(
        ["./tm", "add", description, "--tag", subagent_type],
        capture_output=True, text=True
    ).stdout.strip()
    
    # Update task to in_progress
    subprocess.run(["./tm", "update", task_id, "--status", "in_progress"])
    
    # Add task ID to agent prompt
    enhanced_prompt = f"""
    TASK_ID: {task_id}
    
    {prompt}
    
    IMPORTANT: 
    - When starting, run: tm show {task_id}
    - Check for dependencies: tm show {task_id} | grep Dependencies
    - When complete, run: tm complete {task_id} --impact-review
    - If blocked, run: tm update {task_id} --status blocked --impact "reason"
    """
    
    # Call original Task tool
    result = Task(
        description=description,
        prompt=enhanced_prompt,
        subagent_type=subagent_type
    )
    
    return result
```

### 3. Handling Agent Responses

```python
def process_agent_completion(agent_response, task_id):
    """Process agent response and update task manager"""
    
    if "successfully completed" in agent_response.lower():
        # Mark task as complete
        subprocess.run(["./tm", "complete", task_id, "--impact-review"])
        
        # Check for newly unblocked tasks
        notifications = subprocess.run(
            ["./tm", "watch"],
            capture_output=True, text=True
        ).stdout
        
        # Process unblocked tasks
        for line in notifications.split('\n'):
            if 'unblocked' in line:
                unblocked_task = extract_task_id(line)
                delegate_to_next_agent(unblocked_task)
    
    elif "blocked" in agent_response.lower():
        # Update status to blocked
        reason = extract_blocking_reason(agent_response)
        subprocess.run([
            "./tm", "update", task_id, 
            "--status", "blocked",
            "--impact", reason
        ])
    
    elif "error" in agent_response.lower():
        # Mark as cancelled and create new remediation task
        subprocess.run(["./tm", "update", task_id, "--status", "cancelled"])
        create_remediation_task(task_id, agent_response)
```

## Practical Examples

### Example 1: Complex Refactoring

```python
# Claude Code receives: "Refactor the entire authentication system to use OAuth2"

# Step 1: Create task hierarchy
main = tm("add", "Refactor auth to OAuth2", priority="high")
analyze = tm("add", "Analyze current auth", depends_on=main, file="src/auth/**")
design = tm("add", "Design OAuth2 flow", depends_on=analyze)
backend = tm("add", "Implement OAuth2 backend", depends_on=design, file="src/auth/oauth.py")
frontend = tm("add", "Update frontend auth", depends_on=design, file="src/ui/auth/**")
migrate = tm("add", "Migrate user data", depends_on=backend, file="migrations/")
test = tm("add", "Test OAuth2 flow", depends_on=[backend, frontend])

# Step 2: Delegate to specialized agents
Task("Analyze auth code", "Review current authentication...", "code-analyzer")
# Agent will see task is blocked until main task completes

# Step 3: Monitor and coordinate
while not all_tasks_complete():
    check_and_delegate_unblocked_tasks()
    handle_blocked_tasks()
    process_notifications()
```

### Example 2: Parallel Testing

```python
# Claude Code needs to run tests across multiple components

# Create parallel test tasks (no dependencies between them)
ui_tests = tm("add", "Run UI tests", file="tests/ui/**", priority="high")
api_tests = tm("add", "Run API tests", file="tests/api/**", priority="high")
db_tests = tm("add", "Run database tests", file="tests/db/**", priority="high")
integration = tm("add", "Run integration tests", 
               depends_on=[ui_tests, api_tests, db_tests])

# Launch parallel agents
for task_id in [ui_tests, api_tests, db_tests]:
    Task(
        description=f"Run tests for {task_id}",
        prompt=f"Execute tests and report results for task {task_id}",
        subagent_type="test-runner"
    )

# Integration tests automatically unblock when all unit tests complete
```

### Example 3: Handling Failures

```python
def handle_agent_failure(task_id, error_message):
    """When an agent fails, create remediation tasks"""
    
    # Mark original task as cancelled
    tm("update", task_id, status="cancelled", impact=error_message)
    
    # Create investigation task
    investigate = tm("add", 
        f"Investigate failure: {error_message[:50]}",
        priority="critical",
        file=get_error_location(error_message)
    )
    
    # Create retry task dependent on investigation
    retry = tm("add",
        f"Retry task {task_id} after fix",
        depends_on=investigate,
        priority="high"
    )
    
    # Delegate investigation to specialized debugger agent
    Task(
        description="Debug and fix error",
        prompt=f"Investigate task {investigate} failure: {error_message}",
        subagent_type="debugger"
    )
```

## Best Practices

### 1. Task Granularity
```python
# Good: Specific, measurable tasks
tm("add", "Implement user login endpoint", file="src/api/auth.py:45-120")

# Bad: Too vague
tm("add", "Fix authentication")
```

### 2. Dependency Management
```python
# Create logical dependency chains
auth = tm("add", "Implement authentication")
author = tm("add", "Add authorization", depends_on=auth)  # Can't authorize without auth
audit = tm("add", "Add audit logging", depends_on=author)  # Log after authorization

# Avoid over-constraining
# Bad: Making everything depend on everything
# Good: Only real dependencies
```

### 3. File Reference Tracking
```python
# Always include file references for better context
task_id = tm("add", 
    "Fix type error in user model",
    file="src/models/user.py:42",
    priority="high"
)

# This helps agents find exactly what to work on
```

### 4. Impact Analysis
```python
# Always use --impact-review for structural changes
tm("complete", task_id, impact_review=True)

# This notifies other agents whose tasks might be affected
```

### 5. Agent Communication
```python
# Use impact notes for cross-agent communication
tm("update", task_id, 
   impact="Changed API response format - update clients")
```

## Monitoring Dashboard

```bash
#!/bin/bash
# dashboard.sh - Real-time task monitoring

show_dashboard() {
    clear
    echo "=== Claude Code Task Dashboard ==="
    echo ""
    
    # Summary stats
    echo "📊 Summary"
    echo "  Completed: $(tm list --status completed | grep -c '●')"
    echo "  Active:    $(tm list --status in_progress | grep -c '◐')"
    echo "  Pending:   $(tm list --status pending | grep -c '○')"
    echo "  Blocked:   $(tm list --status blocked | grep -c '⊘')"
    echo ""
    
    # Active tasks
    echo "🔄 In Progress"
    tm list --status in_progress | head -5
    echo ""
    
    # Blocked tasks
    echo "⛔ Blocked Tasks"
    tm list --status blocked | head -5
    echo ""
    
    # Recent completions
    echo "✅ Recently Completed"
    tm list --status completed | head -3
    echo ""
    
    # Notifications
    echo "🔔 Notifications"
    tm watch
}

# Update every 5 seconds
while true; do
    show_dashboard
    sleep 5
done
```

## Error Recovery

```python
def recover_from_task_failure(task_id):
    """Sophisticated error recovery mechanism"""
    
    # Get task details
    task_info = tm_show(task_id)
    
    # Analyze failure type
    if "dependency" in task_info.get('impact_notes', ''):
        # Dependency issue - check if dependencies are really complete
        for dep in task_info['dependencies']:
            if not is_really_complete(dep):
                tm("update", dep, status="pending")
                return delegate_to_agent(dep, "verifier")
    
    elif "conflict" in task_info.get('impact_notes', ''):
        # Merge conflict - create resolution task
        resolution = tm("add", 
            f"Resolve conflicts for {task_id}",
            priority="critical",
            file=task_info['file_refs']
        )
        return delegate_to_agent(resolution, "conflict-resolver")
    
    else:
        # Unknown failure - escalate
        escalation = tm("add",
            f"Manual review needed: {task_id}",
            priority="critical"
        )
        notify_human_operator(escalation)
```

## Performance Optimization

```python
def optimize_task_delegation():
    """Optimize which agents get which tasks"""
    
    # Get all pending tasks
    pending = tm_list(status="pending")
    
    # Group by file locality
    tasks_by_area = {}
    for task in pending:
        area = extract_code_area(task['file_refs'])
        tasks_by_area.setdefault(area, []).append(task)
    
    # Assign tasks to agents with context
    for area, tasks in tasks_by_area.items():
        # Same agent handles related tasks for better context
        agent = get_or_create_agent_for_area(area)
        for task in tasks:
            tm("assign", task['id'], agent)
```

## Conclusion

By integrating the task manager into Claude Code's orchestration workflow:

1. **Better Coordination**: Dependencies ensure correct execution order
2. **Improved Visibility**: Real-time progress tracking across all agents
3. **Automatic Recovery**: Failed tasks can be retried or escalated
4. **Context Preservation**: File references and impact notes maintain context
5. **Efficient Delegation**: Tasks automatically unblock and get assigned
6. **Reduced Conflicts**: Impact analysis prevents agents from interfering

The task manager acts as a central nervous system for Claude Code's multi-agent orchestration, ensuring smooth coordination even with dozens of parallel agents working on complex projects.