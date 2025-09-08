# Mikado Method Plan: Complete Foundation Layer Implementation

## Task Overview
- **Task ID**: MIK-001
- **Created**: 2025-08-21
- **Estimated Complexity**: High
- **Status**: Planning
- **Target**: Achieve >90% PRD satisfaction across all versions

## Goal Statement
Complete the Foundation Layer implementation to fix the v2.1 gaps (currently at 56% success rate) and bring overall PRD satisfaction above 90%. This includes circular dependency detection, critical path visualization, enhanced PRD parsing, and retry mechanisms.

## Success Criteria
1. v2.1 validation score increases from 56% to >85%
2. Overall PRD satisfaction across all versions >90%
3. All Foundation Layer hooks properly integrated
4. Zero regression in existing functionality
5. Performance maintained <10ms hook overhead

## Task Decomposition

### Phase 1: Circular Dependency Detection (FR-042)
- [ ] Task 1.1: Implement dependency graph builder
  - Dependencies: None
  - Estimated time: 2 hours
  - Validation: Unit tests for graph construction
  
- [ ] Task 1.2: Add cycle detection algorithm
  - Dependencies: [1.1]
  - Estimated time: 2 hours
  - Validation: Tests with known circular dependencies
  
- [ ] Task 1.3: Integrate with task-dependencies hook
  - Dependencies: [1.2]
  - Estimated time: 1 hour
  - Validation: Integration tests with tm add command

### Phase 2: Critical Path Visualization (FR-043)
- [ ] Task 2.1: Implement longest path algorithm
  - Dependencies: [1.1]
  - Estimated time: 2 hours
  - Validation: Unit tests with complex dependency graphs
  
- [ ] Task 2.2: Add blocking task identification
  - Dependencies: [2.1]
  - Estimated time: 1 hour
  - Validation: Tests identify correct blockers
  
- [ ] Task 2.3: Create visualization output
  - Dependencies: [2.2]
  - Estimated time: 2 hours
  - Validation: tm critical-path command works

### Phase 3: Enhanced PRD Parsing (FR-044)
- [ ] Task 3.1: Improve PRD format detection
  - Dependencies: None
  - Estimated time: 2 hours
  - Validation: Tests with various PRD formats
  
- [ ] Task 3.2: Extract phase dependencies automatically
  - Dependencies: [3.1]
  - Estimated time: 3 hours
  - Validation: Correctly parses phase relationships
  
- [ ] Task 3.3: Write tasks to shared-context.md
  - Dependencies: [3.2]
  - Estimated time: 1 hour
  - Validation: Shared context properly updated

### Phase 4: Retry Mechanism (FR-045)
- [ ] Task 4.1: Implement exponential backoff logic
  - Dependencies: None
  - Estimated time: 2 hours
  - Validation: Unit tests verify backoff timing
  
- [ ] Task 4.2: Add retry wrapper for hooks
  - Dependencies: [4.1]
  - Estimated time: 2 hours
  - Validation: Failed operations retry correctly
  
- [ ] Task 4.3: Integrate with event-flows hook
  - Dependencies: [4.2]
  - Estimated time: 1 hour
  - Validation: Events retry on transient failures

### Phase 5: Context & Notification Enhancement
- [ ] Task 5.1: Auto-generate shared context
  - Dependencies: [3.3]
  - Estimated time: 2 hours
  - Validation: Context files created automatically
  
- [ ] Task 5.2: Extend checkpoint with private notes
  - Dependencies: None
  - Estimated time: 1 hour
  - Validation: Checkpoints include note references
  
- [ ] Task 5.3: Implement broadcast for team events
  - Dependencies: None
  - Estimated time: 2 hours
  - Validation: Events appear in broadcast.md

### Phase 6: Integration Testing
- [ ] Task 6.1: Run v2.1 validation script
  - Dependencies: [1.3, 2.3, 3.3, 4.3, 5.3]
  - Estimated time: 1 hour
  - Validation: Score >85%
  
- [ ] Task 6.2: Run all PRD validation scripts
  - Dependencies: [6.1]
  - Estimated time: 1 hour
  - Validation: All versions maintain or improve scores
  
- [ ] Task 6.3: Performance benchmarking
  - Dependencies: [6.2]
  - Estimated time: 1 hour
  - Validation: Hook overhead <10ms

## Risk Analysis

| Risk | Probability | Impact | Mitigation |
|------|-------------|---------|------------|
| Circular dependency detection affects performance | Medium | High | Use cached graph, update incrementally |
| Breaking existing functionality | Low | High | Comprehensive test coverage before changes |
| Complex integration between hooks | High | Medium | Clear interfaces, extensive integration tests |
| PRD parsing too rigid | Medium | Medium | Support multiple formats, graceful fallback |

## Rollback Strategy
1. All changes in separate commit blocks
2. Feature flags for new functionality (via config system)
3. Keep old hook versions as -v2 backups
4. Database changes are backward compatible
5. Can disable via TM_DISABLE_FOUNDATION environment variable