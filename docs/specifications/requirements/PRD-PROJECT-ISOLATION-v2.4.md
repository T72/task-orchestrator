# Product Requirements Document - Task Orchestrator v2.4
## Project Isolation & Foundation Layer Enhancement

### Executive Summary
Version 2.4 addresses critical architectural issues discovered during v2.3 deployment, primarily the lack of project isolation and incomplete Foundation Layer implementation. This release focuses on making Task Orchestrator truly usable for multi-project development.

### Version Information
- **Version**: 2.4.0
- **Date**: 2025-08-21
- **Status**: In Development
- **Previous Version**: v2.3 (Core Loop Enhancement)

## Problem Statement

### Critical Issues from v2.3
1. **Project Contamination**: All projects share global database at `~/.task-orchestrator/`
2. **Foundation Layer Gaps**: Only 56% of v2.1 Foundation requirements implemented
3. **Multi-Project Workflow**: Impossible to work on multiple projects simultaneously
4. **Context Switching**: Task bleeding causes confusion and errors

## Requirements

### Section 1: Project Isolation (CRITICAL)

#### FR-040: Project-Local Database Isolation ✅ IMPLEMENTED
**User Story**: As a developer working on multiple projects, I need complete task isolation between projects.
**Acceptance Criteria**:
- Each project has own `.task-orchestrator/` directory
- No task bleeding between projects
- Backward compatibility via `TM_DB_PATH`
- Zero configuration for new projects
**Priority**: CRITICAL
**Status**: ✅ Implemented

#### FR-041: Project Context Preservation
**User Story**: As a developer, I want project-specific context and notes preserved locally.
**Acceptance Criteria**:
- Context files stored in project `.task-orchestrator/context/`
- Notes remain with project when moving/cloning
- Archive stays project-local
**Priority**: HIGH
**Status**: 🔄 Partial (directories exist)

### Section 2: Foundation Layer Completion (From v2.1)

#### FR-042: Circular Dependency Detection
**User Story**: As a developer, I need to detect circular dependencies before they cause deadlocks.
**Acceptance Criteria**:
- Detect cycles in dependency graph
- Prevent circular dependency creation
- Clear error messages when detected
**Priority**: HIGH
**Status**: ❌ Not Implemented
**Target**: v2.1 FR1.3

#### FR-043: Critical Path Visualization
**User Story**: As a project manager, I need to see the critical path through dependencies.
**Acceptance Criteria**:
- Identify longest dependency chain
- Highlight blocking tasks
- Show estimated completion path
**Priority**: MEDIUM
**Status**: ❌ Not Implemented  
**Target**: v2.1 FR1.4

#### FR-044: Enhanced PRD Parsing
**User Story**: As a developer, I want PRDs automatically converted to structured tasks.
**Acceptance Criteria**:
- Parse PRD format from prompts
- Extract phases and dependencies
- Create task hierarchy automatically
**Priority**: MEDIUM
**Status**: 🔄 Partial
**Target**: v2.1 FR3.2, FR3.3

#### FR-045: Retry Mechanism for Failed Tasks
**User Story**: As a system, I should retry failed operations with exponential backoff.
**Acceptance Criteria**:
- Automatic retry on transient failures
- Exponential backoff (1s, 2s, 4s, 8s)
- Max 3 retries before escalation
**Priority**: MEDIUM
**Status**: ❌ Not Implemented
**Target**: v2.1 FR4.2

### Section 3: Performance & Reliability

#### NFR-006: Multi-Project Performance
**Requirement**: Support 10+ concurrent projects without performance degradation
**Acceptance Criteria**:
- Database operations <10ms per project
- No lock contention between projects
- Memory usage <10MB per project
**Priority**: HIGH
**Status**: ✅ Achieved (via isolation)

#### NFR-007: Migration Safety
**Requirement**: Zero data loss during v2.3 to v2.4 migration
**Acceptance Criteria**:
- Automatic backup before migration
- Rollback capability
- Migration validation
**Priority**: CRITICAL
**Status**: ✅ Documented

### Section 4: Integration Improvements

#### FR-046: Hook Performance Monitoring
**User Story**: As a developer, I need to know when hooks are slowing down operations.
**Acceptance Criteria**:
- Measure hook execution time
- Log slow hooks (>10ms)
- Performance dashboard in telemetry
**Priority**: LOW
**Status**: ❌ Not Implemented

#### FR-047: Advanced Task Templates
**User Story**: As a team lead, I want reusable task templates for common workflows.
**Acceptance Criteria**:
- Define templates in YAML/JSON
- Instantiate with variables
- Share templates across team
**Priority**: MEDIUM
**Status**: ❌ Not Implemented
**Note**: Mentioned in v2.3 roadmap

### Section 5: Documentation & Usability

#### FR-048: Interactive Setup Wizard
**User Story**: As a new user, I want guided setup for my first project.
**Acceptance Criteria**:
- Interactive tm init with prompts
- Project type selection
- Feature toggle configuration
- Quick start guide generation
**Priority**: LOW
**Status**: ❌ Not Implemented

## Success Metrics

### Adoption Metrics
- Zero task contamination incidents
- 90%+ user satisfaction with isolation
- <5 minute setup for new projects

### Performance Metrics  
- Maintain <10ms hook overhead
- Support 100+ concurrent agents per project
- Database operations <5ms average

### Quality Metrics
- 90%+ requirements satisfaction (up from 81%)
- Zero data loss during migration
- 100% backward compatibility maintained

## Implementation Plan

### Phase 1: Project Isolation (COMPLETED)
- ✅ FR-040: Database isolation
- ✅ NFR-006: Multi-project support
- ✅ NFR-007: Migration safety

### Phase 2: Foundation Layer (IN PROGRESS)
- 🔄 FR-041: Context preservation
- ❌ FR-042: Circular dependency detection
- ❌ FR-043: Critical path visualization
- 🔄 FR-044: Enhanced PRD parsing
- ❌ FR-045: Retry mechanism

### Phase 3: Advanced Features (PLANNED)
- ❌ FR-046: Performance monitoring
- ❌ FR-047: Task templates
- ❌ FR-048: Setup wizard

## Migration Path

### From v2.3 to v2.4
1. **Default Change**: Database location moves to project-local
2. **Backward Compatible**: Set `TM_DB_PATH=~/.task-orchestrator` for old behavior
3. **Data Migration**: Optional tools to split global database by project

## Validation Criteria

### Requirement Validation
- Run all PRD validation scripts (v1.0 through v2.4)
- Target: >90% overall satisfaction
- Focus: v2.1 Foundation gaps (current 56%)

### Integration Testing
```bash
# Test project isolation
project1/tm add "Task A"
project2/tm list  # Should not show Task A

# Test migration compatibility
TM_DB_PATH=~/.task-orchestrator tm list  # Old tasks visible
unset TM_DB_PATH && tm list  # Only project tasks
```

## Risk Analysis

### Technical Risks
- **Migration Complexity**: Mitigated by environment variable override
- **Performance Impact**: Mitigated by local databases (faster than global)
- **Compatibility Break**: Mitigated by TM_DB_PATH backward compatibility

### User Experience Risks
- **Confusion on Upgrade**: Mitigated by clear migration guide
- **Lost Tasks**: Mitigated by keeping global database intact
- **Setup Complexity**: Mitigated by zero-config defaults

## Approval

### Stakeholders
- Development Team: ✅ Approved (critical fix needed)
- User Community: ✅ Implicit (fixes reported issues)
- Project Owner: ✅ Pre-approved (fixes fundamental flaw)

## Appendix: Gaps from Previous Versions

### v2.1 Foundation Layer Gaps (44% missing)
- FR1.3: Circular dependency detection
- FR1.4: Critical path visualization  
- FR3.2: Write tasks to shared-context.md
- FR3.3: Assign specialists in context
- FR3.4: Preserve metadata in shared state
- FR4.2: Retry notifications via broadcast
- FR4.3: Help requests in notification file
- FR4.4: Complexity alerts broadcast
- FR5.2: Coordination via shared context
- FR5.3: Private notes for agent state
- FR5.4: Broadcast for team events
- COMP1: Auto-generated shared context
- COMP2: Extended checkpoints with private notes
- COMP3: Event broadcasts

### v1.0 Gaps (20% missing)
- FR3.1: Task decomposition support (partial)
- FR3.3: Escalation mechanism
- NFR2: Hook execution performance
- ARCH1: Orchestrator subagent definition

### Next Steps
1. Complete Foundation Layer implementation
2. Add circular dependency detection
3. Implement critical path analysis
4. Create task template system
5. Build performance monitoring

---
*End of PRD v2.4*