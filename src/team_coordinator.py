#!/usr/bin/env python3
"""
Team coordination through shared context and broadcasts.

@implements FR5.2: Coordination via shared context
@implements FR5.3: Private notes for agent state
@implements FR5.4: Broadcast for team events
"""
from pathlib import Path
from typing import Dict, List, Optional
from datetime import datetime
import json

from event_broadcaster import EventBroadcaster, EventType, EventPriority
from context_generator import ContextGenerator

class TeamCoordinator:
    """
    Coordinate team activities through shared context and events.
    """
    
    def __init__(self):
        self.context_dir = Path(".task-orchestrator/context")
        self.notes_dir = Path(".task-orchestrator/agents/notes")
        self.broadcaster = EventBroadcaster()
        self.context_generator = ContextGenerator()
        
        # Ensure directories exist
        self.context_dir.mkdir(parents=True, exist_ok=True)
        self.notes_dir.mkdir(parents=True, exist_ok=True)
    
    def coordinate_through_context(self, coordination_data: Dict):
        """
        Enable team coordination via shared context (FR5.2)
        """
        context_file = self.context_dir / "team-coordination.md"
        
        content = []
        content.append("# Team Coordination")
        content.append(f"\n*Last Updated: {datetime.now().isoformat()}*\n")
        
        # Active handoffs
        content.append("## Active Handoffs")
        if "handoffs" in coordination_data:
            for handoff in coordination_data["handoffs"]:
                content.append(f"- **From**: {handoff['from']}")
                content.append(f"  **To**: {handoff['to']}")
                content.append(f"  **Task**: {handoff['task']}")
                content.append(f"  **Status**: {handoff['status']}")
                content.append("")
        
        # Team sync points
        content.append("## Sync Points")
        if "sync_points" in coordination_data:
            for sync in coordination_data["sync_points"]:
                content.append(f"- **{sync['name']}**")
                content.append(f"  - Teams: {', '.join(sync['teams'])}")
                content.append(f"  - Next: {sync['next_sync']}")
                content.append("")
        
        # Coordination messages
        content.append("## Coordination Messages")
        if "messages" in coordination_data:
            for msg in coordination_data["messages"]:
                content.append(f"- [{msg['timestamp']}] **{msg['from']}**: {msg['message']}")
        
        # Write to file
        context_file.write_text('\n'.join(content))
        
        return context_file
    
    def preserve_agent_state(self, agent_id: str, state: Dict):
        """
        Preserve agent state in private notes (FR5.3)
        """
        notes_file = self.notes_dir / f"{agent_id}-notes.md"
        
        # Read existing notes
        existing = ""
        if notes_file.exists():
            existing = notes_file.read_text()
        
        # Append state information
        state_content = []
        state_content.append(f"\n## State Checkpoint - {datetime.now().isoformat()}")
        state_content.append(f"### Current Task")
        state_content.append(f"- Task ID: {state.get('current_task', 'None')}")
        state_content.append(f"- Status: {state.get('status', 'Unknown')}")
        state_content.append(f"- Progress: {state.get('progress', '0%')}")
        
        state_content.append(f"\n### Working Memory")
        for key, value in state.get('memory', {}).items():
            state_content.append(f"- {key}: {value}")
        
        state_content.append(f"\n### Next Actions")
        for action in state.get('next_actions', []):
            state_content.append(f"- {action}")
        
        # Write updated notes
        notes_file.write_text(existing + '\n'.join(state_content))
        
        return notes_file
    
    def broadcast_team_event(self, event_name: str, teams: List[str], details: Dict):
        """
        Broadcast events for team coordination (FR5.4)
        """
        self.broadcaster.broadcast(
            event_type=EventType.TEAM_EVENT,
            message=f"Team coordination event: {event_name}",
            details={
                "event": event_name,
                "teams": teams,
                "timestamp": datetime.now().isoformat(),
                **details
            },
            priority=EventPriority.MEDIUM,
            recipients=teams
        )
    
    def handoff_task(self, task_id: str, from_agent: str, to_agent: str, context: Dict):
        """
        Coordinate task handoff between agents
        """
        # Update coordination context
        coordination_data = {
            "handoffs": [{
                "from": from_agent,
                "to": to_agent,
                "task": task_id,
                "status": "in_progress",
                "context": context
            }]
        }
        self.coordinate_through_context(coordination_data)
        
        # Preserve source agent state
        self.preserve_agent_state(from_agent, {
            "current_task": f"Handed off {task_id}",
            "status": "handoff_complete",
            "memory": {"last_handoff": task_id}
        })
        
        # Preserve target agent state
        self.preserve_agent_state(to_agent, {
            "current_task": task_id,
            "status": "handoff_received",
            "memory": context,
            "next_actions": ["Review handoff context", "Begin task execution"]
        })
        
        # Broadcast handoff event
        self.broadcast_team_event(
            "task_handoff",
            [from_agent, to_agent],
            {
                "task_id": task_id,
                "handoff_context": context
            }
        )
        
        return True

# Example usage
if __name__ == "__main__":
    coordinator = TeamCoordinator()
    
    # Test coordination through context
    coord_data = {
        "handoffs": [{
            "from": "database-specialist",
            "to": "backend-specialist",
            "task": "task_001",
            "status": "pending"
        }],
        "sync_points": [{
            "name": "API Review",
            "teams": ["backend-specialist", "frontend-specialist"],
            "next_sync": "2025-08-22T10:00:00"
        }],
        "messages": [{
            "timestamp": datetime.now().isoformat(),
            "from": "orchestrator",
            "message": "Phase 1 complete, beginning Phase 2"
        }]
    }
    
    context_file = coordinator.coordinate_through_context(coord_data)
    print(f"Coordination context saved to: {context_file}")
    
    # Test agent state preservation
    agent_state = {
        "current_task": "task_002",
        "status": "in_progress",
        "progress": "60%",
        "memory": {
            "api_design": "REST",
            "auth_method": "JWT"
        },
        "next_actions": [
            "Complete endpoint implementation",
            "Write unit tests"
        ]
    }
    
    notes_file = coordinator.preserve_agent_state("backend-specialist", agent_state)
    print(f"Agent state saved to: {notes_file}")
    
    # Test task handoff
    coordinator.handoff_task(
        task_id="task_003",
        from_agent="backend-specialist",
        to_agent="frontend-specialist",
        context={
            "api_endpoints": ["/login", "/logout", "/refresh"],
            "auth_token": "JWT",
            "cors_enabled": True
        }
    )
    print("Task handoff completed")