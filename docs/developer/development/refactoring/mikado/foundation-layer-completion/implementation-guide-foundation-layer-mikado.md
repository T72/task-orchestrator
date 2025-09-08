# Mikado Method Implementation Guide: Foundation Layer Completion

## Pre-Execution Validation
- [ ] PRD v2.4 requirements understood
- [ ] Current validation scores baseline recorded
- [ ] Test environment ready (project-local database)
- [ ] Rollback plan documented
- [ ] All existing tests passing

## Phase 1: Circular Dependency Detection (FR-042)

### Task 1.1: Implement Dependency Graph Builder
- [ ] Create `src/dependency_graph.py` module
- [ ] Implement `DependencyGraph` class with add_node/add_edge methods
- [ ] Add topological sort capability
- [ ] Write unit tests for graph operations
- [ ] **VALIDATION**: Run `python3 -m pytest src/test_dependency_graph.py`
- [ ] Update Mikado graph status (CD1 → completed)
- [ ] Commit: `feat: Add dependency graph builder for circular detection`

### Task 1.2: Add Cycle Detection Algorithm
- [ ] Implement DFS-based cycle detection in `DependencyGraph`
- [ ] Add method to return cycle path if found
- [ ] Handle self-loops and multi-edges
- [ ] Write tests with known circular dependencies
- [ ] **VALIDATION**: Test detects A→B→C→A cycle correctly
- [ ] Update Mikado graph status (CD2 → completed)
- [ ] Commit: `feat: Add cycle detection to dependency graph`

### Task 1.3: Integrate with task-dependencies Hook
- [ ] Modify `.claude/hooks/task-dependencies.py`
- [ ] Build graph from task dependencies on each check
- [ ] Block task creation if cycle detected
- [ ] Add clear error message with cycle path
- [ ] Test with `tm add` commands that create cycles
- [ ] **VALIDATION**: `tm add "A" && tm add "B" --depends-on A && tm add "C" --depends-on B && tm add "A" --depends-on C` shows error
- [ ] Update Mikado graph status (CD3 → completed)
- [ ] Commit: `feat: Integrate circular dependency detection in hooks`

## Phase 2: Critical Path Visualization (FR-043)

### Task 2.1: Implement Longest Path Algorithm
- [ ] Add `find_critical_path()` method to DependencyGraph
- [ ] Implement DAG longest path using dynamic programming
- [ ] Calculate path weights based on task estimates
- [ ] Write unit tests with complex graphs
- [ ] **VALIDATION**: Correctly identifies longest path in test graphs
- [ ] Update Mikado graph status (CP1 → completed)
- [ ] Commit: `feat: Add critical path algorithm to dependency graph`

### Task 2.2: Add Blocking Task Identification
- [ ] Identify tasks on critical path as blockers
- [ ] Mark tasks with multiple dependents as high-impact
- [ ] Calculate blocking score for each task
- [ ] Write tests for blocker identification
- [ ] **VALIDATION**: Correctly identifies bottleneck tasks
- [ ] Update Mikado graph status (CP2 → completed)
- [ ] Commit: `feat: Add blocking task identification`

### Task 2.3: Create Visualization Output
- [ ] Add `tm critical-path` command to wrapper
- [ ] Generate ASCII or Mermaid graph of critical path
- [ ] Highlight blocking tasks in red
- [ ] Show estimated completion time
- [ ] Test with real task database
- [ ] **VALIDATION**: `./tm critical-path` produces readable output
- [ ] Update Mikado graph status (CP3 → completed)
- [ ] Commit: `feat: Add critical path visualization command`

## Phase 3: Enhanced PRD Parsing (FR-044)

### Task 3.1: Improve PRD Format Detection
- [ ] Enhance `.claude/hooks/prd-to-tasks.py`
- [ ] Add regex patterns for common PRD formats
- [ ] Support markdown headers as phases
- [ ] Detect numbered lists as tasks
- [ ] Write tests with various PRD formats
- [ ] **VALIDATION**: Correctly parses 5 different PRD formats
- [ ] Update Mikado graph status (PRD1 → completed)
- [ ] Commit: `feat: Enhance PRD format detection patterns`

### Task 3.2: Extract Phase Dependencies Automatically
- [ ] Parse "Phase X requires Phase Y" patterns
- [ ] Detect "depends on", "after", "requires" keywords
- [ ] Build dependency graph from parsed structure
- [ ] Generate appropriate task metadata
- [ ] Test with complex multi-phase PRDs
- [ ] **VALIDATION**: Correctly extracts dependencies from test PRDs
- [ ] Update Mikado graph status (PRD2 → completed)
- [ ] Commit: `feat: Add automatic phase dependency extraction`

### Task 3.3: Write Tasks to shared-context.md
- [ ] Modify PRD parser to update shared context
- [ ] Format tasks in markdown with metadata
- [ ] Include phase relationships in context
- [ ] Preserve existing context content
- [ ] Test context file generation
- [ ] **VALIDATION**: `.task-orchestrator/context/shared-context.md` updated correctly
- [ ] Update Mikado graph status (PRD3 → completed)
- [ ] Commit: `feat: Write parsed PRD tasks to shared context`

## Phase 4: Retry Mechanism (FR-045)

### Task 4.1: Implement Exponential Backoff Logic
- [ ] Create `src/retry_utils.py` module
- [ ] Implement exponential backoff with jitter
- [ ] Support configurable max retries and base delay
- [ ] Add circuit breaker pattern
- [ ] Write unit tests for retry logic
- [ ] **VALIDATION**: Tests verify 1s, 2s, 4s, 8s backoff sequence
- [ ] Update Mikado graph status (RM1 → completed)
- [ ] Commit: `feat: Add exponential backoff retry utilities`

### Task 4.2: Add Retry Wrapper for Hooks
- [ ] Create decorator for hook functions
- [ ] Handle transient exceptions (network, locks)
- [ ] Log retry attempts and failures
- [ ] Preserve original error on final failure
- [ ] Test with simulated failures
- [ ] **VALIDATION**: Hook retries 3 times before failing
- [ ] Update Mikado graph status (RM2 → completed)
- [ ] Commit: `feat: Add retry wrapper for hook execution`

### Task 4.3: Integrate with event-flows Hook
- [ ] Apply retry wrapper to event-flows.py
- [ ] Configure retries for different event types
- [ ] Add retry metrics to telemetry
- [ ] Test with transient failures
- [ ] **VALIDATION**: Events retry and eventually succeed
- [ ] Update Mikado graph status (RM3 → completed)
- [ ] Commit: `feat: Integrate retry mechanism with event flows`

## Phase 5: Context & Notification Enhancement

### Task 5.1: Auto-generate Shared Context
- [ ] Create context generation templates
- [ ] Auto-populate from task metadata
- [ ] Update on task state changes
- [ ] Include specialist assignments
- [ ] Test context generation
- [ ] **VALIDATION**: Context auto-updates with task changes
- [ ] Update Mikado graph status (CE1 → completed)
- [ ] Commit: `feat: Add auto-generation of shared context`

### Task 5.2: Extend Checkpoints with Private Notes
- [ ] Modify checkpoint-manager.py
- [ ] Include note references in checkpoint data
- [ ] Link to agent-specific note files
- [ ] Preserve notes on resume
- [ ] Test checkpoint/resume with notes
- [ ] **VALIDATION**: Notes preserved across checkpoint/resume
- [ ] Update Mikado graph status (CE2 → completed)
- [ ] Commit: `feat: Extend checkpoints to include private notes`

### Task 5.3: Implement Broadcast for Team Events
- [ ] Create event broadcasting system
- [ ] Write to `.task-orchestrator/notifications/broadcast.md`
- [ ] Include task completions, blocks, help requests
- [ ] Format with timestamps and priorities
- [ ] Test broadcast generation
- [ ] **VALIDATION**: Events appear in broadcast.md
- [ ] Update Mikado graph status (CE3 → completed)
- [ ] Commit: `feat: Add event broadcasting for team coordination`

## Phase 6: Integration Testing

### Task 6.1: Run v2.1 Validation Script
- [ ] Execute `./tests/prd-validation/test_v2.1_requirements.sh`
- [ ] Record new success rate
- [ ] Debug any failing requirements
- [ ] Fix issues found
- [ ] Re-run until score >85%
- [ ] **VALIDATION**: v2.1 success rate >85% (up from 56%)
- [ ] Update Mikado graph status (T1 → completed)
- [ ] Commit: `test: Achieve 85% v2.1 PRD satisfaction`

### Task 6.2: Run All PRD Validation Scripts
- [ ] Run v1.0 validation (target: maintain 80%)
- [ ] Run v2.0 validation (target: maintain 76%)
- [ ] Run v2.2 validation (target: maintain 86%)
- [ ] Run v2.3 validation (target: maintain 81%)
- [ ] Fix any regressions found
- [ ] **VALIDATION**: All versions maintain or improve scores
- [ ] Update Mikado graph status (T2 → completed)
- [ ] Commit: `test: Verify no regression across all PRD versions`

### Task 6.3: Performance Benchmarking
- [ ] Measure hook execution times
- [ ] Profile dependency graph operations
- [ ] Check retry mechanism overhead
- [ ] Optimize hot paths if needed
- [ ] Document performance metrics
- [ ] **VALIDATION**: Average hook overhead <10ms
- [ ] Update Mikado graph status (T3 → completed)
- [ ] Commit: `perf: Ensure hook overhead remains under 10ms`

## Final Validation
- [ ] All unit tests passing
- [ ] All integration tests passing
- [ ] v2.1 score >85%
- [ ] Overall PRD satisfaction >90%
- [ ] Performance benchmarks met (<10ms)
- [ ] No regression in any PRD version
- [ ] Documentation updated

## Post-Execution
- [ ] Update PRD v2.4 with completion status
- [ ] Document lessons learned
- [ ] Create release notes for v2.4
- [ ] Archive Mikado artifacts
- [ ] Update CHANGELOG.md
- [ ] Tag release v2.4.0