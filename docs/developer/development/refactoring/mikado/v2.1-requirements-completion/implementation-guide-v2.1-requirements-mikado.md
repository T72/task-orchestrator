# Mikado Method Implementation Guide: Complete v2.1 Requirements to 85%

## Pre-Execution Validation
- [ ] Current v2.1 score confirmed at 65%
- [ ] All test scripts executable
- [ ] Backup of current implementation created
- [ ] PRD v2.1 specification available for reference

## Phase 1: Critical Path Integration (FR1.4)

### Task 1.1: Auto-update shared context with critical path
- [ ] Modify `src/context_generator.py` to include critical path
- [ ] Import dependency graph module
- [ ] Calculate critical path from current tasks
- [ ] Add critical path section to context template
- [ ] Test context generation with sample tasks
- [ ] **VALIDATION**: Run `python3 src/context_generator.py` and verify critical path appears
- [ ] Commit: `feat: Add critical path to auto-generated context`

### Task 1.2: Hook integration for critical path updates
- [ ] Create hook trigger for task state changes
- [ ] Call context generator on task completion
- [ ] Update critical path when dependencies change
- [ ] Test with task state transitions
- [ ] **VALIDATION**: Complete a task and verify context updates
- [ ] Commit: `feat: Auto-update critical path on task changes`

## Phase 2: Specialist Assignment Preservation (FR3.3-3.4)

### Task 2.1: Enhance PRD parser specialist assignment
- [ ] Review current specialist detection logic
- [ ] Ensure specialists written to shared context
- [ ] Add specialist summary section
- [ ] Test with various PRD formats
- [ ] **VALIDATION**: Parse PRD and verify specialists in context
- [ ] Commit: `feat: Enhance specialist assignment in PRD parser`

### Task 2.2: Metadata preservation in shared state
- [ ] Ensure metadata persists through updates
- [ ] Add metadata validation in hooks
- [ ] Preserve custom fields from PRD
- [ ] Test metadata retention
- [ ] **VALIDATION**: Update task and verify metadata preserved
- [ ] Commit: `feat: Preserve task metadata in shared state`

## Phase 3: Advanced Notifications (FR4.2-4.4)

### Task 3.1: Retry notifications via broadcast
- [ ] Modify retry logic to broadcast events
- [ ] Add retry event type to broadcaster
- [ ] Include retry count and reason
- [ ] Test retry broadcast
- [ ] **VALIDATION**: Trigger retry and check broadcast.md
- [ ] Commit: `feat: Broadcast retry notifications`

### Task 3.2: Help request notifications
- [ ] Add help_requested event type
- [ ] Create help request detection logic
- [ ] Broadcast to relevant specialists
- [ ] Test help request flow
- [ ] **VALIDATION**: Trigger help request and verify broadcast
- [ ] Commit: `feat: Add help request broadcasting`

### Task 3.3: Complexity alerts broadcast
- [ ] Define complexity thresholds
- [ ] Add complexity detection to task analysis
- [ ] Broadcast when threshold exceeded
- [ ] Test with complex tasks
- [ ] **VALIDATION**: Create complex task and verify alert
- [ ] Commit: `feat: Broadcast complexity alerts`

## Phase 4: Team Coordination (FR5.2-5.4)

### Task 4.1: Coordination via shared context
- [ ] Add team coordination section to context
- [ ] Track specialist interactions
- [ ] Show handoff points
- [ ] Test team coordination flow
- [ ] **VALIDATION**: Verify teams coordinate through context
- [ ] Commit: `feat: Enable team coordination via shared context`

### Task 4.2: Private notes for agent state
- [ ] Ensure private notes directory exists
- [ ] Create note templates for each specialist
- [ ] Add state preservation logic
- [ ] Test state recovery from notes
- [ ] **VALIDATION**: Check agent notes created and updated
- [ ] Commit: `feat: Preserve agent state in private notes`

### Task 4.3: Broadcast for team events
- [ ] Define team event types
- [ ] Add team event broadcasting
- [ ] Include team member notifications
- [ ] Test team event flow
- [ ] **VALIDATION**: Trigger team event and verify broadcast
- [ ] Commit: `feat: Broadcast team coordination events`

## Phase 5: Compliance Features (COMP1, COMP3)

### Task 5.1: Auto-generate shared context on changes
- [ ] Add file watchers for task changes
- [ ] Trigger context generation automatically
- [ ] Debounce rapid changes
- [ ] Test auto-generation
- [ ] **VALIDATION**: Change task and verify context updates
- [ ] Commit: `feat: Auto-generate context on task changes`

### Task 5.2: Event broadcasts compliance
- [ ] Ensure all required events broadcast
- [ ] Add missing event types
- [ ] Verify broadcast format compliance
- [ ] Test all event types
- [ ] **VALIDATION**: Check all events appear in broadcast.md
- [ ] Commit: `feat: Complete event broadcast compliance`

## Phase 6: Validation & Testing

### Task 6.1: Run v2.1 validation
- [ ] Execute `./tests/prd-validation/test_v2.1_requirements.sh`
- [ ] Record new score
- [ ] Identify any remaining gaps
- [ ] Fix any issues found
- [ ] **VALIDATION**: Score ≥85%
- [ ] Document final score

### Task 6.2: Regression testing
- [ ] Run v1.0 validation
- [ ] Run v2.0 validation
- [ ] Run v2.2 validation
- [ ] Run v2.3 validation
- [ ] **VALIDATION**: No score decreases
- [ ] Commit: `test: Achieve 85% v2.1 compliance`

## Final Validation
- [ ] v2.1 score ≥85%
- [ ] All other versions maintained/improved
- [ ] No performance degradation
- [ ] All tests passing
- [ ] Documentation updated

## Post-Execution
- [ ] Update CHANGELOG.md
- [ ] Document lessons learned
- [ ] Archive Mikado artifacts
- [ ] Create release notes for v2.1 completion