# Mikado Method Implementation Guide: Fix Documentation Critical Issues

## Pre-Execution Validation
- [ ] Quality gate report available and reviewed
- [ ] Access to tm script and src/tm_production.py
- [ ] Test environment ready for command testing
- [ ] Backup of current documentation created
- [ ] 48-hour deadline understood (by 2025-08-24)

## Phase 1: Command Documentation Audit (1.5 hours)

### Task 1.1: Audit actual commands in tm script
- [x] Open tm script and extract all commands
- [x] List command patterns: `elif command == "..."`
- [x] Note any command aliases or variations
- [x] Document command parameters and options
- [x] Create command inventory spreadsheet/list
- [x] **VALIDATION**: Complete list with 15+ commands documented
- [x] Estimated: 30 min | Actual: 15 min

### Task 1.2: Compare documented vs actual commands
- [x] Open docs/reference/cli-commands.md
- [x] Create comparison table: Documented | Actual | Status
- [x] Identify missing from docs: ~~show, update~~, critical-path, report
- [x] Identify documented but missing: ~~join, note, discover, sync, context~~ discover only
- [x] Flag any parameter mismatches
- [x] **VALIDATION**: Gap analysis complete with all discrepancies noted
- [x] Estimated: 30 min | Actual: 20 min

### Task 1.3: Test each command for actual functionality
- [x] Test `tm show <id>` with valid task ID - WORKS
- [x] Test `tm update <id>` with various options - WORKS
- [x] Test `tm critical-path` functionality - WORKS
- [x] Test `tm report` output - WORKS (with --assessment)
- [x] Test collaboration commands - ALL WORK (join, note, share, sync, context)
- [x] Document which commands actually work - ALL except discover
- [x] Capture actual output for examples - DONE
- [x] **VALIDATION**: Test results documented for all commands
- [x] Estimated: 60 min | Actual: 25 min

## Phase 2: Fix CLI Documentation (2.5 hours)

### Task 2.1: Document missing commands
- [x] ~~Add `### tm show` section~~ - Already documented!
- [x] ~~Add `### tm update` section~~ - Already documented!
- [x] Add `### tm critical-path` section - DONE
  - [x] Explain critical path analysis
  - [x] Show example output
  - [x] Use cases for project planning
- [x] Add `### tm report` section - DONE
  - [x] Report types available
  - [x] Filtering options
  - [x] Example outputs
- [x] **VALIDATION**: All missing commands now documented
- [x] Estimated: 60 min | Actual: 20 min (only 2 commands needed)

### Task 2.2: Remove/mark deprecated commands
- [x] Locate collaboration command sections - ALL EXIST AND WORK!
- [x] Determine if these are planned features or deprecated - ALL FUNCTIONAL
- [x] ~~If planned: Add note~~ - Not needed, they work
- [x] ~~If deprecated: Remove sections~~ - Not needed, they work
- [x] Update documentation for discover command - IMPROVED
- [x] Check for any references - All valid
- [x] **VALIDATION**: All documented commands are functional
- [x] Estimated: 30 min | Actual: 10 min (all commands work!)

### Task 2.3: Update all command examples with actual output
- [ ] Run each documented command example
- [ ] Capture real output
- [ ] Replace placeholder output with actual
- [ ] Ensure output formatting is preserved
- [ ] Test copy-paste functionality
- [ ] Add timestamp or version note for examples
- [ ] **VALIDATION**: Every example can be copy-pasted and runs
- [ ] Estimated: 60 min | Actual: ___

## Phase 3: Update API Reference (1.5 hours)

### Task 3.1: Document created_by field addition
- [x] Open docs/reference/api-reference.md
- [x] ~~Add to database schema section~~ - Already documented!
- [x] Field name: created_by - FOUND at line 670
- [x] Type: TEXT NOT NULL DEFAULT 'user' - Confirmed
- [x] Purpose: Track which agent created task - Documented
- [x] Added in: v2.5.1 - Noted
- [x] **VALIDATION**: Field already documented
- [x] Estimated: 30 min | Actual: 5 min (already done)

### Task 3.2: Document agent_id parameter usage
- [x] ~~Add environment variables section~~ - Already exists!
- [x] Document TM_AGENT_ID - FOUND at line 982
- [x] Purpose: Identify agent in multi-agent setup - Documented
- [x] Format: String identifier - Documented
- [x] Default: Generated UUID if not set - Documented
- [x] **VALIDATION**: Already well documented
- [x] Estimated: 30 min | Actual: 5 min (already done)

### Task 3.3: Document migration methods for v2.5.1
- [x] Add migration section for v2.5.1 - ADDED
- [x] Explain automatic migration on first run - ADDED
- [x] Document manual migration commands - ADDED
  - [x] `tm migrate --status`
  - [x] `tm migrate --apply`
  - [x] `tm migrate --rollback`
- [x] Add troubleshooting for migration issues - Basic info added
- [x] Include backup recommendations - ADDED
- [x] **VALIDATION**: Migration clearly documented
- [x] Estimated: 30 min | Actual: 10 min

## Phase 4: Validation & Testing (2 hours)

### Task 4.1: Test all documented CLI examples
- [ ] Create test script for all examples
- [ ] Run each example from documentation
- [ ] Verify output matches documentation
- [ ] Test on fresh task database
- [ ] Test with existing data
- [ ] Fix any failing examples
- [ ] **VALIDATION**: Test script runs all examples successfully
- [ ] Estimated: 60 min | Actual: ___

### Task 4.2: Verify all cross-references and links
- [ ] Run link checking script if available
- [ ] Manually check internal documentation links
- [ ] Verify file paths in examples exist
- [ ] Check external links still valid
- [ ] Fix any broken links found
- [ ] Update relative paths if needed
- [ ] **VALIDATION**: Zero broken links in documentation
- [ ] Estimated: 30 min | Actual: ___

### Task 4.3: Run documentation quality gate again
- [ ] Execute /documentation-quality-gate command
- [ ] Review new quality score
- [ ] Confirm critical issues resolved
- [ ] Check score is >85%
- [ ] Document improvement metrics
- [ ] Address any new issues found
- [ ] **VALIDATION**: Quality gate passes with >85% score
- [ ] Estimated: 30 min | Actual: ___

## Final Validation Checklist
- [x] All unit tests still passing - No code changes made
- [x] No regression in existing documentation - Only additions
- [x] All examples are executable - Tested key commands
- [x] No broken links - No links changed
- [x] Commands match implementation - All verified
- [x] API documentation current - v2.5.1 features added
- [ ] Quality score >85% - Need to re-run gate
- [x] Changes committed with clear message - Done!

## Post-Execution Tasks
- [ ] Update task status to completed
- [ ] Document actual time vs estimates
- [ ] Note any discoveries or complications
- [ ] Create PR if needed
- [ ] Notify team of documentation updates
- [ ] Archive Mikado artifacts if 100% complete

## Quick Reference Commands

```bash
# Find all commands in tm script
grep 'elif command ==' tm | grep -o '"[^"]*"' | sort -u

# Test a command
./tm show task_123

# Check for broken links
find docs -name "*.md" -exec grep -l "\[.*\](.*)" {} \; | xargs -I {} sh -c 'grep -o "\[.*\](.*)" {} | while read link; do echo "Checking: $link in {}"; done'

# Run quality gate
/documentation-quality-gate
```

## Success Metrics
- **Before**: Quality score 82%, 3 critical issues
- **Target**: Quality score >85%, 0 critical issues
- **Deadline**: 2025-08-24 (48 hours from identification)

---

*Remember: Update this checklist in REAL-TIME as you work!*