#!/usr/bin/env python3
"""
ORCHESTRATOR.md Discovery Protocol Implementation
Manages the creation and updating of ORCHESTRATOR.md for AI agent discovery
@implements FR-050: AI Agent Discovery Protocol
"""

import os
import re
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional, Any

class OrchestratorDiscovery:
    """
    Manages ORCHESTRATOR.md creation and updates for AI agent discovery
    @implements FR-050: AI Agent Discovery Protocol
    """
    
    def __init__(self, task_manager=None):
        """Initialize with optional task manager for live updates"""
        self.task_manager = task_manager
        self.template_path = Path(__file__).parent.parent / "templates" / "ORCHESTRATOR.md.template"
        self.orchestrator_file = Path.cwd() / "ORCHESTRATOR.md"
        self.readme_file = Path.cwd() / "README.md"
        
    def create_orchestrator_md(self) -> bool:
        """
        Create ORCHESTRATOR.md from template
        @implements FR-050: Auto-generate discovery file
        """
        try:
            # Load template
            if self.template_path.exists():
                template = self.template_path.read_text()
            else:
                # Fallback to embedded template
                template = self._get_embedded_template()
            
            # Replace timestamp
            content = template.replace("{timestamp}", datetime.now().isoformat())
            
            # Update with current task state if task_manager available
            if self.task_manager:
                content = self._update_task_status(content)
            
            # Write file
            self.orchestrator_file.write_text(content)
            print(f"✅ Created ORCHESTRATOR.md for AI agent discovery")
            return True
            
        except Exception as e:
            print(f"⚠️ Could not create ORCHESTRATOR.md: {e}")
            return False
    
    def update_orchestrator_md(self) -> bool:
        """
        LEAN: No updates needed - agents get fresh data from database
        @implements FR-050: Keep discovery file current
        """
        # LEAN principle: Eliminate waste
        # The file is for DISCOVERY only - agents use ./tm list for current status
        # This eliminates 100% of file contention at any scale
        if not self.orchestrator_file.exists():
            return self.create_orchestrator_md()
        return True  # File exists, nothing to update
    
    def add_readme_section(self) -> bool:
        """
        Add AI coordination section to README.md if not present
        @implements FR-050: Multiple discovery points
        """
        if not self.readme_file.exists():
            print("ℹ️ No README.md found to update")
            return False
        
        try:
            content = self.readme_file.read_text()
            
            # Check if section already exists
            if "AI Development Notice" in content or "AI Agent Coordination" in content:
                print("ℹ️ README.md already has AI coordination section")
                return True
            
            # Find appropriate insertion point
            ai_section = self._generate_readme_section()
            
            # Try to insert after first heading
            if "## " in content:
                # Insert after first section
                parts = content.split("## ", 2)
                if len(parts) >= 2:
                    content = parts[0] + "## " + parts[1] + "\n" + ai_section + "\n## " + "## ".join(parts[2:]) if len(parts) > 2 else parts[0] + "## " + parts[1] + "\n" + ai_section
            else:
                # Append to end
                content = content + "\n" + ai_section
            
            self.readme_file.write_text(content)
            print("✅ Added AI coordination section to README.md")
            return True
            
        except Exception as e:
            print(f"⚠️ Could not update README.md: {e}")
            return False
    
    def _update_task_status(self, content: str) -> str:
        """Update task status section with current data"""
        if not self.task_manager:
            return content
        
        try:
            # Get current tasks
            tasks = self.task_manager.list()
            
            if not tasks:
                status_text = "_No tasks created yet. Run `./tm add \"Your first task\"` to begin._"
            else:
                # Group tasks by status
                status_lines = []
                in_progress = [t for t in tasks if t['status'] == 'in_progress']
                blocked = [t for t in tasks if t['status'] == 'blocked']
                pending = [t for t in tasks if t['status'] == 'pending']
                completed_recent = [t for t in tasks if t['status'] == 'completed'][:3]  # Last 3
                
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
    
    def _generate_readme_section(self) -> str:
        """Generate README section for AI coordination"""
        return """## 🤖 AI Agent Coordination

This project uses **Task Orchestrator** for multi-agent coordination.

- **Current Tasks**: See [ORCHESTRATOR.md](./ORCHESTRATOR.md) for live task status
- **Coordination**: All task management should use the `./tm` command
- **For AI Agents**: Check ORCHESTRATOR.md for detailed instructions and patterns

```bash
# Quick start for AI agents
./tm list                    # See all tasks
./tm add "Task" --assignee agent_name  # Create a task
./tm watch                   # Monitor real-time updates
```
"""
    
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

def setup_discovery(task_manager=None) -> bool:
    """
    Main entry point for setting up AI agent discovery
    @implements FR-050: Discovery protocol setup
    """
    discovery = OrchestratorDiscovery(task_manager)
    
    # Create or update ORCHESTRATOR.md
    success = discovery.create_orchestrator_md()
    
    # Optionally update README
    if success:
        # Ask user permission for README update
        if Path("README.md").exists():
            print("\n📝 Would you like to add an AI coordination section to README.md?")
            print("   This helps AI agents discover Task Orchestrator more easily.")
            response = input("   Add section? (y/n): ").lower().strip()
            if response == 'y':
                discovery.add_readme_section()
    
    return success