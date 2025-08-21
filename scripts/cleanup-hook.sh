#!/bin/bash

# Task Orchestrator Cleanup Hook
# This script can be called:
# 1. As a git hook (post-commit, post-merge)
# 2. As a cron job
# 3. Manually by agents
# 4. By CI/CD pipelines

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TM_PYTHON="${PYTHON:-python3}"

# Function to run cleanup with proper environment
run_cleanup() {
    local action="$1"
    shift
    
    cd "$SCRIPT_DIR"
    
    # Import cleanup manager and run command
    $TM_PYTHON << EOF
import sys
sys.path.append('$SCRIPT_DIR')
from tm_context_enhanced import TaskManager
from tm_cleanup_manager import CleanupManager

tm = TaskManager()
tm.init_db()
cm = CleanupManager(tm)

if "$action" == "auto":
    # Auto cleanup on task completion
    result = cm.run_scheduled_cleanup()
    if result:
        print(f"Cleaned {result['files_removed']} files, freed {result['space_freed']/(1024*1024):.2f} MB")
elif "$action" == "prune":
    # Prune old files
    result = cm.prune_old_files()
    print(f"Pruned {result['files_removed']} files, freed {result['space_freed']/(1024*1024):.2f} MB")
elif "$action" == "report":
    # Show storage report
    report = cm.get_storage_report()
    print(f"Total storage: {report['total_size_mb']:.2f} MB")
    print(f"Archives: {report['by_type']['archives']['count']} files")
elif "$action" == "check":
    # Check for oversized files
    oversized = cm.check_file_sizes()
    if oversized:
        print(f"Warning: {len(oversized)} oversized files found")
        for f in oversized[:3]:
            print(f"  - Task {f['task_id']}: {f['size_mb']:.1f} MB")
EOF
}

# Function to setup as git hook
setup_git_hook() {
    local git_root=$(git rev-parse --show-toplevel 2>/dev/null)
    if [ -z "$git_root" ]; then
        echo "Error: Not in a git repository"
        exit 1
    fi
    
    local hook_file="$git_root/.git/hooks/post-commit"
    
    # Create hook script
    cat > "$hook_file" << 'HOOK'
#!/bin/bash
# Task Orchestrator Auto Cleanup Hook

# Run cleanup in background to not slow down git operations
(
    TM_DIR="$(git rev-parse --show-toplevel)/.task-orchestrator"
    if [ -d "$TM_DIR" ]; then
        # Check if cleanup is due
        if [ -f "$TM_DIR/.cleanup_schedule" ]; then
            $(git rev-parse --show-toplevel)/task-orchestrator/cleanup-hook.sh auto &
        fi
    fi
) &
HOOK
    
    chmod +x "$hook_file"
    echo "✓ Git post-commit hook installed at: $hook_file"
}

# Function to setup cron job
setup_cron() {
    local interval="${1:-daily}"
    local cron_schedule=""
    
    case "$interval" in
        hourly)
            cron_schedule="0 * * * *"
            ;;
        daily)
            cron_schedule="0 2 * * *"  # 2 AM daily
            ;;
        weekly)
            cron_schedule="0 2 * * 0"  # 2 AM Sunday
            ;;
        *)
            echo "Usage: $0 cron [hourly|daily|weekly]"
            exit 1
            ;;
    esac
    
    local cron_cmd="$SCRIPT_DIR/cleanup-hook.sh auto"
    
    # Add to crontab
    (crontab -l 2>/dev/null | grep -v "cleanup-hook.sh" ; echo "$cron_schedule $cron_cmd") | crontab -
    
    echo "✓ Cron job scheduled: $interval cleanup"
    echo "  Schedule: $cron_schedule"
    echo "  Command: $cron_cmd"
}

# Function to integrate with task completion
on_task_complete() {
    local task_id="$1"
    
    $TM_PYTHON << EOF
import sys
sys.path.append('$SCRIPT_DIR')
from tm_context_enhanced import TaskManager
from tm_cleanup_manager import CleanupManager

tm = TaskManager()
tm.init_db()
cm = CleanupManager(tm)

# Check if auto-cleanup is enabled
if cm.policies.get('auto_cleanup_on_complete', False):
    result = cm.cleanup_task_files('$task_id', archive_first=True)
    print(f"✓ Task $task_id cleaned: {result['files_removed']} files")
    if result['archived']:
        print(f"  Archived to: {result['archive_path']}")
EOF
}

# Main script logic
case "${1:-help}" in
    auto)
        # Run scheduled cleanup
        run_cleanup "auto"
        ;;
    
    prune)
        # Manual prune
        run_cleanup "prune"
        ;;
    
    report)
        # Show report
        run_cleanup "report"
        ;;
    
    check)
        # Check file sizes
        run_cleanup "check"
        ;;
    
    git-hook)
        # Install as git hook
        setup_git_hook
        ;;
    
    cron)
        # Setup cron job
        setup_cron "${2:-daily}"
        ;;
    
    task-complete)
        # Called when task completes
        if [ -z "$2" ]; then
            echo "Usage: $0 task-complete TASK_ID"
            exit 1
        fi
        on_task_complete "$2"
        ;;
    
    help|*)
        cat << EOF
Task Orchestrator Cleanup Hook

Usage: $0 [command] [options]

Commands:
  auto          Run scheduled cleanup if due
  prune         Manually prune old files
  report        Show storage usage report
  check         Check for oversized files
  git-hook      Install as git post-commit hook
  cron [freq]   Setup cron job (hourly|daily|weekly)
  task-complete Called when task completes
  help          Show this help

Examples:
  # Install git hook for auto cleanup
  $0 git-hook
  
  # Setup daily cron cleanup
  $0 cron daily
  
  # Manual cleanup
  $0 prune
  
  # Check storage usage
  $0 report

This hook can be integrated with:
- Git hooks (post-commit, post-merge)
- Cron jobs for periodic cleanup
- Task completion callbacks
- CI/CD pipelines
EOF
        ;;
esac