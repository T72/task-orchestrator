#!/usr/bin/env python3
"""
Concurrent-safe ORCHESTRATOR.md Discovery Protocol Implementation
Handles multiple agents accessing the file simultaneously
@implements FR-050: AI Agent Discovery Protocol (Concurrent-Safe)
"""

import os
import re
import time
import tempfile
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional, Any
import threading
import hashlib

class ConcurrentOrchestratorDiscovery:
    """
    Thread-safe ORCHESTRATOR.md management for multi-agent environments
    @implements FR-050: AI Agent Discovery Protocol
    """
    
    # Class-level lock for file operations
    _file_lock = threading.Lock()
    _last_update_time = 0
    _update_interval = 1.0  # Minimum seconds between updates
    
    def __init__(self, task_manager=None):
        """Initialize with optional task manager for live updates"""
        self.task_manager = task_manager
        self.template_path = Path(__file__).parent.parent / "templates" / "ORCHESTRATOR.md.template"
        self.orchestrator_file = Path.cwd() / "ORCHESTRATOR.md"
        self.readme_file = Path.cwd() / "README.md"
        
    def update_orchestrator_md(self) -> bool:
        """
        Update ORCHESTRATOR.md with concurrency protection
        Uses debouncing and file locking to prevent race conditions
        """
        # Debounce rapid updates
        current_time = time.time()
        if current_time - self._last_update_time < self._update_interval:
            return True  # Skip update, too recent
            
        # Acquire lock for file operations
        with self._file_lock:
            try:
                # Check again inside lock (double-check pattern)
                current_time = time.time()
                if current_time - self._last_update_time < self._update_interval:
                    return True
                    
                # Create if doesn't exist
                if not self.orchestrator_file.exists():
                    return self._create_orchestrator_md_locked()
                
                # Read current content
                content = self.orchestrator_file.read_text()
                original_hash = hashlib.md5(content.encode()).hexdigest()
                
                # Update task status section
                if self.task_manager:
                    content = self._update_task_status(content)
                
                # Update timestamp
                content = re.sub(
                    r'\*Last updated: .*\*',
                    f'*Last updated: {datetime.now().isoformat()}*',
                    content
                )
                
                # Only write if content actually changed
                new_hash = hashlib.md5(content.encode()).hexdigest()
                if new_hash != original_hash:
                    # Atomic write using temp file and rename
                    self._atomic_write(self.orchestrator_file, content)
                
                # Update last update time
                self.__class__._last_update_time = current_time
                return True
                
            except Exception as e:
                print(f"⚠️ Could not update ORCHESTRATOR.md: {e}")
                return False
    
    def _atomic_write(self, target_file: Path, content: str):
        """
        Atomically write content to file using temp file and rename
        This prevents partial writes and corruption
        """
        # Create temp file in same directory (for atomic rename)
        temp_fd, temp_path = tempfile.mkstemp(
            dir=target_file.parent,
            prefix='.tmp_',
            suffix=target_file.suffix
        )
        
        try:
            # Write content to temp file
            with os.fdopen(temp_fd, 'w') as f:
                f.write(content)
            
            # Atomic rename (on POSIX systems)
            # On Windows, this might not be fully atomic but still safer
            Path(temp_path).replace(target_file)
            
        except Exception as e:
            # Clean up temp file on error
            try:
                os.unlink(temp_path)
            except:
                pass
            raise e
    
    def _create_orchestrator_md_locked(self) -> bool:
        """Create ORCHESTRATOR.md from template (already inside lock)"""
        try:
            # Load template
            if self.template_path.exists():
                template = self.template_path.read_text()
            else:
                template = self._get_embedded_template()
            
            # Replace timestamp
            content = template.replace("{timestamp}", datetime.now().isoformat())
            
            # Update with current task state if available
            if self.task_manager:
                content = self._update_task_status(content)
            
            # Atomic write
            self._atomic_write(self.orchestrator_file, content)
            print(f"✅ Created ORCHESTRATOR.md for AI agent discovery")
            return True
            
        except Exception as e:
            print(f"⚠️ Could not create ORCHESTRATOR.md: {e}")
            return False
    
    def _update_task_status(self, content: str) -> str:
        """Update task status section with current data"""
        if not self.task_manager:
            return content
        
        try:
            # Get current tasks (this is already protected by database locks)
            tasks = self.task_manager.list()
            
            if not tasks:
                status_text = "_No tasks created yet. Run `./tm add \"Your first task\"` to begin._"
            else:
                # Group tasks by status (limit items to prevent huge files)
                status_lines = []
                in_progress = [t for t in tasks if t['status'] == 'in_progress'][:10]
                blocked = [t for t in tasks if t['status'] == 'blocked'][:10]
                pending = [t for t in tasks if t['status'] == 'pending'][:10]
                completed_recent = [t for t in tasks if t['status'] == 'completed'][:3]
                
                if in_progress:
                    status_lines.append("### 🔄 In Progress")
                    for task in in_progress:
                        assignee = f" (assignee: {task.get('assignee', 'unassigned')})" if task.get('assignee') else ""
                        status_lines.append(f"- `{task['id']}` {task['title']}{assignee}")
                
                if blocked:
                    status_lines.append("\n### 🚫 Blocked")
                    for task in blocked:
                        assignee = f" (assignee: {task.get('assignee', 'unassigned')})" if task.get('assignee') else ""
                        status_lines.append(f"- `{task['id']}` {task['title']}{assignee}")
                
                if pending:
                    status_lines.append("\n### 📋 Pending")
                    for task in pending[:5]:  # Show max 5
                        assignee = f" (assignee: {task.get('assignee', 'unassigned')})" if task.get('assignee') else ""
                        status_lines.append(f"- `{task['id']}` {task['title']}{assignee}")
                    if len(pending) > 5:
                        status_lines.append(f"- _{len(pending) - 5} more pending tasks..._")
                
                if completed_recent:
                    status_lines.append("\n### ✅ Recently Completed")
                    for task in completed_recent:
                        status_lines.append(f"- `{task['id']}` {task['title']}")
                
                status_text = "\n".join(status_lines)
            
            # Update metrics
            total = len(tasks)
            completed = len([t for t in tasks if t['status'] == 'completed'])
            in_prog = len([t for t in tasks if t['status'] == 'in_progress'])
            blocked_count = len([t for t in tasks if t['status'] == 'blocked'])
            
            # Replace status section
            pattern = r'## 📋 Current Task Status\n<!-- This section auto-updates when tasks change -->\n.*?(?=\n##)'
            replacement = f'## 📋 Current Task Status\n<!-- This section auto-updates when tasks change -->\n{status_text}'
            content = re.sub(pattern, replacement, content, flags=re.DOTALL)
            
            # Update metrics
            content = re.sub(r'- Total Tasks: \d+', f'- Total Tasks: {total}', content)
            content = re.sub(r'- Completed: \d+', f'- Completed: {completed}', content)
            content = re.sub(r'- In Progress: \d+', f'- In Progress: {in_prog}', content)
            content = re.sub(r'- Blocked: \d+', f'- Blocked: {blocked_count}', content)
            
        except Exception as e:
            print(f"Warning: Could not update task status: {e}")
        
        return content
    
    def _get_embedded_template(self) -> str:
        """Fallback template if file not found"""
        return """# 🤖 AI Agent Orchestration Protocol

This project uses **Task Orchestrator** for multi-agent coordination.

## 📋 Current Task Status
<!-- This section auto-updates when tasks change -->
_No tasks created yet. Run `./tm add "Your first task"` to begin._

## 🚀 Quick Start for AI Agents

```bash
# Set your agent identity
export TM_AGENT_ID="your_agent_type"

# See all tasks
./tm list

# Create a task
./tm add "Task description" --assignee agent_name

# Monitor updates
./tm watch
```

## 📚 Documentation

See the [Task Orchestrator documentation](https://github.com/T72/task-orchestrator) for full details.

---
*Task Orchestrator v2.6.1*
*Last updated: {timestamp}*
"""

def setup_concurrent_discovery(task_manager=None) -> bool:
    """
    Set up concurrent-safe AI agent discovery
    @implements FR-050: Discovery protocol setup (thread-safe)
    """
    discovery = ConcurrentOrchestratorDiscovery(task_manager)
    
    # Create or update ORCHESTRATOR.md
    return discovery.update_orchestrator_md()


# Alternative: Event Queue Implementation
class QueuedOrchestratorDiscovery:
    """
    Queue-based ORCHESTRATOR.md updates for maximum scalability
    Single writer thread prevents all race conditions
    """
    
    def __init__(self, task_manager=None):
        import queue
        self.task_manager = task_manager
        self.update_queue = queue.Queue()
        self.worker_thread = None
        self.running = False
        
    def start(self):
        """Start the update worker thread"""
        if not self.running:
            self.running = True
            self.worker_thread = threading.Thread(target=self._update_worker)
            self.worker_thread.daemon = True
            self.worker_thread.start()
    
    def stop(self):
        """Stop the update worker thread"""
        self.running = False
        if self.worker_thread:
            self.worker_thread.join(timeout=2)
    
    def queue_update(self):
        """Queue an update request (non-blocking)"""
        if self.running:
            self.update_queue.put("update")
    
    def _update_worker(self):
        """Worker thread that processes update queue"""
        discovery = ConcurrentOrchestratorDiscovery(self.task_manager)
        
        while self.running:
            try:
                # Wait for update request (with timeout for shutdown)
                self.update_queue.get(timeout=1)
                
                # Clear any duplicate requests
                while not self.update_queue.empty():
                    try:
                        self.update_queue.get_nowait()
                    except:
                        break
                
                # Perform single update for all queued requests
                discovery.update_orchestrator_md()
                
            except:
                continue  # Timeout is normal, continue loop