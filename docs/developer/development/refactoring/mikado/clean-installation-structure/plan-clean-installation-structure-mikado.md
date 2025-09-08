# Mikado Method Plan: Clean Installation Structure

## Task Overview
- **Task ID**: MIK-001
- **Created**: 2025-09-08
- **Estimated Complexity**: Medium
- **Status**: Planning

## Goal Statement
Transform Task Orchestrator installation from 29+ files in project root to a single `tm` wrapper file, with all implementation hidden in `.task-orchestrator/lib/`.

## Success Criteria
1. Only ONE file (`tm`) visible in project root after installation
2. All 35+ Python modules relocated to `.task-orchestrator/lib/`
3. Backward compatibility maintained for existing installations
4. Migration script successfully moves old structure to new
5. All commands work identically with new structure
6. Package size remains unchanged
7. Installation process simplified

## Task Decomposition

### Phase 1: Foundation (Preparation)
- [ ] Task 1.1: Analyze current package structure
  - Dependencies: None
  - Estimated time: 0.5 hours
  - Validation: Document all 35+ Python files and their locations

- [ ] Task 1.2: Create new directory structure locally
  - Dependencies: [1.1]
  - Estimated time: 0.5 hours
  - Validation: `.task-orchestrator/lib/` structure exists

- [ ] Task 1.3: Update tm wrapper for path resolution
  - Dependencies: [1.2]
  - Estimated time: 1 hour
  - Validation: Wrapper can import from both old and new paths

### Phase 2: Core Implementation
- [ ] Task 2.1: Reorganize Python modules into lib directory
  - Dependencies: [1.3]
  - Estimated time: 1 hour
  - Validation: All .py files in `.task-orchestrator/lib/`

- [ ] Task 2.2: Update all internal imports
  - Dependencies: [2.1]
  - Estimated time: 2 hours
  - Validation: No import errors when running from new structure

- [ ] Task 2.3: Move configuration files
  - Dependencies: [2.1]
  - Estimated time: 0.5 hours
  - Validation: ORCHESTRATOR.md in `.task-orchestrator/config/`

- [ ] Task 2.4: Create migration script
  - Dependencies: [2.2, 2.3]
  - Estimated time: 1 hour
  - Validation: Script successfully migrates test installation

### Phase 3: Testing & Validation
- [ ] Task 3.1: Test all core commands
  - Dependencies: [2.4]
  - Estimated time: 1 hour
  - Validation: init, add, list, update, complete all work

- [ ] Task 3.2: Test migration from old structure
  - Dependencies: [3.1]
  - Estimated time: 1 hour
  - Validation: Old installation migrates without data loss

- [ ] Task 3.3: Test fresh installation
  - Dependencies: [3.1]
  - Estimated time: 0.5 hours
  - Validation: Clean install has only `tm` in root

- [ ] Task 3.4: Update packaging scripts
  - Dependencies: [3.3]
  - Estimated time: 1 hour
  - Validation: Package creates correct structure

### Phase 4: Documentation & Release
- [ ] Task 4.1: Update installation documentation
  - Dependencies: [3.4]
  - Estimated time: 0.5 hours
  - Validation: Docs reflect new structure

- [ ] Task 4.2: Update .gitignore template
  - Dependencies: [4.1]
  - Estimated time: 0.25 hours
  - Validation: Correct patterns for new structure

- [ ] Task 4.3: Create release package
  - Dependencies: [4.2]
  - Estimated time: 0.5 hours
  - Validation: v2.8.0 package with new structure

## Risk Analysis
| Risk | Probability | Impact | Mitigation |
|------|-------------|---------|------------|
| Import path issues | Medium | High | Thorough testing of all imports |
| Breaking existing installations | Low | High | Backward compatibility in wrapper |
| Migration script fails | Medium | Medium | Manual migration instructions |
| Performance impact from path resolution | Low | Low | Benchmark before/after |

## Rollback Strategy
1. Keep backup of current package structure
2. Revert tm wrapper to original version
3. Move files back to root if needed
4. Document any issues encountered
5. Restore from backup package if necessary