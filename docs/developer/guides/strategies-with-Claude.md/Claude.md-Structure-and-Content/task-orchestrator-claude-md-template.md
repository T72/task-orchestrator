# Task Orchestrator CLAUDE.md Template for New Projects

## Copy this section into your project's CLAUDE.md file

```markdown
## Task Orchestrator Integration (v2.5.1+)

### Installation & Setup

**Quick Install** (if not present):
```bash
# Download latest version
curl -o tm https://raw.githubusercontent.com/t72/task-orchestrator/main/tm
chmod +x tm
./tm --version  # Verify installation
```

**Project Structure**:
```
project-root/
├── tm                           # Task orchestrator executable
├── .task-orchestrator/          # Auto-created on first use
│   ├── tasks.db                # Task database (project-isolated)
│   ├── contexts/               # Shared team communication
│   └── notes/                  # Private agent reasoning
└── CLAUDE.md                    # This file
```

### Core Usage Patterns

#### Pattern 1: Single Task Workflow
```bash
# For simple, single-person tasks
TASK_ID=$(./tm add "Implement user authentication")
./tm update $TASK_ID --status in_progress
# ... do work ...
./tm complete $TASK_ID
```

#### Pattern 2: Multi-Agent Squadron Deployment
```bash
# MANDATORY for coordinating multiple AI agents
SQUAD_ID=$(./tm add "Squadron: Fix failing tests")
TASK_1=$(./tm add "Debug mock infrastructure" --depends-on $SQUAD_ID)
TASK_2=$(./tm add "Fix integration tests" --depends-on $SQUAD_ID)
TASK_3=$(./tm add "Optimize test performance" --depends-on $SQUAD_ID)

# Deploy agents with proper identification
# In each agent prompt, include:
export TM_AGENT_ID="debugger"  # Unique for each agent
./tm join $TASK_1
```

#### Pattern 3: Three-Channel Communication System

**Every deployed agent MUST use these three channels**:

1. **Private Notes** (internal reasoning):
```bash
export TM_AGENT_ID="optimizer"
./tm note $TASK_ID "Analyzing performance bottlenecks"
./tm note $TASK_ID "Found N+1 query pattern in service layer"
```

2. **Shared Updates** (team communication):
```bash
./tm share $TASK_ID "Identified root cause: Missing database index"
./tm share $TASK_ID "Fix applied: Added composite index on user_id, created_at"
```

3. **Critical Discoveries** (broadcast alerts):
```bash
./tm discover $TASK_ID "CRITICAL: Security vulnerability in auth flow"
./tm discover $TASK_ID "BREAKING: API contract change required"
```

### MANDATORY Agent Deployment Protocol

**Include this in EVERY agent prompt**:

```
MANDATORY Task Orchestrator Usage:
1. Set your agent ID: export TM_AGENT_ID='[agent_type]'
2. Join your task: ./tm join $[TASK_ID]
3. Private reasoning: ./tm note $[TASK_ID] 'internal thoughts'
4. Team updates: ./tm share $[TASK_ID] 'progress update'
5. Critical alerts: ./tm discover $[TASK_ID] 'CRITICAL: issue'
6. Before starting: ./tm context $[PARENT_TASK_ID]
7. Mark complete: ./tm complete $[TASK_ID]
```

### Common Commands Reference

```bash
# Task Management
./tm add "Task description"                    # Create task
./tm list                                      # View all tasks
./tm list --status in_progress                # Filter by status
./tm show [TASK_ID]                           # Task details
./tm update [TASK_ID] --status [STATUS]       # Update status
./tm complete [TASK_ID]                       # Mark complete
./tm delete [TASK_ID]                         # Remove task

# Dependencies
./tm add "Subtask" --depends-on [PARENT_ID]   # Create subtask
./tm list --depends-on [PARENT_ID]            # View subtasks

# Collaboration
./tm join [TASK_ID]                           # Agent joins task
./tm share [TASK_ID] "Update"                 # Share progress
./tm note [TASK_ID] "Private note"            # Private reasoning
./tm discover [TASK_ID] "Discovery"           # Broadcast finding
./tm context [TASK_ID]                        # View all context

# Export & Reports
./tm export                                   # Export all tasks
./tm export --format json                     # JSON export
```

### Troubleshooting Guide

| Issue | Solution |
|-------|----------|
| **"NOT NULL constraint failed: tasks.created_by"** | Upgrade to v2.5.1+ or set `export TM_AGENT_ID="agent"` |
| **"No such file or directory: ./tm"** | Ensure you're in project root: `cd [project-root]` |
| **"Database is locked"** | Kill zombie process: `ps aux \| grep tm` then `kill -9 [PID]` |
| **Agent updates not visible** | Verify agent set TM_AGENT_ID before operations |
| **Tasks disappear between sessions** | Check `.task-orchestrator/tasks.db` exists |

### Best Practices

1. **Always Set Agent ID**: Every AI agent must have unique TM_AGENT_ID
2. **Use Dependencies**: Create task hierarchies for complex work
3. **Regular Status Updates**: Keep tasks current with progress
4. **Complete Tasks Promptly**: Mark done immediately when finished
5. **Share Context**: Use `./tm share` for team visibility
6. **Document Discoveries**: Use `./tm discover` for important findings

### Success Metrics

Track these to ensure effective usage:
- Task completion rate: >80%
- Average task cycle time: <4 hours
- Orphaned tasks (no updates >24h): <10%
- Agent collaboration rate: >60% tasks have shared context

### Integration with LEAN Principles

Task Orchestrator supports LEAN by:
- **Eliminating Waste**: No duplicate work across agents
- **Visual Management**: Clear task status visibility
- **Flow Efficiency**: Dependencies ensure correct order
- **Continuous Improvement**: Historical data for analysis
```

## Additional Recommendations for New Projects

### 1. Project-Specific Customization

Add your project-specific patterns:
```markdown
### [Your Project] Specific Patterns

#### Pattern: [Your Common Workflow]
```bash
# Example: Deploy to staging
DEPLOY_ID=$(./tm add "Deploy v1.2.3 to staging")
TEST_ID=$(./tm add "Run staging tests" --depends-on $DEPLOY_ID)
SMOKE_ID=$(./tm add "Smoke test critical paths" --depends-on $TEST_ID)
```
```

### 2. Team Conventions

Define your team's conventions:
```markdown
### Team Task Naming Conventions

- Features: `feat: [description]`
- Bugs: `fix: [description]`
- Documentation: `docs: [description]`
- Refactoring: `refactor: [description]`
- Tests: `test: [description]`

Example: `./tm add "feat: Add user profile editing"`
```

### 3. Integration Points

Document integration with your tools:
```markdown
### CI/CD Integration

```yaml
# .github/workflows/ci.yml example
- name: Create deployment task
  run: |
    TASK_ID=$(./tm add "Deploy ${{ github.sha }}")
    echo "TASK_ID=$TASK_ID" >> $GITHUB_ENV
    
- name: Mark deployment complete
  if: success()
  run: ./tm complete ${{ env.TASK_ID }}
```
```

### 4. Monitoring & Alerts

Set up monitoring patterns:
```markdown
### Task Monitoring

**Daily Standup Query**:
```bash
# Tasks worked on yesterday
./tm list --updated-after yesterday --updated-before today

# Current in-progress tasks
./tm list --status in_progress

# Blocked tasks (no updates >24h)
./tm list --status in_progress --updated-before yesterday
```
```

### 5. Migration from Other Systems

If migrating from another task system:
```markdown
### Migration from [Previous System]

```bash
# Import tasks from JSON
./tm import --format json < old-tasks.json

# Bulk create from CSV
cat tasks.csv | while IFS=',' read -r title status; do
  TASK_ID=$(./tm add "$title")
  ./tm update $TASK_ID --status "$status"
done
```
```

## Quick Start Checklist for New Projects

- [ ] Copy the template section into your CLAUDE.md
- [ ] Install Task Orchestrator (`tm`) in project root
- [ ] Customize patterns for your workflow
- [ ] Define team naming conventions
- [ ] Set up CI/CD integration if applicable
- [ ] Create first task to verify setup: `./tm add "Setup complete"`
- [ ] Test three-channel communication if using AI agents
- [ ] Document any project-specific commands
- [ ] Train team on basic commands
- [ ] Schedule weekly task cleanup/review

## Expected Benefits

**Immediate**:
- Clear task visibility
- No lost work items
- Agent coordination

**Week 1**:
- 50% reduction in "what should I work on?" questions
- Complete audit trail of work
- Improved handoffs between team members

**Month 1**:
- Historical data for velocity tracking
- Pattern identification for common issues
- Reduced context switching overhead

## Common Pitfalls to Avoid

1. **Not setting TM_AGENT_ID**: Agents appear as anonymous
2. **Forgetting dependencies**: Work happens out of order
3. **Not completing tasks**: Cluttered task list
4. **Skipping context check**: Agents duplicate work
5. **Using test database**: Tasks don't persist

## Support Resources

- **Documentation**: [Task Orchestrator Docs](https://github.com/t72/task-orchestrator)
- **Issues**: [GitHub Issues](https://github.com/t72/task-orchestrator/issues)
- **Examples**: This template and production usage in RoleScoutPro-MVP

---

*This template provides comprehensive Task Orchestrator integration for optimal multi-agent coordination and task management in your project.*