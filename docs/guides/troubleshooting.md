# Task Orchestrator Troubleshooting Guide

Comprehensive troubleshooting guide for common issues, solutions, and debugging techniques.

## Table of Contents

- [Quick Diagnostics](#quick-diagnostics)
- [Installation Problems](#installation-problems)
- [Database Issues](#database-issues)
- [Core Loop Issues (v2.3)](#core-loop-issues-v23)
- [Lock File Problems](#lock-file-problems)
- [Performance Issues](#performance-issues)
- [Claude Code Integration Issues](#claude-code-integration-issues)
- [Platform-Specific Issues](#platform-specific-issues)
- [Error Messages](#error-messages)
- [Frequently Asked Questions (FAQ)](#frequently-asked-questions-faq)
- [Getting Help](#getting-help)

## Quick Diagnostics

### Health Check Script

Run this quick diagnostic to identify common issues:

```bash
#!/bin/bash
# Task Orchestrator Health Check

echo "=== Task Orchestrator Health Check ==="
echo "Date: $(date)"
echo

# 1. Check Python version
echo "1. Python Version:"
python3 --version || echo "ERROR: Python 3 not found"
echo

# 2. Check tm executable
echo "2. TM Executable:"
if [ -x "./tm" ]; then
    echo "✓ tm executable found and is executable"
else
    echo "✗ tm executable not found or not executable"
    echo "  Solution: chmod +x tm"
fi
echo

# 3. Check database
echo "3. Database Status:"
if [ -f ".task-orchestrator/tasks.db" ]; then
    echo "✓ Database file exists"
    # Check if database is readable
    if sqlite3 .task-orchestrator/tasks.db "SELECT COUNT(*) FROM tasks;" 2>/dev/null; then
        echo "✓ Database is accessible"
    else
        echo "✗ Database exists but is not accessible"
    fi
else
    echo "? Database not initialized"
    echo "  Run: ./tm init"
fi
echo

# 4. Check lock file
echo "4. Lock File Status:"
if [ -f ".task-orchestrator/.lock" ]; then
    echo "⚠ Lock file exists - may indicate stale lock"
    echo "  File: .task-orchestrator/.lock"
    echo "  Created: $(stat -c %y .task-orchestrator/.lock 2>/dev/null || stat -f %Sm .task-orchestrator/.lock 2>/dev/null)"
else
    echo "✓ No lock file present"
fi
echo

# 5. Check permissions
echo "5. Permissions:"
ls -la .task-orchestrator/ 2>/dev/null || echo "? .task-orchestrator directory not found"
echo

# 6. Basic functionality test
echo "6. Basic Functionality Test:"
if ./tm list >/dev/null 2>&1; then
    echo "✓ Basic commands working"
else
    echo "✗ Basic commands failing"
    echo "  Error details:"
    ./tm list 2>&1 | head -3
fi
echo

echo "=== Health Check Complete ==="
```

### System Information

Collect this information when reporting issues:

```bash
# System info
echo "OS: $(uname -a)"
echo "Python: $(python3 --version)"
echo "SQLite: $(sqlite3 --version 2>/dev/null || echo 'Not available')"
echo "Git: $(git --version 2>/dev/null || echo 'Not available')"
echo "Shell: $SHELL"
echo "Working Directory: $(pwd)"
echo "Repository: $(git remote get-url origin 2>/dev/null || echo 'Not in git repo')"

# Task Orchestrator specific
echo "TM Version: $(./tm --version 2>/dev/null || echo 'Not available')"
echo "Database Path: $(readlink -f .task-orchestrator/tasks.db 2>/dev/null || echo 'Not found')"
echo "Agent ID: $(./tm list 2>/dev/null | head -1 || echo 'Cannot determine')"
```

## Installation Problems

### Issue: "Permission denied" when running ./tm

**Symptoms**:
```bash
$ ./tm init
bash: ./tm: Permission denied
```

**Solution**:
```bash
# Make the script executable
chmod +x tm

# Verify permissions
ls -la tm
# Should show: -rwxr-xr-x ... tm
```

**Alternative Solution (if chmod doesn't work)**:
```bash
# Run with Python directly
python3 tm init
```

### Issue: "Python command not found"

**Symptoms**:
```bash
$ ./tm init
./tm: line 1: python3: command not found
```

**Solutions**:

**Linux/Ubuntu**:
```bash
# Install Python 3
sudo apt update
sudo apt install python3

# Alternative: use python if python3 not available
sed -i '1s|python3|python|' tm
```

**macOS**:
```bash
# Install Python 3 via Homebrew
brew install python3

# Or use built-in Python
sed -i '' '1s|python3|python|' tm
```

**Windows (WSL)**:
```bash
# Install Python in WSL
sudo apt update
sudo apt install python3
```

### Issue: "Module not found" errors

**Symptoms**:
```bash
ModuleNotFoundError: No module named 'sqlite3'
```

**Solutions**:

**For sqlite3**:
```bash
# Usually built into Python, but if missing:
# Ubuntu/Debian
sudo apt install python3-sqlite3

# CentOS/RHEL
sudo yum install python3-sqlite3
```

**For other modules**:
All required modules should be in Python standard library. If you get module errors:

```bash
# Check Python installation
python3 -c "import sys; print(sys.version)"
python3 -c "import sqlite3; print('sqlite3 OK')"
python3 -c "import json; print('json OK')"
python3 -c "import pathlib; print('pathlib OK')"

# Reinstall Python if modules missing
```

### Issue: Git repository not found

**Symptoms**:
```bash
$ ./tm init
Error: Not in a git repository
```

**Solutions**:
```bash
# Initialize git repository
git init

# Or work outside git (database will be in current directory)
export TM_DB_PATH="./tasks.db"
./tm init
```

## Database Issues

### Issue: Database corruption

**Symptoms**:
```bash
$ ./tm list
Error: database disk image is malformed
```

**Diagnostic Steps**:
```bash
# Check database integrity
sqlite3 .task-orchestrator/tasks.db "PRAGMA integrity_check;"

# Check database schema
sqlite3 .task-orchestrator/tasks.db ".schema"

# Check file permissions
ls -la .task-orchestrator/tasks.db
```

**Solutions**:

**Option 1: Backup and recreate**:
```bash
# Export existing data
./tm export --format json > backup_$(date +%Y%m%d).json

# Backup corrupted database
mv .task-orchestrator/tasks.db .task-orchestrator/tasks.db.corrupt

# Reinitialize
./tm init

# Manual data recovery (requires custom script)
# See "Data Recovery" section below
```

**Option 2: SQLite recovery**:
```bash
# Try SQLite recovery
sqlite3 .task-orchestrator/tasks.db.corrupt ".recover" | sqlite3 .task-orchestrator/tasks_recovered.db

# Test recovered database
sqlite3 .task-orchestrator/tasks_recovered.db "SELECT COUNT(*) FROM tasks;"

# If successful, replace original
mv .task-orchestrator/tasks.db .task-orchestrator/tasks.db.backup
mv .task-orchestrator/tasks_recovered.db .task-orchestrator/tasks.db
```

### Issue: Database locked errors

**Symptoms**:
```bash
$ ./tm add "Test task"
Error: database is locked
```

**Diagnostic Steps**:
```bash
# Check for running processes
ps aux | grep tm
ps aux | grep sqlite

# Check lock file
ls -la .task-orchestrator/.lock

# Check database access
lsof .task-orchestrator/tasks.db 2>/dev/null || echo "No processes using database"
```

**Solutions**:
```bash
# 1. Wait for operations to complete
sleep 5
./tm list

# 2. Remove stale lock file (use with caution)
rm .task-orchestrator/.lock

# 3. Kill stuck processes
pkill -f "tm "

# 4. Increase timeout
export TM_LOCK_TIMEOUT=60
./tm add "Test task"

# 5. Check filesystem issues
df -h .
# Ensure sufficient disk space
```

### Issue: Foreign key constraint errors

**Symptoms**:
```bash
$ ./tm delete abc12345
Error: FOREIGN KEY constraint failed
```

**Explanation**: This is expected behavior when trying to delete tasks that other tasks depend on.

**Solutions**:
```bash
# Check what depends on this task
./tm show abc12345

# Delete dependent tasks first
./tm list | grep "deps: abc12345"

# Or complete the task instead of deleting
./tm complete abc12345
```

### Issue: Database schema version mismatch

**Symptoms**:
```bash
$ ./tm list
Error: no such column: version
```

**Solution - Database migration**:
```bash
# Backup current database
cp .task-orchestrator/tasks.db .task-orchestrator/tasks.db.backup

# Check current schema
sqlite3 .task-orchestrator/tasks.db ".schema tasks"

# Add missing columns
sqlite3 .task-orchestrator/tasks.db << 'EOF'
ALTER TABLE tasks ADD COLUMN version INTEGER DEFAULT 1;
ALTER TABLE tasks ADD COLUMN impact_notes TEXT;
EOF

# Verify update
./tm list
```

## Core Loop Issues (v2.3)

### Migration Issues

#### Issue: Migration fails with "duplicate column"

**Symptoms**:
```bash
$ ./tm migrate --apply
Error: duplicate column name: success_criteria
```

**Cause**: The migration has already been applied or columns were manually added.

**Solutions**:
```bash
# Check migration status
./tm migrate --status

# If already applied, no action needed
# If partially applied, rollback and retry:
./tm migrate --rollback
./tm migrate --apply

# If rollback fails, restore from backup:
cp ~/.task-orchestrator.backup/tasks.db ~/.task-orchestrator/tasks.db
./tm migrate --apply
```

#### Issue: Migration backup fails

**Symptoms**:
```bash
$ ./tm migrate --apply
Error: Failed to create backup
```

**Solutions**:
```bash
# Check disk space
df -h ~/.task-orchestrator

# Check permissions
ls -la ~/.task-orchestrator

# Create backup directory manually
mkdir -p ~/.task-orchestrator/backups
chmod 755 ~/.task-orchestrator/backups

# Retry migration
./tm migrate --apply
```

### Success Criteria Issues

#### Issue: Invalid success criteria format

**Symptoms**:
```bash
$ ./tm add "Task" --criteria "Test complete"
Error: Invalid JSON in success criteria
```

**Cause**: Criteria must be a valid JSON array of objects.

**Solutions**:
```bash
# Correct format - JSON array with objects:
./tm add "Task" --criteria '[{"criterion":"Test complete","measurable":"true"}]'

# Multiple criteria:
./tm add "Task" --criteria '[
  {"criterion":"Tests pass","measurable":"true"},
  {"criterion":"Docs updated","measurable":"docs_complete == true"}
]'

# Common mistakes to avoid:
# 1. Missing array brackets
./tm add "Task" --criteria '{"criterion":"Test"}'  # WRONG

# 2. Single quotes in JSON (use double quotes)
./tm add "Task" --criteria "[{'criterion':'Test'}]"  # WRONG

# 3. Unquoted JSON
./tm add "Task" --criteria [{"criterion":"Test"}]  # WRONG
```

#### Issue: Validation fails unexpectedly

**Symptoms**:
```bash
$ ./tm complete task_id --validate
Error: Criteria validation failed: Expression evaluation error
```

**Solutions**:
```bash
# Check criteria syntax
./tm show task_id

# Common expression issues:
# 1. Undefined variables (use simple boolean)
--criteria '[{"criterion":"Done","measurable":"true"}]'

# 2. Invalid operators (use ==, !=, <, >, <=, >=)
--criteria '[{"criterion":"Score high","measurable":"score >= 90"}]'

# 3. Complex expressions (keep simple)
--criteria '[{"criterion":"Fast","measurable":"time < 100"}]'

# Skip validation if criteria are subjective
./tm complete task_id  # Without --validate flag
```

### Feedback Issues

#### Issue: Cannot add feedback

**Symptoms**:
```bash
$ ./tm feedback task_id --quality 5
Error: Cannot add feedback to non-completed task
```

**Solutions**:
```bash
# 1. Check task status
./tm show task_id

# 2. Complete task first
./tm complete task_id

# 3. Then add feedback
./tm feedback task_id --quality 5 --timeliness 4

# 4. If task was already completed but feedback fails:
# Check if feedback is enabled
./tm config --show
./tm config --enable feedback
```

#### Issue: Metrics not showing

**Symptoms**:
```bash
$ ./tm metrics --feedback
No feedback data available
```

**Solutions**:
```bash
# 1. Ensure feedback is enabled
./tm config --enable feedback

# 2. Check if any tasks have feedback
sqlite3 ~/.task-orchestrator/tasks.db \
  "SELECT COUNT(*) FROM tasks WHERE feedback_quality IS NOT NULL;"

# 3. Add feedback to some completed tasks
./tm list --status completed | head -3 | while read line; do
  task_id=$(echo $line | awk '{print $1}')
  ./tm feedback $task_id --quality 4 --timeliness 4
done

# 4. Retry metrics
./tm metrics --feedback
```

### Progress Tracking Issues

#### Issue: Progress updates not saving

**Symptoms**:
```bash
$ ./tm progress task_id "Update message"
Progress update added
$ ./tm show task_id
# No progress shown
```

**Solutions**:
```bash
# 1. Check database permissions
ls -la ~/.task-orchestrator/tasks.db

# 2. Verify task exists
./tm show task_id

# 3. Check if progress tracking is enabled
./tm config --show
./tm config --enable time-tracking

# 4. Try with explicit timestamp
./tm progress task_id "$(date): Update message"
```

### Configuration Issues

#### Issue: Configuration not persisting

**Symptoms**:
```bash
$ ./tm config --enable feedback
$ ./tm config --show
# feedback still shows disabled
```

**Solutions**:
```bash
# 1. Check config file location
ls -la ~/.task-orchestrator/config.yaml

# 2. Fix permissions
chmod 644 ~/.task-orchestrator/config.yaml

# 3. Check disk space
df -h ~/.task-orchestrator

# 4. Reset configuration
./tm config --reset
./tm config --enable feedback

# 5. Verify YAML syntax if manually edited
python3 -c "import yaml; yaml.safe_load(open('$HOME/.task-orchestrator/config.yaml'))"
```

#### Issue: Minimal mode not working

**Symptoms**: Core Loop features still active after enabling minimal mode

**Solutions**:
```bash
# 1. Enable minimal mode correctly
./tm config --minimal-mode

# 2. Verify all features disabled
./tm config --show
# Should show all Core Loop features as disabled

# 3. If not working, disable manually
./tm config --disable success-criteria
./tm config --disable feedback
./tm config --disable telemetry
./tm config --disable completion-summaries
./tm config --disable time-tracking
./tm config --disable deadlines
```

### Time Tracking Issues

#### Issue: Actual hours not recording

**Symptoms**:
```bash
$ ./tm complete task_id --actual-hours 5.5
Task completed
$ ./tm show task_id
# No actual hours shown
```

**Solutions**:
```bash
# 1. Ensure time tracking is enabled
./tm config --enable time-tracking

# 2. Check if task had estimated hours
./tm show task_id

# 3. Update database schema if needed
./tm migrate --apply

# 4. Manually update if necessary
sqlite3 ~/.task-orchestrator/tasks.db \
  "UPDATE tasks SET actual_hours = 5.5 WHERE id = 'task_id';"
```

### Deadline Issues

#### Issue: Deadlines not recognized

**Symptoms**:
```bash
$ ./tm add "Task" --deadline "tomorrow"
Error: Invalid deadline format
```

**Solutions**:
```bash
# Use ISO 8601 format for deadlines
./tm add "Task" --deadline "2025-12-31T17:00:00Z"

# Common formats:
# Date only: 2025-12-31
# Date and time: 2025-12-31T17:00:00
# With timezone: 2025-12-31T17:00:00Z (UTC)
#               2025-12-31T17:00:00-05:00 (EST)

# Check overdue tasks
./tm list --overdue

# Update existing task deadline
sqlite3 ~/.task-orchestrator/tasks.db \
  "UPDATE tasks SET deadline = '2025-12-31T17:00:00Z' WHERE id = 'task_id';"
```

## Lock File Problems

### Issue: Persistent lock file prevents operations

**Symptoms**:
```bash
$ ./tm list
Error: Could not acquire database lock
```

**Diagnostic Steps**:
```bash
# Check lock file age
stat .task-orchestrator/.lock

# Check if any tm processes are running
ps aux | grep tm | grep -v grep

# Check system load
uptime
```

**Solutions**:

**Safe approach**:
```bash
# Wait for lock to clear
echo "Waiting for lock to clear..."
while [ -f .task-orchestrator/.lock ]; do
    sleep 1
    echo -n "."
done
echo " Lock cleared!"

# Or with timeout
timeout 30 bash -c 'while [ -f .task-orchestrator/.lock ]; do sleep 1; done'
```

**Force removal (use with caution)**:
```bash
# Only if you're certain no other processes are running
if ! ps aux | grep -q "[t]m "; then
    echo "No tm processes found, removing stale lock"
    rm .task-orchestrator/.lock
else
    echo "tm processes still running, do not remove lock"
fi
```

### Issue: Permission denied on lock file

**Symptoms**:
```bash
$ ./tm init
Error: Permission denied: .task-orchestrator/.lock
```

**Solutions**:
```bash
# Check permissions
ls -la .task-orchestrator/

# Fix directory permissions
chmod 755 .task-orchestrator

# Fix lock file permissions (if exists)
[ -f .task-orchestrator/.lock ] && chmod 644 .task-orchestrator/.lock

# Check if directory is writable
touch .task-orchestrator/test && rm .task-orchestrator/test
```

## Performance Issues

### Issue: Slow database operations

**Symptoms**:
- Commands take more than 5 seconds
- Database grows very large
- System becomes unresponsive during operations

**Diagnostic Steps**:
```bash
# Check database size
ls -lh .task-orchestrator/tasks.db

# Count records
sqlite3 .task-orchestrator/tasks.db << 'EOF'
SELECT 'tasks', COUNT(*) FROM tasks
UNION ALL
SELECT 'dependencies', COUNT(*) FROM dependencies
UNION ALL
SELECT 'file_refs', COUNT(*) FROM file_refs
UNION ALL
SELECT 'audit_log', COUNT(*) FROM audit_log;
EOF

# Check for missing indexes
sqlite3 .task-orchestrator/tasks.db << 'EOF'
.indexes
EOF
```

**Solutions**:

**Database optimization**:
```bash
# Vacuum database
sqlite3 .task-orchestrator/tasks.db "VACUUM;"

# Analyze tables for better query planning
sqlite3 .task-orchestrator/tasks.db "ANALYZE;"

# Check query performance
sqlite3 .task-orchestrator/tasks.db << 'EOF'
EXPLAIN QUERY PLAN SELECT * FROM tasks WHERE status = 'pending';
EOF
```

**Cleanup old data**:
```bash
# Archive completed tasks older than 90 days
sqlite3 .task-orchestrator/tasks.db << 'EOF'
-- Export old completed tasks
.output old_tasks.sql
.dump
.output stdout

-- Delete old completed tasks
DELETE FROM tasks 
WHERE status = 'completed' 
  AND datetime(completed_at) < datetime('now', '-90 days');
EOF

# Vacuum after cleanup
sqlite3 .task-orchestrator/tasks.db "VACUUM;"
```

**Performance tuning**:
```bash
# Increase lock timeout for slow systems
export TM_LOCK_TIMEOUT=60

# Use pagination for large lists
./tm list --limit 50

# Filter results
./tm list --status pending --limit 20
```

### Issue: High memory usage

**Diagnostic Steps**:
```bash
# Monitor memory usage
top -p $(pgrep -f tm)

# Check for memory leaks
valgrind --tool=memcheck python3 tm list
```

**Solutions**:
```bash
# Use streaming export for large datasets
./tm export --format json | gzip > tasks_$(date +%Y%m%d).json.gz

# Limit query results
./tm list --limit 100

# Restart long-running processes periodically
```

## Claude Code Integration Issues

### Issue: Claude Code can't find task orchestrator

**Symptoms**:
- Claude Code commands fail
- Integration features not working

**Solutions**:
```bash
# Set environment variables
export TM_CLAUDE_INTEGRATION=true
export PATH=$PATH:$(pwd)

# Verify integration
echo $TM_CLAUDE_INTEGRATION
which tm

# Test basic integration
./tm add "Test Claude integration" --tag claude-test
```

### Issue: File reference synchronization problems

**Symptoms**:
- File changes not triggering notifications
- Incorrect line number references

**Diagnostic Steps**:
```bash
# Check file references in database
sqlite3 .task-orchestrator/tasks.db << 'EOF'
SELECT task_id, file_path, line_start, line_end 
FROM file_refs 
ORDER BY file_path;
EOF

# Check for stale references
find . -name "*.py" | while read file; do
    if ! [ -f "$file" ]; then
        echo "Missing file referenced in tasks: $file"
    fi
done
```

**Solutions**:
```bash
# Update file references
# (Manual process - update line numbers in database)

# Clean up stale references
sqlite3 .task-orchestrator/tasks.db << 'EOF'
DELETE FROM file_refs 
WHERE task_id IN (
    SELECT DISTINCT task_id 
    FROM file_refs f 
    WHERE NOT EXISTS (
        SELECT 1 FROM tasks t WHERE t.id = f.task_id
    )
);
EOF
```

## Platform-Specific Issues

### Windows (WSL) Issues

#### Issue: Line ending problems

**Symptoms**:
```bash
$ ./tm init
: No such file or directory
```

**Solution**:
```bash
# Convert line endings
dos2unix tm

# Or manually fix
sed -i 's/\r$//' tm
```

#### Issue: Path separator issues

**Symptoms**:
- File references use backslashes
- Database path errors

**Solutions**:
```bash
# Set Unix-style paths
export TM_DB_PATH=".task-orchestrator/tasks.db"

# Use forward slashes in file references
./tm add "Fix Windows issue" --file "src/auth.py:42"
```

### macOS Issues

#### Issue: BSD vs GNU tool differences

**Symptoms**:
- stat command format errors
- sed behavior differences

**Solutions**:
```bash
# Install GNU tools via Homebrew
brew install coreutils gnu-sed

# Use gstat instead of stat
alias stat=gstat

# Or modify commands for BSD compatibility
# BSD: stat -f %Sm filename
# GNU: stat -c %y filename
```

### Linux Distribution Issues

#### Issue: Missing sqlite3 on minimal installations

**Solutions**:
```bash
# Ubuntu/Debian
sudo apt install sqlite3

# CentOS/RHEL
sudo yum install sqlite

# Alpine
apk add sqlite
```

#### Issue: SELinux blocking database access

**Symptoms**:
```bash
$ ./tm init
Error: Permission denied (SELinux)
```

**Solutions**:
```bash
# Check SELinux status
getenforce

# Temporarily disable (not recommended for production)
sudo setenforce 0

# Or create SELinux policy
# (Advanced - consult SELinux documentation)
```

## Error Messages

### "ValidationError: Task title cannot be empty"

**Cause**: Attempting to create task with empty or whitespace-only title.

**Solution**:
```bash
# Correct usage
./tm add "Actual task title"

# Not this
./tm add ""
./tm add "   "
```

### "CircularDependencyError: Adding these dependencies would create a circular dependency"

**Cause**: Trying to create dependencies that would form a cycle.

**Example Problem**:
```bash
# Task A depends on Task B
# Task B depends on Task C  
# Trying to make Task C depend on Task A (creates cycle)
```

**Solution**:
```bash
# Review dependency chain
./tm show task_a_id
./tm show task_b_id  
./tm show task_c_id

# Restructure dependencies to be linear
# Consider breaking large tasks into smaller independent tasks
```

### "Task abc12345 not found"

**Cause**: Referencing a task ID that doesn't exist.

**Diagnostic Steps**:
```bash
# List all tasks to find correct ID
./tm list

# Search for similar IDs
./tm list | grep abc

# Check if task was deleted
sqlite3 .task-orchestrator/tasks.db << 'EOF'
SELECT * FROM audit_log WHERE task_id LIKE 'abc%';
EOF
```

### "Cannot delete task: N task(s) depend on it"

**Cause**: Attempting to delete a task that other tasks depend on.

**Solution**:
```bash
# Find dependent tasks
./tm show abc12345

# Complete the task instead of deleting
./tm complete abc12345

# Or delete dependent tasks first
for dep_task in $(./tm list | grep "deps: abc12345" | cut -d' ' -f2); do
    ./tm delete $dep_task
done
./tm delete abc12345
```

### "Invalid task ID format"

**Cause**: Using incorrectly formatted task ID.

**Requirements**: Task IDs must be exactly 8 hexadecimal characters.

**Examples**:
```bash
# Valid
./tm show abc12345

# Invalid
./tm show abc123     # Too short
./tm show abc123456  # Too long  
./tm show abcdefgh   # Not hex
```

## Frequently Asked Questions (FAQ)

### Q: How do I backup my tasks?

**A**: Use the export functionality:
```bash
# Regular backup
./tm export --format json > backup_$(date +%Y%m%d).json

# Automated daily backup
echo "0 2 * * * cd /path/to/project && ./tm export --format json > backups/tasks_\$(date +\%Y\%m\%d).json" | crontab -

# Database file backup
cp .task-orchestrator/tasks.db backup_tasks_$(date +%Y%m%d).db
```

### Q: How do I restore from backup?

**A**: Currently manual process:
```bash
# Backup current state
./tm export --format json > current_backup.json

# Clear database (WARNING: This deletes all tasks)
rm .task-orchestrator/tasks.db
./tm init

# Manual restoration requires custom script
# (Feature request: Add tm import command)
```

### Q: Can I use task orchestrator across multiple repositories?

**A**: Each repository has its own task database:
```bash
# Option 1: Use symbolic links
ln -s /central/task-orchestrator/.task-orchestrator .task-orchestrator

# Option 2: Set custom database path
export TM_DB_PATH="/central/tasks.db"

# Option 3: Use multiple databases and sync externally
```

### Q: How do I migrate to a new version?

**A**: Generally backwards compatible:
```bash
# Backup first
./tm export --format json > migration_backup.json

# Test new version
./tm list

# Check for new features
./tm --help
```

### Q: What's the maximum number of tasks supported?

**A**: SQLite can handle millions of records, but performance depends on:
- Available memory
- Disk speed
- Query complexity

**Practical limits**:
- Small projects: < 1,000 tasks (excellent performance)
- Medium projects: 1,000-10,000 tasks (good performance)
- Large projects: 10,000+ tasks (may need optimization)

### Q: How do I change the database location?

**A**: Use environment variable:
```bash
# Temporary change
export TM_DB_PATH="/new/location/tasks.db"
./tm init

# Permanent change (add to shell profile)
echo 'export TM_DB_PATH="/new/location/tasks.db"' >> ~/.bashrc
source ~/.bashrc
```

### Q: Can multiple users share the same task database?

**A**: Yes, but consider:
```bash
# Ensure shared access
chmod 664 .task-orchestrator/tasks.db
chmod 775 .task-orchestrator/

# Each user gets unique agent ID
# Based on username and process ID

# For team coordination, consider file sharing:
# - Network drives
# - Git repository sharing
# - Database synchronization tools
```

### Q: How do I clean up completed tasks?

**A**: Manual cleanup process:
```bash
# Archive completed tasks older than 30 days
sqlite3 .task-orchestrator/tasks.db << 'EOF'
-- Create archive table
CREATE TABLE IF NOT EXISTS archived_tasks AS 
SELECT * FROM tasks WHERE 1=0;

-- Move old completed tasks to archive
INSERT INTO archived_tasks 
SELECT * FROM tasks 
WHERE status = 'completed' 
  AND datetime(completed_at) < datetime('now', '-30 days');

-- Remove from main table
DELETE FROM tasks 
WHERE status = 'completed' 
  AND datetime(completed_at) < datetime('now', '-30 days');
EOF

# Vacuum database
sqlite3 .task-orchestrator/tasks.db "VACUUM;"
```

### Core Loop Features FAQ (v2.3)

#### Q: How do I enable Core Loop features?

**A**: Core Loop features are optional and can be enabled individually:
```bash
# View current configuration
./tm config --show

# Enable specific features
./tm config --enable success-criteria
./tm config --enable feedback
./tm config --enable time-tracking

# Or use minimal mode (all features off)
./tm config --minimal-mode
```

#### Q: Do I need to migrate for v2.3?

**A**: Yes, if upgrading from v2.2 or earlier:
```bash
# ALWAYS backup first
cp -r ~/.task-orchestrator ~/.task-orchestrator.backup

# Apply migration
./tm migrate --apply

# Verify success
./tm migrate --status
```

#### Q: What format do success criteria use?

**A**: JSON array of objects:
```bash
# Correct format
--criteria '[{"criterion":"Tests pass","measurable":"true"}]'

# Multiple criteria
--criteria '[
  {"criterion":"Tests pass","measurable":"true"},
  {"criterion":"Docs complete","measurable":"docs_written == true"}
]'
```

#### Q: How do feedback scores work?

**A**: 1-5 scale for quality and timeliness:
- **5**: Exceptional/Well ahead of schedule
- **4**: Above expectations/Ahead of schedule  
- **3**: Meets expectations/On time
- **2**: Below expectations/Late
- **1**: Poor quality/Significantly late

```bash
./tm feedback task_id --quality 4 --timeliness 5 --note "Great work!"
```

#### Q: Can I disable Core Loop features?

**A**: Yes, all features can be toggled:
```bash
# Disable specific feature
./tm config --disable telemetry

# Disable all (minimal mode)
./tm config --minimal-mode

# Reset to defaults
./tm config --reset
```

#### Q: Will existing tasks work with Core Loop?

**A**: Yes, fully backward compatible:
- Existing tasks work unchanged
- Core Loop fields are optional
- Add Core Loop data to existing tasks anytime
- No workflow changes required

#### Q: How do progress updates work?

**A**: Track task advancement with messages:
```bash
# Simple update
./tm progress task_id "Started work"

# Percentage progress
./tm progress task_id "50% - Backend complete"

# View history
./tm show task_id
```

#### Q: What are completion summaries for?

**A**: Capture context and learnings:
```bash
./tm complete task_id --summary "Fixed race condition with mutex locks.
                                 Root cause: concurrent updates.
                                 Added regression tests."
```

#### Q: How accurate is time tracking?

**A**: Compares estimates to actuals:
```bash
# Set estimate
./tm add "Task" --estimated-hours 20

# Record actual
./tm complete task_id --actual-hours 18.5

# View variance
./tm show task_id
# Shows: -1.5 hours (7.5% under)
```

#### Q: Can I use Core Loop in CI/CD?

**A**: Yes, supports automation:
```bash
# CI pipeline example
TASK=$(./tm add "Build #123" --criteria '[{"criterion":"Tests pass","measurable":"true"}]')
./tm progress $TASK "Running tests..."
if [ "$TESTS" = "pass" ]; then
  ./tm complete $TASK --validate --summary "All tests passed"
fi
```

## Getting Help

### Self-Service Debugging

1. **Run health check** (see Quick Diagnostics section)
2. **Check logs** (if verbose mode enabled)
3. **Review error messages** carefully
4. **Test minimal reproduction** case

### Community Support

#### GitHub Issues

Create an issue with:
- **Environment details** (OS, Python version, etc.)
- **Complete error messages**
- **Steps to reproduce**
- **Expected vs actual behavior**
- **Health check output**

#### Discussions

For questions and usage help:
- General usage questions
- Integration ideas
- Feature discussions
- Best practices

### Reporting Bugs

**Bug Report Template**:
```markdown
## Environment
- OS: 
- Python version:
- Task Orchestrator version:
- Repository type: (git/non-git)

## Steps to Reproduce
1. 
2. 
3. 

## Expected Behavior


## Actual Behavior


## Error Messages
```

## Additional Resources

- [User Guide](USER_GUIDE.md) - Complete usage documentation
- [Developer Guide](DEVELOPER_GUIDE.md) - Contributing and extending
- [API Reference](API_REFERENCE.md) - Complete API documentation
- [GitHub Repository](https://github.com/T72/task-orchestrator) - Latest code and issues

---

**Remember**: When in doubt, backup your tasks with `./tm export` before attempting any fixes!