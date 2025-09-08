# Mikado Method Implementation Guide: Core Loop Enhancement

## Pre-Execution Validation
- [ ] All 6 TDD test suites reviewed and understood
- [ ] PRD v2.3 requirements (64 total) confirmed
- [ ] Development environment ready (Python 3.8+, SQLite3)
- [ ] Backup of current tasks.db created
- [ ] Test runner verified: `./tests/run_core_loop_tests.sh`

## Phase 1: Foundation Tasks (Week 1)

### Task 1.1: Create Migration Infrastructure
- [ ] Create `src/migrations/` directory structure
- [ ] Implement `MigrationManager` class with version tracking
- [ ] Add migration table to track applied migrations
- [ ] Create `tm migrate` command stub in wrapper script
- [ ] **VALIDATION**: Run `./tests/test_core_loop_migration.sh` - Test 1 passes
- [ ] Commit: "feat: Add migration infrastructure for Core Loop"

### Task 1.2: Design Core Loop Schema Extensions
- [ ] Document new fields in `docs/reference/core-loop-schema.md`:
  - success_criteria (TEXT/JSON, nullable)
  - feedback_quality (INTEGER 1-5, nullable)
  - feedback_timeliness (INTEGER 1-5, nullable)
  - feedback_notes (TEXT, nullable)
  - completion_summary (TEXT, nullable)
  - deadline (TEXT/ISO8601, nullable)
  - estimated_hours (REAL, nullable)
  - actual_hours (REAL, nullable)
- [ ] Create SQL migration file: `001_add_core_loop_fields.sql`
- [ ] **VALIDATION**: Schema design reviewed and documented
- [ ] Commit: "docs: Design Core Loop database schema extensions"

### Task 1.3: Implement Safe Schema Migration
- [ ] Write migration up() method to add new columns
- [ ] Ensure all new fields are nullable for backward compatibility
- [ ] Add transaction wrapper for atomic migrations
- [ ] Implement dry-run mode for migration preview
- [ ] **VALIDATION**: Run `./tests/test_core_loop_schema.sh` - Tests 1-2 pass
- [ ] **VALIDATION**: Run `./tests/test_core_loop_migration.sh` - Test 2 passes
- [ ] Commit: "feat: Implement safe schema migration for Core Loop"

### Task 1.4: Add Backup and Rollback Mechanisms
- [ ] Create `.task-orchestrator/backups/` directory structure
- [ ] Implement automatic backup before migration
- [ ] Add timestamp to backup filenames
- [ ] Implement rollback() method to restore from backup
- [ ] Add migration status tracking
- [ ] **VALIDATION**: Run `./tests/test_core_loop_migration.sh` - Tests 3-7 pass
- [ ] Commit: "feat: Add backup and rollback for migrations"

### Task 1.5: Ensure Idempotent Migrations
- [ ] Add version checking to prevent duplicate migrations
- [ ] Implement "already applied" detection
- [ ] Add migration locking to prevent concurrent migrations
- [ ] **VALIDATION**: Run `./tests/test_core_loop_migration.sh` - Tests 8-10 pass
- [ ] **VALIDATION**: All migration tests passing
- [ ] Commit: "feat: Make migrations idempotent and safe"

## Phase 2: Configuration Management (Week 2)

### Task 2.1: Create Configuration Command Structure
- [ ] Add `config` command to tm wrapper script
- [ ] Create `ConfigManager` class in Python
- [ ] Implement basic --help for config command
- [ ] Add config file location: `.task-orchestrator/config.yaml`
- [ ] **VALIDATION**: Run `./tests/test_core_loop_configuration.sh` - Test 1 passes
- [ ] Commit: "feat: Add configuration command structure"

### Task 2.2: Implement Feature Toggles
- [ ] Define feature flags: success-criteria, feedback, telemetry
- [ ] Implement --enable and --disable flags
- [ ] Create feature registry with default states
- [ ] Add feature checking in main code paths
- [ ] **VALIDATION**: Run `./tests/test_core_loop_configuration.sh` - Tests 2-3 pass
- [ ] Commit: "feat: Implement feature toggle system"

### Task 2.3: Add Minimal Mode Support
- [ ] Implement --minimal-mode flag
- [ ] Ensure minimal mode disables all Core Loop features
- [ ] Add bypass logic in task creation/completion
- [ ] **VALIDATION**: Run `./tests/test_core_loop_configuration.sh` - Test 4 passes
- [ ] Commit: "feat: Add minimal mode for Core Loop bypass"

### Task 2.4: Persist Configuration to YAML
- [ ] Implement YAML read/write for config
- [ ] Add --show flag to display current config
- [ ] Implement --reset to restore defaults
- [ ] Ensure config persists across sessions
- [ ] **VALIDATION**: Run `./tests/test_core_loop_configuration.sh` - Tests 5-10 pass
- [ ] **VALIDATION**: All configuration tests passing
- [ ] Commit: "feat: Add persistent YAML configuration"

## Phase 3: Success Criteria Implementation (Week 2-3)

### Task 3.1: Add success_criteria Field to Database
- [ ] Apply migration to add success_criteria column
- [ ] Update Task model with criteria field
- [ ] Ensure field accepts JSON array format
- [ ] **VALIDATION**: Run `./tests/test_core_loop_schema.sh` - Test 3 passes
- [ ] Commit: "feat: Add success_criteria database field"

### Task 3.2: Implement Criteria Parsing and Storage
- [ ] Add --criteria flag to `tm add` command
- [ ] Parse JSON criteria format
- [ ] Validate criteria structure (criterion, measurable)
- [ ] Store criteria in database
- [ ] Display criteria in `tm show` command
- [ ] **VALIDATION**: Run `./tests/test_core_loop_success_criteria.sh` - Tests 1-3 pass
- [ ] Commit: "feat: Implement success criteria parsing"

### Task 3.3: Add Validation at Task Completion
- [ ] Add --validate flag to `tm complete` command
- [ ] Check each criterion at completion
- [ ] Report validation results
- [ ] Block completion if validation fails (when flag used)
- [ ] **VALIDATION**: Run `./tests/test_core_loop_success_criteria.sh` - Tests 4-7 pass
- [ ] Commit: "feat: Add criteria validation at completion"

### Task 3.4: Create Criteria Reporting
- [ ] Add criteria status to task display
- [ ] Show percentage of criteria met
- [ ] Add criteria summary to list view
- [ ] **VALIDATION**: Run `./tests/test_core_loop_success_criteria.sh` - Tests 8-10 pass
- [ ] **VALIDATION**: All success criteria tests passing
- [ ] Commit: "feat: Add success criteria reporting"

## Phase 4: Feedback Mechanism (Week 3)

### Task 4.1: Add Feedback Fields to Database
- [ ] Apply migration for feedback columns
- [ ] Update Task model with feedback fields
- [ ] **VALIDATION**: Run `./tests/test_core_loop_schema.sh` - Test 4 passes
- [ ] Commit: "feat: Add feedback database fields"

### Task 4.2: Implement Feedback Command
- [ ] Add `feedback` command to tm wrapper
- [ ] Create basic feedback submission
- [ ] Store feedback in database
- [ ] **VALIDATION**: Run `./tests/test_core_loop_feedback.sh` - Tests 1-3 pass
- [ ] Commit: "feat: Implement feedback command"

### Task 4.3: Add Quality Scoring (1-5)
- [ ] Add --quality and --timeliness flags
- [ ] Validate score range (1-5)
- [ ] Add --note for text feedback
- [ ] **VALIDATION**: Run `./tests/test_core_loop_feedback.sh` - Tests 4-6 pass
- [ ] Commit: "feat: Add quality scoring to feedback"

### Task 4.4: Create Metrics Aggregation
- [ ] Add `metrics` command with --feedback flag
- [ ] Calculate average quality scores
- [ ] Show feedback distribution
- [ ] Export metrics as JSON
- [ ] **VALIDATION**: Run `./tests/test_core_loop_feedback.sh` - Tests 7-10 pass
- [ ] **VALIDATION**: All feedback tests passing
- [ ] Commit: "feat: Add feedback metrics aggregation"

## Phase 5: Completion Summaries (Week 3)

### Task 5.1: Add completion_summary Field
- [ ] Apply migration for summary field
- [ ] Update Task model
- [ ] **VALIDATION**: Run `./tests/test_core_loop_schema.sh` - Test 5 passes
- [ ] Commit: "feat: Add completion summary field"

### Task 5.2: Implement Summary Capture at Completion
- [ ] Add --summary flag to `tm complete`
- [ ] Store summary with task
- [ ] Display summary in task details
- [ ] **VALIDATION**: Integration test step 7 passes
- [ ] Commit: "feat: Capture completion summaries"

## Phase 6: Additional Core Loop Features (Week 3-4)

### Task 6.1: Add Deadline Support
- [ ] Apply migration for deadline field
- [ ] Add --deadline flag to `tm add`
- [ ] Parse ISO8601 date format
- [ ] Show deadline in task display
- [ ] **VALIDATION**: Run `./tests/test_core_loop_schema.sh` - Test 6 passes
- [ ] Commit: "feat: Add deadline support"

### Task 6.2: Add Time Tracking Fields
- [ ] Apply migration for time tracking fields
- [ ] Add --estimated-hours to `tm add`
- [ ] Add --actual-hours to `tm complete`
- [ ] Calculate time variance
- [ ] **VALIDATION**: Run `./tests/test_core_loop_schema.sh` - Tests 7-8 pass
- [ ] Commit: "feat: Add time tracking fields"

## Phase 7: Telemetry & Analytics (Week 4)

### Task 7.1: Create Telemetry Infrastructure
- [ ] Create `.task-orchestrator/telemetry/` directory
- [ ] Implement event logging system
- [ ] Add telemetry configuration option
- [ ] Create JSON event format
- [ ] **VALIDATION**: Telemetry files created when enabled
- [ ] Commit: "feat: Add telemetry infrastructure"

### Task 7.2: Capture Core Loop Events
- [ ] Log task creation with criteria
- [ ] Log completion with validation results
- [ ] Log feedback submissions
- [ ] Add daily aggregation
- [ ] **VALIDATION**: Integration test step 13 passes
- [ ] Commit: "feat: Capture Core Loop telemetry events"

## Phase 8: Integration & Final Validation (Week 4-5)

### Task 8.1: Full End-to-End Workflow Test
- [ ] Run complete integration test
- [ ] Fix any integration issues discovered
- [ ] Verify all 14 integration steps pass
- [ ] **VALIDATION**: Run `./tests/test_core_loop_integration.sh` - All steps pass
- [ ] Commit: "test: Complete Core Loop integration"

### Task 8.2: Backward Compatibility Verification
- [ ] Test legacy task creation without Core Loop features
- [ ] Verify old tasks still work after migration
- [ ] Ensure minimal mode completely disables features
- [ ] **VALIDATION**: Integration test step 11 passes
- [ ] Commit: "test: Verify backward compatibility"

### Task 8.3: Performance Validation
- [ ] Measure task creation time with/without features
- [ ] Check database query performance
- [ ] Verify no memory leaks
- [ ] Document performance metrics
- [ ] **VALIDATION**: No performance regression >10%
- [ ] Commit: "perf: Validate Core Loop performance"

## Final Validation

### Complete Test Suite Validation
- [ ] Run `./tests/run_core_loop_tests.sh`
- [ ] Verify output shows:
  ```
  Total Test Suites: 6
  Executed: 6
  Failed: 0
  ```
- [ ] All individual test files pass 100%
- [ ] Document any deviations from plan

### PRD Compliance Check
- [ ] All 22 new Core Loop requirements implemented
- [ ] All 42 v2.2 requirements still functional
- [ ] Total 64 requirements satisfied

### Documentation Update
- [ ] Update main README with Core Loop features
- [ ] Create user guide for new features
- [ ] Document configuration options
- [ ] Add examples to docs/examples/

## Post-Execution

### Telemetry Analysis (30 days later)
- [ ] Analyze telemetry data for usage patterns
- [ ] Calculate feature adoption rates
- [ ] Measure quality score improvements
- [ ] Prepare Phase 2 recommendations

### Archive Mikado Artifacts
- [ ] Move implementation guide to archived/
- [ ] Create COMPLETION.md with metrics
- [ ] Document lessons learned
- [ ] Update Mikado graph with final state

### Communication
- [ ] Create release notes for v2.3
- [ ] Update CHANGELOG.md
- [ ] Notify stakeholders of completion
- [ ] Share success metrics

## Implementation Metrics Tracking

| Metric | Target | Actual |
|--------|--------|--------|
| Test Suites Passing | 6/6 | _/6 |
| Individual Tests | 60/60 | _/60 |
| Code Coverage | >80% | _% |
| Performance Impact | <10% | _% |
| Migration Success | 100% | _% |
| Backward Compatibility | 100% | _% |

## Notes
- Run tests after EVERY task to catch issues early
- Commit frequently with clear messages
- Update this checklist in real-time as you work
- If blocked, document the issue and try next parallel task
- Keep PRD v2.3 open for requirement reference