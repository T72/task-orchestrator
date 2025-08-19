# CLAUDE.md - Task Orchestrator Integration Example

This example demonstrates how to integrate Task Orchestrator as the default agent communication system in your Claude Code project.

## ⚠️ PROTECTED CONTENT NOTICE

[Your project-specific protected rules would go here...]

## 🎯 ABSOLUTE TOP PRIORITY

[Your project priorities and principles would go here...]

## Key Points I Should Always Remember

[Your first 10 project-specific rules would go here...]

### 11. **[RECOMMENDED] THREE-CHANNEL TASK ORCHESTRATOR COMMUNICATION**

**MANDATORY**: ALL agent communication MUST use the Task Orchestrator (`./tm`) three-channel system. Every deployed agent MUST:

1. Set their agent ID via `export TM_AGENT_ID="agent_name"`
2. Use `./tm note` for private reasoning
3. Use `./tm share` for team updates  
4. Use `./tm discover` for critical alerts
5. Check context via `./tm context $TASK_ID` before starting work

This is the DEFAULT and ONLY approved inter-agent communication method. Agents working without task orchestrator coordination are operating blind and creating waste.

**⚠️ CRITICAL**: This rule ensures coordinated multi-agent collaboration with full context awareness and progress tracking.

## Critical Rules - NEVER FORGET

[Your first 13 critical rules would go here...]

### 14. **[RECOMMENDED] TASK ORCHESTRATOR AGENT DEPLOYMENT PROTOCOL**

**MANDATORY implementation sequence for ALL agent deployments:**

```bash
# BEFORE deploying ANY agent:
cd {{PROJECT_PATH}}
PARENT_TASK=$(./tm add "Main objective description")
AGENT_TASK=$(./tm add "Agent-specific work" --depends-on $PARENT_TASK)

# IN agent prompt, ALWAYS include:
"MANDATORY: Use Task Orchestrator for all communication:
1. Set your ID: export TM_AGENT_ID='your_agent_type'
2. Join task: ./tm join $AGENT_TASK
3. Private notes: ./tm note $AGENT_TASK 'internal reasoning'
4. Share updates: ./tm share $AGENT_TASK 'team update'
5. Critical alerts: ./tm discover $AGENT_TASK 'CRITICAL: finding'
6. Check context: ./tm context $PARENT_TASK before starting"

# AFTER agent completes:
./tm show $AGENT_TASK  # Verify completion
./tm context $AGENT_TASK  # Review shared updates
```

**Agents deployed WITHOUT task orchestrator are operating blind and violating core protocols.**

[Your remaining critical rules would go here...]

## Task Orchestrator for Multi-Agent Coordination

### When to Use Task Orchestrator

**MANDATORY**: Use task-orchestrator when deploying Parallel Agent Squadron or coordinating multiple agents:

1. **Before Squadron Deployment**: Create tasks for each agent's work
2. **During Agent Work**: Track progress and dependencies
3. **After Agent Completion**: Mark tasks complete and verify results

### Task Orchestrator Workflow for Agent Coordination

```bash
# 1. Create main epic for Squadron mission
cd {{PROJECT_PATH}}
EPIC=$(./tm add "Fix integration test failures via Parallel Squadron")

# 2. Create tasks for each agent (with dependencies if needed)
DEBUG_TASK=$(./tm add "Debug mock infrastructure issues" --depends-on $EPIC)
OPTIMIZE_TASK=$(./tm add "Optimize test execution and eliminate waste" --depends-on $EPIC)
MIGRATE_TASK=$(./tm add "Fix database mock alignment" --depends-on $EPIC)
DOMAIN_TASK=$(./tm add "Fix domain-specific tests" --depends-on $EPIC)

# 3. Update status as agents work
./tm update $DEBUG_TASK --status in_progress
./tm update $OPTIMIZE_TASK --status in_progress

# 4. Mark complete when agents finish
./tm complete $DEBUG_TASK
./tm list --depends-on $EPIC  # See overall progress
```

### Three-Channel Communication System for Agents

**CRITICAL**: Each deployed agent has THREE communication channels when working on tasks:

#### 1. Private Notes (Internal Reasoning)

```bash
# Agent's private thoughts - NOT shared with other agents
export TM_AGENT_ID="debugger_agent"
./tm note $TASK_ID "Considering stateful vs stateless mock approach"
./tm note $TASK_ID "Root cause likely in method chaining implementation"
# Stored in: .task-orchestrator/notes/notes_[task_id]_[agent_id].md
```

#### 2. Shared Updates (Team Communication)

```bash
# Share progress with all agents working on related tasks
export TM_AGENT_ID="debugger_agent"
./tm share $TASK_ID "Found root cause: Static mocks incompatible with integration tests"
./tm share $TASK_ID "Creating stateful query builder solution"
# Visible to ALL agents via: ./tm context $TASK_ID
```

#### 3. Critical Discoveries (Broadcast Alerts)

```bash
# Broadcast critical findings to entire Squadron
export TM_AGENT_ID="migration_guardian"
./tm discover $TASK_ID "CRITICAL: Mock infrastructure requires complete refactor"
./tm discover $TASK_ID "WARNING: 500+ tests affected by this change"
# Immediately visible to all agents monitoring the epic
```

### How Agents Access Shared Context

```bash
# Any agent can check shared context from other agents
export TM_AGENT_ID="test_optimizer"
./tm context $DEBUG_TASK  # See all shared updates from debugger
./tm context $EPIC        # See all discoveries across Squadron

# Monitor for real-time updates
./tm watch               # See live updates from all agents
```

### Agent Communication Best Practices

1. **Use Private Notes for**:
   - Exploration and experimentation
   - Internal reasoning and hypothesis
   - Failed approaches (for learning)
   - Strategy planning

2. **Use Shared Updates for**:
   - Progress milestones
   - Completed solutions
   - Dependencies for other agents
   - Coordination points

3. **Use Discoveries for**:
   - Critical blockers
   - Security issues
   - Performance problems
   - Architecture changes affecting multiple agents

### Example: Multi-Agent Collaboration Flow

```bash
# === DEBUGGER AGENT ===
export TM_AGENT_ID="debugger"
./tm join $DEBUG_TASK
./tm note $DEBUG_TASK "Analyzing mock infrastructure patterns"
./tm note $DEBUG_TASK "Found 3 potential root causes"
./tm share $DEBUG_TASK "Root cause identified: Static mock state management"
./tm discover $DEBUG_TASK "BREAKING: Need to refactor all integration test mocks"

# === TEST OPTIMIZER (sees debugger's discovery) ===
export TM_AGENT_ID="test_optimizer"
./tm context $DEBUG_TASK  # Reads debugger's shared updates
./tm join $OPTIMIZE_TASK
./tm note $OPTIMIZE_TASK "Adjusting optimization based on debugger findings"
./tm share $OPTIMIZE_TASK "Identified 5 test files to delete based on new mock approach"

# === ORCHESTRATOR (monitors all) ===
export TM_AGENT_ID="orchestrator"
./tm watch  # Sees all agent activity in real-time
./tm context $EPIC  # Reviews all shared updates and discoveries
```

### Task Orchestrator Benefits for Agent Work

1. **Dependency Tracking**: Ensures agents work in correct order when needed
2. **Progress Visibility**: See which agents completed their work
3. **Coordination**: Multiple agents can check task status
4. **Persistence**: Task state survives across Claude sessions
5. **Reporting**: Export task completion for documentation

### Quick Commands for Agent Orchestration

```bash
# View all Squadron tasks
./tm list --status in_progress

# Check specific agent's assigned work
./tm show [task-id]

# Export Squadron results
./tm export --format json > squadron-results.json

# Monitor for task updates
./tm watch
```

### Integration with Parallel Squadron Pattern

When deploying Parallel Squadron, ALWAYS:

1. Create parent task for Squadron mission
2. Create child tasks for each agent's domain
3. Update task status as agents report progress
4. Use task completion as verification checkpoint
5. Export results for mission report

**Location**: Task Orchestrator installed at project root as `./tm`
**Database**: `.task-orchestrator/tasks.db` (persists across sessions)
**Documentation**: `.task-orchestrator/QUICK_REFERENCE.md`

### Information Architecture for Multi-Agent Work

```
.task-orchestrator/
├── tasks.db                              # Shared task database (all agents)
├── contexts/                              # Shared team communication
│   ├── context_[task_id]_debugger.md    # Debugger's shared updates
│   ├── context_[task_id]_optimizer.md   # Optimizer's shared updates
│   └── context_[epic_id]_orchestrator.md # Orchestrator's coordination
├── notes/                                 # Private agent reasoning
│   ├── notes_[task_id]_debugger.md      # Debugger's private notes
│   └── notes_[task_id]_optimizer.md     # Optimizer's private notes
└── archives/                              # Completed Squadron missions
```

**Key Points**:

- **Private notes**: Only visible to the agent that created them
- **Shared contexts**: Visible to ALL agents via `./tm context`
- **Task database**: Single source of truth for all task states
- **Archives**: Historical record of completed Squadron missions

## Other Claude.md Sections

### Project Architecture

[Your project architecture details would go here...]

### Testing Strategy  

[Your testing approach would go here...]

### Build & Development Commands

[Your build commands would go here...]

### Documentation Strategy

[Your documentation standards would go here...]

### Sub-Agent Deployment Strategy

**🚨 CRITICAL: USE TASK ORCHESTRATOR FOR ALL AGENT COORDINATION**

[Your agent deployment details would go here, but ALWAYS using Task Orchestrator for communication...]

### MCP Agent Team Playbooks

[Your MCP patterns would go here, with Task Orchestrator integration for all multi-agent patterns...]

## Important Instruction Reminders

- ALWAYS use Task Orchestrator (`./tm`) for multi-agent coordination
- NEVER deploy agents without establishing task context first
- ALWAYS set TM_AGENT_ID before agent communication
- Use three-channel system: note (private), share (team), discover (critical)
- Check shared context before starting work on any task
- Export task results for documentation and tracking