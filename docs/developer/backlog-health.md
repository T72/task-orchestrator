
# Backlog Health Scoring Framework

## Purpose

The Backlog Health Score quantifies structural engineering maturity of this repository.

It evaluates:

* Governance adherence
* Dependency integrity
* Phase discipline
* Risk alignment
* TDD enforcement
* Delivery readiness

This framework does **not** measure velocity or story points.
It measures structural engineering integrity.

The goal is to prevent architectural drift, hidden risk accumulation, and backlog entropy.

---

# Scoring Overview

Total Score: **100 points**

| Dimension                 | Weight |
| ------------------------- | ------ |
| 1. Label Completeness     | 15     |
| 2. Dependency Integrity   | 15     |
| 3. Phase Discipline       | 15     |
| 4. Risk Management        | 10     |
| 5. Priority Hygiene       | 10     |
| 6. Blocker Visibility     | 10     |
| 7. Stabilization Coverage | 10     |
| 8. TDD Alignment          | 10     |
| 9. Issue Granularity      | 5      |

---

# 1. Label Completeness (15 points)

All issues must contain:

* Exactly one `type:*`
* Exactly one `phase:*`
* Exactly one `priority:*`
* Exactly one `risk:*`

Scoring:

* 15 → 100% compliant
* 10 → ≥80% compliant
* 5 → ≥50% compliant
* 0 → <50% compliant

Purpose:
Ensures deterministic AI triage and consistent governance.

---

# 2. Dependency Integrity (15 points)

Evaluate:

* Proper use of `## Dependencies` section
* Proper formatting of:

  * `blocked-by: #123`
  * `blocks: #456`
* No circular dependencies
* No unresolved blockers missing `status:blocked`

Scoring:

* 15 → Clean dependency graph
* 10 → Minor formatting issues
* 5 → Missing blocker labels
* 0 → Circular or broken graph

Purpose:
Maintains critical-path clarity.

---

# 3. Phase Discipline (15 points)

Evaluate backlog phase distribution:

Healthy progression:

* Stabilization: 15–30%
* Hardening: 10–20%
* Architecture: 15–25%
* Observability: 5–15%
* Optimization: <15%

Check:

* Stabilization before architecture expansion
* Release phase only after stabilization
* No premature scaling work

Scoring:

* 15 → Balanced phase progression
* 10 → Mild imbalance
* 5 → Architecture dominating prematurely
* 0 → No visible phase strategy

Purpose:
Prevents structural instability.

---

# 4. Risk Management (10 points)

Check:

* All `risk:critical` issues have `priority:critical` or `priority:high`
* No unresolved critical risk lingering
* Risk and priority aligned

Scoring:

* 10 → Strong alignment
* 5 → Partial misalignment
* 0 → Critical risk ignored

Purpose:
Avoid silent systemic failure.

---

# 5. Priority Hygiene (10 points)

Evaluate:

* ≤20% of backlog labeled `priority:critical`
* Clear differentiation between priority levels
* No inflation of urgency

Scoring:

* 10 → Clean priority distribution
* 5 → Moderate inflation
* 0 → Everything labeled high

Purpose:
Prevents priority collapse.

---

# 6. Blocker Visibility (10 points)

Check:

* All `blocked-by:` issues have `status:blocked`
* No blocked issue actively in progress
* Critical path identifiable

Scoring:

* 10 → Fully visible blockers
* 5 → Minor inconsistencies
* 0 → Hidden blockers

Purpose:
Prevents stalled work.

---

# 7. Stabilization Coverage (10 points)

Check:

* CI/test gaps prioritized before new features
* Governance fixes not deferred behind expansion
* Correctness issues resolved before scaling

Scoring:

* 10 → Stabilization prioritized
* 5 → Mixed prioritization
* 0 → Ignored stabilization

Purpose:
Correctness before expansion.

---

# 8. TDD Alignment (10 points)

Evaluate:

* `type:bug` issues include regression tests
* `type:feature` issues include acceptance criteria
* `status:needs-tests` does not accumulate
* No feature-first implementation pattern

Scoring:

* 10 → Strong TDD discipline
* 5 → Partial enforcement
* 0 → TDD bypassed

Purpose:
Protects system integrity over time.

---

# 9. Issue Granularity (5 points)

Check:

* Issues are atomic
* No vague or oversized issues
* Clear, executable scope

Examples of unhealthy issues:

* "Improve system"
* "Refactor everything"
* "Security improvements"

Scoring:

* 5 → Atomic and clear
* 3 → Some oversized issues
* 0 → Backlog entropy

Purpose:
Prevents scope ambiguity.

---

# Score Interpretation

| Score  | Health Level                   |
| ------ | ------------------------------ |
| 85–100 | Engineering-grade maturity     |
| 70–84  | Stable, minor governance drift |
| 55–69  | Growing structural risk        |
| 40–54  | Significant instability        |
| <40    | Backlog chaos                  |

---

# Evaluation Cadence

Recommended frequency:

* Every 2–4 weeks
* Before major release
* After large milestone completion
* After architecture refactor wave

---

# AI-Assisted Evaluation Prompt

Recommended prompt:

```
Analyze all open GitHub issues and compute a Backlog Health Score using the repository's Backlog Health Scoring Framework.

Provide:
- Score per dimension
- Total score
- Top 3 structural weaknesses
- Concrete remediation steps
- Risk forecast if no correction occurs
```

Sonnet is sufficient for routine scoring.
Opus is recommended for deep structural audits.

---

# Governance Principle

Backlog health is a leading indicator of system health.

Structural backlog decay precedes:

* Architectural instability
* Delivery delays
* Quality regression
* Hidden risk accumulation

Maintaining a healthy backlog is a primary engineering responsibility.

---

End of document.