---
name: task-orchestrator
description: Coordinate multi-agent software execution with Task Orchestrator using commander intent, dependency chains, and live status commands. Use when an agent must break down work, assign tasks, track progress, or unblock dependent work with tm.
license: MIT
compatibility: Designed for filesystem-based coding agents (Codex, Claude Code, similar tools). Requires shell access, Python 3.8+, and executable tm in the project root.
metadata:
  author: T72
  version: "1.0"
---

# task-orchestrator skill

Use this skill when the user needs reliable agent coordination with `tm`.

## Activation cues

Activate this skill when requests involve:

- delegating to multiple agents
- sequencing dependent tasks
- sharing context between assignees
- tracking progress or blocked work
- orchestrating a delivery pipeline

## Prerequisites

1. `tm` exists in the current project root.
2. The project has been initialized with `./tm init`.
3. `TM_AGENT_ID` is set for the current agent session.

## Startup protocol (always)

```bash
./tm list
./tm list --format json
```

Do not treat `ORCHESTRATOR.md` as live runtime state. It is a static discovery contract.

## Standard workflow

1. Set identity:
   ```bash
   export TM_AGENT_ID="orchestrator_agent"
   ```
2. Create tasks with Commander's Intent:
   ```bash
   ./tm add "Implement auth API" --assignee backend_agent \
     -d "WHY: secure user access, WHAT: login/token/session endpoints, DONE: users can authenticate successfully"
   ```
3. Add dependencies:
   ```bash
   ./tm add "Create login UI" --assignee frontend_agent --depends-on <backend_task_id>
   ```
4. Share handoff context:
   ```bash
   ./tm share <task_id> "API contract: POST /auth/login, POST /auth/refresh"
   ```
5. Track progress:
   ```bash
   ./tm progress <task_id> "Implemented token issuance and refresh validation"
   ```
6. Complete to trigger unblocking:
   ```bash
   ./tm complete <task_id>
   ```

## Coordination rules

- Query state with `./tm list` before creating or updating tasks.
- Include `WHY`, `WHAT`, and `DONE` in all substantive delegated tasks.
- Use `./tm share` for cross-agent information, not private notes.
- Use `./tm note` only for private reasoning.
- Keep commands non-interactive and deterministic.

## Safety and quality

- Avoid destructive operations unless explicitly requested.
- If task state conflicts with assumptions, re-query `./tm list --format json`.
- For release-related orchestration, run from release source branch policy (`main` unless overridden by process).

## Available resources

- Runtime checks: `scripts/verify-tm.sh`
- Extended reference: `references/REFERENCE.md`

