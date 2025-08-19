# File Cleanup Strategy for Task Orchestrator

## Overview

The Task Orchestrator's cleanup system prevents file clutter through automatic archival, retention policies, and intelligent pruning. This ensures the system remains performant even with hundreds of tasks and agents.

## Architecture

### Cleanup Manager Components

```
CleanupManager
├── Retention Policies (configurable)
├── Archive System (compressed storage)
├── Pruning Engine (age-based cleanup)
├── Size Monitoring (prevent bloat)
└── Scheduling System (automated cleanup)
```

### File Lifecycle

```
Task Created → Active Files → Task Complete → Archive → Prune
     ↓             ↓              ↓              ↓         ↓
  Context      Read/Write    Auto-Archive   Compress   Delete
  & Notes      by Agents     (optional)    (tar.gz)   (30 days)
```

## Retention Policies

### Default Policies
```json
{
  "completed_tasks_retention_days": 30,
  "cancelled_tasks_retention_days": 7,
  "archive_completed_tasks": true,
  "compress_archives": true,
  "auto_cleanup_on_complete": false,
  "max_context_file_size_mb": 10,
  "max_notes_file_size_mb": 5,
  "cleanup_empty_files": true,
  "archive_format": "tar.gz"
}
```

### Customizing Policies
```bash
# Enable auto-cleanup on task completion
tm cleanup set-policy auto_cleanup_on_complete true

# Change retention period
tm cleanup set-policy completed_tasks_retention_days 60

# Disable compression for faster access
tm cleanup set-policy compress_archives false
```

## Cleanup Commands

### Manual Operations

```bash
# Archive a specific task
tm cleanup archive TASK_ID

# Clean task files (with archival)
tm cleanup clean TASK_ID

# Clean without archiving
tm cleanup clean TASK_ID --no-archive

# Prune old files based on policies
tm cleanup prune

# Dry run to see what would be deleted
tm cleanup prune --dry-run
```

### Monitoring

```bash
# Storage usage report
tm cleanup report

# Check for oversized files
tm cleanup check-sizes

# View current policies
tm cleanup policies
```

### Recovery

```bash
# Restore from archive
tm cleanup restore /path/to/archive.tar.gz

# Restore with specific task ID
tm cleanup restore archive.tar.gz --task-id abc123
```

## Automatic Cleanup

### 1. On Task Completion

When enabled, automatically archives and cleans files when tasks are marked complete:

```bash
# Enable auto-cleanup
tm cleanup set-policy auto_cleanup_on_complete true

# Now when completing tasks:
tm complete TASK_ID  # Files are automatically archived
```

### 2. Git Hook Integration

Install post-commit hook for automatic cleanup:

```bash
# Install git hook
./cleanup-hook.sh git-hook

# Now cleanup runs automatically after git commits
```

### 3. Cron Job Scheduling

Schedule regular cleanup:

```bash
# Daily cleanup at 2 AM
./cleanup-hook.sh cron daily

# Weekly cleanup on Sundays
./cleanup-hook.sh cron weekly

# Hourly cleanup for busy environments
./cleanup-hook.sh cron hourly
```

### 4. CI/CD Integration

Add to your CI/CD pipeline:

```yaml
# GitHub Actions example
- name: Cleanup old task files
  run: |
    cd task-orchestrator
    ./cleanup-hook.sh prune
```

## Archive Structure

Archives preserve complete task context:

```
task_abc123_20250118_143022.tar.gz
├── metadata.json          # Task info and archive metadata
├── context/
│   └── abc123_context.yaml  # Shared context
├── notes/
│   ├── abc123_agent1.md    # Agent 1 private notes
│   └── abc123_agent2.md    # Agent 2 private notes
└── attachments/           # Future: file attachments
```

### Archive Metadata
```json
{
  "task_id": "abc123",
  "title": "Implement feature X",
  "status": "completed",
  "created_at": "2025-01-10T10:00:00",
  "completed_at": "2025-01-18T14:30:00",
  "archived_at": "2025-01-18T14:30:22",
  "files_count": 5,
  "total_size_bytes": 45678
}
```

## Storage Management

### Size Monitoring

The system monitors file sizes to prevent bloat:

```bash
# Check for oversized files
tm cleanup check-sizes

# Output:
# Task abc123: context file
#   Size: 12.3 MB (limit: 10 MB)
#   File: .task-orchestrator/contexts/abc123_context.yaml
```

### Storage Report

Get detailed storage usage:

```bash
tm cleanup report

# Output:
# === Storage Usage Report ===
# Total size: 45.2 MB
# 
# By type:
#   context: 23 files, 12.3 MB
#   notes: 67 files, 8.9 MB
#   archives: 15 files, 24.0 MB
# 
# Largest tasks:
#   abc123: 4.5 MB
#   def456: 3.2 MB
```

## Best Practices

### 1. Retention Strategy

- **Active Development**: 30-60 day retention for completed tasks
- **Long Projects**: 90+ day retention or disable auto-cleanup
- **Cancelled Tasks**: 7 day retention (usually not needed)

### 2. Archive Strategy

- **Always Archive**: Completed tasks with important discoveries
- **Skip Archive**: Temporary or test tasks
- **Compress**: For long-term storage (saves ~70% space)
- **No Compress**: For frequently accessed archives

### 3. Cleanup Triggers

```bash
# Manual cleanup after major milestone
tm cleanup prune

# Auto cleanup on task completion
tm cleanup set-policy auto_cleanup_on_complete true

# Scheduled cleanup for consistent maintenance
./cleanup-hook.sh cron daily
```

### 4. Space Optimization

```bash
# Aggressive cleanup for space-constrained environments
tm cleanup set-policy completed_tasks_retention_days 7
tm cleanup set-policy compress_archives true
tm cleanup set-policy cleanup_empty_files true
tm cleanup set-policy max_context_file_size_mb 5
```

## Integration Patterns

### Pattern 1: Development Workflow

```bash
# Start of sprint - clean old sprint data
tm cleanup prune

# During development - monitor sizes
tm cleanup check-sizes

# Task completion - auto archive
tm complete TASK_ID  # With auto_cleanup_on_complete=true

# End of sprint - storage report
tm cleanup report
```

### Pattern 2: CI/CD Pipeline

```yaml
# .github/workflows/cleanup.yml
name: Task Cleanup
on:
  schedule:
    - cron: '0 2 * * *'  # Daily at 2 AM
  workflow_dispatch:

jobs:
  cleanup:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Prune old tasks
        run: |
          cd task-orchestrator
          python3 -c "
          from tm_context_enhanced import TaskManager
          from tm_cleanup_manager import CleanupManager
          tm = TaskManager()
          tm.init_db()
          cm = CleanupManager(tm)
          result = cm.prune_old_files()
          print(f'Cleaned {result['files_removed']} files')
          "
```

### Pattern 3: Multi-Agent Project

```bash
# Orchestrator sets cleanup policy
export TM_AGENT_ID="orchestrator"
tm cleanup set-policy completed_tasks_retention_days 45
tm cleanup set-policy auto_cleanup_on_complete true

# Agents work normally - cleanup is automatic
export TM_AGENT_ID="agent1"
tm complete task1  # Auto archived

# Periodic maintenance by orchestrator
export TM_AGENT_ID="orchestrator"
tm cleanup report  # Monitor storage
tm cleanup prune --dry-run  # Preview cleanup
```

## Troubleshooting

### Issue: Files Not Being Cleaned

```bash
# Check policies
tm cleanup policies

# Verify retention period has passed
tm list --status completed --format json | \
  jq '.[] | select(.completed_at < "2025-01-01")'

# Force cleanup
tm cleanup clean TASK_ID --no-archive
```

### Issue: Archive Restoration Failed

```bash
# Check archive integrity
tar -tzf archive.tar.gz > /dev/null

# Extract manually if needed
tar -xzf archive.tar.gz
cp -r task_*/context/* .task-orchestrator/contexts/
cp -r task_*/notes/* .task-orchestrator/notes/
```

### Issue: Storage Growing Despite Cleanup

```bash
# Find large files
find .task-orchestrator -type f -size +1M -ls

# Check for tasks with many files
tm cleanup report | grep "Largest tasks"

# Aggressive cleanup
tm cleanup set-policy completed_tasks_retention_days 3
tm cleanup prune
```

## Performance Impact

### Cleanup Operations

| Operation | Time (100 tasks) | Time (1000 tasks) |
|-----------|------------------|-------------------|
| Archive   | ~0.5s per task   | ~0.5s per task    |
| Prune     | <1s total        | ~3s total         |
| Report    | <0.5s            | ~2s               |
| Restore   | ~0.3s per task   | ~0.3s per task    |

### Storage Savings

| Scenario | Before | After Archive | After Prune | Savings |
|----------|--------|---------------|-------------|---------|
| 100 tasks, 30 days | 150 MB | 45 MB | 15 MB | 90% |
| 500 tasks, 60 days | 750 MB | 225 MB | 100 MB | 87% |
| 1000 tasks, 90 days | 1.5 GB | 450 MB | 250 MB | 83% |

## Future Enhancements

1. **Cloud Storage**: Archive to S3/GCS for long-term storage
2. **Incremental Backups**: Only archive changes since last backup
3. **Smart Compression**: Different levels based on file age
4. **Access Patterns**: Keep frequently accessed tasks uncompressed
5. **Distributed Cleanup**: Coordinate cleanup across multiple repositories
6. **Audit Trail**: Track all cleanup operations for compliance

## Summary

The cleanup system ensures the Task Orchestrator remains efficient and clutter-free through:

- **Automatic archival** of completed tasks
- **Configurable retention** policies
- **Compressed storage** for long-term preservation
- **Multiple triggers** (manual, scheduled, hooks)
- **Easy restoration** when needed
- **Size monitoring** to prevent bloat

This allows teams to focus on development without worrying about file management, while preserving important context for future reference.