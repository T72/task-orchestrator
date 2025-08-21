"""
Metrics Calculator for Task Orchestrator Core Loop.
Provides real-time metrics aggregation and analysis.
"""

import sqlite3
from pathlib import Path
from typing import Dict, Any, List
from datetime import datetime, timedelta
import statistics


class MetricsCalculator:
    """
    Calculate metrics from task data.
    
    @implements FR-037: Metrics Collection Framework
    @implements FR-038: Performance Analytics System
    @implements FR-039: Feedback Analytics
    """
    
    def __init__(self, db_path: str):
        """Initialize metrics calculator."""
        self.db_path = db_path
    
    def get_feedback_metrics(self) -> Dict[str, Any]:
        """
        Calculate feedback-related metrics.
        
        @implements FR-039: Feedback Analytics
        @implements FR-037: Metrics Collection Framework
        """
        with sqlite3.connect(str(self.db_path)) as conn:
            # Get all tasks with feedback
            cursor = conn.execute("""
                SELECT feedback_quality, feedback_timeliness 
                FROM tasks 
                WHERE feedback_quality IS NOT NULL 
                   OR feedback_timeliness IS NOT NULL
            """)
            feedback_data = cursor.fetchall()
            
            # Get total task count
            cursor = conn.execute("SELECT COUNT(*) FROM tasks")
            total_tasks = cursor.fetchone()[0]
            
            # Calculate metrics
            quality_scores = [row[0] for row in feedback_data if row[0] is not None]
            timeliness_scores = [row[1] for row in feedback_data if row[1] is not None]
            
            metrics = {
                'avg_quality': statistics.mean(quality_scores) if quality_scores else 0.0,
                'avg_timeliness': statistics.mean(timeliness_scores) if timeliness_scores else 0.0,
                'tasks_with_feedback': len(feedback_data),
                'total_tasks': total_tasks,
                'feedback_coverage': len(feedback_data) / total_tasks if total_tasks > 0 else 0.0,
                'quality_std_dev': statistics.stdev(quality_scores) if len(quality_scores) > 1 else 0.0,
                'timeliness_std_dev': statistics.stdev(timeliness_scores) if len(timeliness_scores) > 1 else 0.0
            }
            
            # Add distribution analysis
            if quality_scores:
                metrics['quality_distribution'] = self._get_distribution(quality_scores)
            if timeliness_scores:
                metrics['timeliness_distribution'] = self._get_distribution(timeliness_scores)
            
            return metrics
    
    def get_success_criteria_metrics(self) -> Dict[str, Any]:
        """Calculate success criteria validation metrics."""
        with sqlite3.connect(str(self.db_path)) as conn:
            # Get tasks with success criteria
            cursor = conn.execute("""
                SELECT id, success_criteria, status, completion_summary
                FROM tasks 
                WHERE success_criteria IS NOT NULL
            """)
            
            tasks_with_criteria = cursor.fetchall()
            total_with_criteria = len(tasks_with_criteria)
            completed_with_criteria = sum(1 for t in tasks_with_criteria if t[2] == 'completed')
            
            # Analyze completion summaries for validation mentions
            validated_count = 0
            for task in tasks_with_criteria:
                if task[3] and ('validated' in task[3].lower() or 
                              'criteria met' in task[3].lower() or
                              'success' in task[3].lower()):
                    validated_count += 1
            
            return {
                'tasks_with_criteria': total_with_criteria,
                'completed_with_criteria': completed_with_criteria,
                'validation_rate': validated_count / completed_with_criteria if completed_with_criteria > 0 else 0.0,
                'criteria_adoption_rate': total_with_criteria / self._get_total_tasks() if self._get_total_tasks() > 0 else 0.0
            }
    
    def get_time_tracking_metrics(self) -> Dict[str, Any]:
        """Calculate time tracking metrics."""
        with sqlite3.connect(str(self.db_path)) as conn:
            cursor = conn.execute("""
                SELECT estimated_hours, actual_hours, status
                FROM tasks 
                WHERE estimated_hours IS NOT NULL OR actual_hours IS NOT NULL
            """)
            
            time_data = cursor.fetchall()
            
            # Calculate estimation accuracy
            estimation_errors = []
            for est, act, status in time_data:
                if est is not None and act is not None and status == 'completed':
                    error_pct = abs(est - act) / est if est > 0 else 0
                    estimation_errors.append(error_pct)
            
            # Calculate velocity (tasks completed per time period)
            cursor = conn.execute("""
                SELECT COUNT(*), SUM(actual_hours)
                FROM tasks 
                WHERE status = 'completed' 
                  AND completed_at >= date('now', '-30 days')
                  AND actual_hours IS NOT NULL
            """)
            
            recent_completed, recent_hours = cursor.fetchone()
            
            return {
                'tasks_with_estimates': sum(1 for t in time_data if t[0] is not None),
                'tasks_with_actuals': sum(1 for t in time_data if t[1] is not None),
                'avg_estimation_error': statistics.mean(estimation_errors) if estimation_errors else 0.0,
                'estimation_accuracy': 1 - statistics.mean(estimation_errors) if estimation_errors else 0.0,
                'velocity_30d': recent_completed / 30 if recent_completed else 0.0,
                'avg_task_hours': recent_hours / recent_completed if recent_completed and recent_hours else 0.0
            }
    
    def get_deadline_metrics(self) -> Dict[str, Any]:
        """Calculate deadline-related metrics."""
        with sqlite3.connect(str(self.db_path)) as conn:
            cursor = conn.execute("""
                SELECT deadline, completed_at, status
                FROM tasks 
                WHERE deadline IS NOT NULL
            """)
            
            deadline_data = cursor.fetchall()
            
            on_time = 0
            late = 0
            at_risk = 0
            
            for deadline_str, completed_str, status in deadline_data:
                if status == 'completed' and completed_str:
                    deadline = datetime.fromisoformat(deadline_str.replace('Z', '+00:00'))
                    completed = datetime.fromisoformat(completed_str)
                    if completed <= deadline:
                        on_time += 1
                    else:
                        late += 1
                elif status in ['pending', 'in_progress']:
                    deadline = datetime.fromisoformat(deadline_str.replace('Z', '+00:00'))
                    if datetime.now() > deadline:
                        late += 1
                    elif datetime.now() > deadline - timedelta(days=1):
                        at_risk += 1
            
            total_with_deadlines = len(deadline_data)
            
            return {
                'tasks_with_deadlines': total_with_deadlines,
                'on_time_delivery': on_time,
                'late_delivery': late,
                'at_risk': at_risk,
                'on_time_rate': on_time / total_with_deadlines if total_with_deadlines > 0 else 0.0
            }
    
    def get_comprehensive_metrics(self) -> Dict[str, Any]:
        """Get all metrics in one call."""
        return {
            'feedback': self.get_feedback_metrics(),
            'success_criteria': self.get_success_criteria_metrics(),
            'time_tracking': self.get_time_tracking_metrics(),
            'deadlines': self.get_deadline_metrics(),
            'generated_at': datetime.now().isoformat()
        }
    
    def _get_distribution(self, scores: List[int]) -> Dict[int, int]:
        """Get distribution of scores (1-5)."""
        distribution = {i: 0 for i in range(1, 6)}
        for score in scores:
            if score in distribution:
                distribution[score] += 1
        return distribution
    
    def _get_total_tasks(self) -> int:
        """Get total number of tasks."""
        with sqlite3.connect(str(self.db_path)) as conn:
            cursor = conn.execute("SELECT COUNT(*) FROM tasks")
            return cursor.fetchone()[0]