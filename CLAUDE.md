# CLAUDE.md - Critical Project Guidelines for AI Assistants

## 🔒 PROTECTED SECTION - DO NOT MODIFY OR REMOVE
### Test Isolation Requirements

**⚠️ CRITICAL REQUIREMENT: This section MUST NOT be modified or removed without explicit user permission.**

All tests in the Task Orchestrator project MUST adhere to these isolation requirements:

1. **Isolated Test Environments**
   - All tests MUST run in temporary directories created with `mktemp -d`
   - Tests MUST NOT modify the host system or current Claude Code instance
   - Test directories MUST be cleaned up after execution

2. **Safe Execution Practices**
   - No `sudo` commands or system-level modifications
   - No installation of system packages
   - No modification of system configuration files
   - All file operations confined to test directory

3. **Resource Protection**
   - Tests must handle resource cleanup (processes, files, locks)
   - Background processes must be properly terminated
   - Lock files must be removed after tests
   - No resource leaks that could affect system stability

4. **Error Handling**
   - All tests must fail gracefully without crashing
   - Proper timeout mechanisms for long-running operations
   - Signal handling for cleanup on interruption

5. **Path Resolution**
   - Tests must dynamically locate the `tm` executable
   - Support both parent directory (`../tm`) and current directory (`./tm`)
   - Clear error messages if executable not found

### Example Test Template
```bash
#!/bin/bash
set -e

# Create isolated environment
TEST_DIR=$(mktemp -d -t tm_test_XXXXXX)
cd "$TEST_DIR"

# Find tm executable safely
if [ -f "../tm" ]; then
    TM="../tm"
elif [ -f "./tm" ]; then
    TM="./tm"
else
    echo "Error: tm executable not found"
    exit 1
fi

# Run tests...

# Cleanup
cd ..
rm -rf "$TEST_DIR"
```

## 🔒 END OF PROTECTED SECTION

---

## WSL Test Crash Prevention (Added 2025-01-19)

### Problem Identified
Tests were causing complete WSL environment crashes due to:
- SQLite database operations in temporary directories triggering WSL filesystem bugs
- File locking mechanisms conflicting with WSL's filesystem layer
- Resource exhaustion from tests creating resources faster than WSL could handle
- Recursive script execution causing infinite loops

### Solutions Implemented

#### 1. WSL Detection & Adaptive Behavior
All test scripts now detect WSL environment and adapt accordingly:
```bash
IS_WSL=0
if grep -qi microsoft /proc/version 2>/dev/null; then
    IS_WSL=1
    echo "WSL environment detected - enabling safety measures"
fi
```

#### 2. Resource Limits for WSL
- File descriptors limited to 512 (prevents exhaustion)
- Process limit set to 100 (prevents fork bombs)
- CPU time limits enforced via timeout commands
- Memory-conscious parameters (reduced task counts)

#### 3. Database Safety Measures
- SQLite WAL mode enabled for better concurrency
- Retry logic with exponential backoff for initialization
- Proper PRAGMA settings for WSL performance
- Timeout parameters on all database connections

#### 4. Test Isolation
- All tests run in isolated /tmp directories
- Complete cleanup after each test
- Orphaned process termination
- Trap handlers for proper cleanup on signals

#### 5. Fixed Script Issues
- Resolved tm wrapper script recursive execution bug
- Implemented proper command routing
- Added missing command implementations
- Fixed path resolution for executables

### Running Tests Safely

**Recommended approach:**
```bash
# Use the safe test runner
./tests/run_all_tests_safe.sh
```

**Individual test execution:**
```bash
# Tests automatically detect WSL and apply safety measures
./tests/test_tm.sh
./tests/test_edge_cases.sh
```

### Key Files Modified
- All test scripts in `tests/` directory
- `src/tm_production.py` - Added WSL-safe database initialization
- `tm` wrapper script - Fixed recursive execution and added commands
- Created `tests/run_all_tests_safe.sh` for orchestrated test execution

### Performance Considerations
- Tests run slower in WSL due to safety delays
- Reduced parallelism to prevent resource exhaustion
- Sequential test execution recommended over parallel

---

## Git Branching Strategy (Added 2025-08-19)

### IMPORTANT: Development Workflow
This project follows a Git Flow branching strategy:

1. **`develop` branch** - PRIMARY DEVELOPMENT BRANCH
   - All active development happens here
   - Feature branches are created from and merged back to `develop`
   - This is the default branch for all work

2. **`master` branch** - PRODUCTION RELEASE BRANCH
   - Only contains production-ready code
   - Merges from `develop` only when releasing
   - Tagged with version numbers (e.g., v2.0.0)

### Workflow Commands
```bash
# Daily development (ALWAYS use develop)
git checkout develop
git pull origin develop

# Creating a feature
git checkout -b feature/my-feature develop
# ... work on feature ...
git checkout develop
git merge feature/my-feature

# Releasing to production
git checkout master
git merge develop
git tag -a v2.0.1 -m "Release v2.0.1"
git push origin master --tags
git checkout develop  # Return to develop immediately

# NEVER work directly on master!
```

### Key Rules
- ✅ ALWAYS work on `develop` branch by default
- ✅ Create feature branches from `develop`
- ✅ Only merge to `master` for releases
- ❌ NEVER commit directly to `master`
- ❌ NO `main` branch exists (we use `master` for releases)

---

## Project Overview

Task Orchestrator is a sophisticated task management system designed for Claude Code, enabling enhanced capabilities for successful task orchestration through specialized sub-agents. It provides shared context, private notes, notifications with lightweight hooks, and delivers durable, dependency-aware, and event-driven coordination across agents.

## Core Features

1. **Task Management**
   - Create, update, and track tasks with dependencies
   - Priority levels and status tracking
   - File reference associations

2. **Agent Specialization**
   - Support for different specialist types (database, backend, frontend, etc.)
   - Phase-based task coordination
   - Automatic task routing by specialty

3. **Collaboration Features**
   - Shared context between agents
   - Private notes for individual agents
   - Sync points and handoffs

4. **Event-Driven Architecture**
   - State change events
   - Dependency resolution events
   - Hook execution for automation

5. **Durability & Resilience**
   - Transaction atomicity
   - Crash recovery
   - State persistence

## Testing Guidelines

### Running Tests

All tests are located in the `tests/` directory:

```bash
# Run individual test suites
./tests/test_tm.sh                    # Basic functionality
./tests/test_edge_cases.sh           # Edge cases
./tests/test_stress_test.sh          # Performance under load
./tests/test_hooks.sh                 # Hook execution
./tests/test_agent_specialization.sh  # Agent routing
./tests/test_event_driven.sh         # Event system
./tests/test_durability.sh           # Resilience
./tests/test_orchestration_integration.sh  # End-to-end
```

### Test Development

When creating new tests:
1. Always use the isolation template above
2. Test both success and failure paths
3. Include cleanup in all scenarios
4. Document expected behavior

## Architecture Notes

- **Database**: SQLite for durability and ACID compliance
- **Concurrency**: File-based locking with timeout mechanisms
- **Events**: File-based event log with subscription patterns
- **Hooks**: Shell scripts executed at lifecycle points

## Development Best Practices

1. **Safety First**: Never execute operations that could affect the host system
2. **Isolation**: Keep all operations within designated directories
3. **Cleanup**: Always clean up resources (files, processes, locks)
4. **Validation**: Validate inputs before processing
5. **Logging**: Log important events for debugging

## Known Limitations

- Single-node operation (no distributed support yet)
- File-based locking (may have race conditions under extreme load)
- Hook execution is synchronous (may block operations)

## Future Enhancements

- Distributed task coordination
- Async hook execution
- REST API interface
- Web UI dashboard
- Metric collection and monitoring

---

*Last Updated: August 19, 2025*
*Version: 2.0.0*