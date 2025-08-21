#!/bin/bash

# Agent Helper Script - Integrates task orchestrator into agent workflows

TM="./tm"

# Function to check for pending tasks for this agent
check_my_tasks() {
    echo "=== Your Pending Tasks ==="
    $TM list --status pending --assignee $(whoami)
    echo ""
    echo "=== Your In-Progress Tasks ==="
    $TM list --status in_progress --assignee $(whoami)
}

# Function to pick up next available task
pickup_next_task() {
    # Find first unassigned pending task
    TASK=$($TM list --status pending | grep "○" | head -1 | grep -o '\[[a-f0-9]\{8\}\]' | tr -d '[]')
    
    if [ -n "$TASK" ]; then
        echo "Picking up task: $TASK"
        $TM assign $TASK $(whoami)
        $TM update $TASK --status in_progress
        $TM show $TASK
    else
        echo "No pending tasks available"
    fi
}

# Function to check if blocked by dependencies
check_blockers() {
    echo "=== Blocked Tasks ==="
    $TM list --status blocked
    echo ""
    echo "Check which tasks need to complete first"
}

# Function to complete current task and check impacts
complete_with_review() {
    TASK=$1
    if [ -z "$TASK" ]; then
        echo "Usage: complete_with_review <task_id>"
        return 1
    fi
    
    echo "Completing task $TASK with impact review..."
    $TM complete $TASK --impact-review
    
    echo ""
    echo "Checking for newly unblocked tasks..."
    $TM watch
}

# Function to add a quick todo
quick_todo() {
    TITLE=$1
    FILE=$2
    
    if [ -z "$TITLE" ]; then
        echo "Usage: quick_todo \"title\" [file:line]"
        return 1
    fi
    
    if [ -n "$FILE" ]; then
        $TM add "$TITLE" --file "$FILE" -p low
    else
        $TM add "$TITLE" -p low
    fi
}

# Function to sync and check notifications
sync_check() {
    echo "=== Checking for Updates ==="
    $TM watch
    echo ""
    echo "=== Current Task Status ==="
    check_my_tasks
}

# Main menu
case "$1" in
    "status")
        check_my_tasks
        ;;
    "pickup")
        pickup_next_task
        ;;
    "blocked")
        check_blockers
        ;;
    "complete")
        complete_with_review $2
        ;;
    "todo")
        shift
        quick_todo "$@"
        ;;
    "sync")
        sync_check
        ;;
    *)
        echo "Task Orchestrator Agent Helper"
        echo ""
        echo "Usage: $0 <command> [args]"
        echo ""
        echo "Commands:"
        echo "  status    - Show your assigned tasks"
        echo "  pickup    - Pick up next available task"
        echo "  blocked   - Show blocked tasks"
        echo "  complete  - Complete task with impact review"
        echo "  todo      - Add a quick todo"
        echo "  sync      - Check notifications and sync"
        echo ""
        echo "Examples:"
        echo "  $0 status"
        echo "  $0 pickup"
        echo "  $0 complete abc12345"
        echo "  $0 todo \"Fix typo\" src/main.py:42"
        echo "  $0 sync"
        ;;
esac