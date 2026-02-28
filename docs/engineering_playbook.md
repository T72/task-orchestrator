
# Engineering Governance Playbook

Version: 2.1
Scope: Repository-wide engineering standards and execution model

---

## 1. Purpose

This document defines how engineering work is:

- Proposed
- Designed
- Implemented
- Tested
- Reviewed
- Documented
- Merged

The objective is to ensure:

- Architectural integrity
- Lightweight TDD enforcement
- Traceability of decisions
- Clean separation of concerns
- Sustainable long-term evolution

---

## 2. Core Principles

1. One issue = one concern.
2. No non-trivial change without a GitHub issue.
3. Lightweight TDD is mandatory.
4. Architecture before optimization.
5. Preserve core vs plugin boundaries.
6. Documentation is part of Definition of Done.
7. Prefer incremental change over large rewrites.
8. Backlog health precedes system health.

---

## 3. Lightweight Test-Driven Development (TDD)

We enforce a pragmatic TDD model.

### 3.1 Required Patterns

For behavioral changes:

- Write tests first when feasible.
- For bug fixes: write a failing regression test first.
- For refactors: protect behavior with tests before changing code.
- For architectural changes: add contract tests to protect boundaries.

### 3.2 Minimum TDD Requirements

A task is not complete unless:

- [ ] New behavior is covered by unit or contract tests.
- [ ] Bug fixes include a regression test.
- [ ] Refactors do not reduce meaningful coverage.
- [ ] No new skipped tests introduced.
- [ ] CI passes.

### 3.3 Test Categories

- **Unit tests** → Fast, isolated, no network.
- **Contract tests** → Protect API & architectural boundaries.
- **Integration tests** → Optional; may use Docker/external services.

Default CI must run:

- Unit + contract tests.

---

## 4. Issue Governance Standard

All non-trivial work must:

- Use the structured GitHub Issue template.
- Define measurable acceptance criteria.
- Define scope boundaries.
- Include a TDD plan when behavior changes.
- Assign milestone.

Milestone naming convention:

```plaintext

<Phase> – <Objective>

```

Examples:

- MVP – Stability Hardening
- Architecture – Policy Refactor
- v1.2 – Observability Improvements
- Security – Auth Hardening

---

## 5. Pull Request Governance

Each PR must:

- Reference exactly one primary issue.
- Be scoped to one concern.
- Pass CI.
- Include tests for behavioral changes.
- Update documentation when required.

PR title format:

```plaintext

<type>: concise description

```

Examples:

- fix: correct healthcheck endpoint
- refactor: extract shared API key verification
- test: add contract tests for routing layer

---

## 6. Architectural Integrity Rules

The following must always hold:

- Core modules must not import plugin internals.
- Plugin modules must not mutate core runtime behavior.
- Provider abstraction must remain isolated.
- Middleware order must remain documented.
- No silent breaking changes.
- Internal-only components must not become public unintentionally.

If a change affects:

- Core boundaries
- Public API contracts
- Agent lifecycle behavior
- Tool governance rules
- Provider abstraction
- Routing behavior

→ Create an ADR.

---

## 7. Architecture Decision Records (ADR)

Location:

```plaintext

docs/developer/adr/

```

Create an ADR when:

- Changing core architecture
- Introducing breaking changes
- Modifying runtime behavior contracts
- Introducing new cross-cutting patterns
- Making significant governance decisions

ADR naming:

```plaintext

adr-xxx-short-title.md

```

---

## 8. Documentation Placement Rules

Documentation must be separated by audience and responsibility.

### 8.1 Audience Separation

- `docs/user/` → Consumer-facing documentation
- `docs/developer/` → Internal engineering documentation
- `docs/operations/` → Deployment and runtime documentation

### 8.2 Architectural Artifacts

Store:

- ADRs → `docs/developer/adr/`
- Analysis & review reports → `docs/developer/reports/`
- Architecture documentation → `docs/developer/architecture/`

### 8.3 Do Not Mix Audiences

- Do not place internal design notes in `docs/user/`.
- Do not place deployment instructions in `docs/user/`.
- Avoid duplication across folders.

### 8.4 Documentation as Definition of Done

Changes that modify:

- API behavior
- System architecture
- Deployment process
- Governance rules

must update documentation before merge.

---

## 9. Definition of Done (DoD)

A task is complete when:

- Acceptance criteria are met.
- Required tests are present and passing.
- CI is green.
- No architectural boundaries violated.
- Documentation updated if applicable.
- Issue linked and closed via PR.

---

## 10. Deferred Scope Control

The following must not be implemented without structured issue tracking and review:

- Human-in-the-loop orchestration
- A/B evaluation systems
- Cross-agent messaging buses
- Distributed caching (e.g., Redis) without scaling requirement
- Advanced cost accounting layers
- Major refactors without test coverage

---

## 11. AI-Assisted Development Policy

AI is a collaborator, not an autonomous architect.

When using AI:

- Always create structured issues before coding.
- Always require tests for behavioral changes.
- Do not allow scope creep.
- Review architectural suggestions critically.
- Prefer incremental implementation cycles.

---

## 12. Backlog Health & Engineering Maturity

Backlog health is a leading indicator of system health.

This repository evaluates structural engineering maturity using the **Backlog Health Score** defined in:

```plaintext

docs/developer/backlog-health.md

```

### 12.1 Mandatory Backlog Standards

Every issue must contain:

- Exactly one `type:*`
- Exactly one `phase:*`
- Exactly one `priority:*`
- Exactly one `risk:*`

If dependencies exist, the issue must include:

```plaintext

## Dependencies

blocked-by: #123
blocks: #456

```

If `blocked-by` is present:

- `status:blocked` must be applied automatically.
- `status:ready` must not be present.

### 12.2 Phase Discipline

Backlog progression must follow:

Stabilization → Hardening → Architecture → Observability → Optimization → Release

Architecture expansion must not dominate while stabilization issues remain unresolved.

### 12.3 Risk & Priority Alignment

- `risk:critical` must not be assigned low priority.
- Critical risks must not persist across milestone boundaries.

### 12.4 TDD Enforcement

Backlog hygiene must reflect TDD discipline:

- Bug issues require regression tests.
- Feature issues require measurable acceptance criteria.
- CI gaps must be resolved before expansion work.

### 12.5 Score Evaluation Cadence

Backlog Health must be evaluated:

- Before merging to `main`
- At milestone completion
- After major refactor waves
- At least once every 4 weeks

Score interpretation:

- 85–100 → Engineering-grade maturity
- 70–84 → Stable with minor drift
- 55–69 → Emerging structural risk
- <55 → Governance instability

Maintaining backlog health is a core engineering responsibility.

---

## 13. Continuous Improvement

This playbook evolves.

Changes require:

- A GitHub issue
- A review
- An ADR (if architectural)
- Version increment in this document
