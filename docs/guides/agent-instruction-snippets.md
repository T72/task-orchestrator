# AI Agent Instruction Snippets

Use these snippets to make AI coding agents consistently discover and use Task Orchestrator in your project.

## Option 1: AGENTS.md snippet

```markdown
## Task Orchestrator

This project uses Task Orchestrator for multi-agent coordination.

Before starting work:
1. Run `./tm list` to get fresh task state from the database.
2. Check `ORCHESTRATOR.md` for discovery guidance and command patterns.
3. Set identity when coordinating work:
   - `export TM_AGENT_ID="your_agent_name"`

When delegating:
- Use Commander's Intent in task descriptions:
  - `WHY`: purpose
  - `WHAT`: deliverables
  - `DONE`: success criteria

Example:
`./tm add "Implement auth API" --assignee backend_agent -d "WHY: secure user access, WHAT: login/token/session endpoints, DONE: users can authenticate successfully"`
```

## Option 2: CLAUDE.md snippet

```markdown
## REQUIRED: Task Orchestrator Workflow

If `./tm` and `ORCHESTRATOR.md` are present, use Task Orchestrator as the source of truth for task coordination.

Required startup flow:
1. `./tm list`
2. `./tm list --assignee $TM_AGENT_ID` (when identity is configured)
3. Use `ORCHESTRATOR.md` for usage patterns, not for live task state.

Required task lifecycle:
- Create: `./tm add ... --assignee ...`
- Progress: `./tm progress TASK_ID "..."`
- Share context: `./tm share TASK_ID "..."`
- Complete: `./tm complete TASK_ID`

Do not treat `ORCHESTRATOR.md` as a live task board.
Live state is always retrieved via `./tm list`.
```

## Notes

- `ORCHESTRATOR.md` is a static discovery and protocol file.
- Runtime task status is always stored in Task Orchestrator data and queried via CLI commands.
- Keep snippets short and project-specific if you have custom agent roles.
