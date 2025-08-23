#!/usr/bin/env python3
"""
Event broadcasting system for team coordination.

@implements FR-CORE-3: Event broadcasting for task completion and team coordination
"""
import json
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional
from enum import Enum

class EventPriority(Enum):
    """Event priority levels"""
    CRITICAL = "critical"  # Immediate attention required
    HIGH = "high"          # Important, needs quick response
    MEDIUM = "medium"      # Normal priority
    LOW = "low"            # Informational only

class EventType(Enum):
    """Standard event types"""
    TASK_COMPLETED = "task_completed"
    TASK_BLOCKED = "task_blocked"
    TASK_FAILED = "task_failed"
    TASK_RETRY = "task_retry"  # FR4.2
    HELP_REQUESTED = "help_requested"  # FR4.3
    COMPLEXITY_ALERT = "complexity_alert"  # FR4.4
    PHASE_COMPLETED = "phase_completed"
    DEPENDENCY_RESOLVED = "dependency_resolved"
    SPECIALIST_ASSIGNED = "specialist_assigned"
    CRITICAL_PATH_CHANGED = "critical_path_changed"
    TEAM_EVENT = "team_event"  # FR5.4

class EventBroadcaster:
    """
    Broadcast events to team members through notifications.
    """
    
    def __init__(self, broadcast_dir: Path = None):
        self.broadcast_dir = broadcast_dir or Path(".task-orchestrator/notifications")
        self.broadcast_dir.mkdir(parents=True, exist_ok=True)
        self.broadcast_file = self.broadcast_dir / "broadcast.md"
        self.event_log = self.broadcast_dir / "event_log.json"
        
        # Initialize broadcast file if needed
        if not self.broadcast_file.exists():
            self.broadcast_file.write_text("# Task Orchestrator - Event Broadcast\n\n")
    
    def broadcast(
        self,
        event_type: EventType,
        message: str,
        details: Dict,
        priority: EventPriority = EventPriority.MEDIUM,
        recipients: Optional[List[str]] = None
    ) -> None:
        """
        Broadcast an event to team members.
        
        Args:
            event_type: Type of event
            message: Human-readable message
            details: Event details dictionary
            priority: Event priority level
            recipients: List of specific recipients (None = broadcast to all)
        """
        timestamp = datetime.now()
        
        # Create event record
        event = {
            "id": f"evt_{timestamp.strftime('%Y%m%d_%H%M%S')}",
            "timestamp": timestamp.isoformat(),
            "type": event_type.value,
            "priority": priority.value,
            "message": message,
            "details": details,
            "recipients": recipients or ["all"]
        }
        
        # Append to event log
        self._log_event(event)
        
        # Format and append to broadcast file
        self._append_to_broadcast(event)
        
        # Handle priority-based actions
        if priority == EventPriority.CRITICAL:
            self._handle_critical_event(event)
    
    def _log_event(self, event: Dict) -> None:
        """Log event to JSON file for processing"""
        events = []
        if self.event_log.exists():
            try:
                events = json.loads(self.event_log.read_text())
            except:
                events = []
        
        events.append(event)
        
        # Keep only last 100 events
        if len(events) > 100:
            events = events[-100:]
        
        self.event_log.write_text(json.dumps(events, indent=2))
    
    def _append_to_broadcast(self, event: Dict) -> None:
        """Append formatted event to broadcast file"""
        priority_icons = {
            "critical": "🚨",
            "high": "⚠️",
            "medium": "📢",
            "low": "ℹ️"
        }
        
        icon = priority_icons.get(event["priority"], "📌")
        
        # Format the broadcast entry
        broadcast_entry = []
        broadcast_entry.append(f"\n## {icon} {event['type'].replace('_', ' ').title()}")
        broadcast_entry.append(f"*{event['timestamp']}*\n")
        broadcast_entry.append(f"**Message**: {event['message']}")
        
        # Add recipients if specific
        if event["recipients"] != ["all"]:
            broadcast_entry.append(f"**To**: {', '.join(event['recipients'])}")
        
        # Add priority if high or critical
        if event["priority"] in ["high", "critical"]:
            broadcast_entry.append(f"**Priority**: {event['priority'].upper()}")
        
        # Add key details
        if event["details"]:
            broadcast_entry.append("\n**Details**:")
            for key, value in event["details"].items():
                if value:  # Only show non-empty values
                    broadcast_entry.append(f"- {key}: {value}")
        
        # Add action required for critical/high priority
        if event["priority"] in ["critical", "high"]:
            action = self._determine_action(event)
            if action:
                broadcast_entry.append(f"\n**Action Required**: {action}")
        
        broadcast_entry.append("\n---")
        
        # Append to file
        with open(self.broadcast_file, 'a') as f:
            f.write('\n'.join(broadcast_entry))
    
    def _handle_critical_event(self, event: Dict) -> None:
        """Special handling for critical events"""
        # Create a critical events file for immediate attention
        critical_file = self.broadcast_dir / "CRITICAL.md"
        
        critical_content = [
            "# ⚠️ CRITICAL EVENTS REQUIRING IMMEDIATE ATTENTION\n",
            f"## {event['message']}",
            f"Time: {event['timestamp']}",
            f"Type: {event['type']}",
            f"Details: {json.dumps(event['details'], indent=2)}",
            "\n---\n"
        ]
        
        if critical_file.exists():
            existing = critical_file.read_text()
            critical_file.write_text('\n'.join(critical_content) + existing)
        else:
            critical_file.write_text('\n'.join(critical_content))
    
    def _determine_action(self, event: Dict) -> Optional[str]:
        """Determine required action based on event type"""
        actions = {
            EventType.TASK_BLOCKED.value: "Resolve blocker or reassign task",
            EventType.TASK_FAILED.value: "Investigate failure and retry or escalate",
            EventType.TASK_RETRY.value: "Monitor retry attempt and prepare fallback",
            EventType.HELP_REQUESTED.value: "Provide assistance or assign specialist",
            EventType.COMPLEXITY_ALERT.value: "Consider task decomposition or specialist assignment",
            EventType.CRITICAL_PATH_CHANGED.value: "Review and adjust priorities",
            EventType.TEAM_EVENT.value: "Coordinate with team members"
        }
        
        return actions.get(event["type"])
    
    def get_recent_events(
        self,
        count: int = 10,
        priority: Optional[EventPriority] = None,
        event_type: Optional[EventType] = None
    ) -> List[Dict]:
        """
        Get recent events with optional filtering.
        
        Args:
            count: Number of events to retrieve
            priority: Filter by priority
            event_type: Filter by event type
        
        Returns:
            List of matching events
        """
        if not self.event_log.exists():
            return []
        
        try:
            events = json.loads(self.event_log.read_text())
        except:
            return []
        
        # Apply filters
        if priority:
            events = [e for e in events if e.get("priority") == priority.value]
        
        if event_type:
            events = [e for e in events if e.get("type") == event_type.value]
        
        # Return most recent
        return events[-count:]

# Example usage
if __name__ == "__main__":
    broadcaster = EventBroadcaster()
    
    # Example: Task completed
    broadcaster.broadcast(
        event_type=EventType.TASK_COMPLETED,
        message="Database schema design completed",
        details={
            "task_id": "task_001",
            "specialist": "database-specialist",
            "duration": "2.5 hours",
            "unblocked_tasks": ["task_002", "task_003"]
        },
        priority=EventPriority.MEDIUM
    )
    
    # Example: Critical blocker
    broadcaster.broadcast(
        event_type=EventType.TASK_BLOCKED,
        message="API development blocked by missing authentication design",
        details={
            "task_id": "task_004",
            "blocker": "Authentication schema not finalized",
            "impact": "3 dependent tasks blocked",
            "specialist": "backend-specialist"
        },
        priority=EventPriority.CRITICAL,
        recipients=["backend-specialist", "security-specialist"]
    )
    
    print("Events broadcast successfully")
    print(f"Check {broadcaster.broadcast_file} for broadcast log")