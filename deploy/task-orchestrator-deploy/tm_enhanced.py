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
    
    # Check if this is a collaboration command
    if len(sys.argv) > 1 and sys.argv[1] in ['join', 'share', 'note', 'discover', 'sync', 'context']:
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
            elif command == 'discover':
                collab.discover(task_id, message)
            elif command == 'sync':
                collab.sync(task_id, message)
    else:
        # Pass through to original tm for other commands
        original_tm = script_dir / "tm"
        if not original_tm.exists():
            print("Error: Original tm script not found")
            sys.exit(1)
        
        # Execute original tm with all arguments
        result = subprocess.run([str(original_tm)] + sys.argv[1:])
        sys.exit(result.returncode)

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