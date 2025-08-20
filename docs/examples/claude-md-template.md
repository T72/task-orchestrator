# Task Orchestrator Instructions for CLAUDE.md

This template provides comprehensive Task Orchestrator integration with mandatory multi-agent communication protocols.

## 📋 **COPY THIS ENTIRE SECTION TO YOUR CLAUDE.md**

**Select everything from "START COPY" to "END COPY" and paste into your project's CLAUDE.md file:**

<!-- START COPY -->

## Task Orchestrator Integration

This project uses Task Orchestrator (`./tm`) for task management and multi-agent coordination.

### Essential Commands

```bash
./tm init                                    # Initialize (once per project)
./tm add "Task description" --priority high  # Create task
./tm list                                    # View tasks
./tm update <id> --status in_progress       # Start work
./tm complete <id>                          # Mark done
./tm watch                                  # Check notifications
```

### Workflow Example

```bash
# 1. Start a new feature
FEATURE=$(./tm add "Implement payment processing" --priority critical)

# 2. Break it down into subtasks
API=$(./tm add "Create payment API endpoints" --depends-on $FEATURE)
UI=$(./tm add "Build payment UI components" --depends-on $API)
TESTS=$(./tm add "Write payment tests" --depends-on $UI)

# 3. Track progress
./tm update $API --status in_progress
# ... do the work ...
./tm complete $API

# 4. Check what's next
./tm list --status pending
```

### MANDATORY: Multi-Agent Communication Protocol System (MACPS)

**CRITICAL**: All AI agents in this project MUST follow these communication protocols. No exceptions.

#### Agent Identification (REQUIRED)

Every agent MUST set unique identity before any work:

```bash
# MANDATORY: Set before any Task Orchestrator operations
export TM_AGENT_ID="[role]_[specialty]_[session]"

# Examples:
export TM_AGENT_ID="orchestrator_main_001"
export TM_AGENT_ID="specialist_database_001" 
export TM_AGENT_ID="specialist_frontend_002"
export TM_AGENT_ID="specialist_security_001"
```

#### Three-Channel Communication System (MANDATORY)

All agents MUST use all three channels appropriately:

**1. SHARED CONTEXT** (`./tm share`) - **PUBLIC COORDINATION**
- Task decisions and outcomes
- Handoff information for other agents
- Dependencies and blocking/unblocking notifications
- Artifacts and deliverables

```bash
# REQUIRED: Share all decisions and outcomes
./tm share $TASK_ID "Database schema completed: Users table with auth fields"
./tm share $TASK_ID "API endpoints ready: /auth/login, /auth/register, /auth/logout"
./tm share $TASK_ID "HANDOFF: Frontend team can now implement login UI"
```

**2. PRIVATE NOTES** (`./tm note`) - **INTERNAL REASONING**
- Exploration of different approaches
- Analysis of pros/cons
- Strategy planning and decision-making process
- Learning from failures

```bash
# Internal reasoning - NOT shared with other agents
./tm note $TASK_ID "Evaluating JWT vs session tokens. JWT better for stateless architecture."
./tm note $TASK_ID "Three implementation approaches identified. Going with option 2 for simplicity."
./tm note $TASK_ID "Failed attempt with approach A taught me X, Y, Z. Switching to approach B."
```

**3. COORDINATION SIGNALS** (`./tm discover`) - **CRITICAL ALERTS**
- Security issues affecting multiple agents
- Architecture changes impacting other work
- Blockers preventing progress
- Dependencies discovered

```bash
# CRITICAL: Broadcast to all agents immediately
./tm discover $TASK_ID "BLOCKING: Authentication system requires HTTPS certificate setup"
./tm discover $TASK_ID "SECURITY: Found vulnerability in password hashing - all agents pause auth work"
./tm discover $TASK_ID "ARCHITECTURE: Moving to microservices affects all database connections"
```

#### Communication Scenarios (MANDATORY PROTOCOLS)

**Scenario 1: Orchestrator → Specialist Agent**

```bash
# Orchestrator creates and assigns task
TASK_ID=$(./tm add "Implement user authentication system" --assignee database_specialist)

# Orchestrator provides complete context
./tm share $TASK_ID "CONTEXT: OAuth2 integration with Google/GitHub, session management, role-based permissions"
./tm share $TASK_ID "REQUIREMENTS: User table, session storage, audit logging"
./tm share $TASK_ID "DEADLINE: Complete by end of sprint for frontend team dependency"

# Specialist MUST acknowledge receipt
export TM_AGENT_ID="specialist_database_001"
./tm share $TASK_ID "ACKNOWLEDGED: Starting database schema design. ETA 2 hours."
```

**Scenario 2: Peer Agents on Same Task**

```bash
# Multiple agents working on same task MUST coordinate
export TM_AGENT_ID="specialist_frontend_001"
./tm share $TASK_ID "COORDINATION: Working on login form component"

export TM_AGENT_ID="specialist_backend_001" 
./tm share $TASK_ID "COORDINATION: Implementing login endpoint - will provide API contract in 30min"

# Conflict resolution
./tm discover $TASK_ID "CONFLICT: Both working on validation logic - frontend_001 take client-side, backend_001 take server-side"
```

**Scenario 3: Cross-Task Context Sharing**

```bash
# Agent working on Task A shares context affecting Task B
export TM_AGENT_ID="specialist_security_001"
./tm discover $TASK_B "CONTEXT: Auth system from Task A requires rate limiting - impacts your API design"
./tm share $TASK_B "CONTEXT: Security headers implemented: CORS, CSRF, CSP - ensure compatibility"
```

**Scenario 4: Dependency Coordination**

```bash
# Upstream agent notifies downstream agents
export TM_AGENT_ID="specialist_database_001"
./tm share $DATABASE_TASK "COMPLETED: User schema ready with fields: id, email, password_hash, role, created_at"
./tm discover $FRONTEND_TASK "DEPENDENCY RESOLVED: You can now implement user registration form"
./tm discover $BACKEND_TASK "DEPENDENCY RESOLVED: Database ready for authentication API implementation"
```

#### Mandatory Communication Checklist

Before ANY multi-agent interaction, verify:

- [ ] Agent identity set: `echo $TM_AGENT_ID`
- [ ] Task context understood: `./tm context $TASK_ID` 
- [ ] Dependencies checked: `./tm show $TASK_ID`
- [ ] Shared relevant decisions: `./tm share` used for public info
- [ ] Private reasoning documented: `./tm note` used for internal thoughts
- [ ] Critical issues broadcast: `./tm discover` used for alerts
- [ ] Other agents' context reviewed: `./tm context $RELATED_TASKS`

#### Response Time Requirements

**MANDATORY**: All agents must respond within these timeframes:

- **Acknowledgment**: 5 minutes of task assignment
- **Progress Update**: Every 30 minutes during active work  
- **Critical Alert Response**: 2 minutes for `./tm discover` messages
- **Handoff Completion**: 15 minutes for `./tm share` dependency notifications
- **Context Check**: Review `./tm context` every 20 minutes during work

#### Failure Recovery Protocols

**If agent doesn't respond in required time:**

```bash
# Escalation sequence
./tm discover $TASK_ID "ESCALATION: [agent_id] not responding - reassigning work"
./tm share $TASK_ID "CONTINGENCY: Switching to backup approach due to agent availability"
```

**If context is lost:**

```bash
# Recovery sequence
./tm context $TASK_ID     # Get full context history
./tm share $TASK_ID "RECOVERY: Reviewing context and resuming from checkpoint X"
```

#### Success Metrics

Monitor these metrics for each agent:
- **Response Time**: <5 minutes for acknowledgments
- **Context Accuracy**: 100% understanding of shared context
- **Communication Quality**: All updates contain actionable information
- **Dependency Coordination**: Zero missed handoffs or blockers

### Best Practices

1. **Create tasks for everything** - Even small items benefit from tracking
2. **Use clear, actionable titles** - "Fix login bug" not "bug"
3. **Set appropriate priorities** - critical > high > medium > low
4. **Update status regularly** - Keep the task list current
5. **Complete tasks when done** - This unblocks dependent tasks
6. **Use dependencies** - Link related tasks to maintain workflow
7. **Check notifications** - Run `./tm watch` to see unblocked tasks

### Working with Dependencies

```bash
# Tasks automatically block when dependencies exist
./tm add "Deploy to production" --depends-on task1 task2 task3

# View dependency chains
./tm list --has-deps

# Tasks automatically unblock when dependencies complete
./tm complete task1  # If this was the last dependency, dependent tasks unblock
```

### File References

Link tasks to specific code locations:

```bash
# Reference specific files and lines
./tm add "Fix type error" --file src/auth.ts:42
./tm add "Refactor validation" --file src/models/user.ts:100:150
```

### Export and Reporting

```bash
# Export task data for analysis
./tm export --format json > tasks.json
./tm export --format markdown > task-report.md
```

### Whitelisted Commands

Add to your Claude Code configuration:

```json
{
  "whitelisted_commands": [
    "./tm *"
  ]
}
```

<!-- END COPY -->

---

## What This Provides

When you add the above section to your CLAUDE.md, Claude Code will automatically:

1. **Use Task Orchestrator** for all task management
2. **Follow MACPS protocols** for multi-agent coordination
3. **Maintain proper communication** between AI agents
4. **Track dependencies** and coordinate workflows
5. **Provide real-time updates** on task progress
6. **Enable seamless handoffs** between specialist agents

## Additional Resources

- [Minimal Template](claude-md-minimal.md) - For quick essential setup
- [User Guide](../user-guide.md) - Complete usage documentation
- [Troubleshooting](../troubleshooting.md) - Common issues and solutions