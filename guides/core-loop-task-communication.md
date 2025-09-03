# Core Loop Task Communication Guide

## How Task Orchestrator v2.3 Transforms Agent Communication

This guide demonstrates how the Core Loop enhancements in PRD v2.3 transform vague task assignments into precise, measurable, and trackable work items with built-in quality assurance.

## The Problem: Vague Task Communication

Traditional task assignments often suffer from:
- 🔴 Unclear success criteria ("make it better")
- 🔴 No progress visibility until completion
- 🔴 Lost learnings after task completion
- 🔴 No quality feedback loop
- 🔴 Ambiguous validation ("looks good to me")

## The Solution: Core Loop Communication Pattern

The Core Loop introduces three critical enhancements:
1. **Success Criteria** - Define measurable outcomes upfront
2. **Completion Summaries** - Capture knowledge and learnings
3. **Feedback Scores** - Enable continuous improvement

## Real-World Example: Test Blitz Recovery

### Before: Traditional Task Assignment

```text
"Test Blitz Recovery - Fix any remaining failed integration tests. 
Current baseline: 24 failed files, 138 failed tests.
Follow the testing guide.
Success: Reduce failures below baseline!"
```

**Problems:**
- ❌ Success criteria not measurable
- ❌ No structured context
- ❌ No progress tracking mechanism
- ❌ No knowledge capture
- ❌ No feedback loop

### After: Core Loop Enhanced Task

#### Step 1: Create Task with Success Criteria

```bash
tm add "Test Blitz Recovery: Fix Integration Test Failures" \
  --criteria '[
    {
      "criterion": "Reduce failed test files below 24",
      "measurable": "test_files_failed < 24"
    },
    {
      "criterion": "Reduce failed tests below 138", 
      "measurable": "tests_failed < 138"
    },
    {
      "criterion": "Maintain or improve passing tests",
      "measurable": "tests_passed >= 379"
    },
    {
      "criterion": "Follow testing best practices",
      "measurable": "compliance with Writing_Good_Integration_Tests.md"
    }
  ]' \
  --deadline "2025-02-21T18:00:00Z" \
  --estimated-hours 8
```

#### Step 2: Add Structured Context

```bash
tm context test_blitz_001 --shared "
## Task Brief: Test Blitz Recovery

### Current Baseline (Must Improve)
- Test Files: 24 failed | 27 passed | 2 skipped (53 total)
- Individual Tests: 138 failed | 379 passed | 41 skipped (558 total)

### Required Resources
- Testing Guide: docs/developer/guides/testing/fundamentals/Writing_Good_Integration_Tests.md
- Test Environment: staging-test-server
- Access Required: test database, CI/CD pipeline

### Approach Guidelines
1. Prioritize tests that block critical paths
2. Group related failures for batch fixes
3. Follow TDD for any new test creation
4. Document root causes for knowledge base

### Success Validation
Run: npm test -- --coverage
Verify all success criteria met before marking complete
"
```

#### Step 3: Agent Execution with Progress Updates

```bash
# Agent joins and begins work
tm join test_blitz_001
tm progress test_blitz_001 "Analyzing test failures - grouping by root cause"

# Regular progress updates
tm progress test_blitz_001 "Fixed authentication-related failures: 
- Test Files: 18 failed (-6)
- Tests: 102 failed (-36)
Root cause: Missing JWT mock in test setup"

# Critical discovery shared
tm discover test_blitz_001 "CRITICAL: Database migration missing in test environment causing 40% of failures"
```

#### Step 4: Completion with Validation

```bash
tm complete test_blitz_001 --validate --summary "
Reduced test failures below baseline through systematic fixes:
- Final: 15 failed files, 87 failed tests
- Fixed 62 test failures (45% reduction)
- Root causes: 60% env setup, 30% mocks, 10% timing
- Created reusable test fixtures for future prevention
- Updated Writing_Good_Integration_Tests.md with new patterns
" --actual-hours 6
```

**Validation Output:**
```
✓ Reduce failed test files below 24 (15 < 24)
✓ Reduce failed tests below 138 (87 < 138)  
✓ Maintain or improve passing tests (412 >= 379)
✓ Follow testing best practices (verified in changes)
Task completed successfully!
```

#### Step 5: Quality Feedback

```bash
tm feedback test_blitz_001 --quality 5 --timeliness 5 --note "
Excellent systematic approach. 
45% reduction exceeds expectations.
Knowledge capture in fixtures prevents recurrence.
"
```

## Communication Patterns

### Pattern 1: Measurable Success Criteria

**Instead of:** "Make the tests pass"

**Use:**
```json
{
  "criterion": "All critical path tests passing",
  "measurable": "critical_tests_passing == 100%"
}
```

### Pattern 2: Structured Context

**Instead of:** Wall of text with mixed information

**Use:** Clear sections with specific categories:
- Current State (baseline metrics)
- Required Resources (tools, access, guides)
- Approach Guidelines (priorities, methods)
- Validation Method (how to verify success)

### Pattern 3: Progress Visibility

**Instead of:** Silence until completion

**Use:** Regular updates with metrics:
```bash
tm progress task_id "Completed 40% - Fixed authentication module (12 tests passing)"
```

### Pattern 4: Knowledge Capture

**Instead of:** Fixes lost after completion

**Use:** Detailed completion summary:
```bash
tm complete task_id --summary "
What was done: [specific actions]
Root causes found: [analysis]
Patterns identified: [reusable knowledge]
Future prevention: [improvements made]
"
```

### Pattern 5: Quality Signals

**Instead of:** No feedback

**Use:** Simple scores with notes:
```bash
tm feedback task_id --quality 4 --timeliness 5 --note "Good work, consider automation next time"
```

## Task Templates

### Template: Bug Fix Task

```yaml
# .task-orchestrator/context/templates/bug-fix.yaml
template:
  type: bug-fix
  success_criteria:
    - criterion: "Bug no longer reproducible"
      measurable: "reproduction_steps fail"
    - criterion: "No regression in related features"
      measurable: "regression_tests pass"
    - criterion: "Root cause documented"
      measurable: "RCA document created"
  estimated_hours: 4
  context_required:
    - bug_report
    - reproduction_steps
    - affected_components
    - test_environment
```

### Template: Performance Optimization

```yaml
# .task-orchestrator/context/templates/performance.yaml
template:
  type: performance
  success_criteria:
    - criterion: "Response time improved"
      measurable: "p95_latency < baseline * 0.8"
    - criterion: "Memory usage reduced"
      measurable: "peak_memory < baseline * 0.9"
    - criterion: "No functionality broken"
      measurable: "all_tests pass"
  estimated_hours: 8
  context_required:
    - performance_baseline
    - bottleneck_analysis
    - target_metrics
    - load_test_environment
```

### Template: Feature Implementation

```yaml
# .task-orchestrator/context/templates/feature.yaml
template:
  type: feature
  success_criteria:
    - criterion: "Feature works as specified"
      measurable: "acceptance_tests pass"
    - criterion: "Code coverage maintained"
      measurable: "coverage >= 80%"
    - criterion: "Documentation complete"
      measurable: "user_docs and api_docs updated"
  estimated_hours: 16
  context_required:
    - feature_specification
    - design_mockups
    - api_contracts
    - test_scenarios
```

## Benefits of Core Loop Communication

### For Orchestrating Agents
- ✅ Clear expectations set upfront
- ✅ Progress visibility throughout execution
- ✅ Objective validation of completion
- ✅ Learning signals from feedback

### For Specialist Agents
- ✅ Unambiguous success criteria
- ✅ All context in one place
- ✅ Freedom to approach creatively
- ✅ Recognition through feedback

### For the System
- ✅ Knowledge accumulation over time
- ✅ Quality trends visible
- ✅ Reduced rework through clarity
- ✅ Continuous improvement cycle

## Implementation Checklist

When creating tasks with Core Loop:

- [ ] Define 3-5 specific, measurable success criteria
- [ ] Provide structured context with clear sections
- [ ] Set realistic deadline and effort estimates
- [ ] Include validation method in context
- [ ] Plan for progress update points
- [ ] Prepare to capture learnings at completion
- [ ] Commit to providing feedback

## Migration Guide

### Phase 1: Start with Success Criteria
Begin adding success criteria to new tasks:
```bash
tm add "Task" --criteria '[{"criterion": "X", "measurable": "Y"}]'
```

### Phase 2: Add Completion Summaries
Require summaries for knowledge capture:
```bash
tm complete task_id --summary "What was learned..."
```

### Phase 3: Implement Feedback
Start providing quality signals:
```bash
tm feedback task_id --quality 4 --timeliness 5
```

### Phase 4: Use Templates
Standardize common task types with templates.

## Metrics to Track

After implementing Core Loop communication:

1. **Clarity Metrics**
   - % of tasks with success criteria
   - Average criteria per task
   - % of criteria marked measurable

2. **Execution Metrics**
   - % of tasks completed on first attempt
   - Average rework rate
   - Time to completion vs estimate

3. **Quality Metrics**
   - Average quality score
   - Feedback coverage %
   - Score trends over time

4. **Knowledge Metrics**
   - % of tasks with summaries
   - Summary length/detail
   - Reusable patterns extracted

## Common Pitfalls to Avoid

1. **Vague Criteria**: "Make it better" → "Reduce latency by 20%"
2. **Too Many Criteria**: Keep to 3-5 essential ones
3. **Unmeasurable Criteria**: Every criterion needs a measurable
4. **Missing Context**: Include all necessary resources upfront
5. **Silent Execution**: Encourage progress updates
6. **Skipping Summaries**: Knowledge capture is valuable
7. **No Feedback**: Even simple scores help improvement

## Conclusion

The Core Loop transforms task communication from ambiguous requests into precise contracts with measurable outcomes, visible progress, and continuous improvement. By implementing these patterns, teams can:

- Reduce miscommunication and rework
- Capture and reuse knowledge
- Improve quality over time
- Build trust through transparency

Start with success criteria on your next task and experience the difference clear communication makes.

---

*Last Updated: 2025-08-20*
*Based on: PRD v2.3 Core Loop Enhancement*
*Examples from: Real test remediation scenarios*