#!/usr/bin/env python3
"""
Task Manager Collaboration Module
Adds multi-agent collaboration commands: share, note, discover, sync, context, join
"""

import os
import json
import time
import hashlib
from pathlib import Path
from datetime import datetime
from typing import Optional, List, Dict, Any

class CollaborationManager:
    """Manages multi-agent collaboration features"""
    
    def __init__(self, repo_root: Path):
        self.repo_root = repo_root
        self.db_dir = repo_root / ".task-orchestrator"
        self.contexts_dir = self.db_dir / "contexts"
        self.notes_dir = self.db_dir / "notes"
        self.archives_dir = self.db_dir / "archives"
        
        # Create directories if they don't exist
        self.contexts_dir.mkdir(parents=True, exist_ok=True)
        self.notes_dir.mkdir(parents=True, exist_ok=True)
        self.archives_dir.mkdir(parents=True, exist_ok=True)
        
        # Get agent ID from environment or generate
        self.agent_id = os.environ.get('TM_AGENT_ID', self._generate_agent_id())
    
    def _generate_agent_id(self) -> str:
        """Generate a unique agent ID"""
        unique_str = f"{os.getpid()}:{os.environ.get('USER', 'agent')}:{time.time()}"
        return hashlib.md5(unique_str.encode()).hexdigest()[:8]
    
    def _get_context_file(self, task_id: str) -> Path:
        """Get context file path for a task and agent"""
        return self.contexts_dir / f"context_{task_id}_{self.agent_id}.md"
    
    def _get_notes_file(self, task_id: str) -> Path:
        """Get notes file path for a task and agent"""
        return self.notes_dir / f"notes_{task_id}_{self.agent_id}.md"
    
    def _get_shared_context_file(self, task_id: str) -> Path:
        """Get shared context file that all agents can read"""
        return self.contexts_dir / f"shared_{task_id}.md"
    
    def join(self, task_id: str) -> bool:
        """
        Join a task's collaboration context
        Creates context file for this agent
        """
        context_file = self._get_context_file(task_id)
        
        # Create initial context entry
        timestamp = datetime.utcnow().isoformat()
        entry = f"# Task Context: {task_id}\n"
        entry += f"Agent: {self.agent_id}\n"
        entry += f"Joined: {timestamp}\n"
        entry += f"\n---\n\n"
        
        with open(context_file, 'w') as f:
            f.write(entry)
        
        # Add to shared context
        self._append_to_shared(task_id, f"[{timestamp}] Agent {self.agent_id} joined task")
        
        print(f"Joined task {task_id} collaboration")
        return True
    
    def share(self, task_id: str, message: str) -> bool:
        """
        Share an update with all agents working on this task
        Visible to all agents
        """
        timestamp = datetime.utcnow().isoformat()
        
        # Add to agent's context
        context_file = self._get_context_file(task_id)
        entry = f"\n### Update [{timestamp}]\n"
        entry += f"**Type**: Shared Update\n"
        entry += f"**Message**: {message}\n\n"
        
        with open(context_file, 'a') as f:
            f.write(entry)
        
        # Add to shared context for all agents
        self._append_to_shared(task_id, f"[{timestamp}] {self.agent_id}: {message}")
        
        print(f"Shared update for task {task_id}")
        return True
    
    def note(self, task_id: str, message: str) -> bool:
        """
        Add a private note for this agent only
        Not visible to other agents
        """
        timestamp = datetime.utcnow().isoformat()
        notes_file = self._get_notes_file(task_id)
        
        # Create or append to notes file
        entry = f"\n### Note [{timestamp}]\n"
        entry += f"{message}\n\n"
        
        with open(notes_file, 'a') as f:
            f.write(entry)
        
        print(f"Added private note for task {task_id}")
        return True
    
    def discover(self, task_id: str, message: str) -> bool:
        """
        Share a critical discovery or finding
        High priority notification to all agents
        """
        timestamp = datetime.utcnow().isoformat()
        
        # Add to agent's context with discovery flag
        context_file = self._get_context_file(task_id)
        entry = f"\n### 🔍 DISCOVERY [{timestamp}]\n"
        entry += f"**Type**: Critical Discovery\n"
        entry += f"**Message**: {message}\n\n"
        
        with open(context_file, 'a') as f:
            f.write(entry)
        
        # Add to shared context with priority
        self._append_to_shared(
            task_id, 
            f"🔍 DISCOVERY [{timestamp}] {self.agent_id}: {message}",
            priority=True
        )
        
        print(f"Shared discovery for task {task_id}")
        return True
    
    def sync(self, task_id: str, message: str) -> bool:
        """
        Create a synchronization point for all agents
        Used for milestones and checkpoints
        """
        timestamp = datetime.utcnow().isoformat()
        
        # Add sync point to shared context
        entry = f"\n{'='*60}\n"
        entry += f"🔄 SYNC POINT [{timestamp}]\n"
        entry += f"Agent: {self.agent_id}\n"
        entry += f"Message: {message}\n"
        entry += f"{'='*60}\n\n"
        
        shared_file = self._get_shared_context_file(task_id)
        with open(shared_file, 'a') as f:
            f.write(entry)
        
        print(f"Created sync point for task {task_id}")
        return True
    
    def context(self, task_id: str) -> str:
        """
        View all shared context for a task
        Shows all agents' shared updates and discoveries
        """
        shared_file = self._get_shared_context_file(task_id)
        
        if not shared_file.exists():
            return f"No shared context for task {task_id}"
        
        with open(shared_file, 'r') as f:
            content = f.read()
        
        # Also show agent's own context
        context_file = self._get_context_file(task_id)
        if context_file.exists():
            content += "\n\n--- Agent's Own Context ---\n"
            with open(context_file, 'r') as f:
                content += f.read()
        
        # Show private notes if they exist
        notes_file = self._get_notes_file(task_id)
        if notes_file.exists():
            content += "\n\n--- Private Notes (Only You) ---\n"
            with open(notes_file, 'r') as f:
                content += f.read()
        
        return content
    
    def _append_to_shared(self, task_id: str, message: str, priority: bool = False):
        """Append a message to the shared context file"""
        shared_file = self._get_shared_context_file(task_id)
        
        # Create file if it doesn't exist
        if not shared_file.exists():
            with open(shared_file, 'w') as f:
                f.write(f"# Shared Context for Task {task_id}\n")
                f.write(f"Created: {datetime.utcnow().isoformat()}\n\n")
                f.write("---\n\n")
        
        # Append message
        with open(shared_file, 'a') as f:
            if priority:
                f.write(f"\n**{message}**\n")
            else:
                f.write(f"\n{message}\n")
    
    def archive_completed(self, task_id: str):
        """Archive all collaboration files for a completed task"""
        timestamp = datetime.utcnow().strftime("%Y%m%d_%H%M%S")
        archive_name = f"archive_{timestamp}_{task_id}"
        archive_path = self.archives_dir / archive_name
        
        # Create archive directory
        archive_path.mkdir(exist_ok=True)
        
        # Move all related files
        patterns = [
            f"context_{task_id}_*.md",
            f"notes_{task_id}_*.md",
            f"shared_{task_id}.md"
        ]
        
        moved = 0
        for pattern in patterns:
            for file in self.contexts_dir.glob(pattern):
                file.rename(archive_path / file.name)
                moved += 1
            for file in self.notes_dir.glob(pattern):
                file.rename(archive_path / file.name)
                moved += 1
        
        if moved > 0:
            print(f"Archived {moved} collaboration files for task {task_id}")
    
    def cleanup_old_archives(self, days: int = 30):
        """Remove archives older than specified days"""
        cutoff = time.time() - (days * 24 * 60 * 60)
        
        for archive_dir in self.archives_dir.iterdir():
            if archive_dir.is_dir():
                mtime = archive_dir.stat().st_mtime
                if mtime < cutoff:
                    # Remove old archive
                    for file in archive_dir.iterdir():
                        file.unlink()
                    archive_dir.rmdir()
                    print(f"Removed old archive: {archive_dir.name}")


def add_collaboration_commands(task_manager_instance):
    """
    Add collaboration commands to existing task manager
    This function should be called from the main tm script
    """
    collab = CollaborationManager(task_manager_instance.repo_root)
    
    # Add methods to task manager instance
    task_manager_instance.join = collab.join
    task_manager_instance.share = collab.share
    task_manager_instance.note = collab.note
    task_manager_instance.discover = collab.discover
    task_manager_instance.sync = collab.sync
    task_manager_instance.context = collab.context
    task_manager_instance.archive_collaboration = collab.archive_completed
    task_manager_instance.cleanup_archives = collab.cleanup_old_archives
    
    return task_manager_instance


# Standalone usage for testing
if __name__ == "__main__":
    import sys
    from pathlib import Path
    
    # Test the collaboration manager
    repo_root = Path.cwd()
    collab = CollaborationManager(repo_root)
    
    if len(sys.argv) < 3:
        print("Usage: tm_collaboration.py <command> <task_id> [message]")
        print("Commands: join, share, note, discover, sync, context")
        sys.exit(1)
    
    command = sys.argv[1]
    task_id = sys.argv[2]
    message = sys.argv[3] if len(sys.argv) > 3 else ""
    
    if command == "join":
        collab.join(task_id)
    elif command == "share":
        collab.share(task_id, message)
    elif command == "note":
        collab.note(task_id, message)
    elif command == "discover":
        collab.discover(task_id, message)
    elif command == "sync":
        collab.sync(task_id, message)
    elif command == "context":
        print(collab.context(task_id))
    else:
        print(f"Unknown command: {command}")