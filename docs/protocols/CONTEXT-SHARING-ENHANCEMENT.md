# Context Sharing Enhancement for Task Orchestrator

## Overview

The Task Orchestrator has been enhanced with comprehensive context sharing capabilities that enable seamless collaboration between orchestrating agents and deployed sub-agents. This enhancement introduces two file-based collaboration mechanisms: **Private Notes** and **Shared Context Files**.

## Architecture

### File Structure
```
.task-orchestrator/
├── tasks.db                    # Main task database
├── contexts/                    # Shared context files
│   └── {task_id}_context.yaml  # Per-task shared context
└── notes/                       # Private notes
    └── {task_id}_{agent_id}.md # Agent-specific private notes
```

### Key Components

1. **ContextManager Class**: Manages all context-related operations
2. **Enhanced Database Schema**: Tracks context participation and notifications
3. **YAML-based Shared Context**: Structured collaboration format
4. **Markdown Private Notes**: Personal agent workspace

## Features

### 1. Private Notes File

Each agent has a personal notes file per task for private thoughts and observations:

```bash
# Write private notes
tm context update TASK_ID --type private --content "Initial analysis: Need to refactor auth module"

# Read private notes
tm context read TASK_ID --type private
```

**Characteristics:**
- Isolated per agent (other agents cannot access)
- Markdown format for rich documentation
- Timestamped entries for chronological tracking
- Append mode by default

### 2. Shared Context File

A structured YAML file shared among all task participants:

```yaml
task_id: abc12345
task_title: "Implement authentication"
metadata:
  version: "1.0"
  orchestrator: "agent_orchestrator_001"

global_context:
  description: "OAuth2 implementation"
  requirements:
    - "Support Google and GitHub"
    - "JWT token validation"
  constraints:
    - "Must be GDPR compliant"
  resources:
    - "API documentation link"

agent_sections:
  backend_dev:
    joined_at: "2025-01-18T10:00:00"
    contributions:
      - timestamp: "2025-01-18T10:30:00"
        type: "progress"
        content: "Database schema ready"
        
  frontend_dev:
    joined_at: "2025-01-18T11:00:00"
    contributions:
      - timestamp: "2025-01-18T11:30:00"
        type: "update"
        content: "Login form implemented"

shared_discoveries:
  - agent_id: "security_analyst"
    timestamp: "2025-01-18T12:00:00"
    discovery: "Found XSS vulnerability"
    impact: "Critical - affects all forms"
    tags: ["security", "urgent"]

sync_points:
  - agent_id: "orchestrator"
    timestamp: "2025-01-18T13:00:00"
    checkpoint: "Phase 1 complete"
    ready_for: ["qa_tester", "doc_writer"]
    blocked_by: []
```

### 3. Context Management Commands

#### Initialize Context
```bash
# Create task with context
tm add "New feature" --with-context

# Or initialize context for existing task
tm context join TASK_ID --role orchestrator
```

#### Join Context Collaboration
```bash
# Join as contributor (default)
tm context join TASK_ID

# Join with specific role
tm context join TASK_ID --role backend
```

#### Update Context
```bash
# Update shared context - agent section
tm context update TASK_ID --type shared --section agent_sections \
  --content '{"type":"progress","content":"API endpoints complete"}'

# Update global context
tm context update TASK_ID --type shared --section global_context \
  --content '{"description":"Microservices architecture","requirements":["REST API","Docker"]}'

# Share a discovery
tm context discover TASK_ID "Found performance bottleneck" \
  --impact "30% improvement possible" --tags optimization

# Create sync point
tm context sync TASK_ID "Backend ready for integration" \
  --ready-for frontend_dev qa_tester
```

#### Read Context
```bash
# Read both shared and private
tm context read TASK_ID --type both

# Read only shared
tm context read TASK_ID --type shared

# Read only private notes
tm context read TASK_ID --type private
```

#### List Participants
```bash
tm context participants TASK_ID
```

## Usage Patterns

### Pattern 1: Orchestrator Setup
```bash
# Orchestrator creates task with context
TASK_ID=$(tm add "Build authentication system" --with-context | grep "Task ID:" | cut -d' ' -f3)

# Set global context
tm context update $TASK_ID --type shared --section global_context \
  --content '{"description":"OAuth2 implementation","requirements":["Google","GitHub","JWT"]}'

# Create initial sync point
tm context sync $TASK_ID "Requirements defined" --ready-for backend_dev frontend_dev
```

### Pattern 2: Sub-Agent Workflow
```bash
# Sub-agent joins task
export TM_AGENT_ID="backend_specialist"
tm context join $TASK_ID --role backend

# Write private notes for planning
tm context update $TASK_ID --type private \
  --content "TODO: Research OAuth2 libraries, Design token storage"

# Share progress with team
tm context update $TASK_ID --type shared --section agent_sections \
  --content '{"type":"progress","content":"Database schema implemented"}'

# Share important discovery
tm context discover $TASK_ID "Token expiry issue in library X" \
  --impact "Need custom implementation" --tags security library
```

### Pattern 3: Multi-Agent Synchronization
```bash
# Agent 1 completes their part
export TM_AGENT_ID="backend_dev"
tm context sync $TASK_ID "API ready" --ready-for frontend_dev

# Agent 2 gets notified and continues
export TM_AGENT_ID="frontend_dev"
tm watch  # See notification about API readiness
tm context update $TASK_ID --type shared \
  --content '{"type":"progress","content":"Integrating with API"}'
```

## Notification System

Context updates trigger notifications to keep all agents synchronized:

- **CONTEXT_UPDATED**: When any agent updates shared context
- **DISCOVERY**: When an agent shares a discovery
- **SYNC_POINT**: When a checkpoint is reached
- **UNBLOCKED**: When agents are ready to proceed

```bash
# Check notifications
tm watch

# Example output:
# [CONTEXT_UPDATED] Task abc123: backend_dev updated agent_sections
# [DISCOVERY] Task abc123: New discovery by security_analyst
# [UNBLOCKED] Task abc123: Sync point reached: API ready
```

## Benefits

### 1. Enhanced Coordination
- Real-time visibility into all agents' progress
- Clear synchronization points
- Reduced communication overhead

### 2. Knowledge Preservation
- Private notes capture individual thinking process
- Shared discoveries benefit entire team
- Context persists across sessions

### 3. Parallel Efficiency
- Agents work independently with private notes
- Share only relevant information
- Automatic notifications reduce polling

### 4. Flexibility
- Supports various collaboration patterns
- Agents can join/leave dynamically
- Role-based participation

## Implementation Details

### Concurrency Safety
- File-level locking for shared context updates
- ACID compliance through SQLite transactions
- WAL mode for better concurrent access

### Storage Format
- **YAML** for shared context (human-readable, structured)
- **Markdown** for private notes (rich formatting)
- **SQLite** for metadata and notifications

### Performance Considerations
- Lazy loading of context files
- Incremental updates (append-only for contributions)
- Indexed database queries for fast lookups

## Example Scenario: Building a REST API

```bash
# Orchestrator sets up the task
export TM_AGENT_ID="orchestrator"
TASK=$(tm add "Build user management API" --with-context | grep "Task ID:" | cut -d' ' -f3)

tm context update $TASK --type shared --section global_context \
  --content '{"description":"RESTful API for user CRUD operations","requirements":["JWT auth","Rate limiting","OpenAPI spec"]}'

# Backend developer joins
export TM_AGENT_ID="backend_dev"
tm context join $TASK --role backend

# Private planning
tm context update $TASK --type private --content "
Research notes:
- Use Express.js with TypeScript
- PostgreSQL for user data
- Redis for rate limiting
"

# Share progress
tm context update $TASK --type shared \
  --content '{"type":"progress","content":"Database schema and models complete"}'

# Frontend developer joins
export TM_AGENT_ID="frontend_dev"
tm context join $TASK --role frontend

# Discovers issue
tm context discover $TASK "CORS configuration needed for localhost:3000" \
  --impact "Blocking frontend development" --tags blocker cors

# Backend dev sees discovery and fixes
export TM_AGENT_ID="backend_dev"
tm watch  # Sees CORS discovery
tm context update $TASK --type shared \
  --content '{"type":"fix","content":"CORS configured for development"}'

# Create sync point
tm context sync $TASK "API v1 ready for integration" \
  --ready-for frontend_dev qa_tester doc_writer
```

## Future Enhancements

1. **Context Templates**: Predefined structures for common task types
2. **Context Versioning**: Track changes over time with rollback capability
3. **Context Search**: Find information across all contexts
4. **Context Metrics**: Analytics on collaboration patterns
5. **External Tool Integration**: IDE plugins, chat notifications
6. **Context Export**: Generate reports from context data

## Conclusion

The context sharing enhancement transforms the Task Orchestrator into a powerful collaboration platform for multi-agent development. By providing both private and shared spaces, agents can work efficiently while maintaining synchronization and knowledge sharing across the team.