# Documentation Overview

This repository separates documentation by audience and responsibility.

The goal is clarity, low friction, and architectural discipline.

---

## Documentation Structure

```
docs/
  user/         -> Consumer-facing documentation
  developer/    -> Internal engineering documentation
  operations/   -> Deployment and runtime documentation
```

---

## User Documentation (`docs/user/`)

Audience:
- API consumers
- Integrators
- External developers
- Internal consumers of this adapter

Contains:
- Getting started guides
- API usage examples
- Authentication instructions
- Extension guidelines
- Migration notes (when applicable)

Current files:

| File | Description |
|------|-------------|
| [Placeholder_File_Name_Entry] | [Placeholder_File_Content_Short_Description] |

Rule:
User documentation must remain stable and clear.
Avoid internal implementation details here.

---

## Developer Documentation (`docs/developer/`)

Audience:
- Core maintainers
- Contributors
- Platform engineers

Contains:
- Architecture overviews
- Design patterns
- ADRs (Architecture Decision Records)
- Analysis and review reports
- Development workflows
- TDD standards
- Governance documents

Key subfolders:

```
docs/developer/
  architecture/               -> Architecture overviews and technical references
  adr/                        -> Architecture Decision Records
  reports/                    -> Analysis and review reports
  development/sessions/       -> Session summaries (pause/resume context)
  prompt-based-development/   -> Prompt templates and AI-assisted workflows
```

Current files:

| File | Description |
|------|-------------|
| `prompts/create-session-summary-prompt-template.md` | Template for session summaries |

Rule:
This section may evolve rapidly.
Internal technical detail belongs here.

---

## Operations Documentation (`docs/operations/`)

Audience:
- DevOps
- Infrastructure maintainers
- Release managers

Contains:
- Deployment instructions
- Docker / Compose notes (if applicable)
- Environment variable documentation
- Health check behavior
- Observability and monitoring setup
- Incident response notes (if applicable)

Current files: None.

Rule:
Operational docs must be reproducible and environment-specific.

---

## Root-Level Documentation

The following files remain at the `docs/` root because they are governance or strategic artifacts, not audience-specific.

| File | Description |
|------|-------------|
| `docs/engineering_playbook.md` | Repository-wide engineering standards and execution model (v2.0) |

---

## Placement Rules (Quick Reference)

If documentation answers:

| Question | Place It In |
|----------|-------------|
| "How do I use this API?" | `docs/user/` |
| "How is this implemented?" | `docs/developer/` |
| "Why was this design chosen?" | `docs/developer/adr/` |
| "What changed and why?" | `docs/developer/reports/` |
| "How do I deploy or run this?" | `docs/operations/` |

When unsure:
Prefer `docs/developer/`.

---

## Versioning Rule

Major architectural changes must:

- Update `docs/developer/architecture/`
- Include an ADR in `docs/developer/adr/`
- Optionally add a report in `docs/developer/reports/`

---

## Governance Note

Documentation is part of the Definition of Done.

Behavioral or architectural changes require documentation updates.

See:
- `docs/engineering_playbook.md`
- `CLAUDE.md` (if applicable)
