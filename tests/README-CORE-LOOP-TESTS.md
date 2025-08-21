# Task Orchestrator Core Loop Test Suite

## Overview

This document provides comprehensive documentation for the Core Loop test architecture in Task Orchestrator v2.3. The test suite follows Test-Driven Development (TDD) principles to ensure robust, reliable Core Loop functionality while maintaining backward compatibility.

## Philosophy: Lightweight TDD

Our approach emphasizes:
- **Just Enough Coverage**: Test critical paths, not every edge case
- **Behavior Over Implementation**: Test what it does, not how it does it
- **Fail First**: Tests should fail initially, then pass as features are built
- **Simple Tests**: Each test should be obvious in its intent
- **Fast Feedback**: Tests run quickly to enable rapid iteration

## Test Suite Structure

### 1. Unit Tests (Isolated Features)

#### `test_core_loop_success_criteria.sh`
**Purpose**: Validate success criteria definition and validation
**Critical Coverage**:
- Adding tasks with success criteria (JSON format)
- Validation blocking completion when criteria unmet
- Force override for unmet criteria
- Completion summaries
- Backward compatibility

#### `test_core_loop_feedback.sh`
**Purpose**: Validate feedback scores and metrics
**Critical Coverage**:
- Adding quality and timeliness scores (1-5 range)
- One feedback per task enforcement
- Feedback only on completed tasks
- Metrics aggregation
- Note length limits (500 chars)

#### `test_core_loop_schema.sh`
**Purpose**: Validate database schema extensions
**Critical Coverage**:
- New fields exist (success_criteria, deadline, etc.)
- Fields are nullable (backward compatible)
- JSON storage for criteria
- ISO 8601 datetime for deadlines
- Legacy tasks unaffected

#### `test_core_loop_configuration.sh`
**Purpose**: Validate feature toggle system
**Critical Coverage**:
- Enable/disable individual features
- Minimal mode disables all enhancements
- Configuration persistence
- Telemetry opt-in/opt-out

#### `test_core_loop_migration.sh`
**Purpose**: Validate safe migration and rollback
**Critical Coverage**:
- Backup before migration
- Data preservation
- Rollback capability
- Idempotent migrations
- Dry-run mode

### 2. Integration Test (End-to-End)

#### `test_core_loop_integration.sh`
**Purpose**: Validate complete Core Loop workflow
**Complete Flow**:
1. Initialize environment
2. Apply migration
3. Enable features
4. Create task with criteria and deadline
5. Add context
6. Track progress
7. Complete with validation
8. Provide feedback
9. Check metrics
10. Verify backward compatibility
11. Test minimal mode
12. Verify telemetry

## Test Architecture Overview

### Test Organization Structure

The Core Loop test suite is organized by feature area with clear separation of concerns:

```
tests/
├── README-CORE-LOOP-TESTS.md          # This documentation
├── run_core_loop_tests.sh             # Test orchestration script
├── test_core_loop_success_criteria.sh # Success criteria validation
├── test_core_loop_feedback.sh         # Feedback system tests
├── test_core_loop_schema.sh          # Database schema tests
├── test_core_loop_configuration.sh   # Configuration management
├── test_core_loop_migration.sh       # Migration system tests
├── test_core_loop_integration.sh     # End-to-end workflow
├── test_core_loop_edge_cases.sh      # Edge case validation
└── test_implementation_complete.sh   # Final validation
```

### Isolation Patterns and Safety Measures

**Test Isolation Strategy:**
- Each test runs in its own temporary directory (`mktemp -d`)
- Independent database instances prevent test interference
- Complete cleanup after each test execution
- No shared state between test runs

**WSL-Specific Adaptations:**
- Reduced resource limits to prevent system overload
- File descriptor and process limits enforced
- Retry logic for database operations
- Timeout mechanisms for long-running operations

**Safety Measures:**
```bash
# Automatic safety limits applied in WSL
if grep -qi microsoft /proc/version 2>/dev/null; then
    ulimit -n 512    # File descriptors
    ulimit -u 100    # Processes
    ulimit -t 30     # CPU time (seconds)
fi
```

### Mock and Fixture Strategies

**Test Data Management:**
- Minimal test data sets for fast execution
- Predictable IDs and timestamps for validation
- JSON fixtures for complex criteria structures
- Baseline metrics for performance comparisons

**Mock Implementations:**
- File-based locking simulation
- Controlled time progression for deadline testing
- Simulated external system responses
- Deterministic random data generation

## Running Tests

### Quick Test Execution

```bash
# Run all Core Loop tests
./tests/run_core_loop_tests.sh

# Run with verbose output
./tests/run_core_loop_tests.sh --verbose

# Run specific test suite
./tests/run_core_loop_tests.sh criteria
./tests/run_core_loop_tests.sh feedback
./tests/run_core_loop_tests.sh schema
./tests/run_core_loop_tests.sh config
./tests/run_core_loop_tests.sh migration
./tests/run_core_loop_tests.sh integration
```

### Individual Test Execution

```bash
# Direct test execution
./tests/test_core_loop_success_criteria.sh
./tests/test_core_loop_feedback.sh
./tests/test_core_loop_schema.sh

# Run with debugging
VERBOSE=1 ./tests/test_core_loop_integration.sh
```

### Performance Testing Procedures

```bash
# Performance regression testing
./tests/run_core_loop_tests.sh --performance

# Load testing with multiple tasks
LOAD_TEST=1 ./tests/test_core_loop_integration.sh

# Memory usage monitoring
MEMORY_CHECK=1 ./tests/run_core_loop_tests.sh
```

### Integration Test Patterns

**Multi-Component Testing:**
- Database + Configuration + Validation interaction
- Migration + Schema + Backward compatibility
- Feedback + Metrics + Analytics integration
- End-to-end workflow validation

## Expected Test Results

### Before Implementation (TDD Phase)
```
✗ Most tests will FAIL
✓ This is EXPECTED and CORRECT
✓ Failed tests define the specification
✓ Use failures to guide implementation
```

### After Implementation
```
✓ All tests should PASS
✓ Indicates Core Loop fully implemented
✓ Backward compatibility maintained
✓ Ready for release
```

## Test Coverage Map

| PRD Requirement | Test File | Test Cases |
|-----------------|-----------|------------|
| FR-029: Success Criteria Definition | success_criteria.sh | Tests 1, 2, 7 |
| FR-030: Criteria Validation | success_criteria.sh | Tests 3, 4, 5 |
| FR-032: Completion Summary | success_criteria.sh | Test 6 |
| FR-033: Feedback Scores | feedback.sh | Tests 1, 2, 3 |
| FR-034: Feedback Metrics | feedback.sh | Tests 6, 10 |
| FR-027: Schema Extensions | schema.sh | Tests 1-10 |
| FR-038: Feature Configuration | configuration.sh | Tests 2-9 |
| FR-039: Migration Support | migration.sh | Tests 3-10 |
| SR-001: Backward Compatibility | All tests | Test 10 in each |

## Implementation Priority

Based on test dependencies, implement in this order:

1. **Schema Extensions** (enables all other features)
   - Add database fields
   - Make fields nullable

2. **Migration System** (safe deployment)
   - Backup mechanism
   - Apply/rollback commands

3. **Configuration Management** (control features)
   - Feature toggles
   - Minimal mode

4. **Success Criteria** (core enhancement)
   - JSON storage
   - Validation logic

5. **Feedback Mechanism** (quality loop)
   - Score storage
   - Metrics calculation

6. **Integration** (complete workflow)
   - End-to-end validation

## Success Metrics

A successful implementation will show:

```bash
===========================================
           Test Summary                  
===========================================
Total Test Suites: 6
Executed: 6
Failed: 0
Skipped: 0

✓ All test suites executed successfully!
Core Loop implementation is complete.
```

## Test Development Guide

### Adding New Test Cases

**1. Create Test File Structure:**
```bash
#!/bin/bash
set -e

# Test metadata
TEST_NAME="Core Loop Feature Testing"
TEST_VERSION="1.0"

# Safety and isolation setup
TEST_DIR=$(mktemp -d -t tm_test_XXXXXX)
cd "$TEST_DIR"

# Test execution
function test_feature() {
    echo "Testing feature..."
    # Test implementation here
}

# Cleanup
function cleanup() {
    cd ..
    rm -rf "$TEST_DIR"
}
trap cleanup EXIT

# Run tests
test_feature
echo "✓ All tests passed"
```

**2. Follow Naming Conventions:**
- File: `test_core_loop_[feature_name].sh`
- Functions: `test_[specific_behavior]()`
- Variables: `EXPECTED_[OUTCOME]`, `ACTUAL_[RESULT]`

**3. Add to Test Orchestration:**
```bash
# Add to run_core_loop_tests.sh
case "$1" in
    "your-feature")
        run_test "test_core_loop_your_feature.sh" "Your Feature Tests"
        ;;
esac
```

### Test Data Management

**Fixture Creation:**
```bash
# Create test data fixtures
create_test_task() {
    local task_title="$1"
    local criteria="$2"
    
    TASK_ID=$($TM add "$task_title" --criteria "$criteria" 2>/dev/null | tail -1)
    echo "$TASK_ID"
}

# Example criteria fixtures
SIMPLE_CRITERIA='[{"criterion":"Test passes","measurable":"true"}]'
COMPLEX_CRITERIA='[{"criterion":"Performance","measurable":"response_time < 100"}]'
```

**Test Data Cleanup:**
```bash
# Ensure clean state
cleanup_test_data() {
    rm -f ~/.task-orchestrator/tasks.db 2>/dev/null || true
    rm -f ~/.task-orchestrator/config.yaml 2>/dev/null || true
}
```

### Assertion Patterns

**Basic Assertions:**
```bash
# String equality
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="$3"
    
    if [ "$expected" != "$actual" ]; then
        echo "✗ $message"
        echo "  Expected: $expected"
        echo "  Actual: $actual"
        return 1
    fi
    echo "✓ $message"
}

# Command success
assert_success() {
    local command="$1"
    local message="$2"
    
    if ! eval "$command" >/dev/null 2>&1; then
        echo "✗ $message - Command failed: $command"
        return 1
    fi
    echo "✓ $message"
}
```

**Advanced Assertions:**
```bash
# JSON structure validation
assert_json_field() {
    local json="$1"
    local field="$2"
    local expected="$3"
    
    local actual=$(echo "$json" | jq -r "$field")
    assert_equals "$expected" "$actual" "JSON field $field"
}

# Database state validation
assert_db_count() {
    local table="$1"
    local expected_count="$2"
    
    local actual_count=$(sqlite3 ~/.task-orchestrator/tasks.db \
        "SELECT COUNT(*) FROM $table;" 2>/dev/null)
    assert_equals "$expected_count" "$actual_count" "$table record count"
}
```

### Error Condition Testing

**Testing Error Scenarios:**
```bash
# Test invalid input handling
test_invalid_criteria() {
    echo "Testing invalid criteria format rejection..."
    
    # Should fail with malformed JSON
    if $TM add "Test" --criteria "invalid json" 2>/dev/null; then
        echo "✗ Should reject invalid JSON criteria"
        return 1
    fi
    echo "✓ Properly rejects invalid criteria format"
}

# Test boundary conditions
test_boundary_conditions() {
    echo "Testing boundary conditions..."
    
    # Test maximum field lengths
    local long_title=$(printf 'A%.0s' {1..1000})
    if ! $TM add "$long_title" 2>/dev/null; then
        echo "✓ Properly handles long titles"
    else
        echo "? Long title accepted (may need length validation)"
    fi
}
```

### Performance Testing Patterns

**Timing Tests:**
```bash
# Performance regression testing
test_performance() {
    echo "Testing performance benchmarks..."
    
    local start_time=$(date +%s%3N)
    
    # Execute operation
    $TM add "Performance test task"
    
    local end_time=$(date +%s%3N)
    local duration=$((end_time - start_time))
    
    if [ $duration -gt 1000 ]; then  # 1 second
        echo "✗ Task creation took ${duration}ms (>1000ms threshold)"
        return 1
    fi
    echo "✓ Task creation completed in ${duration}ms"
}
```

### Test Principles and Best Practices

**Core Testing Principles:**
- **Keep It Simple**: Each test should be obviously correct
- **Test One Thing**: Don't combine multiple features in one test
- **Use Clear Names**: Test output should explain what failed
- **Fast Execution**: Tests should complete in seconds
- **Isolated**: Tests shouldn't depend on each other
- **Deterministic**: Same input always produces same output

**Error Handling in Tests:**
- Always check command exit codes
- Provide clear failure messages
- Include context in error output
- Test both success and failure paths
- Validate error messages are helpful

**Performance Considerations:**
- Set reasonable timeouts for operations
- Monitor memory usage in long tests
- Use minimal test data sets
- Clean up resources promptly
- Avoid unnecessary external dependencies

### Debugging Test Failures

**Common Debugging Techniques:**
```bash
# Enable verbose output
VERBOSE=1 ./tests/test_core_loop_feature.sh

# Check intermediate state
DEBUG=1 ./tests/test_core_loop_feature.sh

# Manual test execution
TEST_PRESERVE=1 ./tests/test_core_loop_feature.sh
# (leaves test directory for inspection)
```

**Troubleshooting Checklist:**
1. **Verify tm executable location** - Check ../tm, ./tm paths
2. **Check file permissions** - Ensure tests are executable
3. **Validate test environment** - Clean state, no conflicts
4. **Review resource limits** - WSL limitations properly set
5. **Check database state** - No locks or corruption
6. **Verify dependencies** - Required tools available

### Maintenance

**Regular Maintenance Tasks:**
1. **Update test documentation** when adding new features
2. **Review test coverage** for new Core Loop functionality
3. **Optimize slow tests** to maintain fast feedback cycle
4. **Update fixtures** when data formats change
5. **Validate WSL compatibility** after system updates

**Test Suite Health Monitoring:**
- Total execution time should remain under 2 minutes
- No flaky tests (intermittent failures)
- Clear test output and error messages
- All tests should be deterministic and repeatable

## Common Issues

### Tests Can't Find `tm`
```bash
# Ensure tm is in parent directory or current directory
# Tests check multiple locations: ../tm, ./tm, ../../tm
```

### Permission Denied
```bash
# Make tests executable
chmod +x tests/test_core_loop_*.sh
chmod +x tests/run_core_loop_tests.sh
```

### Database Locked
```bash
# Tests use isolated temp directories
# Each test creates its own database
# No conflicts should occur
```

## TDD Workflow

1. **Run tests** → See failures → Understand requirements
2. **Implement feature** → Make minimal change to pass test
3. **Run tests** → See progress → Continue
4. **Refactor** → Improve code → Tests still pass
5. **Complete** → All tests green → Feature done

## Conclusion

This lightweight TDD approach provides:
- **Clear Specification**: Tests define exact behavior needed
- **Safety Net**: Refactoring without breaking functionality
- **Documentation**: Tests show how features should work
- **Confidence**: Green tests mean implementation is correct
- **Focus**: Only implement what's tested (no over-engineering)

The Core Loop tests provide just enough coverage to be confident in the implementation while keeping the test suite maintainable and fast.

---

*Test Suite Version: 1.0*
*PRD Version: 2.3*
*Created: 2025-08-20*
*Approach: Lightweight TDD*