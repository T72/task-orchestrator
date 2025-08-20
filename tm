#!/usr/bin/env python3
"""
Enhanced Task Manager with Collaboration Features
Extends the base tm with share, note, discover, sync, context, and join commands
"""

import sys
import os
import subprocess
from pathlib import Path

# Add src directory to path
script_dir = Path(__file__).parent
src_dir = script_dir / "src"
if src_dir.exists():
    sys.path.insert(0, str(src_dir))

# Import the collaboration module
try:
    from tm_collaboration import CollaborationManager
except ImportError:
    print("Warning: Collaboration module not found. Some commands will be unavailable.")
    CollaborationManager = None

def main():
    """Enhanced main function with collaboration commands"""
    
    # Import TaskManager for all commands
    try:
        from tm_production import TaskManager
        tm = TaskManager()
    except ImportError as e:
        print(f"Error importing production module: {e}")
        sys.exit(1)
    
    # Check if this is a collaboration command that needs special handling
    if len(sys.argv) > 1 and sys.argv[1] in ['join', 'share', 'note', 'sync', 'context']:
        if CollaborationManager is None:
            print("Error: Collaboration features not available")
            sys.exit(1)
        
        # Handle collaboration commands
        repo_root = find_repo_root()
        collab = CollaborationManager(repo_root)
        
        command = sys.argv[1]
        
        if len(sys.argv) < 3:
            print(f"Usage: tm {command} <task_id> [message]")
            sys.exit(1)
        
        task_id = sys.argv[2]
        
        if command == 'join':
            collab.join(task_id)
        elif command == 'context':
            print(collab.context(task_id))
        else:
            # Commands that require a message
            if len(sys.argv) < 4:
                print(f"Usage: tm {command} <task_id> <message>")
                sys.exit(1)
            
            message = ' '.join(sys.argv[3:])
            
            if command == 'share':
                collab.share(task_id, message)
            elif command == 'note':
                collab.note(task_id, message)
            elif command == 'sync':
                collab.sync(task_id, message)
    elif len(sys.argv) > 1 and sys.argv[1] == 'discover':
        # Route discover through tm_production for notifications
        if len(sys.argv) < 4:
            print("Usage: tm discover <task_id> <message>")
            sys.exit(1)
        
        task_id = sys.argv[2]
        message = ' '.join(sys.argv[3:])
        
        if tm.discover(task_id, message):
            print(f"Discovery shared for task {task_id}")
        else:
            print(f"Failed to share discovery")
            sys.exit(1)
    else:
        # Handle standard tm commands using tm_production module
        if len(sys.argv) < 2:
            print("Usage: tm <command> [args]")
            print("Commands: init, add, list, show, update, complete, export, etc.")
            sys.exit(1)
        
        command = sys.argv[1]
        
        # Route to appropriate TaskManager method
        if command == "init":
            tm._init_db()
            print("Task database initialized")
        elif command == "add":
            if len(sys.argv) < 3:
                print("Usage: tm add <title> [-d description] [-p priority] [--depends-on task_id] [--file path:line]")
                sys.exit(1)
            # Simple argument parsing for add command
            title = sys.argv[2]
            description = None
            priority = None
            depends_on = []
            file_refs = []
            
            # Parse additional arguments
            i = 3
            while i < len(sys.argv):
                if sys.argv[i] == "-d" and i + 1 < len(sys.argv):
                    description = sys.argv[i + 1]
                    i += 2
                elif sys.argv[i] == "-p" and i + 1 < len(sys.argv):
                    priority = sys.argv[i + 1]
                    i += 2
                elif sys.argv[i] == "--depends-on" and i + 1 < len(sys.argv):
                    depends_on.append(sys.argv[i + 1])
                    i += 2
                elif sys.argv[i] == "--file" and i + 1 < len(sys.argv):
                    file_refs.append(sys.argv[i + 1])
                    i += 2
                else:
                    i += 1
            
            # Add file references to description if provided
            if file_refs:
                file_info = "Files: " + ", ".join(file_refs)
                if description:
                    description = f"{description}\n{file_info}"
                else:
                    description = file_info
            
            try:
                task_id = tm.add(title, description=description, priority=priority, 
                               depends_on=depends_on if depends_on else None)
                print(f"Task created with ID: {task_id}")
            except ValueError as e:
                print(f"Error: {e}")
                sys.exit(1)
        elif command == "list":
            # Parse list filters
            status_filter = None
            assignee_filter = None
            has_deps = "--has-deps" in sys.argv
            
            if "--status" in sys.argv:
                idx = sys.argv.index("--status")
                if idx + 1 < len(sys.argv):
                    status_filter = sys.argv[idx + 1]
            
            if "--assignee" in sys.argv:
                idx = sys.argv.index("--assignee")
                if idx + 1 < len(sys.argv):
                    assignee_filter = sys.argv[idx + 1]
            
            tasks = tm.list(status=status_filter, assignee=assignee_filter, has_deps=has_deps)
            
            if not tasks:
                print("No tasks found")
            else:
                for task in tasks:
                    print(f"[{task['id']}] {task['title']} - {task['status']}")
        elif command == "show":
            if len(sys.argv) < 3:
                print("Usage: tm show <task_id>")
                sys.exit(1)
            task_id = sys.argv[2]
            task = tm.show(task_id)
            if task:
                for key, value in task.items():
                    print(f"{key}: {value}")
            else:
                print(f"Task {task_id} not found")
                sys.exit(1)
        elif command == "update":
            if len(sys.argv) < 3:
                print("Usage: tm update <task_id> --status <status>")
                sys.exit(1)
            task_id = sys.argv[2]
            # Simple status update handling
            if "--status" in sys.argv:
                idx = sys.argv.index("--status")
                if idx + 1 < len(sys.argv):
                    status = sys.argv[idx + 1]
                    tm.update(task_id, status=status)
                    print(f"Task {task_id} updated")
        elif command == "complete":
            if len(sys.argv) < 3:
                print("Usage: tm complete <task_id> [--impact-review]")
                sys.exit(1)
            task_id = sys.argv[2]
            impact_review = "--impact-review" in sys.argv
            
            # Complete the task
            tm.complete(task_id)
            print(f"Task {task_id} completed")
            
            # If impact review requested, show potentially affected tasks
            if impact_review:
                # Get the completed task details to find file references
                task = tm.show(task_id)
                if task and task.get('description') and 'Files:' in task['description']:
                    print("\n=== Impact Review ===")
                    print("This task referenced files. Other tasks may be affected.")
                    print("Consider reviewing tasks that reference the same files.")
                    # Create a notification for impact review
                    tm.discover(task_id, f"Task completed with impact review - check related file references")
        elif command == "delete":
            if len(sys.argv) < 3:
                print("Usage: tm delete <task_id>")
                sys.exit(1)
            task_id = sys.argv[2]
            if tm.delete(task_id):
                print(f"Task {task_id} deleted")
            else:
                print(f"Failed to delete task {task_id}")
                sys.exit(1)
        elif command == "assign":
            if len(sys.argv) < 4:
                print("Usage: tm assign <task_id> <assignee>")
                sys.exit(1)
            task_id = sys.argv[2]
            assignee = sys.argv[3]
            if tm.update(task_id, assignee=assignee):
                print(f"Task {task_id} assigned to {assignee}")
            else:
                print(f"Failed to assign task {task_id}")
                sys.exit(1)
        elif command == "export":
            # Export implementation using tm_production method
            format_type = "json"  # default
            if "--format" in sys.argv:
                idx = sys.argv.index("--format")
                if idx + 1 < len(sys.argv):
                    format_type = sys.argv[idx + 1]
            
            output = tm.export(format=format_type)
            print(output)
        elif command == "watch":
            # Watch for notifications
            notifications = tm.watch()
            if not notifications:
                print("No new notifications")
            else:
                print(f"=== {len(notifications)} New Notification(s) ===")
                for notif in notifications:
                    print(f"[{notif['type'].upper()}] {notif['message']}")
                    if notif['created_at']:
                        print(f"  Time: {notif['created_at']}")
                    print()
        else:
            print(f"Command '{command}' not yet implemented in enhanced wrapper")
            print("Please use the production module directly for full functionality")

def find_repo_root() -> Path:
    """Find git repository root"""
    try:
        result = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            capture_output=True, text=True, check=True
        )
        return Path(result.stdout.strip())
    except subprocess.CalledProcessError:
        return Path.cwd()

if __name__ == "__main__":
    # Show enhanced help if requested
    if len(sys.argv) > 1 and sys.argv[1] in ['--help', '-h', 'help']:
        print("""Task Manager - Enhanced with Collaboration Features

Standard Commands:
  init                Initialize task database
  add <title>         Add a new task
  list                List all tasks
  show <id>           Show task details
  update <id>         Update task properties
  delete <id>         Delete a task
  complete <id>       Mark task as complete
  assign <id> <agent> Assign task to agent
  watch               Check for notifications
  export              Export tasks

Collaboration Commands:
  join <id>           Join a task's collaboration
  share <id> <msg>    Share update with all agents
  note <id> <msg>     Add private note (only you see)
  discover <id> <msg> Share critical finding (alerts all)
  sync <id> <msg>     Create synchronization point
  context <id>        View all shared context

Environment Variables:
  TM_AGENT_ID         Set your agent identifier
  TM_DB_PATH          Custom database location

Examples:
  tm add "Build feature"
  tm join task_123
  tm share task_123 "Database schema complete"
  tm note task_123 "Consider using Redis for cache"
  tm discover task_123 "Security issue in auth flow"
  tm context task_123
""")
        sys.exit(0)
    
    main()