# Install the Task Orchestrator Agent Skill

This repository ships an official Agent Skills-compatible package at:

- `skills/task-orchestrator/`

## Option 1: Use directly from this repository

Point your skills-enabled agent tooling to:

- `skills/task-orchestrator/SKILL.md`

If your tooling expects a copied skill directory, copy the whole folder:

```bash
cp -r skills/task-orchestrator /path/to/your-agent-skills/
```

## Option 2: Use from public release artifact

When using a `public-releases/<version>/release-package.*` artifact, extract it and copy:

```bash
cp -r skills/task-orchestrator /path/to/your-agent-skills/
```

## Quick validation

From a project root that contains `./tm`:

```bash
export TM_AGENT_ID="orchestrator_agent"
bash skills/task-orchestrator/scripts/verify-tm.sh --json
```

Expected result includes:

- `"ok":true`
- `"exit_code":0`

## Notes

- `ORCHESTRATOR.md` is a static discovery/protocol file.
- Live task state is always queried using `./tm list`.
