# Product Requirements Document: Task-Orchestrator Ultra-Lean System v2.2

## Section 1: Document Metadata

* **Product Name:** Task-Orchestrator: Claude Code Ultra-Lean Orchestration Enhancement
* **PRD Version:** 2.2.0
* **Author / Owner:** Product Team / Engineering Lead
* **Date:** 2025-08-18
* **Status:** Draft (Pending Approval)
* **Stakeholders:** Development Team, Open Source Community, Claude Code Users

**Version History / Change Log**

| Version | Date | Author | Change Summary | Status |
|---------|------|--------|----------------|---------|
| 2.2 | 2025-08-18 | Product Team | Repository rename to task-orchestrator, public release preparation, hook fixes | Draft |
| 2.1 | 2025-08-17 | Product Team | Architectural alignment with foundation layer | Superseded |
| 2.0 | 2025-08-16 | Product Team | Ultra-lean implementation with 247-line hooks | Superseded |
| 1.0 | 2025-08-15 | Product Team | Initial native orchestration baseline | Superseded |

## Section 2: Executive Summary / Overview

**Task-Orchestrator** (formerly task-manager) is a lightweight CLI task orchestration system designed for AI agents and automation workflows. It extends Claude Code with enhanced capabilities for successful task orchestration through specialized sub-agents, enabling the use of shared context, private notes, and notifications with lightweight hooks to deliver durable, dependency-aware, and event-driven coordination across agents.

### Key Changes in v2.2:
- **Renamed** from "task-manager" to "task-orchestrator" for clarity and differentiation
- **Prepared for public release** on GitHub with appropriate documentation
- **Fixed hook validation errors** to ensure Claude Code compatibility
- **Updated all references** throughout codebase for consistency

## Section 3: Background & Context

The system has evolved from an internal task management tool to a public orchestration framework. The rename to "task-orchestrator" better reflects its purpose of orchestrating complex multi-agent workflows rather than simple task management. This positions it as a valuable tool for the AI/LLM community, particularly Claude Code users.

### Context Updates in v2.2:
- Growing demand for AI agent orchestration tools in the community
- Need for clear product identity distinct from traditional task managers
- Opportunity to contribute to open source AI tooling ecosystem

## Section 4: Objectives & Success Metrics

### Primary Objectives (Unchanged)
1. Enable seamless task orchestration across multiple AI agents
2. Provide dependency management and event-driven automation
3. Maintain ultra-lean implementation (~260 lines of hooks)
4. Ensure 100% Claude Code compatibility

### New Success Metrics for v2.2

| KPI ID | Metric | Target | Current | Notes |
|--------|--------|--------|---------|-------|
| KPI-001 | Hook Validation Errors | 0 | 0 | Fixed in v2.2 |
| KPI-002 | Repository Consistency | 100% | 100% | All references updated |
| KPI-003 | Public Release Readiness | Ready | Ready | Documentation complete |
| KPI-004 | Community Adoption | >50 stars | - | Post-release metric |

## Section 5: Functional Requirements

### Modified Requirements

| Req ID | User Story | Acceptance Criteria | Priority | Dependencies | Status | Task/Issue ID | Code / Repo Link | Test Case ID | Linked KPI ID(s) | Comments |
|--------|------------|---------------------|----------|--------------|---------|---------------|------------------|--------------|------------------|----------|
| FR-CORE-1 | Read-Only Shared Context File | Location: `.task-orchestrator/context/shared-context.md` | Critical | None | **Modified v2.2** | TASK-001 | /tm_orchestrator.py | TC-001 | KPI-002 | Path updated |
| FR-CORE-2 | Private Note-Taking Files | Location: `.task-orchestrator/agents/notes/{agent}-notes.md` | Critical | None | **Modified v2.2** | TASK-002 | /tm_worker.py | TC-002 | KPI-002 | Path updated |
| FR-CORE-3 | Shared Notification File | Location: `.task-orchestrator/notifications/broadcast.md` | Critical | None | **Modified v2.2** | TASK-003 | /event-flows.py | TC-003 | KPI-002 | Path updated |
| FR-025 | Hook Decision Values | Hooks must use "approve" or "block" (not "allow" or "enhance") | Critical | None | **New v2.2** | TASK-025 | /.claude/hooks/*.py | TC-025 | KPI-001 | Added for compatibility |
| FR-026 | Public Repository Support | System must work when cloned from public GitHub repo | High | None | **New v2.2** | TASK-026 | /README.md | TC-026 | KPI-003 | Added for OSS |

### Unchanged Requirements (Preserved with Original IDs)

| Req ID | User Story | Acceptance Criteria | Priority | Dependencies | Status | Comments |
|--------|------------|---------------------|----------|--------------|---------|----------|
| FR-001 through FR-024 | [Various orchestration features] | [As defined in v2.1] | [Various] | [Various] | Unchanged | From v2.1 |

## Section 6: Non-Functional Requirements

### Modified Requirements

| Req ID | Category | Requirement | Target | Status | Comments |
|--------|----------|-------------|--------|---------|----------|
| NFR-001 | Performance | Hook overhead | <10ms | Unchanged | From v2.1 |
| NFR-002 | Scalability | Concurrent agents | 100+ | Unchanged | From v2.1 |
| NFR-003 | Compatibility | Claude Code versions | All | **Modified v2.2** | Fixed validation |
| NFR-004 | Maintainability | Code size | <300 lines | Unchanged | 260 lines |
| NFR-005 | Documentation | Coverage | 100% | **Modified v2.2** | Updated for OSS |

## Section 7: User Experience / UI Requirements

### CLI Interface Updates

| Req ID | Component | Description | Status | Comments |
|--------|-----------|-------------|---------|----------|
| UX-001 | Command Name | Maintain `tm` command for backward compatibility | Unchanged | From v2.1 |
| UX-002 | Directory Structure | Use `.task-orchestrator/` instead of `.task-manager/` | **Modified v2.2** | Consistency |
| UX-003 | Error Messages | Reference "Task Orchestrator" in user messages | **Modified v2.2** | Branding |

## Section 8: Technical & Integration Requirements

### Technical Changes in v2.2

| Req ID | Component | Requirement | Implementation | Status |
|--------|-----------|-------------|----------------|---------|
| TECH-001 | Database Path | SQLite at `.task-orchestrator/tasks.db` | All tm*.py files | **Modified v2.2** |
| TECH-002 | Hook Validation | Use Claude Code schema-compliant responses | All hooks/*.py | **Modified v2.2** |
| TECH-003 | Variable Initialization | Prevent UnboundLocalError in hooks | event-flows.py | **Modified v2.2** |
| TECH-004 | Repository Structure | Support public GitHub clone and fork | Project root | **New v2.2** |

## Section 9: Risks & Mitigation Plans

### Updated Risk Assessment

| Risk ID | Risk Description | Probability | Impact | Mitigation Strategy | Status |
|---------|------------------|-------------|---------|-------------------|---------|
| RISK-001 | Breaking changes for existing users | Medium | High | Provide migration guide, maintain `tm` command | **Modified v2.2** |
| RISK-002 | Hook incompatibility | Low | High | Fixed validation errors, tested with Claude Code | **Resolved v2.2** |
| RISK-003 | Public exposure of sensitive code | Low | Medium | Reviewed for secrets, added .gitignore | **New v2.2** |
| RISK-004 | Community adoption challenges | Medium | Medium | Clear documentation, examples, active support | **New v2.2** |

## Section 10: Traceability Matrix

| PRD ID | Requirement | Task/Issue ID | Code Module / Repo Link | Test Case ID | KPI / Metric | Status | Dependencies | Comments |
|--------|-------------|---------------|-------------------------|--------------|--------------|---------|--------------|----------|
| FR-CORE-1 | Shared Context | TASK-001 | /tm_orchestrator.py:23 | TC-001 | KPI-002 | Modified v2.2 | None | Path updated |
| FR-CORE-2 | Private Notes | TASK-002 | /tm_worker.py:19-20 | TC-002 | KPI-002 | Modified v2.2 | None | Path updated |
| FR-CORE-3 | Notifications | TASK-003 | /.claude/hooks/event-flows.py | TC-003 | KPI-002 | Modified v2.2 | None | Path updated |
| FR-025 | Hook Decisions | TASK-025 | /.claude/hooks/*.py | TC-025 | KPI-001 | New v2.2 | None | Compatibility |
| FR-026 | Public Repo | TASK-026 | /README.md | TC-026 | KPI-003 | New v2.2 | None | OSS release |

## Section 11: Glossary / References

### Updated Terms
- **Task Orchestrator**: The new name for the system (formerly Task Manager)
- **task-orchestrator**: Repository and directory name
- **tm**: Command-line interface (unchanged for compatibility)
- **Hook Decision Values**: "approve" or "block" (Claude Code schema requirement)

### New References
- GitHub Repository: https://github.com/[user]/task-orchestrator
- Claude Code Hook Schema: [Internal documentation reference]
- Open Source License: MIT (recommended)

## Section 12: Change Control / Revision Process

| Change ID | New PRD Version | Date | Requested By | Approved By | Affected Requirement(s) | Impact Summary | Status |
|-----------|-----------------|------|--------------|-------------|-------------------------|----------------|---------|
| CHG-002 | 2.2 | 2025-08-18 | Development Team | Pending | FR-CORE-1,2,3, FR-025,026, NFR-003,005, UX-002,003, TECH-001,002,003,004 | Repository rename, public release preparation, hook compatibility fixes | Draft |

### Detailed Change Record

#### CHG-002: Repository Rename and Public Release Preparation

**Justification**: 
- Clear product differentiation from generic task managers
- Community demand for AI orchestration tools
- Opportunity to contribute to Claude Code ecosystem

**Changes Applied**:
1. **Name Updates** (FR-CORE-1, FR-CORE-2, FR-CORE-3, UX-002, UX-003, TECH-001):
   - All references to "task-manager" → "task-orchestrator"
   - Directory `.task-manager/` → `.task-orchestrator/`
   - Documentation titles updated for consistency

2. **Hook Compatibility** (FR-025, TECH-002, TECH-003):
   - Fixed decision values: "allow" → "approve"
   - Fixed UnboundLocalError in event-flows.py
   - Ensured Claude Code schema compliance

3. **Public Release** (FR-026, NFR-005):
   - Added comprehensive README
   - Prepared repository description
   - Reviewed for sensitive information
   - Added open source considerations

**Impact Analysis**:
- Existing users need migration (simple directory rename)
- No functional changes to core orchestration
- Improved compatibility with Claude Code
- Ready for community contribution

**Approval Required From**:
- Product Owner (strategy alignment)
- Engineering Lead (technical review)
- Legal/Compliance (open source release)

## Section 13: Implementation Guidelines for AI Collaboration

### 1. Task Decomposition Strategy
- Maintain atomic, single-purpose tasks
- Use phase-based organization for complex projects
- Leverage specialist agents for domain expertise
- **v2.2 Note**: Public contributors should follow same patterns

### 2. Context Management Protocol
- Shared context in `.task-orchestrator/context/`
- Private notes in `.task-orchestrator/agents/notes/`
- Broadcast critical updates via notifications
- **v2.2 Note**: Paths updated from `.task-manager/`

### 3. Error Handling & Recovery
- Automatic checkpointing every status change
- Resume from exact failure point
- Exponential backoff for retries (2^n seconds)
- **v2.2 Note**: Hook validation errors eliminated

### 4. Dependency Resolution
- Automatic blocking of dependent tasks
- Critical path identification
- Parallel execution where possible
- **v2.2 Note**: No changes to logic

### 5. Communication Patterns
- Asynchronous via shared files
- Event-driven automation through hooks
- Specialist routing based on task metadata
- **v2.2 Note**: Compatible with Claude Code schema

### 6. Quality Assurance
- Each requirement has test coverage
- Hooks validated against Claude Code schema
- Migration testing for existing users
- **v2.2 Note**: Added public repository testing

---

## Appendix A: Migration Guide for v2.1 → v2.2

### For Existing Users:
1. **Rename directory**: `mv .task-manager .task-orchestrator`
2. **Update any custom scripts** referencing old paths
3. **Pull latest hooks** from repository
4. **No database migration needed** - format unchanged

### For New Users:
1. **Clone from GitHub**: `git clone https://github.com/[user]/task-orchestrator`
2. **Run setup**: `./install-hooks.sh`
3. **Initialize**: `tm init`
4. **Ready to use** with Claude Code

## Appendix B: Public Release Checklist

- [x] All "task-manager" references updated to "task-orchestrator"
- [x] Hook validation errors fixed
- [x] Documentation updated for consistency
- [x] README.md prepared with description
- [x] No sensitive information in codebase
- [ ] LICENSE file added (MIT recommended)
- [ ] CONTRIBUTING.md created
- [ ] GitHub Issues templates prepared
- [ ] Initial release tagged (v2.2.0)

---

*This PRD revision v2.2 supersedes v2.1 and documents the repository rename, public release preparation, and hook compatibility fixes. All requirement IDs from previous versions are preserved for complete traceability.*