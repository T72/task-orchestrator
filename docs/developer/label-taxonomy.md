
# Label Taxonomy Standard

This repository follows a strict, structured label taxonomy.

Only the labels defined in `.github/labels.yml` are part of the official governance model.
Default GitHub labels (e.g., `bug`, `enhancement`) are not used.

The taxonomy is designed to:

- Enable deterministic AI-assisted prioritization
- Support dependency-aware triage
- Enforce engineering governance discipline
- Keep backlog filtering unambiguous
- Avoid semantic duplication

---

# 1️⃣ Label Dimensions

Each issue SHOULD have:

- Exactly one `type:*`
- Exactly one `phase:*`
- Exactly one `priority:*`
- Exactly one `risk:*`
- Zero or one `status:*`

Additional `area:*` labels may be used when the repository grows.

---

# 2️⃣ Type Labels (What kind of work?)

- `type:bug`
- `type:feature`
- `type:refactor`
- `type:architecture`
- `type:governance`
- `type:infra`
- `type:security`
- `type:performance`
- `type:test`
- `type:documentation`
- `type:verification`

Rules:
- Refactors MUST preserve behavior.
- Architecture changes affect boundaries or structure.
- Governance changes affect standards, templates, process.

---

# 3️⃣ Phase Labels (Where in lifecycle?)

- `phase:research`
- `phase:mvp`
- `phase:stabilization`
- `phase:hardening`
- `phase:architecture`
- `phase:observability`
- `phase:operations`
- `phase:optimization`
- `phase:governance`
- `phase:release`

Rules:
- Stabilization before Hardening.
- Hardening before Architecture expansion.
- Release only when stabilization is complete.

---

# 4️⃣ Priority Labels (How urgent?)

- `priority:critical`
- `priority:high`
- `priority:medium`
- `priority:low`

Rules:
- `priority:critical` is reserved for correctness/security emergencies.
- Avoid overusing `critical`.

---

# 5️⃣ Risk Labels (How dangerous?)

- `risk:critical`
- `risk:high`
- `risk:medium`
- `risk:low`

Risk measures impact to:
- System correctness
- Security
- Stability
- Deployment safety

Priority ≠ Risk.
An issue may be high risk but low urgency (e.g., architectural debt).

---

# 6️⃣ Status Labels (Workflow visibility)

- `status:blocked`
- `status:ready`
- `status:needs-clarification`
- `status:needs-adr`
- `status:needs-tests`

Rules:

## Blocked Convention

If issue body contains:

```

## Dependencies

blocked-by: #123

```

Then:

- Apply `status:blocked`
- Remove `status:ready`

When no unresolved `blocked-by` remain:

- Remove `status:blocked`
- Apply `status:ready` (optional)

---

# 7️⃣ Dependency Annotation Standard

Dependencies MUST be declared at the bottom of the issue:

```

## Dependencies

blocked-by: #123
blocked-by: #145

blocks: #201
blocks: #209

```

Rules:

- One dependency per line
- No prose in dependency section
- Always use `#issueNumber`
- No circular dependencies

This format is optimized for AI triage and automation.

---

# 8️⃣ Labeling Rules Summary

| Dimension | Required | Cardinality |
|-----------|----------|------------|
| type      | Yes      | Exactly 1  |
| phase     | Yes      | Exactly 1  |
| priority  | Yes      | Exactly 1  |
| risk      | Yes      | Exactly 1  |
| status    | Optional | 0–1        |

Issues missing required dimensions should be marked:

- `status:needs-clarification`

---

# 9️⃣ Governance Principles

- No duplicate semantics (no `bug` + `type:bug`)
- No vague labels (e.g., "enhancement")
- Every issue must be executable
- Every dependency must be explicit
- Status labels reflect real graph state

---

# 🔟 AI Prioritization Compatibility

This taxonomy enables:

- Deterministic backlog prioritization
- Dependency graph reasoning
- Critical path detection
- Phase alignment validation
- Risk-first stabilization strategy

AI prompts rely on structured labels.
Do not bypass the taxonomy.

---

# Enforcement

Label definitions are managed via:

```

.github/labels.yml
.github/workflows/sync-labels.yml

```

Manual label creation is discouraged.
Always modify the YAML and run the sync workflow.

---

End of document.