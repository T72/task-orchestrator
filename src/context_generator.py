#!/usr/bin/env python3
"""
Auto-generate shared context from task metadata.

@implements FR-CORE-3: Auto-generate shared context
@implements FR-046: Context Enhancement with automatic updates
"""
import json
from pathlib import Path
from typing import Dict, List, Optional
from datetime import datetime

class ContextGenerator:
    """
    Automatically generate and maintain shared context.
    Updates on task state changes and specialist assignments.
    """
    
    def __init__(self, context_dir: Path = None):
        self.context_dir = context_dir or Path(".task-orchestrator/context")
        self.context_dir.mkdir(parents=True, exist_ok=True)
        self.shared_context_file = self.context_dir / "shared-context.md"
    
    def generate_from_tasks(self, tasks: List[Dict]) -> str:
        """
        Generate shared context from task list.
        
        Args:
            tasks: List of task dictionaries with metadata
        
        Returns:
            Generated markdown context
        """
        content = []
        content.append("# Task Orchestrator - Shared Context")
        content.append(f"\n*Last Updated: {datetime.now().isoformat()}*\n")
        
        # Summary statistics
        total_tasks = len(tasks)
        completed = sum(1 for t in tasks if t.get("status") == "completed")
        in_progress = sum(1 for t in tasks if t.get("status") == "in_progress")
        blocked = sum(1 for t in tasks if t.get("status") == "blocked")
        
        content.append("## Summary")
        content.append(f"- Total Tasks: {total_tasks}")
        content.append(f"- Completed: {completed} ({completed/total_tasks*100:.1f}%)")
        content.append(f"- In Progress: {in_progress}")
        content.append(f"- Blocked: {blocked}")
        content.append("")
        
        # Group by specialist
        specialists = {}
        for task in tasks:
            specialist = task.get("metadata", {}).get("specialist", "unassigned")
            if specialist not in specialists:
                specialists[specialist] = []
            specialists[specialist].append(task)
        
        content.append("## Specialist Assignments")
        for specialist, specialist_tasks in sorted(specialists.items()):
            content.append(f"\n### {specialist}")
            content.append(f"*{len(specialist_tasks)} tasks assigned*\n")
            
            for task in specialist_tasks:
                task_id = task.get("id", "unknown")
                title = task.get("content", task.get("title", "Untitled"))
                status = task.get("status", "pending")
                phase = task.get("metadata", {}).get("phase", "N/A")
                
                status_icon = {
                    "completed": "✅",
                    "in_progress": "🔄",
                    "blocked": "🚫",
                    "pending": "⏳"
                }.get(status, "❓")
                
                content.append(f"- {status_icon} **[{task_id}]** {title}")
                content.append(f"  - Phase: {phase} | Status: {status}")
                
                # Add dependencies if present
                deps = task.get("metadata", {}).get("depends_on", [])
                if deps:
                    content.append(f"  - Dependencies: {', '.join(deps)}")
                
                # Preserve all metadata
                metadata = task.get("metadata", {})
                if metadata.get("source"):
                    content.append(f"  - Source: {metadata['source']}")
                if metadata.get("format"):
                    content.append(f"  - Format: {metadata['format']}")
                if metadata.get("estimated_hours"):
                    content.append(f"  - Estimated: {metadata['estimated_hours']} hours")
                
                # Add blocking info if blocked
                if status == "blocked":
                    blocker = task.get("metadata", {}).get("blocker", "Unknown")
                    content.append(f"  - **Blocked by**: {blocker}")
        
        # Active phase information
        phases = {}
        for task in tasks:
            phase = task.get("metadata", {}).get("phase", 0)
            if phase not in phases:
                phases[phase] = {"total": 0, "completed": 0}
            phases[phase]["total"] += 1
            if task.get("status") == "completed":
                phases[phase]["completed"] += 1
        
        content.append("\n## Phase Progress")
        for phase_num in sorted(phases.keys()):
            if phase_num > 0:
                phase_data = phases[phase_num]
                progress = phase_data["completed"] / phase_data["total"] * 100
                bar_length = 20
                filled = int(bar_length * progress / 100)
                bar = "█" * filled + "░" * (bar_length - filled)
                
                content.append(f"\n**Phase {phase_num}**: {bar} {progress:.0f}%")
                content.append(f"({phase_data['completed']}/{phase_data['total']} tasks)")
        
        # Critical path if available
        content.append("\n## Critical Path")
        
        # Calculate and include critical path
        try:
            from dependency_graph import DependencyGraph
            
            # Build dependency graph from tasks
            graph = DependencyGraph()
            for task in tasks:
                task_id = task.get("id", "")
                estimated_hours = task.get("estimated_hours", 1.0)
                graph.add_node(task_id, weight=estimated_hours)
            
            # Add edges based on dependencies
            for task in tasks:
                task_id = task.get("id", "")
                deps = task.get("metadata", {}).get("depends_on", [])
                for dep_id in deps:
                    graph.add_edge(task_id, dep_id)
            
            # Find critical path
            critical_path, total_hours = graph.find_critical_path()
            
            if critical_path:
                content.append(f"\n**Critical Path Duration**: {total_hours:.1f} hours")
                content.append("**Path**:")
                for i, node_id in enumerate(critical_path, 1):
                    task_info = next((t for t in tasks if t.get("id") == node_id), {})
                    task_content = task_info.get("content", task_info.get("title", "Unknown"))
                    content.append(f"{i}. [{node_id}] {task_content}")
            else:
                content.append("*No critical path found (no dependencies or cycles detected)*")
                
        except Exception as e:
            content.append(f"*Critical path calculation unavailable: {str(e)}*")
        
        content.append("\n*Use `tm critical-path` for detailed visualization*")
        
        # Recent updates
        content.append("\n## Recent Updates")
        content.append("*Last 5 state changes:*\n")
        # In production, would track actual state changes
        content.append("- Task state changes will be logged here")
        
        return "\n".join(content)
    
    def update_context(self, tasks: List[Dict]) -> None:
        """
        Update the shared context file.
        
        Args:
            tasks: Current task list
        """
        context = self.generate_from_tasks(tasks)
        self.shared_context_file.write_text(context)
    
    def append_event(self, event_type: str, details: Dict) -> None:
        """
        Append an event to the context.
        
        Args:
            event_type: Type of event (task_completed, task_blocked, etc.)
            details: Event details
        """
        if not self.shared_context_file.exists():
            self.update_context([])
        
        current_content = self.shared_context_file.read_text()
        
        # Add event to recent updates section
        event_line = f"\n- [{datetime.now().strftime('%H:%M')}] {event_type}: {json.dumps(details)}"
        
        # Find and update recent updates section
        if "## Recent Updates" in current_content:
            parts = current_content.split("## Recent Updates")
            updated = parts[0] + "## Recent Updates" + event_line + parts[1]
            self.shared_context_file.write_text(updated)
    
    def get_specialist_context(self, specialist: str) -> str:
        """
        Get context specific to a specialist.
        
        Args:
            specialist: Specialist name
        
        Returns:
            Relevant context for the specialist
        """
        if not self.shared_context_file.exists():
            return ""
        
        content = self.shared_context_file.read_text()
        lines = content.split('\n')
        
        specialist_context = []
        in_specialist_section = False
        
        for line in lines:
            if f"### {specialist}" in line:
                in_specialist_section = True
                specialist_context.append(line)
            elif in_specialist_section:
                if line.startswith("###"):
                    break
                specialist_context.append(line)
        
        return "\n".join(specialist_context)

# Example usage
if __name__ == "__main__":
    # Sample tasks
    sample_tasks = [
        {
            "id": "task_001",
            "content": "Design database schema",
            "status": "completed",
            "metadata": {
                "specialist": "database-specialist",
                "phase": 1,
                "depends_on": []
            }
        },
        {
            "id": "task_002",
            "content": "Implement API endpoints",
            "status": "in_progress",
            "metadata": {
                "specialist": "backend-specialist",
                "phase": 2,
                "depends_on": ["task_001"]
            }
        },
        {
            "id": "task_003",
            "content": "Create UI components",
            "status": "blocked",
            "metadata": {
                "specialist": "frontend-specialist",
                "phase": 3,
                "depends_on": ["task_002"],
                "blocker": "API not ready"
            }
        }
    ]
    
    # Generate context
    generator = ContextGenerator()
    context = generator.generate_from_tasks(sample_tasks)
    print(context)
    
    # Save to file
    generator.update_context(sample_tasks)