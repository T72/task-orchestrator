# Claude Code Task Orchestrator Integration Guide

## Status: Example/Guide
- **Example/Guide**: Integration patterns and best practices for Claude Code users

## Last Verified: 2025-08-21
Against version: 2.3.0

## Overview
This guide provides patterns and strategies for integrating Task Orchestrator with Claude Code workflows to manage complex multi-step tasks effectively.

## Integration Patterns

### 1. Task Decomposition Strategy

When Claude Code receives a complex request, break it into manageable subtasks:

```bash
# Main task creation
MAIN_TASK=$(tm add "Refactor authentication system")
echo "Created main task: $MAIN_TASK"

# Create subtasks (manual dependency tracking for now)
ANALYZE=$(tm add "Analyze current auth implementation")
DESIGN=$(tm add "Design new auth architecture")
IMPLEMENT=$(tm add "Implement JWT tokens")
MIGRATE=$(tm add "Migrate database schema")
UPDATE=$(tm add "Update API endpoints")
TEST=$(tm add "Write tests")
DOCS=$(tm add "Update documentation")

# Note dependencies in shared context
tm share $MAIN_TASK "Subtasks created: analyze→design→implement→migrate/update→test→docs"
```

### 2. Multi-Agent Coordination

Use Task Orchestrator's collaboration features for multi-agent workflows:

```bash
# Agent 1: Database specialist
tm join $MIGRATE
tm update $MIGRATE --status in_progress
tm share $MIGRATE "Starting schema migration"
tm progress $MIGRATE "Created migration files"
tm complete $MIGRATE --summary "Schema migrated successfully"

# Agent 2: Backend developer
tm join $IMPLEMENT
tm watch  # Monitor for unblocked tasks
tm update $IMPLEMENT --status in_progress
tm share $IMPLEMENT "JWT implementation complete"

# Agent 3: Test specialist
tm join $TEST
tm note $TEST "Waiting for implementation to complete"
tm context $TEST  # View all shared updates
```

### 3. Progress Monitoring

Track task progress with visual indicators:

```bash
# Check overall status
tm list --format table

# Status indicators in Claude's responses:
# ✅ Completed tasks
# 🔄 In-progress tasks  
# ⏸️ Blocked/waiting tasks
# 📋 Pending tasks
```

### 4. Context Sharing

Share context between agents effectively:

```bash
# Share discoveries
tm share $TASK_ID "Found existing OAuth2 implementation we can reuse"

# Private notes for agent reasoning
tm note $TASK_ID "Consider rate limiting implications"

# Critical findings that alert all agents
tm share $TASK_ID "SECURITY: Found SQL injection vulnerability - fixing now"

# View all context
tm context $TASK_ID
```

### 5. Workflow Examples

#### Complex Refactoring
```bash
# 1. Orchestrator creates task structure
REFACTOR=$(tm add "Refactor payment system")

# 2. Analysis phase
ANALYSIS=$(tm add "Analyze payment dependencies")
tm update $ANALYSIS --assignee code_analyzer
tm share $ANALYSIS "Starting dependency analysis"

# 3. Implementation phase (after analysis)
IMPL=$(tm add "Implement new payment flow")
tm update $IMPL --assignee backend_dev

# 4. Testing phase
TEST=$(tm add "Test payment scenarios")
tm update $TEST --assignee test_specialist

# 5. Monitor progress
tm watch --limit 10
```

#### Parallel Development
```bash
# Create independent tasks that can run in parallel
UI=$(tm add "Build user interface")
API=$(tm add "Create API endpoints")
DB=$(tm add "Design database schema")

# Assign to different agents
tm update $UI --assignee frontend_dev
tm update $API --assignee backend_dev
tm update $DB --assignee database_specialist

# Each agent works independently
tm progress $UI "Component library selected"
tm progress $API "REST endpoints defined"
tm progress $DB "Schema normalized"

# Convergence point
INTEGRATE=$(tm add "Integrate UI with API")
tm share $INTEGRATE "Waiting for UI and API completion"
```

### 6. Error Handling

Handle failures gracefully:

```bash
# Mark task as blocked
tm update $TASK_ID --status blocked
tm share $TASK_ID "Blocked: Missing API credentials"

# Update when unblocked
tm update $TASK_ID --status in_progress
tm share $TASK_ID "Unblocked: Credentials received"

# Recovery from failure
tm share $TASK_ID "Build failed - investigating"
tm note $TASK_ID "Possible memory issue, trying with increased limits"
tm progress $TASK_ID "Retry with 4GB heap successful"
```

### 7. Best Practices

#### Task Granularity
- Create tasks that can be completed in 1-4 hours
- Each task should have a clear, testable outcome
- Avoid tasks that are too broad ("Build system") or too narrow ("Add semicolon")

#### Communication Patterns
- Use `share` for team-visible updates
- Use `note` for agent reasoning and thoughts
- Use `progress` for incremental updates
- Use `context` to catch up on task state

#### Dependency Management
- Currently, dependencies must be tracked manually in shared context
- Future versions will support `--depends-on` flag
- Document dependencies clearly in task descriptions

#### Agent Specialization
```bash
# Assign tasks based on agent expertise
tm update $DB_TASK --assignee database_specialist
tm update $UI_TASK --assignee frontend_specialist
tm update $TEST_TASK --assignee test_specialist
```

### 8. Advanced Patterns

#### Checkpoint Synchronization
```bash
# Create synchronization points
tm share $TASK "CHECKPOINT: Ready for integration testing"
tm share $TASK "CHECKPOINT: All unit tests passing"
```

#### Metrics and Reporting
```bash
# Track task metrics
tm list --status completed | wc -l  # Completed count
tm list --status in_progress  # Active work
tm export --format markdown > progress_report.md
```

#### Task Templates
```bash
# Create reusable task patterns
create_feature_tasks() {
    local FEATURE=$1
    local DESIGN=$(tm add "Design: $FEATURE")
    local IMPL=$(tm add "Implement: $FEATURE")
    local TEST=$(tm add "Test: $FEATURE")
    local DOC=$(tm add "Document: $FEATURE")
    
    echo "Created tasks for $FEATURE:"
    echo "  Design: $DESIGN"
    echo "  Implement: $IMPL"
    echo "  Test: $TEST"
    echo "  Document: $DOC"
}

# Use template
create_feature_tasks "User Authentication"
```

## Integration with Claude Code

### Workflow Integration

1. **Task Creation**: When Claude receives a complex request, immediately create tasks
2. **Progress Updates**: Use `tm progress` after each significant step
3. **Context Preservation**: Use `tm share` to maintain context between sessions
4. **Handoffs**: Use `tm note` to leave breadcrumbs for the next session

### Example Claude Code Session

```
User: "Build a REST API for user management"

Claude: I'll break this down into tasks and track our progress:

[Creates tasks using tm]
Main task created: abc12345

Subtasks:
- Design API schema: def67890
- Create database models: ghi12345
- Implement endpoints: jkl67890
- Add authentication: mno12345
- Write tests: pqr67890

Let me start with the API schema design...
[Uses tm progress and tm share throughout work]
```

## Troubleshooting

### Common Issues

**Tasks not showing up:**
- Ensure `tm init` has been run
- Check database location with `echo $TM_DB_PATH`

**Agent ID issues:**
- Set consistent agent ID: `export TM_AGENT_ID=claude_main`
- Each Claude instance should have unique ID

**Performance issues:**
- Use `tm list --limit 10` for large task lists
- Archive old tasks periodically

## Future Enhancements

These features are planned but not yet implemented:
- Direct dependency support (`--depends-on`)
- File reference tracking (`--file`)
- Automatic task routing based on expertise
- Real-time collaboration via watch mode
- Task templates and workflows

## Resources

- [API Reference](./api-reference.md) - Complete command documentation
- [Database Schema](./database-schema.md) - Storage architecture
- [Claude Hooks Integration Guide](./claude-hooks-integration-guide.md) - Hook-based automation

---

*Last Updated: 2025-08-21*
*Version: 2.3.0*
*This is a guide for integration patterns, not documentation of built-in features*