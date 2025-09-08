# Mikado Method Implementation Guide: Complete Requirements Traceability

## Pre-Execution Validation
- [ ] Current traceability score confirmed at 78%
- [ ] Requirements validation script functional: `./scripts/validate-requirements.sh`
- [ ] Comprehensive test suite operational: `./tests/test_comprehensive.sh`
- [ ] Git working directory clean for incremental commits
- [ ] CLAUDE.md standards documented for requirement annotations

## Phase 1: Investigation & Analysis

### Task 1.1: Research Missing Requirements FR-024, FR-025, FR-026
- [ ] Search for FR-024 in requirement documents
  - Location: `grep -r "FR-024" docs/specifications/requirements/`
  - Extract: Purpose, acceptance criteria, implementation details
  - Document: What functionality is missing
- [ ] Search for FR-025 in requirement documents  
  - Location: `grep -r "FR-025" docs/specifications/requirements/`
  - Extract: Purpose, acceptance criteria, implementation details
  - Document: Dependencies on other requirements
- [ ] Search for FR-026 in requirement documents
  - Location: `grep -r "FR-026" docs/specifications/requirements/`
  - Extract: Purpose, acceptance criteria, implementation details
  - Document: Integration with existing systems
- [ ] **VALIDATION**: Create summary document with implementation plan for each requirement
- [ ] Update Mikado graph status: Research → COMPLETED
- [ ] Commit: `git commit -m "docs: Research missing requirements FR-024, FR-025, FR-026"`

### Task 1.2: Analyze Orphaned Files for Appropriate Annotations
- [ ] Examine `src/__init__.py`
  - Identify: Main purpose and functionality provided
  - Map to: Appropriate requirement categories (CORE, API, SYS)
  - Plan: Specific @implements annotations to add
- [ ] Examine `src/tm_orchestrator.py`
  - Identify: Orchestration and project management features
  - Map to: Collaboration, workflow, or orchestration requirements
  - Plan: Specific @implements annotations for main classes/methods
- [ ] Examine `src/tm_worker.py`  
  - Identify: Worker/agent functionality and capabilities
  - Map to: Agent specialization or execution requirements
  - Plan: Specific @implements annotations for worker features
- [ ] **VALIDATION**: Annotation plan documented for each file with requirement mappings
- [ ] Update Mikado graph status: Analyze → COMPLETED
- [ ] Commit: `git commit -m "docs: Plan requirement annotations for orphaned files"`

## Phase 2: Quick Wins (File Annotations)

### Task 2.1: Add Annotations to src/__init__.py
- [ ] Read file to understand current content and purpose
- [ ] Add appropriate module-level docstring with @implements annotations
- [ ] Focus on: Package initialization, module exports, core functionality
- [ ] Example pattern:
  ```python
  """
  Task Orchestrator package initialization.
  
  @implements SYS-001: System Package Structure
  @implements API-001: Python Package Interface
  """
  ```
- [ ] **VALIDATION**: Run `./scripts/validate-requirements.sh | grep __init__.py` shows "HAS REQUIREMENTS"
- [ ] Update Mikado graph status: Ann1 → COMPLETED
- [ ] Commit: `git commit -m "feat: Add requirement annotations to __init__.py"`

### Task 2.2: Add Annotations to src/tm_orchestrator.py
- [ ] Read file to understand orchestration features and main classes
- [ ] Add @implements annotations to main class docstring
- [ ] Add @implements annotations to key methods (project creation, coordination, etc.)
- [ ] Focus on: Multi-project orchestration, coordination protocols, handoff management
- [ ] Example pattern:
  ```python
  class ProjectOrchestrator:
      """
      Manages multi-project coordination and handoffs.
      
      @implements COLLAB-007: Project Orchestration
      @implements COLLAB-008: Multi-Agent Coordination
      @implements WORKFLOW-001: Project Workflow Management
      """
  ```
- [ ] **VALIDATION**: Run `./scripts/validate-requirements.sh | grep tm_orchestrator.py` shows "HAS REQUIREMENTS"
- [ ] Update Mikado graph status: Ann2 → COMPLETED
- [ ] Commit: `git commit -m "feat: Add requirement annotations to tm_orchestrator.py"`

### Task 2.3: Add Annotations to src/tm_worker.py
- [ ] Read file to understand worker/agent functionality
- [ ] Add @implements annotations to main class docstring
- [ ] Add @implements annotations to key methods (work execution, reporting, etc.)
- [ ] Focus on: Agent specialization, work execution, progress reporting
- [ ] Example pattern:
  ```python
  class SpecializedWorker:
      """
      Handles specialized work execution and reporting.
      
      @implements AGENT-001: Agent Specialization System
      @implements AGENT-002: Work Execution Framework
      @implements AGENT-003: Progress Reporting
      """
  ```
- [ ] **VALIDATION**: Run `./scripts/validate-requirements.sh | grep tm_worker.py` shows "HAS REQUIREMENTS"
- [ ] Update Mikado graph status: Ann3 → COMPLETED  
- [ ] Commit: `git commit -m "feat: Add requirement annotations to tm_worker.py"`

## Phase 3: Missing Requirements Implementation

### Task 3.1: Implement FR-024 Requirement
- [ ] **PREREQUISITE**: Review research from Task 1.1 for FR-024 specification
- [ ] Identify implementation location (existing file vs new file)
- [ ] Design minimal implementation approach that satisfies requirement
- [ ] Implement core functionality with proper error handling
- [ ] Add @implements FR-024 annotation to implementation
- [ ] Write unit test to validate requirement satisfaction
- [ ] **VALIDATION**: 
  - [ ] Unit test passes: `python -m pytest tests/test_fr_024.py -v`
  - [ ] Requirements script shows: `FR-024: IMPLEMENTED`
  - [ ] No regression in existing tests: `./tests/test_comprehensive.sh`
- [ ] Update Mikado graph status: Impl1 → COMPLETED
- [ ] Commit: `git commit -m "feat: Implement FR-024 [requirement description]"`

### Task 3.2: Implement FR-025 Requirement
- [ ] **PREREQUISITE**: Review research from Task 1.1 for FR-025 specification
- [ ] Check dependencies on FR-024 implementation
- [ ] Identify implementation location and integration points
- [ ] Design implementation approach considering existing architecture
- [ ] Implement functionality with proper @implements annotation
- [ ] Write unit tests for new functionality
- [ ] **VALIDATION**:
  - [ ] Unit test passes: `python -m pytest tests/test_fr_025.py -v`
  - [ ] Requirements script shows: `FR-025: IMPLEMENTED`
  - [ ] Integration with FR-024 works correctly
  - [ ] No regression in existing tests: `./tests/test_comprehensive.sh`
- [ ] Update Mikado graph status: Impl2 → COMPLETED
- [ ] Commit: `git commit -m "feat: Implement FR-025 [requirement description]"`

### Task 3.3: Implement FR-026 Requirement  
- [ ] **PREREQUISITE**: Review research from Task 1.1 for FR-026 specification
- [ ] Check dependencies on FR-024 and FR-025 implementations
- [ ] Identify implementation location and system integration
- [ ] Design implementation approach for system coherence
- [ ] Implement functionality with proper @implements annotation
- [ ] Write comprehensive unit tests
- [ ] **VALIDATION**:
  - [ ] Unit test passes: `python -m pytest tests/test_fr_026.py -v`
  - [ ] Requirements script shows: `FR-026: IMPLEMENTED`
  - [ ] Integration with FR-024 and FR-025 works correctly
  - [ ] No regression in existing tests: `./tests/test_comprehensive.sh`
- [ ] Update Mikado graph status: Impl3 → COMPLETED
- [ ] Commit: `git commit -m "feat: Implement FR-026 [requirement description]"`

## Phase 4: Final Validation & Testing

### Task 4.1: Run Comprehensive Requirements Validation
- [ ] Execute full requirements validation: `./scripts/validate-requirements.sh`
- [ ] Verify scores meet targets:
  - [ ] Forward Traceability: ≥90% (≥22/24 requirements)
  - [ ] Backward Traceability: ≥85% (≥8/10 files)  
  - [ ] Overall Score: ≥90%
- [ ] Capture validation output for documentation
- [ ] **VALIDATION**: Green "Requirements traceability validation PASSED" message
- [ ] Update Mikado graph status: Validate → COMPLETED
- [ ] Document results in task completion notes

### Task 4.2: Run Comprehensive Test Suite
- [ ] Execute full test suite: `./tests/test_comprehensive.sh`
- [ ] Verify 100% test pass rate (28/28 tests passing)
- [ ] Run additional test suites if available:
  - [ ] `./tests/test_tm.sh` - Basic functionality
  - [ ] `./tests/test_edge_cases.sh` - Edge cases
  - [ ] `./tests/test_collaboration.sh` - Collaboration features
- [ ] **VALIDATION**: All test suites show 100% pass rate
- [ ] Update Mikado graph status: TestSuite → COMPLETED
- [ ] Commit: `git commit -m "test: Validate all tests pass after traceability improvements"`

### Task 4.3: Update Documentation
- [ ] Update CLAUDE.md success patterns with traceability achievement
- [ ] Add achievement to Success Patterns section:
  ```markdown
  12. **Requirements Traceability Excellence**
   - Systematic Mikado method application achieves 90%+ traceability
   - Forward traceability 95%+ (requirements → implementation)  
   - Backward traceability 100% (code → requirements)
   - Automated validation prevents future drift
   - Bidirectional links enable impact analysis
  ```
- [ ] Update session reflection log with completion details
- [ ] Document lessons learned for future traceability work
- [ ] **VALIDATION**: Documentation changes committed and accurate
- [ ] Update Mikado graph status: UpdateDocs → COMPLETED
- [ ] Commit: `git commit -m "docs: Document requirements traceability achievement"`

## Final Validation Checklist

- [ ] **Traceability Score**: ≥90% overall achieved
- [ ] **Forward Traceability**: 24/24 requirements implemented (100%)
- [ ] **Backward Traceability**: 10/10 files annotated (100%)
- [ ] **Test Coverage**: All tests passing (100%)
- [ ] **Documentation**: Success patterns updated
- [ ] **Git History**: Clean incremental commits with clear messages
- [ ] **Validation Script**: Returns GREEN status

## Post-Execution Actions

- [ ] Archive Mikado artifacts to completed folder
- [ ] Update task status to completed in todo tracking
- [ ] Document total time spent for future estimation reference
- [ ] Share achievement with stakeholders
- [ ] Schedule next requirements validation for maintenance (weekly)

## Success Metrics Summary

**Target Achievement**:
- ✅ 90%+ overall traceability score
- ✅ All orphaned files properly annotated
- ✅ All missing requirements implemented  
- ✅ Comprehensive validation passed
- ✅ No functional regression

**Estimated Completion Time**: 10-13 hours across 2-3 work sessions