# Mikado Method Implementation Guide: Clean Installation Structure

## Pre-Execution Validation
- [ ] Current package structure documented
- [ ] Backup of current release created
- [ ] Test environment prepared
- [ ] All tests currently passing
- [ ] Git status clean
- [ ] **CRITICAL**: Document current file permissions (fixing 777 issue)
- [ ] Create rollback plan with automatic backup

## Phase 1: Foundation Tasks (1.5 hours)

### Task 1.1: Analyze Current Package Structure
- [x] Extract current package to temp directory
- [x] Count and list all Python files (35 total)
- [x] Document current directory structure
- [x] Identify all import patterns used
- [x] Note configuration file locations
- [x] **VALIDATION**: Created `current-structure.txt` with all files listed
- [x] Update Mikado graph status to "attempting"
- [x] Mark complete in graph when done

### Task 1.2: Create New Directory Structure
- [x] Create `.task-orchestrator/` directory
- [x] Create `.task-orchestrator/lib/` subdirectory
- [x] Create `.task-orchestrator/config/` subdirectory
- [x] Create `.task-orchestrator/data/` subdirectory
- [x] Set proper permissions (755)
- [x] **VALIDATION**: Run `ls -la .task-orchestrator/` shows all subdirs
- [x] Update progress tracking
- [x] Commit structure with message: "feat: Create clean directory structure"

### Task 1.3: Update tm Wrapper for Path Resolution
- [x] Open current `tm` wrapper script
- [x] Add path resolution logic for `.task-orchestrator/lib/`
- [x] Add fallback for old structure (backward compatibility)
- [x] Test import from both paths
- [x] Handle missing directory gracefully
- [x] **VALIDATION**: Run `python3 -c "import sys; sys.path.insert(0, '.task-orchestrator/lib'); from tm_production import TaskManager"`
- [x] Test with old structure still works
- [x] Commit changes: "feat: Add dual-path resolution to tm wrapper"

## Phase 2: Core Implementation (4.5 hours)

### Task 2.1: Reorganize Python Modules
- [x] Copy all .py files to `.task-orchestrator/lib/`
- [x] Maintain directory structure for nested modules
- [x] Move migrations/ subdirectory
- [x] Verify all 35+ files moved (28 in lib + 7 in tests)
- [x] Remove original .py files from root
- [x] **VALIDATION**: Run `find .task-orchestrator/lib -name "*.py" | wc -l` shows 28
- [x] Verify no .py files in root: Only tm wrapper remains
- [x] Update Mikado graph
- [x] Commit: "feat: Relocate Python modules to lib directory"

### Task 2.2: Update Internal Imports
- [ ] Search for all relative imports in moved files
- [ ] Update import statements if needed
- [ ] Test each module can be imported
- [ ] Fix any circular import issues
- [ ] Update __init__.py files if present
- [ ] **VALIDATION**: Run `./tm init test-project` works without import errors
- [ ] Run `./tm add "Test task"` successfully
- [ ] All core commands work
- [ ] Commit: "fix: Update internal imports for new structure"

### Task 2.3: Move Configuration Files
- [ ] Move ORCHESTRATOR.md to `.task-orchestrator/config/`
- [ ] Update any hardcoded paths to config
- [ ] Move any .json config files
- [ ] Update config loading logic
- [ ] Set proper permissions
- [ ] **VALIDATION**: Config loads from new location
- [ ] Old location fallback works
- [ ] Commit: "feat: Relocate configuration to config directory"

### Task 2.4: Create Migration Script
- [x] Create `migrate-to-clean-structure.sh`
- [x] Add automatic backup before migration
- [x] **SECURITY**: Fix file permissions (755 for dirs, 644 for files, 755 for executables)
- [x] Add Python file detection and moving from `src/`
- [x] Add config file migration
- [x] Preserve existing data directory
- [x] Add rollback capability
- [x] Make script idempotent
- [x] Add version checking between wrapper and library
- [x] **VALIDATION**: Test on copy of old structure
- [x] Verify all files moved correctly
- [x] Verify task data preserved
- [x] Verify permissions are correct (no 777)
- [x] Commit: "feat: Add migration script with security fixes"

## Phase 3: Testing & Validation (3 hours)

### Task 3.1: Test All Core Commands
- [ ] Test `tm init` creates new project
- [ ] Test `tm add "Task"` adds task
- [ ] Test `tm list` shows tasks
- [ ] Test `tm update [id] --status in_progress`
- [ ] Test `tm complete [id]`
- [ ] Test `tm show [id]`
- [ ] Test collaboration commands
- [ ] Test orchestration features
- [ ] **VALIDATION**: All commands return expected output
- [ ] No Python errors or tracebacks
- [ ] Update test results log

### Task 3.2: Test Migration from Old Structure
- [ ] Create test directory with old structure
- [ ] Copy sample task database
- [ ] Run migration script
- [ ] Verify files moved correctly
- [ ] Test commands still work
- [ ] Verify task data intact
- [ ] **VALIDATION**: Diff before/after shows only structure changed
- [ ] All tasks retrievable
- [ ] Document migration time

### Task 3.3: Test Fresh Installation
- [ ] Create new test directory
- [ ] Extract package with new structure
- [ ] Verify only `tm` in root
- [ ] Run initial setup
- [ ] Test basic workflow
- [ ] **VALIDATION**: `ls | wc -l` shows minimal files
- [ ] `.task-orchestrator/` contains all internals
- [ ] Clean professional appearance

### Task 3.4: Update Packaging Scripts
- [ ] Update package creation script
- [ ] Ensure correct directory structure in tarball
- [ ] Update VERSION to 2.8.0
- [ ] Test package extraction
- [ ] Verify package size unchanged
- [ ] **VALIDATION**: Extract package, verify structure
- [ ] Package installs correctly
- [ ] Create test package successfully

## Phase 4: Documentation & Release (1.25 hours)

### Task 4.1: Update Installation Documentation
- [ ] Update README.md installation section
- [ ] Update user guide with new structure
- [ ] Add migration instructions
- [ ] Update troubleshooting guide
- [ ] Add structure diagram
- [ ] **VALIDATION**: Docs accurately reflect new structure
- [ ] All paths correct
- [ ] Migration steps clear

### Task 4.2: Update .gitignore Template
- [ ] Add `.task-orchestrator/data/`
- [ ] Add `.task-orchestrator/config/ORCHESTRATOR.md`
- [ ] Remove old Python file patterns
- [ ] Test with sample project
- [ ] **VALIDATION**: Git ignores correct files
- [ ] No sensitive data exposed
- [ ] Commit patterns work

### Task 4.3: Create Release Package
- [ ] Update CHANGELOG.md with v2.8.0 entry
- [ ] Run packaging script
- [ ] Create release notes
- [ ] Test final package
- [ ] Create developer note
- [ ] **VALIDATION**: Package ready for distribution
- [ ] All tests pass with package
- [ ] Release notes complete

## Final Validation Checklist
- [ ] Only `tm` visible in project root
- [ ] All 35+ Python files in `.task-orchestrator/lib/`
- [ ] All commands working identically
- [ ] Migration script tested successfully
- [ ] Fresh installation tested
- [ ] Documentation updated
- [ ] Package created for v2.8.0
- [ ] No performance regression
- [ ] Backward compatibility maintained

## Post-Execution Tasks
- [ ] Update feedback document with "Implemented"
- [ ] Archive Mikado artifacts
- [ ] Notify about v2.8.0 availability
- [ ] Monitor for any issues
- [ ] Document lessons learned

## Success Metrics
- Root directory files: Before 29+ → After 1
- User experience: Cleaner, more professional
- Installation complexity: Simplified
- Update process: Easier (replace entire lib directory)
- Uninstall process: Cleaner (just 2 items to remove)