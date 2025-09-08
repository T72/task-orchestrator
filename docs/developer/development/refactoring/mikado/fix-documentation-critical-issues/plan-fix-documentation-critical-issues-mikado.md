# Mikado Method Plan: Fix Documentation Critical Issues

## Task Overview
- **Task ID**: MIK-DOC-001
- **Created**: 2025-08-22
- **Estimated Complexity**: Medium
- **Status**: Planning
- **Priority**: CRITICAL (48-hour deadline)

## Goal Statement
Resolve three critical documentation issues identified in the quality gate report to achieve full production readiness and prevent user confusion.

## Success Criteria
1. All implemented commands are documented in CLI reference
2. No documented features that don't exist in code
3. API reference includes all v2.5.1 changes
4. All code examples in documentation are tested and working
5. Documentation quality score improves to >85%

## Task Decomposition

### Phase 1: Command Documentation Audit
- [ ] Task 1.1: Audit actual commands in tm script
  - Dependencies: None
  - Estimated time: 0.5 hours
  - Validation: Complete list of all commands with their parameters
  
- [ ] Task 1.2: Compare documented vs actual commands
  - Dependencies: [1.1]
  - Estimated time: 0.5 hours
  - Validation: Gap analysis document showing discrepancies

- [ ] Task 1.3: Test each command for actual functionality
  - Dependencies: [1.2]
  - Estimated time: 1 hour
  - Validation: Test results showing which commands work

### Phase 2: Fix CLI Documentation
- [ ] Task 2.1: Document missing commands (show, update, critical-path, report)
  - Dependencies: [1.3]
  - Estimated time: 1 hour
  - Validation: Each command has complete documentation with examples
  
- [ ] Task 2.2: Remove/mark deprecated commands (join, note, discover, sync, context)
  - Dependencies: [1.3]
  - Estimated time: 0.5 hours
  - Validation: No non-existent commands in documentation

- [ ] Task 2.3: Update all command examples with actual output
  - Dependencies: [2.1, 2.2]
  - Estimated time: 1 hour
  - Validation: Every example can be copy-pasted and runs successfully

### Phase 3: Update API Reference
- [ ] Task 3.1: Document created_by field addition
  - Dependencies: None
  - Estimated time: 0.5 hours
  - Validation: Field documented with type, default, and usage
  
- [ ] Task 3.2: Document agent_id parameter usage
  - Dependencies: [3.1]
  - Estimated time: 0.5 hours
  - Validation: TM_AGENT_ID environment variable documented

- [ ] Task 3.3: Document migration methods for v2.5.1
  - Dependencies: [3.1, 3.2]
  - Estimated time: 0.5 hours
  - Validation: Migration process clearly explained with examples

### Phase 4: Validation & Testing
- [ ] Task 4.1: Test all documented CLI examples
  - Dependencies: [2.3]
  - Estimated time: 1 hour
  - Validation: Script that runs all examples successfully
  
- [ ] Task 4.2: Verify all cross-references and links
  - Dependencies: [2.3, 3.3]
  - Estimated time: 0.5 hours
  - Validation: No broken internal links

- [ ] Task 4.3: Run documentation quality gate again
  - Dependencies: [4.1, 4.2]
  - Estimated time: 0.5 hours
  - Validation: Score >85% with no critical issues

## Risk Analysis
| Risk | Probability | Impact | Mitigation |
|------|-------------|---------|------------|
| Commands may have hidden parameters | Medium | High | Test with --help and source code review |
| Collaboration commands might be planned features | High | Medium | Check with git history and PRDs |
| Examples might break existing workflows | Low | Medium | Create backup of original docs |
| Time constraint (48 hours) | Medium | High | Focus on critical issues first |

## Rollback Strategy
1. All changes made in separate commit
2. Original documentation backed up before changes
3. Can revert single commit if issues found
4. Test in isolated environment first

## Time Estimate
- **Total Estimated Time**: 8 hours
- **Phases can run partially in parallel**
- **Critical path**: 5 hours (Phase 1 → Phase 2 → Phase 4)

## Dependencies Discovered
- CLI documentation depends on actual tm script implementation
- API documentation depends on tm_production.py current state
- Example validation depends on working test environment