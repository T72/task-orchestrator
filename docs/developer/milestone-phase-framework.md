
# Milestone Phase Framework

Purpose: Provide consistent milestone naming and planning phases across repositories.

Milestone naming pattern:
<Phase> – <Objective>

Examples:
- MVP – Stability Hardening
- Architecture – Policy Refactor
- v1.2 – Observability Improvements

---

## Phase Catalog (recommended)

### Research
Use when exploring feasibility or unknowns.
Examples:
- Research – Provider Callback Capability
- Research – Streaming Output Policy Options

### MVP
Use when establishing baseline functionality.
Examples:
- MVP – Minimal Agent Runtime
- MVP – Basic API Contract

### Stabilization
Use when fixing correctness gaps and removing sharp edges.
Examples:
- Stabilization – CI Coverage
- Stabilization – Healthcheck + Startup Reliability

### Hardening
Use for governance, security, and safety improvements.
Examples:
- Hardening – Output Policy Rules
- Hardening – Auth Refactor + Audit Trail

### Architecture
Use for structural improvements and boundary clarity.
Examples:
- Architecture – Plugin Discovery Pattern
- Architecture – Routable vs Internal Agents

### Observability
Use for instrumentation, logs/metrics/traces.
Examples:
- Observability – Agent Run Metrics
- Observability – Tool Call Visibility

### Scale
Use when preparing for higher throughput / multi-instance.
Examples:
- Scale – Redis-backed Rate Limiting (only when needed)
- Scale – Queue-based Work Execution

### Release (versioned)
Use for release packaging and public API changes.
Examples:
- v0.2 – Blueprint Corrections Incorporated
- v1.0 – Blueprint Stable Release

### Operations
Use for deployment and runtime readiness.
Examples:
- Operations – Compose Production Parity
- Operations – Runbooks + Health Probes

### Optimization
Use for performance/cost/latency improvements.
Examples:
- Optimization – Reduce LLM Calls
- Optimization – Cache Provider Responses

### Governance
Use for process, templates, standards, compliance.
Examples:
- Governance – Repo Standards Enforcement
- Governance – ADR Workflow Improvements

---

## Guidance

- Prefer “Stabilization” before “Hardening.”
- Do not schedule “Scale” unless there is a real scaling trigger.
- Use “Release” milestones only when shipping/merging to `main`.
- If uncertain, choose:
  Stabilization ? Hardening ? Architecture ? Observability.
