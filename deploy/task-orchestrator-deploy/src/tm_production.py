#!/usr/bin/env python3
"""
Task Orchestrator with Context Sharing - Production Version
Simple interface for multi-agent task coordination with automatic cleanup
"""

import sys
import os
import json
import sqlite3
import argparse
import uuid
import fcntl
import shutil
import tarfile
from datetime import datetime, timedelta
from pathlib import Path
from typing import List, Optional, Dict, Any
import hashlib
import yaml
import time

# Internal constants - not exposed to users
_DEFAULT_RETENTION_DAYS = 30
_AUTO_CLEANUP = True
_COMPRESS_ARCHIVES = True
_MAX_CONTEXT_SIZE_MB = 10

class TaskManager:
    """Simple task manager for multi-agent coordination"""
    
    def __init__(self):
        self.repo_root = self._find_repo_root()
        self.db_dir = self.repo_root / ".task-orchestrator"
        self.db_path = self.db_dir / "tasks.db"
        self.agent_id = os.environ.get('TM_AGENT_ID', self._generate_agent_id())
        self._init_db()
    
    def _find_repo_root(self) -> Path:
        """Find git repository root"""
        try:
            import subprocess
            result = subprocess.run(
                ["git", "rev-parse", "--show-toplevel"],
                capture_output=True, text=True, check=True
            )
            return Path(result.stdout.strip())
        except:
            return Path.cwd()
    
    def _generate_agent_id(self) -> str:
        """Generate unique agent ID"""
        unique = f"{os.getpid()}:{os.environ.get('USER', 'agent')}"
        return hashlib.md5(unique.encode()).hexdigest()[:8]
    
    def _init_db(self):
        """Initialize database if needed with WSL safety"""
        import platform
        import time
        
        # Detect WSL environment
        is_wsl = 'microsoft' in platform.uname().release.lower()
        
        self.db_dir.mkdir(parents=True, exist_ok=True)
        
        # Initialize subdirectories
        (self.db_dir / "contexts").mkdir(exist_ok=True)
        (self.db_dir / "notes").mkdir(exist_ok=True)
        (self.db_dir / "archives").mkdir(exist_ok=True)
        
        # WSL-safe database connection with retries
        max_retries = 3 if is_wsl else 1
        for attempt in range(max_retries):
            try:
                # Add small delay for WSL
                if is_wsl and attempt > 0:
                    time.sleep(0.5)
                
                # Use WAL mode for better concurrency in WSL
                with sqlite3.connect(str(self.db_path), timeout=10.0) as conn:
                    if is_wsl or os.environ.get('TM_WSL_MODE'):
                        # Enable WAL mode for better WSL performance
                        conn.execute("PRAGMA journal_mode=WAL")
                        conn.execute("PRAGMA synchronous=NORMAL")
                        conn.execute("PRAGMA temp_store=MEMORY")
                        conn.execute("PRAGMA mmap_size=30000000000")
                    
                    conn.execute("""
                        CREATE TABLE IF NOT EXISTS tasks (
                            id TEXT PRIMARY KEY,
                            title TEXT NOT NULL,
                            description TEXT,
                            status TEXT DEFAULT 'pending',
                            priority TEXT DEFAULT 'medium',
                            assignee TEXT,
                            created_at TEXT NOT NULL,
                            updated_at TEXT NOT NULL,
                            completed_at TEXT
                        )
                    """)
                    
                    conn.execute("""
                        CREATE TABLE IF NOT EXISTS dependencies (
                            task_id TEXT NOT NULL,
                            depends_on TEXT NOT NULL,
                            PRIMARY KEY (task_id, depends_on)
                        )
                    """)
                    
                    conn.execute("""
                        CREATE TABLE IF NOT EXISTS notifications (
                            id INTEGER PRIMARY KEY AUTOINCREMENT,
                            agent_id TEXT,
                            task_id TEXT,
                            type TEXT NOT NULL,
                            message TEXT NOT NULL,
                            created_at TEXT NOT NULL,
                            read BOOLEAN DEFAULT 0
                        )
                    """)
                    
                    conn.execute("""
                        CREATE TABLE IF NOT EXISTS participants (
                            task_id TEXT NOT NULL,
                            agent_id TEXT NOT NULL,
                            joined_at TEXT NOT NULL,
                            PRIMARY KEY (task_id, agent_id)
                        )
                    """)
                    
                    conn.commit()
                    break  # Success, exit retry loop
                    
            except sqlite3.OperationalError as e:
                if attempt == max_retries - 1:
                    raise  # Re-raise on last attempt
                print(f"Database initialization attempt {attempt + 1} failed, retrying...")
                continue
    
    # ========== SIMPLE PUBLIC INTERFACE ==========
    
    def add(self, title: str, description: str = None, 
            priority: str = "medium", depends_on: List[str] = None) -> str:
        """Add a new task"""
        # Validate title
        if not title or not title.strip():
            raise ValueError("Task title cannot be empty")
        
        task_id = uuid.uuid4().hex[:8]
        now = datetime.now().isoformat()
        
        try:
            with sqlite3.connect(str(self.db_path), timeout=10.0) as conn:
                # Check if dependencies exist
                if depends_on:
                    placeholders = ','.join('?' for _ in depends_on)
                    cursor = conn.execute(f"""
                        SELECT id FROM tasks WHERE id IN ({placeholders})
                    """, depends_on)
                    existing_deps = {row[0] for row in cursor.fetchall()}
                    missing_deps = set(depends_on) - existing_deps
                    if missing_deps:
                        raise ValueError(f"Dependencies not found: {', '.join(missing_deps)}")
                
                # Determine status based on dependencies
                status = "blocked" if depends_on else "pending"
                
                conn.execute("""
                    INSERT INTO tasks (id, title, description, status, priority, created_at, updated_at)
                    VALUES (?, ?, ?, ?, ?, ?, ?)
                """, (task_id, title, description, status, priority, now, now))
                
                # Add dependencies
                if depends_on:
                    for dep_id in depends_on:
                        conn.execute("""
                            INSERT INTO dependencies (task_id, depends_on)
                            VALUES (?, ?)
                        """, (task_id, dep_id))
                
                conn.commit()
        except sqlite3.IntegrityError as e:
            raise ValueError(f"Database integrity error: {e}")
        except Exception as e:
            raise ValueError(f"Failed to add task: {e}")
        
        # Auto-initialize context for collaboration
        self._init_context(task_id, title)
        
        return task_id
    
    def show(self, task_id: str) -> Optional[Dict]:
        """Show details of a specific task"""
        try:
            with sqlite3.connect(str(self.db_path)) as conn:
                conn.row_factory = sqlite3.Row
                cursor = conn.execute("""
                    SELECT t.*, 
                           GROUP_CONCAT(d.depends_on) as dependencies
                    FROM tasks t
                    LEFT JOIN dependencies d ON t.id = d.task_id
                    WHERE t.id = ?
                    GROUP BY t.id
                """, (task_id,))
                
                row = cursor.fetchone()
                if row:
                    task = dict(row)
                    # Convert dependencies string to list
                    if task.get('dependencies'):
                        task['dependencies'] = task['dependencies'].split(',')
                    else:
                        task['dependencies'] = []
                    return task
                return None
        except Exception as e:
            print(f"Error showing task: {e}")
            return None
    
    def update(self, task_id: str, status: str = None, assignee: str = None) -> bool:
        """Update task status or assignment"""
        try:
            # Validate inputs
            if not task_id or not task_id.strip():
                raise ValueError("Task ID cannot be empty")
            
            if status and status not in ['pending', 'in_progress', 'completed', 'blocked']:
                raise ValueError(f"Invalid status: {status}")
            
            now = datetime.now().isoformat()
            updates = ["updated_at = ?"]
            params = [now]
            
            if status:
                updates.append("status = ?")
                params.append(status)
            
            if assignee:
                updates.append("assignee = ?")
                params.append(assignee)
            
            params.append(task_id)
            
            with sqlite3.connect(str(self.db_path), timeout=10.0) as conn:
                cursor = conn.execute(f"""
                    UPDATE tasks 
                    SET {', '.join(updates)}
                    WHERE id = ?
                """, params)
                
                if cursor.rowcount == 0:
                    print(f"Warning: Task {task_id} not found")
                    return False
                
                conn.commit()
            
            return True
        except sqlite3.Error as e:
            print(f"Database error: {e}")
            return False
        except ValueError as e:
            print(f"Validation error: {e}")
            return False
        except Exception as e:
            print(f"Unexpected error: {e}")
            return False
    
    def delete(self, task_id: str) -> bool:
        """Delete a task and clean up dependencies"""
        try:
            with sqlite3.connect(str(self.db_path)) as conn:
                # Check if task exists
                cursor = conn.execute("SELECT id FROM tasks WHERE id = ?", (task_id,))
                if not cursor.fetchone():
                    return False
                
                # Remove task from dependencies
                conn.execute("DELETE FROM dependencies WHERE task_id = ? OR depends_on = ?", 
                           (task_id, task_id))
                
                # Delete the task
                conn.execute("DELETE FROM tasks WHERE id = ?", (task_id,))
                
                # Cleanup associated files
                context_file = self.db_dir / "contexts" / f"{task_id}.json"
                if context_file.exists():
                    context_file.unlink()
                
                note_file = self.db_dir / "notes" / f"{task_id}.txt"
                if note_file.exists():
                    note_file.unlink()
                
                conn.commit()
            return True
        except Exception as e:
            print(f"Error deleting task: {e}")
            return False
    
    def watch(self, limit: int = 10) -> List[Dict]:
        """Check for recent notifications and important events"""
        try:
            with sqlite3.connect(str(self.db_path), timeout=10.0) as conn:
                conn.row_factory = sqlite3.Row
                
                # Get recent unread notifications for this agent
                cursor = conn.execute("""
                    SELECT * FROM notifications 
                    WHERE (agent_id = ? OR agent_id IS NULL)
                    AND read = 0
                    ORDER BY created_at DESC
                    LIMIT ?
                """, (self.agent_id, limit))
                
                notifications = []
                for row in cursor:
                    notifications.append(dict(row))
                
                # Mark notifications as read
                conn.execute("""
                    UPDATE notifications 
                    SET read = 1 
                    WHERE (agent_id = ? OR agent_id IS NULL)
                    AND read = 0
                """, (self.agent_id,))
                
                conn.commit()
                return notifications
                
        except Exception as e:
            print(f"Error checking notifications: {e}")
            return []
    
    def _create_notification(self, conn, task_id: str, type: str, message: str, 
                           agent_id: str = None):
        """Create a notification (internal helper)"""
        now = datetime.now().isoformat()
        conn.execute("""
            INSERT INTO notifications (agent_id, task_id, type, message, created_at)
            VALUES (?, ?, ?, ?, ?)
        """, (agent_id, task_id, type, message, now))
    
    def complete(self, task_id: str) -> bool:
        """Complete a task and trigger auto-cleanup"""
        now = datetime.now().isoformat()
        
        with sqlite3.connect(str(self.db_path)) as conn:
            conn.execute("""
                UPDATE tasks 
                SET status = 'completed', completed_at = ?
                WHERE id = ?
            """, (now, task_id))
            
            # Find tasks that will be unblocked
            cursor = conn.execute("""
                SELECT task_id, assignee FROM tasks t
                JOIN dependencies d ON t.id = d.task_id
                WHERE t.status = 'blocked' 
                AND d.depends_on = ?
                AND NOT EXISTS (
                    SELECT 1 FROM dependencies d2
                    JOIN tasks t2 ON d2.depends_on = t2.id
                    WHERE d2.task_id = d.task_id
                    AND d2.depends_on != ?
                    AND t2.status != 'completed'
                )
            """, (task_id, task_id))
            
            unblocked_tasks = cursor.fetchall()
            
            # Unblock dependent tasks
            conn.execute("""
                UPDATE tasks 
                SET status = 'pending'
                WHERE status = 'blocked' 
                AND id IN (
                    SELECT task_id FROM dependencies 
                    WHERE depends_on = ?
                    AND NOT EXISTS (
                        SELECT 1 FROM dependencies d2
                        JOIN tasks t ON d2.depends_on = t.id
                        WHERE d2.task_id = dependencies.task_id
                        AND d2.depends_on != ?
                        AND t.status != 'completed'
                    )
                )
            """, (task_id, task_id))
            
            # Create notifications for unblocked tasks
            for task_row in unblocked_tasks:
                unblocked_id, assignee = task_row
                self._create_notification(conn, unblocked_id, 'unblocked', 
                                         f'Task {unblocked_id} unblocked - dependencies completed',
                                         assignee)
            
            conn.commit()
        
        # Auto archive and cleanup
        if _AUTO_CLEANUP:
            self._archive_and_cleanup(task_id)
        
        return True
    
    def export(self, format: str = "json") -> str:
        """Export all tasks in specified format"""
        tasks = self.list()
        
        if format == "json":
            return json.dumps(tasks, indent=2)
        elif format == "markdown":
            output = ["# Task Orchestrator Export", ""]
            output.append(f"Generated: {datetime.now().isoformat()}")
            output.append("")
            
            # Group by status
            statuses = {}
            for task in tasks:
                status = task.get('status', 'unknown')
                if status not in statuses:
                    statuses[status] = []
                statuses[status].append(task)
            
            for status, status_tasks in statuses.items():
                output.append(f"## {status.title()} Tasks")
                output.append("")
                for task in status_tasks:
                    output.append(f"- **[{task['id']}]** {task['title']}")
                    if task.get('description'):
                        output.append(f"  - Description: {task['description']}")
                    if task.get('assignee'):
                        output.append(f"  - Assignee: {task['assignee']}")
                    if task.get('priority') and task['priority'] != 'medium':
                        output.append(f"  - Priority: {task['priority']}")
                output.append("")
            
            return "\n".join(output)
        else:
            # Default TSV format
            output = []
            for task in tasks:
                output.append(f"{task['id']}\t{task['title']}\t{task['status']}\t{task.get('assignee', '')}")
            return "\n".join(output)
    
    def list(self, status: str = None, assignee: str = None, has_deps: bool = False) -> List[Dict]:
        """List tasks with optional filters"""
        if has_deps:
            # Query for tasks that have dependencies
            query = """
                SELECT DISTINCT t.* FROM tasks t
                JOIN dependencies d ON t.id = d.task_id
                WHERE 1=1
            """
        else:
            query = "SELECT * FROM tasks WHERE 1=1"
        
        params = []
        
        if status:
            query += " AND status = ?"
            params.append(status)
        
        if assignee:
            query += " AND assignee = ?"
            params.append(assignee)
        
        query += " ORDER BY created_at DESC"
        
        with sqlite3.connect(str(self.db_path)) as conn:
            conn.row_factory = sqlite3.Row
            cursor = conn.execute(query, params)
            return [dict(row) for row in cursor.fetchall()]
    
    def join(self, task_id: str) -> bool:
        """Join a task's collaborative context"""
        now = datetime.now().isoformat()
        
        with sqlite3.connect(str(self.db_path)) as conn:
            conn.execute("""
                INSERT OR REPLACE INTO participants (task_id, agent_id, joined_at)
                VALUES (?, ?, ?)
            """, (task_id, self.agent_id, now))
            conn.commit()
        
        # Ensure context exists
        context_path = self.db_dir / "contexts" / f"{task_id}.yaml"
        if not context_path.exists():
            with sqlite3.connect(str(self.db_path)) as conn:
                cursor = conn.execute("SELECT title FROM tasks WHERE id = ?", (task_id,))
                row = cursor.fetchone()
                if row:
                    self._init_context(task_id, row[0])
        
        return True
    
    def note(self, task_id: str, content: str) -> bool:
        """Add private notes for a task"""
        notes_path = self.db_dir / "notes" / f"{task_id}_{self.agent_id}.md"
        
        # Append with timestamp
        with open(notes_path, 'a') as f:
            if notes_path.stat().st_size > 0:
                f.write(f"\n\n---\n{datetime.now().isoformat()}\n")
            f.write(content)
        
        return True
    
    def share(self, task_id: str, content: str, type: str = "update") -> bool:
        """Share information with other agents on the task"""
        context_path = self.db_dir / "contexts" / f"{task_id}.yaml"
        
        # Ensure we've joined the task
        self.join(task_id)
        
        # Load context
        if context_path.exists():
            with open(context_path, 'r') as f:
                context = yaml.safe_load(f) or {}
        else:
            context = {}
        
        # Add contribution
        if "contributions" not in context:
            context["contributions"] = []
        
        context["contributions"].append({
            "agent": self.agent_id,
            "timestamp": datetime.now().isoformat(),
            "type": type,
            "content": content
        })
        
        # Keep only last 100 contributions to prevent bloat
        if len(context["contributions"]) > 100:
            context["contributions"] = context["contributions"][-100:]
        
        # Save context
        with open(context_path, 'w') as f:
            yaml.dump(context, f, default_flow_style=False)
        
        return True
    
    def sync(self, task_id: str, checkpoint: str) -> bool:
        """Create a synchronization point"""
        return self.share(task_id, checkpoint, type="sync")
    
    def discover(self, task_id: str, finding: str) -> bool:
        """Share an important discovery and notify all agents"""
        # Share the discovery
        result = self.share(task_id, finding, type="discovery")
        
        # Create notification for all agents (agent_id = NULL means broadcast)
        if result:
            try:
                with sqlite3.connect(str(self.db_path), timeout=10.0) as conn:
                    self._create_notification(conn, task_id, 'discovery', 
                                            f'DISCOVERY in {task_id}: {finding}',
                                            None)  # None means broadcast to all
                    conn.commit()
            except Exception as e:
                print(f"Error creating discovery notification: {e}")
        
        return result
    
    def context(self, task_id: str) -> Dict:
        """Get task context (both shared and private)"""
        result = {"task_id": task_id}
        
        # Get shared context
        context_path = self.db_dir / "contexts" / f"{task_id}.yaml"
        if context_path.exists():
            with open(context_path, 'r') as f:
                result["shared"] = yaml.safe_load(f)
        
        # Get private notes
        notes_path = self.db_dir / "notes" / f"{task_id}_{self.agent_id}.md"
        if notes_path.exists():
            with open(notes_path, 'r') as f:
                result["notes"] = f.read()
        
        return result
    
    # ========== INTERNAL METHODS (Hidden from users) ==========
    
    def _init_context(self, task_id: str, title: str):
        """Initialize context for a task"""
        context_path = self.db_dir / "contexts" / f"{task_id}.yaml"
        if not context_path.exists():
            context = {
                "task_id": task_id,
                "title": title,
                "created": datetime.now().isoformat(),
                "contributions": []
            }
            with open(context_path, 'w') as f:
                yaml.dump(context, f, default_flow_style=False)
    
    def _archive_and_cleanup(self, task_id: str):
        """Archive and cleanup completed task files"""
        try:
            # Create archive
            archive_dir = self.db_dir / "archives"
            archive_dir.mkdir(exist_ok=True)
            
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            archive_name = f"task_{task_id}_{timestamp}"
            
            if _COMPRESS_ARCHIVES:
                archive_path = archive_dir / f"{archive_name}.tar.gz"
                with tarfile.open(archive_path, 'w:gz') as tar:
                    # Add context file
                    context_file = self.db_dir / "contexts" / f"{task_id}.yaml"
                    if context_file.exists():
                        tar.add(context_file, arcname=f"{archive_name}/context.yaml")
                        context_file.unlink()
                    
                    # Add all notes files for this task
                    for notes_file in (self.db_dir / "notes").glob(f"{task_id}_*.md"):
                        tar.add(notes_file, arcname=f"{archive_name}/notes/{notes_file.name}")
                        notes_file.unlink()
            
            # Schedule cleanup of old archives
            self._cleanup_old_archives()
            
        except Exception:
            pass  # Silently handle cleanup errors
    
    def _cleanup_old_archives(self):
        """Remove archives older than retention period"""
        try:
            cutoff = datetime.now() - timedelta(days=_DEFAULT_RETENTION_DAYS)
            archive_dir = self.db_dir / "archives"
            
            for archive in archive_dir.glob("*.tar.gz"):
                # Parse timestamp from filename
                parts = archive.stem.split('_')
                if len(parts) >= 3:
                    date_str = parts[-2] + parts[-1]
                    try:
                        file_date = datetime.strptime(date_str, "%Y%m%d%H%M%S")
                        if file_date < cutoff:
                            archive.unlink()
                    except:
                        pass
        except Exception:
            pass


def main():
    """Simple CLI interface"""
    parser = argparse.ArgumentParser(
        description="Task Orchestrator - Simple multi-agent coordination",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  tm add "Build API"                    # Create task
  tm list                               # List all tasks
  tm join abc123                        # Join task collaboration
  tm share abc123 "API design ready"    # Share with team
  tm complete abc123                    # Complete and auto-cleanup
        """
    )
    
    subparsers = parser.add_subparsers(dest="command", help="Commands")
    
    # Add task
    add_parser = subparsers.add_parser("add", help="Add new task")
    add_parser.add_argument("title", help="Task title")
    add_parser.add_argument("-d", "--description", help="Description")
    add_parser.add_argument("-p", "--priority", choices=["low", "medium", "high"], default="medium")
    add_parser.add_argument("--depends-on", nargs="+", help="Task dependencies")
    
    # List tasks
    list_parser = subparsers.add_parser("list", help="List tasks")
    list_parser.add_argument("--status", help="Filter by status")
    list_parser.add_argument("--assignee", help="Filter by assignee")
    
    # Update task
    update_parser = subparsers.add_parser("update", help="Update task")
    update_parser.add_argument("task_id", help="Task ID")
    update_parser.add_argument("--status", choices=["pending", "in_progress", "blocked"])
    update_parser.add_argument("--assignee", help="Assign to agent")
    
    # Complete task
    complete_parser = subparsers.add_parser("complete", help="Complete task")
    complete_parser.add_argument("task_id", help="Task ID")
    
    # Join task
    join_parser = subparsers.add_parser("join", help="Join task collaboration")
    join_parser.add_argument("task_id", help="Task ID")
    
    # Add note
    note_parser = subparsers.add_parser("note", help="Add private note")
    note_parser.add_argument("task_id", help="Task ID")
    note_parser.add_argument("content", help="Note content")
    
    # Share update
    share_parser = subparsers.add_parser("share", help="Share with team")
    share_parser.add_argument("task_id", help="Task ID")
    share_parser.add_argument("content", help="Content to share")
    
    # Sync point
    sync_parser = subparsers.add_parser("sync", help="Create sync point")
    sync_parser.add_argument("task_id", help="Task ID")
    sync_parser.add_argument("checkpoint", help="Checkpoint description")
    
    # Discovery
    discover_parser = subparsers.add_parser("discover", help="Share discovery")
    discover_parser.add_argument("task_id", help="Task ID")
    discover_parser.add_argument("finding", help="Discovery description")
    
    # View context
    context_parser = subparsers.add_parser("context", help="View task context")
    context_parser.add_argument("task_id", help="Task ID")
    
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        return
    
    tm = TaskManager()
    
    if args.command == "add":
        task_id = tm.add(args.title, args.description, args.priority, args.depends_on)
        print(f"Created task: {task_id}")
    
    elif args.command == "list":
        tasks = tm.list(args.status, args.assignee)
        for task in tasks:
            status_icon = "✓" if task["status"] == "completed" else "○"
            print(f"{status_icon} {task['id']}: {task['title']} [{task['status']}]")
    
    elif args.command == "update":
        tm.update(args.task_id, args.status, args.assignee)
        print(f"Updated task: {args.task_id}")
    
    elif args.command == "complete":
        tm.complete(args.task_id)
        print(f"Completed task: {args.task_id}")
    
    elif args.command == "join":
        tm.join(args.task_id)
        print(f"Joined task: {args.task_id}")
    
    elif args.command == "note":
        tm.note(args.task_id, args.content)
        print("Note added")
    
    elif args.command == "share":
        tm.share(args.task_id, args.content)
        print("Shared with team")
    
    elif args.command == "sync":
        tm.sync(args.task_id, args.checkpoint)
        print(f"Sync point created: {args.checkpoint}")
    
    elif args.command == "discover":
        tm.discover(args.task_id, args.finding)
        print("Discovery shared")
    
    elif args.command == "context":
        context = tm.context(args.task_id)
        print(f"Task: {args.task_id}")
        if "shared" in context:
            print("\nShared Context:")
            contributions = context["shared"].get("contributions", [])
            for contrib in contributions[-5:]:  # Show last 5
                print(f"  [{contrib['type']}] {contrib['agent']}: {contrib['content']}")
        if "notes" in context:
            print("\nYour Notes:")
            print(context["notes"][:500])  # Show first 500 chars


if __name__ == "__main__":
    main()