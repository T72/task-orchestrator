"""
Telemetry system for Task Orchestrator Core Loop.
Captures events for data-driven decision making and 30-day assessment.
"""

import json
import os
from pathlib import Path
from datetime import datetime, timedelta
from typing import Dict, Any, Optional
import hashlib


class TelemetryCapture:
    """Capture and store telemetry events."""
    
    def __init__(self, telemetry_dir: Path = None):
        """Initialize telemetry capture."""
        if telemetry_dir:
            self.telemetry_dir = Path(telemetry_dir)
        else:
            self.telemetry_dir = Path.home() / ".task-orchestrator" / "telemetry"
        
        self.telemetry_dir.mkdir(parents=True, exist_ok=True)
        self.session_id = self._generate_session_id()
        self.enabled = self._check_if_enabled()
    
    def _generate_session_id(self) -> str:
        """Generate unique session ID."""
        unique = f"{os.getpid()}:{datetime.now().isoformat()}"
        return hashlib.md5(unique.encode()).hexdigest()[:12]
    
    def _check_if_enabled(self) -> bool:
        """Check if telemetry is enabled in config."""
        try:
            from config_manager import ConfigManager
            config = ConfigManager()
            return config.is_telemetry_enabled()
        except:
            # Default to enabled if config not available
            return True
    
    def capture_event(self, event_type: str, event_data: Dict[str, Any]):
        """Capture a telemetry event."""
        if not self.enabled:
            return
        
        event = {
            'event_type': event_type,
            'timestamp': datetime.now().isoformat(),
            'session_id': self.session_id,
            'data': event_data
        }
        
        # Store in daily file
        date_str = datetime.now().strftime("%Y%m%d")
        event_file = self.telemetry_dir / f"events_{date_str}.jsonl"
        
        try:
            with open(event_file, 'a') as f:
                f.write(json.dumps(event) + '\n')
        except Exception as e:
            # Silently fail - telemetry should not break main functionality
            pass
    
    def capture_task_created(self, task_id: str, has_criteria: bool = False,
                           has_deadline: bool = False, has_estimate: bool = False):
        """Capture task creation event."""
        self.capture_event('task_created', {
            'task_id': task_id,
            'has_success_criteria': has_criteria,
            'has_deadline': has_deadline,
            'has_time_estimate': has_estimate,
            'core_loop_features_used': sum([has_criteria, has_deadline, has_estimate])
        })
    
    def capture_task_completed(self, task_id: str, validated: bool = False,
                              has_summary: bool = False, actual_hours: Optional[float] = None):
        """Capture task completion event."""
        self.capture_event('task_completed', {
            'task_id': task_id,
            'criteria_validated': validated,
            'has_completion_summary': has_summary,
            'actual_hours_recorded': actual_hours is not None,
            'actual_hours': actual_hours
        })
    
    def capture_feedback_provided(self, task_id: str, quality: Optional[int] = None,
                                 timeliness: Optional[int] = None):
        """Capture feedback event."""
        self.capture_event('feedback_provided', {
            'task_id': task_id,
            'quality_score': quality,
            'timeliness_score': timeliness,
            'has_quality': quality is not None,
            'has_timeliness': timeliness is not None
        })
    
    def capture_progress_update(self, task_id: str):
        """Capture progress update event."""
        self.capture_event('progress_updated', {
            'task_id': task_id
        })
    
    def capture_config_change(self, feature: str, enabled: bool):
        """Capture configuration change event."""
        self.capture_event('config_changed', {
            'feature': feature,
            'enabled': enabled
        })
    
    def capture_migration_applied(self, version: str, success: bool):
        """Capture migration event."""
        self.capture_event('migration_applied', {
            'version': version,
            'success': success
        })
    
    def capture_criteria_validation(self, task_id: str, criteria_met: int, 
                                   criteria_total: int):
        """Capture criteria validation event."""
        self.capture_event('criteria_validated', {
            'task_id': task_id,
            'criteria_met': criteria_met,
            'criteria_total': criteria_total,
            'success_rate': criteria_met / criteria_total if criteria_total > 0 else 0
        })
    
    def get_daily_summary(self, date: datetime = None) -> Dict[str, Any]:
        """Get summary of telemetry for a specific day."""
        if date is None:
            date = datetime.now()
        
        date_str = date.strftime("%Y%m%d")
        event_file = self.telemetry_dir / f"events_{date_str}.jsonl"
        
        if not event_file.exists():
            return {'date': date_str, 'events': [], 'summary': {}}
        
        events = []
        with open(event_file, 'r') as f:
            for line in f:
                if line.strip():
                    events.append(json.loads(line))
        
        # Aggregate summary
        summary = {
            'total_events': len(events),
            'tasks_created': sum(1 for e in events if e['event_type'] == 'task_created'),
            'tasks_completed': sum(1 for e in events if e['event_type'] == 'task_completed'),
            'feedback_provided': sum(1 for e in events if e['event_type'] == 'feedback_provided'),
            'core_loop_adoption': self._calculate_adoption_rate(events)
        }
        
        return {
            'date': date_str,
            'events': events,
            'summary': summary
        }
    
    def _calculate_adoption_rate(self, events: list) -> float:
        """Calculate Core Loop feature adoption rate."""
        task_events = [e for e in events if e['event_type'] == 'task_created']
        if not task_events:
            return 0.0
        
        using_features = sum(1 for e in task_events 
                           if e['data'].get('core_loop_features_used', 0) > 0)
        
        return using_features / len(task_events)
    
    def cleanup_old_events(self, days_to_keep: int = 30):
        """Clean up telemetry files older than specified days."""
        cutoff_date = datetime.now() - timedelta(days=days_to_keep)
        
        for event_file in self.telemetry_dir.glob("events_*.jsonl"):
            # Parse date from filename
            try:
                file_date_str = event_file.stem.split('_')[1]
                file_date = datetime.strptime(file_date_str, "%Y%m%d")
                
                if file_date < cutoff_date:
                    event_file.unlink()
            except:
                # Skip files that don't match expected pattern
                continue