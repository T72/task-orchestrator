# Documentation Update Action Plan - Core Loop Implementation

**Generated**: 2025-08-20
**Priority**: EXECUTE BEFORE RELEASE

## CRITICAL PATH - Must Complete Before Any Release

### 1. README.md (UPDATE EXISTING)
**File**: `/README.md`
**Changes**:
```markdown
## 🚀 Core Loop Features (NEW in v2.3)

### Success Criteria & Validation
- Define measurable success criteria for tasks
- Automatic validation on completion
- Support for complex expressions

### Feedback & Metrics
- Collect quality and timeliness feedback
- View aggregated metrics and insights
- Track performance over time

### Progress Tracking
- Add progress updates throughout task lifecycle
- Time tracking with estimated vs actual hours
- Deadline management

### Quick Example
```bash
# Create task with success criteria and deadline
tm add "Implement auth" --criteria '[{"criterion":"Tests pass","measurable":"coverage > 80%"}]' \
  --deadline "2025-12-31T23:59:59Z" --estimated-hours 20

# Track progress
tm progress <task-id> "50% complete - API done"

# Complete with validation
tm complete <task-id> --validate --actual-hours 18 --summary "All requirements met"

# Add feedback
tm feedback <task-id> --quality 5 --timeliness 4 --note "Excellent work"

# View metrics
tm metrics --feedback
```
```

### 2. CHANGELOG.md (UPDATE EXISTING)
**File**: `/CHANGELOG.md`
**Add at top**:
```markdown
## [2.3.0] - 2025-08-20

### Added
- Success criteria definition and validation system
- Feedback mechanism with quality/timeliness scoring
- Progress tracking with detailed updates
- Completion summaries for context preservation
- Metrics aggregation and reporting
- Time tracking (estimated vs actual hours)
- Deadline management
- Configuration system with feature toggles
- Database migration system
- Telemetry and event capture
- 75+ edge case tests

### Changed
- Database path standardized to ~/.task-orchestrator
- Enhanced tm wrapper script with Core Loop commands
- Improved error handling throughout

### Technical
- New modules: migrations, config_manager, telemetry, metrics_calculator, criteria_validator, error_handler
- Database schema: Added 8 new fields for Core Loop features
- Test coverage: Added 3 comprehensive edge case test suites

### Migration Required
Run `tm migrate --apply` after updating to apply database changes.
```

### 3. Migration Guide (CREATE NEW)
**File**: `/docs/migration/v2.3-migration-guide.md`
**Content**:
```markdown
# Migration Guide: v2.2 to v2.3

## Overview
Version 2.3 adds Core Loop features requiring database schema updates.

## Backup First
```bash
cp -r ~/.task-orchestrator ~/.task-orchestrator.backup
```

## Migration Steps

1. Update to v2.3
```bash
git pull origin main
```

2. Apply migrations
```bash
tm migrate --apply
```

3. Verify migration
```bash
tm migrate --status
# Should show: "Applied migrations: 001"
```

## Rollback if Needed
```bash
tm migrate --rollback
# Or restore backup:
rm -rf ~/.task-orchestrator
mv ~/.task-orchestrator.backup ~/.task-orchestrator
```

## New Features Available After Migration
- Success criteria on tasks
- Feedback collection
- Progress tracking
- Metrics viewing
- And more...

## Troubleshooting

### "duplicate column" error
The columns already exist. This is safe to ignore.

### "no such table" error
Run `tm init` first, then `tm migrate --apply`
```

### 4. Quick Start Guide (UPDATE EXISTING)
**File**: `/docs/guides/QUICKSTART-CLAUDE-CODE.md`
**Add new section**:
```markdown
## Core Loop Workflow Example

1. Create a task with success criteria:
```bash
tm add "Build feature X" \
  --criteria '[{"criterion":"All tests pass","measurable":"true"}]' \
  --deadline "2025-12-31T23:59:59Z" \
  --estimated-hours 10
```

2. Track progress:
```bash
tm progress <task-id> "Started implementation"
tm progress <task-id> "50% - Core logic complete"
```

3. Complete with validation:
```bash
tm complete <task-id> --validate --actual-hours 9 \
  --summary "Feature complete with all tests passing"
```

4. Add feedback:
```bash
tm feedback <task-id> --quality 5 --timeliness 5 \
  --note "Delivered ahead of schedule"
```

5. View metrics:
```bash
tm metrics --feedback
```
```

### 5. CLI Reference (CREATE NEW)
**File**: `/docs/reference/cli-commands.md`
**Priority Content**:
```markdown
# CLI Command Reference

## Core Loop Commands

### tm add
Create task with Core Loop features:
```bash
tm add <title> [options]
  --criteria JSON      Success criteria array
  --deadline ISO8601   Task deadline
  --estimated-hours N  Time estimate
```

### tm complete
Complete task with validation:
```bash
tm complete <task-id> [options]
  --validate           Run criteria validation
  --actual-hours N     Actual time spent
  --summary TEXT       Completion summary
```

### tm progress
Add progress update:
```bash
tm progress <task-id> <message>
```

### tm feedback
Add feedback scores:
```bash
tm feedback <task-id> [options]
  --quality N (1-5)    Quality score
  --timeliness N (1-5) Timeliness score
  --note TEXT          Additional notes
```

### tm metrics
View aggregated metrics:
```bash
tm metrics --feedback  Show feedback metrics
```

### tm config
Manage configuration:
```bash
tm config --show                    Show current config
tm config --enable <feature>        Enable feature
tm config --disable <feature>       Disable feature
tm config --minimal-mode            Enable minimal mode
tm config --reset                   Reset to defaults
```

### tm migrate
Manage database migrations:
```bash
tm migrate --status   Check migration status
tm migrate --apply    Apply pending migrations
tm migrate --rollback Rollback last migration
```
```

---

## EXISTING FILES NEEDING UPDATES (15 files)

| File | Priority | Key Updates |
|------|----------|-------------|
| `/README.md` | CRITICAL | Add Core Loop features section, update examples |
| `/CHANGELOG.md` | CRITICAL | Add v2.3.0 entry |
| `/CONTRIBUTING.md` | HIGH | Add Core Loop dev guidelines |
| `/docs/guides/QUICKSTART-CLAUDE-CODE.md` | CRITICAL | Add Core Loop workflow |
| `/docs/guides/USER_GUIDE.md` | HIGH | Document all new features |
| `/docs/guides/DEVELOPER_GUIDE.md` | HIGH | Add module documentation |
| `/docs/guides/TROUBLESHOOTING.md` | HIGH | Add Core Loop issues |
| `/docs/reference/API_REFERENCE.md` | HIGH | Document new methods |
| `/docs/reference/core-loop-schema.md` | HIGH | Update with actual schema |
| `/docs/specifications/requirements/PRD-CORE-LOOP-v2.3.md` | MEDIUM | Mark as IMPLEMENTED |
| `/tests/README-CORE-LOOP-TESTS.md` | MEDIUM | Document test results |
| `/tests/README-EDGE-CASES.md` | DONE | Already documents tests |
| `/deploy/README.md` | MEDIUM | Update deployment steps |
| `/docs/support/README.md` | LOW | Add Core Loop FAQ |
| `/docs/examples/core-loop-examples.md` | MEDIUM | Add real examples |

---

## NEW FILES TO CREATE (20 priority files)

| File | Priority | Purpose |
|------|----------|---------|
| `/docs/migration/v2.3-migration-guide.md` | CRITICAL | Migration instructions |
| `/docs/reference/cli-commands.md` | CRITICAL | Complete CLI reference |
| `/docs/releases/v2.3.0-release-notes.md` | CRITICAL | Detailed release notes |
| `/docs/configuration/config-guide.md` | HIGH | Configuration documentation |
| `/docs/guides/metrics-guide.md` | HIGH | Metrics interpretation |
| `/docs/guides/success-criteria-guide.md` | HIGH | Criteria syntax guide |
| `/docs/guides/feedback-guide.md` | HIGH | Feedback best practices |
| `/docs/architecture/core-loop-architecture.md` | HIGH | System design docs |
| `/docs/api/python-api.md` | MEDIUM | Python API reference |
| `/docs/developer/modules/migrations.md` | MEDIUM | Migration system docs |
| `/docs/developer/modules/config-manager.md` | MEDIUM | Config module docs |
| `/docs/developer/modules/telemetry.md` | MEDIUM | Telemetry docs |
| `/docs/developer/modules/metrics-calculator.md` | MEDIUM | Metrics module docs |
| `/docs/developer/modules/criteria-validator.md` | MEDIUM | Validator docs |
| `/docs/developer/modules/error-handler.md` | MEDIUM | Error handling docs |
| `/docs/testing/test-coverage.md` | LOW | Coverage report |
| `/docs/performance/benchmarks.md` | LOW | Performance metrics |
| `/docs/faq.md` | LOW | Frequently asked questions |
| `/examples/workflows/README.md` | LOW | Example workflows |
| `/docs/tutorial/core-loop-tutorial.md` | LOW | Step-by-step tutorial |

---

## IMMEDIATE ACTION ITEMS (Do First)

### Phase 1: Critical Updates (2-3 hours)
1. ✅ Update `/README.md` with Core Loop section
2. ✅ Update `/CHANGELOG.md` with v2.3.0
3. ✅ Create `/docs/migration/v2.3-migration-guide.md`
4. ✅ Create `/docs/reference/cli-commands.md`
5. ✅ Update `/docs/guides/QUICKSTART-CLAUDE-CODE.md`

### Phase 2: Release Documentation (2-3 hours)
1. Create `/docs/releases/v2.3.0-release-notes.md`
2. Update `/CONTRIBUTING.md` with Core Loop guidelines
3. Update `/docs/guides/USER_GUIDE.md` comprehensively
4. Create `/docs/configuration/config-guide.md`
5. Update `/docs/guides/TROUBLESHOOTING.md`

### Phase 3: Developer Documentation (4-5 hours)
1. Update `/docs/guides/DEVELOPER_GUIDE.md`
2. Update `/docs/reference/API_REFERENCE.md`
3. Create module documentation (6 files)
4. Update `/docs/reference/core-loop-schema.md`
5. Create `/docs/architecture/core-loop-architecture.md`

### Phase 4: User Guides (3-4 hours)
1. Create `/docs/guides/metrics-guide.md`
2. Create `/docs/guides/success-criteria-guide.md`
3. Create `/docs/guides/feedback-guide.md`
4. Update `/docs/examples/core-loop-examples.md`
5. Create FAQ

---

## VALIDATION CHECKLIST

Before release, verify:

### User Can:
- [ ] Find Core Loop features in README
- [ ] Migrate database successfully
- [ ] Create task with criteria following docs
- [ ] Complete task with validation
- [ ] View metrics
- [ ] Understand all commands from CLI reference

### Developer Can:
- [ ] Understand architecture from docs
- [ ] Find API documentation
- [ ] Run tests successfully
- [ ] Add new Core Loop feature

### Documentation Quality:
- [ ] All examples work when copy-pasted
- [ ] No broken internal links
- [ ] Version numbers consistent
- [ ] Migration guide tested
- [ ] Changelog complete

---

## TRACKING METRICS

- **Existing files to update**: 15
- **New files to create**: 20 (minimum)
- **Estimated effort**: 15-20 hours total
- **Critical path**: 5 files (2-3 hours)

## RECOMMENDATION

Start with Phase 1 (Critical Updates) immediately. These 5 items will unblock users and enable basic adoption of Core Loop features. Phases 2-4 can be completed incrementally after initial release.

---

*Use this action plan to systematically update documentation. Check off items as completed.*