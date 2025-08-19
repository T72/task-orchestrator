# Complexity Handling Protocol

## The Problem: Discovering Complexity During Execution

Workers often discover that assigned tasks are more complex than initially understood. They need ways to handle this without becoming orchestrators themselves.

## Three Mechanisms for Workers

### 1. 🔨 Decomposition (Self-Managed)

When a worker realizes their task needs breakdown:

```bash
# Worker discovers complexity
worker get item_123
# Sees: "Design database schema"
# Realizes: This needs multiple sub-tasks

# Decompose into sub-items
worker decompose item_123 \
  --sub-tasks "User tables" "Session tables" "Audit tables" "Indexes"

# Work on each sub-item
worker work-sub item_123 item_123_sub_a1b2c3 --status in_progress
worker work-sub item_123 item_123_sub_a1b2c3 --status completed --note "Users table with constraints"

# Complete parent when all sub-items done
worker complete item_123 "All 4 schema components designed"
```

**Key Points:**
- Worker manages their own sub-items
- No orchestrator intervention needed
- Progress automatically tracked
- Parent can't complete until all sub-items done

### 2. 🆘 Help Requests (Orchestrator-Assisted)

When a worker needs specialist help:

```bash
# Worker hits area outside expertise
worker request-help item_456 "security_review" \
  --specialist "security_expert" \
  --reason "JWT implementation needs security audit"

# Orchestrator sees request
orchestrate help-requests
# Output: [help_abc] security_review for item_456

# Orchestrator assigns helper
orchestrate assign-help help_abc security_expert

# Security expert receives notification
export AGENT_ID="security_expert"
worker check
# Sees: HELP:help_abc:item_456

# Both agents can now collaborate
worker collaborate item_456 "JWT implementation ready for review" --to security_expert
```

**Key Points:**
- Worker continues working while waiting for help
- Helper gets context automatically
- Collaboration through shared messages
- Original worker maintains ownership

### 3. ⚠️ Escalation (Scope Change)

When scope changes significantly:

```bash
# Worker discovers major scope change
worker escalate item_789 "Requirements completely different than described" \
  --scope-change "Need microservices not monolith" \
  --blockers "Architecture decision" "Technology stack"

# Orchestrator immediately notified
orchestrate escalations
# Output: ⚠️ [esc_xyz] item_789: Requirements completely different

# Orchestrator handles escalation
orchestrate handle-esc esc_xyz "Approved: redesign as microservices" \
  --action decompose

# Or reassign to different specialist
orchestrate handle-esc esc_xyz "Reassigning to microservices expert" \
  --action reassign
```

**Key Points:**
- Used for significant scope changes
- Blocks work until resolved
- Orchestrator decides action
- Can result in reassignment or cancellation

## Decision Tree for Workers

```
Discovered Complexity
        |
        ├── Can I handle this myself by breaking it down?
        |   YES → Decompose into sub-items
        |
        ├── Do I need specific expertise I lack?
        |   YES → Request help from specialist
        |
        └── Has the scope fundamentally changed?
            YES → Escalate to orchestrator
```

## Real-World Example: Database Design Task

### Initial Assignment

```bash
# Orchestrator assigns
orchestrate assign item_db123 database_expert
```

### Worker Discovers Complexity

```bash
export AGENT_ID="database_expert"

# Get assignment
worker get item_db123
# Title: "Design user database"
# Requirements: ["Store user data", "Handle authentication"]

# Start work
worker progress item_db123 "Analyzing requirements"

# DISCOVERY 1: Needs multiple schemas
worker decompose item_db123 \
  --sub-tasks "Core user tables" "Auth tables" "Audit tables" "Performance indexes"

# Work through sub-items
worker work-sub item_db123 item_db123_sub_001 --status in_progress
worker work-sub item_db123 item_db123_sub_001 --status completed

# DISCOVERY 2: Need security review
worker request-help item_db123 "security_review" \
  --specialist "security_expert" \
  --reason "Password encryption strategy needs review"

# Continue working while waiting
worker work-sub item_db123 item_db123_sub_002 --status in_progress

# DISCOVERY 3: Major requirement missing
worker escalate item_db123 "GDPR compliance not mentioned but required" \
  --scope-change "Need complete privacy-by-design architecture" \
  --blockers "Legal requirements" "Data retention policies"
```

### Orchestrator Response

```bash
# Check complexity status
orchestrate monitor project_xyz

# Handle escalation
orchestrate handle-esc esc_001 "Adding GDPR requirements, continue work" \
  --action continue

# Assign security help
orchestrate assign-help help_001 security_specialist

# Approve decomposition
orchestrate approve-decomp item_db123
```

## Benefits of This Approach

### For Workers:
- **Autonomy**: Can handle complexity without waiting
- **Flexibility**: Three escalation levels
- **Clarity**: Clear when to use each mechanism
- **Continuity**: Can keep working while waiting for help

### For Orchestrators:
- **Visibility**: See all complexity discoveries
- **Control**: Decide on escalations
- **Efficiency**: Workers handle routine complexity
- **Focus**: Only involved when needed

### For the System:
- **Scalability**: Complexity handled at appropriate level
- **Resilience**: Work continues despite discoveries
- **Learning**: Discoveries inform future planning
- **Quality**: Right expertise applied when needed

## Communication Patterns

### Pattern 1: Simple Decomposition
```
Worker → Decompose → Work on sub-items → Complete
         (No orchestrator involvement)
```

### Pattern 2: Collaborative Help
```
Worker → Request Help → Orchestrator → Assigns Helper
                              ↓
                         Helper Agent
                              ↓
                     Provides Assistance
                              ↓
                      Worker Continues
```

### Pattern 3: Escalation Resolution
```
Worker → Escalate → Orchestrator → Evaluate
                           ↓
                    [Reassign/Cancel/Continue]
                           ↓
                    Resolution Applied
```

## File Structure for Complexity

```
.task-orchestrator/
├── handoffs/
│   ├── item123_handoff.json         # Original assignment
│   ├── item123_decomposed.json      # Decomposition record
│   ├── item123_help_req001.json     # Help request
│   ├── item123_escalation_esc001.json # Escalation
│   └── help_requests.txt            # Help queue
├── workspace/
│   └── database_expert/
│       └── item123_subitems.json    # Worker's sub-items
└── URGENT_escalations.txt           # High-priority alerts
```

## Best Practices

### For Workers:

1. **Try decomposition first** - Often you can handle complexity yourself
2. **Request help early** - Don't wait until blocked
3. **Escalate sparingly** - Only for true scope changes
4. **Document discoveries** - Help future planning

### For Orchestrators:

1. **Monitor regularly** - Check complexity reports
2. **Respond quickly** - Escalations block work
3. **Assign help wisely** - Match expertise to need
4. **Learn from patterns** - Improve initial planning

## Summary

This enhanced system gives workers three powerful tools:

1. **Decompose** - Break down work independently
2. **Request Help** - Get specialist assistance
3. **Escalate** - Flag major scope changes

Workers maintain their focus on execution while having the flexibility to handle discovered complexity. Orchestrators stay informed without micromanaging, intervening only when their decision-making is truly needed.

The result: A resilient system that handles real-world complexity while maintaining clear role separation.