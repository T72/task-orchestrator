#!/usr/bin/env python3
"""
Helper functions for broadcasting specific notification types.

@implements FR4.2: Retry notifications via broadcast
@implements FR4.3: Help requests in notification file
@implements FR4.4: Complexity alerts broadcast
"""
from event_broadcaster import EventBroadcaster, EventType, EventPriority

def broadcast_retry(task_id: str, attempt: int, reason: str, delay: float):
    """Broadcast a retry notification (FR4.2)"""
    broadcaster = EventBroadcaster()
    
    broadcaster.broadcast(
        event_type=EventType.TASK_RETRY,
        message=f"Task {task_id} retry attempt {attempt}",
        details={
            "task_id": task_id,
            "attempt": attempt,
            "reason": reason,
            "delay_seconds": delay,
            "max_attempts": 3
        },
        priority=EventPriority.MEDIUM
    )

def broadcast_help_request(task_id: str, specialist: str, issue: str, urgency: str = "medium"):
    """Broadcast a help request (FR4.3)"""
    broadcaster = EventBroadcaster()
    
    priority_map = {
        "low": EventPriority.LOW,
        "medium": EventPriority.MEDIUM,
        "high": EventPriority.HIGH,
        "critical": EventPriority.CRITICAL
    }
    
    broadcaster.broadcast(
        event_type=EventType.HELP_REQUESTED,
        message=f"{specialist} needs help with task {task_id}",
        details={
            "task_id": task_id,
            "specialist": specialist,
            "issue": issue,
            "urgency": urgency
        },
        priority=priority_map.get(urgency, EventPriority.MEDIUM),
        recipients=[specialist, "orchestrator"]
    )

def broadcast_complexity_alert(task_id: str, complexity_score: float, factors: list):
    """Broadcast a complexity alert (FR4.4)"""
    broadcaster = EventBroadcaster()
    
    # Determine priority based on complexity score
    if complexity_score > 8:
        priority = EventPriority.HIGH
    elif complexity_score > 5:
        priority = EventPriority.MEDIUM
    else:
        priority = EventPriority.LOW
    
    broadcaster.broadcast(
        event_type=EventType.COMPLEXITY_ALERT,
        message=f"High complexity detected in task {task_id}",
        details={
            "task_id": task_id,
            "complexity_score": complexity_score,
            "factors": factors,
            "recommendation": "Consider decomposition" if complexity_score > 5 else "Monitor progress"
        },
        priority=priority
    )

def broadcast_team_event(event_name: str, team_members: list, details: dict):
    """Broadcast a team coordination event (FR5.4)"""
    broadcaster = EventBroadcaster()
    
    broadcaster.broadcast(
        event_type=EventType.TEAM_EVENT,
        message=f"Team event: {event_name}",
        details={
            "event": event_name,
            "team_members": team_members,
            **details
        },
        priority=EventPriority.MEDIUM,
        recipients=team_members
    )

# Example usage
if __name__ == "__main__":
    # Test retry notification
    broadcast_retry("task_001", attempt=2, reason="Connection timeout", delay=4.0)
    
    # Test help request
    broadcast_help_request(
        task_id="task_002",
        specialist="backend-specialist",
        issue="JWT implementation unclear",
        urgency="high"
    )
    
    # Test complexity alert
    broadcast_complexity_alert(
        task_id="task_003",
        complexity_score=7.5,
        factors=["Multiple dependencies", "Unclear requirements", "New technology"]
    )
    
    # Test team event
    broadcast_team_event(
        event_name="Sprint Planning",
        team_members=["frontend-specialist", "backend-specialist", "database-specialist"],
        details={"phase": 2, "focus": "API Development"}
    )
    
    print("All notifications broadcast successfully")