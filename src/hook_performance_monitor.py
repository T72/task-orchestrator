#!/usr/bin/env python3
"""
Hook Performance Monitoring System for Task Orchestrator
Tracks execution time, success rates, and performance metrics for hooks
@implements FR-046: Hook Performance Monitoring
"""

import os
import time
import json
import sqlite3
import subprocess
import statistics
from pathlib import Path
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Tuple, Any
from dataclasses import dataclass, asdict

@dataclass
class HookExecution:
    """Represents a single hook execution with metrics"""
    hook_name: str
    hook_type: str  # pre-add, post-add, pre-complete, etc.
    start_time: float
    end_time: float
    duration_ms: float
    success: bool
    exit_code: int
    error_message: Optional[str]
    task_id: Optional[str]
    trigger_event: str
    metadata: Dict[str, Any]

class HookPerformanceMonitor:
    """
    Monitors and tracks hook performance metrics
    @implements FR-046: Performance tracking and analysis
    """
    
    def __init__(self, db_path: Optional[str] = None):
        """Initialize the performance monitor with database"""
        self.db_path = db_path or ".task-orchestrator/metrics/hook_performance.db"
        self.metrics_dir = Path(self.db_path).parent
        self.metrics_dir.mkdir(parents=True, exist_ok=True)
        self.hooks_dir = Path(".task-orchestrator/hooks")
        self._init_database()
        
        # Performance thresholds (configurable)
        self.thresholds = {
            'warning_ms': 500,   # Warn if hook takes > 500ms
            'critical_ms': 2000,  # Critical if hook takes > 2 seconds
            'timeout_ms': 10000   # Timeout after 10 seconds
        }
    
    def _init_database(self):
        """Initialize the performance metrics database"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        # Create hook executions table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS hook_executions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                hook_name TEXT NOT NULL,
                hook_type TEXT NOT NULL,
                start_time REAL NOT NULL,
                end_time REAL NOT NULL,
                duration_ms REAL NOT NULL,
                success INTEGER NOT NULL,
                exit_code INTEGER NOT NULL,
                error_message TEXT,
                task_id TEXT,
                trigger_event TEXT NOT NULL,
                metadata TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        
        # Create performance summary table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS hook_performance_summary (
                hook_name TEXT PRIMARY KEY,
                total_executions INTEGER DEFAULT 0,
                successful_executions INTEGER DEFAULT 0,
                failed_executions INTEGER DEFAULT 0,
                avg_duration_ms REAL DEFAULT 0,
                min_duration_ms REAL DEFAULT 0,
                max_duration_ms REAL DEFAULT 0,
                p50_duration_ms REAL DEFAULT 0,
                p95_duration_ms REAL DEFAULT 0,
                p99_duration_ms REAL DEFAULT 0,
                last_execution TIMESTAMP,
                last_success TIMESTAMP,
                last_failure TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        
        # Create alerts table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS hook_alerts (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                hook_name TEXT NOT NULL,
                alert_type TEXT NOT NULL,
                severity TEXT NOT NULL,
                message TEXT NOT NULL,
                duration_ms REAL,
                threshold_ms REAL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        
        # Create indices for performance
        cursor.execute('CREATE INDEX IF NOT EXISTS idx_hook_name ON hook_executions(hook_name)')
        cursor.execute('CREATE INDEX IF NOT EXISTS idx_created_at ON hook_executions(created_at)')
        cursor.execute('CREATE INDEX IF NOT EXISTS idx_task_id ON hook_executions(task_id)')
        
        conn.commit()
        conn.close()
    
    def execute_hook_with_monitoring(self, hook_path: str, hook_type: str, 
                                    context: Dict[str, Any]) -> Tuple[bool, float]:
        """
        Execute a hook with performance monitoring
        @implements FR-046: Hook execution timing
        """
        hook_name = Path(hook_path).name
        task_id = context.get('task_id')
        trigger_event = context.get('event', 'manual')
        
        # Prepare execution
        execution = HookExecution(
            hook_name=hook_name,
            hook_type=hook_type,
            start_time=time.time(),
            end_time=0,
            duration_ms=0,
            success=False,
            exit_code=-1,
            error_message=None,
            task_id=task_id,
            trigger_event=trigger_event,
            metadata=context
        )
        
        try:
            # Execute hook with timeout
            env = os.environ.copy()
            env.update({
                'TM_TASK_ID': str(task_id) if task_id else '',
                'TM_HOOK_TYPE': hook_type,
                'TM_TRIGGER_EVENT': trigger_event
            })
            
            # Add context variables to environment
            for key, value in context.items():
                env[f'TM_{key.upper()}'] = str(value)
            
            # Execute with timeout
            timeout_seconds = self.thresholds['timeout_ms'] / 1000
            
            process = subprocess.Popen(
                [hook_path],
                env=env,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )
            
            try:
                stdout, stderr = process.communicate(timeout=timeout_seconds)
                execution.exit_code = process.returncode
                execution.success = (process.returncode == 0)
                if stderr:
                    execution.error_message = stderr[:1000]  # Limit error message size
            except subprocess.TimeoutExpired:
                process.kill()
                execution.success = False
                execution.exit_code = -1
                execution.error_message = f"Hook timed out after {timeout_seconds} seconds"
                
        except Exception as e:
            execution.success = False
            execution.error_message = str(e)[:1000]
        
        # Record end time and duration
        execution.end_time = time.time()
        execution.duration_ms = (execution.end_time - execution.start_time) * 1000
        
        # Store execution metrics
        self._store_execution(execution)
        
        # Check for performance alerts
        self._check_performance_alerts(execution)
        
        # Update summary statistics
        self._update_summary_stats(hook_name)
        
        return execution.success, execution.duration_ms
    
    def _store_execution(self, execution: HookExecution):
        """Store hook execution metrics in database"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute('''
            INSERT INTO hook_executions 
            (hook_name, hook_type, start_time, end_time, duration_ms, 
             success, exit_code, error_message, task_id, trigger_event, metadata)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', (
            execution.hook_name,
            execution.hook_type,
            execution.start_time,
            execution.end_time,
            execution.duration_ms,
            1 if execution.success else 0,
            execution.exit_code,
            execution.error_message,
            execution.task_id,
            execution.trigger_event,
            json.dumps(execution.metadata)
        ))
        
        conn.commit()
        conn.close()
    
    def _check_performance_alerts(self, execution: HookExecution):
        """Check if execution triggers any performance alerts"""
        alerts = []
        
        # Check duration thresholds
        if execution.duration_ms > self.thresholds['critical_ms']:
            alerts.append({
                'type': 'slow_execution',
                'severity': 'critical',
                'message': f"Hook {execution.hook_name} took {execution.duration_ms:.0f}ms (threshold: {self.thresholds['critical_ms']}ms)"
            })
        elif execution.duration_ms > self.thresholds['warning_ms']:
            alerts.append({
                'type': 'slow_execution',
                'severity': 'warning',
                'message': f"Hook {execution.hook_name} took {execution.duration_ms:.0f}ms (threshold: {self.thresholds['warning_ms']}ms)"
            })
        
        # Check for failures
        if not execution.success:
            alerts.append({
                'type': 'execution_failure',
                'severity': 'error',
                'message': f"Hook {execution.hook_name} failed: {execution.error_message}"
            })
        
        # Store alerts
        if alerts:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            for alert in alerts:
                cursor.execute('''
                    INSERT INTO hook_alerts 
                    (hook_name, alert_type, severity, message, duration_ms, threshold_ms)
                    VALUES (?, ?, ?, ?, ?, ?)
                ''', (
                    execution.hook_name,
                    alert['type'],
                    alert['severity'],
                    alert['message'],
                    execution.duration_ms,
                    self.thresholds.get(f"{alert['severity']}_ms", 0)
                ))
            
            conn.commit()
            conn.close()
    
    def _update_summary_stats(self, hook_name: str):
        """Update summary statistics for a hook"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        # Get all executions for this hook
        cursor.execute('''
            SELECT duration_ms, success 
            FROM hook_executions 
            WHERE hook_name = ? 
            ORDER BY created_at DESC 
            LIMIT 1000
        ''', (hook_name,))
        
        executions = cursor.fetchall()
        if not executions:
            conn.close()
            return
        
        durations = [e[0] for e in executions]
        successes = [e[1] for e in executions]
        
        # Calculate statistics
        total = len(executions)
        successful = sum(successes)
        failed = total - successful
        
        # Duration statistics
        avg_duration = statistics.mean(durations)
        min_duration = min(durations)
        max_duration = max(durations)
        
        # Percentiles
        sorted_durations = sorted(durations)
        p50 = sorted_durations[int(len(sorted_durations) * 0.50)]
        p95 = sorted_durations[int(len(sorted_durations) * 0.95)] if len(sorted_durations) > 20 else max_duration
        p99 = sorted_durations[int(len(sorted_durations) * 0.99)] if len(sorted_durations) > 100 else max_duration
        
        # Get last execution times
        cursor.execute('''
            SELECT MAX(created_at) FROM hook_executions WHERE hook_name = ?
        ''', (hook_name,))
        last_execution = cursor.fetchone()[0]
        
        cursor.execute('''
            SELECT MAX(created_at) FROM hook_executions WHERE hook_name = ? AND success = 1
        ''', (hook_name,))
        last_success = cursor.fetchone()[0]
        
        cursor.execute('''
            SELECT MAX(created_at) FROM hook_executions WHERE hook_name = ? AND success = 0
        ''', (hook_name,))
        last_failure = cursor.fetchone()[0]
        
        # Update or insert summary
        cursor.execute('''
            INSERT OR REPLACE INTO hook_performance_summary
            (hook_name, total_executions, successful_executions, failed_executions,
             avg_duration_ms, min_duration_ms, max_duration_ms,
             p50_duration_ms, p95_duration_ms, p99_duration_ms,
             last_execution, last_success, last_failure, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
        ''', (
            hook_name, total, successful, failed,
            avg_duration, min_duration, max_duration,
            p50, p95, p99,
            last_execution, last_success, last_failure
        ))
        
        conn.commit()
        conn.close()
    
    def get_performance_report(self, hook_name: Optional[str] = None,
                              days: int = 7) -> Dict[str, Any]:
        """
        Generate performance report for hooks
        @implements FR-046: Performance reporting
        """
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        since = datetime.now() - timedelta(days=days)
        
        if hook_name:
            # Report for specific hook
            cursor.execute('''
                SELECT * FROM hook_performance_summary WHERE hook_name = ?
            ''', (hook_name,))
            summary = cursor.fetchone()
            
            if not summary:
                conn.close()
                return {'error': f'No data found for hook {hook_name}'}
            
            # Get recent executions
            cursor.execute('''
                SELECT duration_ms, success, created_at
                FROM hook_executions
                WHERE hook_name = ? AND created_at > ?
                ORDER BY created_at DESC
                LIMIT 100
            ''', (hook_name, since))
            recent = cursor.fetchall()
            
            # Get recent alerts
            cursor.execute('''
                SELECT alert_type, severity, message, created_at
                FROM hook_alerts
                WHERE hook_name = ? AND created_at > ?
                ORDER BY created_at DESC
                LIMIT 20
            ''', (hook_name, since))
            alerts = cursor.fetchall()
            
            report = {
                'hook_name': hook_name,
                'summary': {
                    'total_executions': summary[1],
                    'success_rate': (summary[2] / summary[1] * 100) if summary[1] > 0 else 0,
                    'avg_duration_ms': summary[4],
                    'min_duration_ms': summary[5],
                    'max_duration_ms': summary[6],
                    'p50_duration_ms': summary[7],
                    'p95_duration_ms': summary[8],
                    'p99_duration_ms': summary[9],
                    'last_execution': summary[10],
                    'last_success': summary[11],
                    'last_failure': summary[12]
                },
                'recent_executions': [
                    {
                        'duration_ms': r[0],
                        'success': bool(r[1]),
                        'timestamp': r[2]
                    } for r in recent
                ],
                'alerts': [
                    {
                        'type': a[0],
                        'severity': a[1],
                        'message': a[2],
                        'timestamp': a[3]
                    } for a in alerts
                ]
            }
        else:
            # Report for all hooks
            cursor.execute('''
                SELECT * FROM hook_performance_summary
                ORDER BY total_executions DESC
            ''')
            summaries = cursor.fetchall()
            
            # Get overall statistics
            cursor.execute('''
                SELECT 
                    COUNT(*) as total,
                    SUM(success) as successful,
                    AVG(duration_ms) as avg_duration
                FROM hook_executions
                WHERE created_at > ?
            ''', (since,))
            overall = cursor.fetchone()
            
            # Get slow hooks
            cursor.execute('''
                SELECT hook_name, COUNT(*) as slow_count
                FROM hook_executions
                WHERE duration_ms > ? AND created_at > ?
                GROUP BY hook_name
                ORDER BY slow_count DESC
                LIMIT 5
            ''', (self.thresholds['warning_ms'], since))
            slow_hooks = cursor.fetchall()
            
            report = {
                'period_days': days,
                'overall': {
                    'total_executions': overall[0] or 0,
                    'successful_executions': overall[1] or 0,
                    'success_rate': ((overall[1] / overall[0] * 100) if overall[0] else 0),
                    'avg_duration_ms': overall[2] or 0
                },
                'hooks': [
                    {
                        'name': s[0],
                        'total': s[1],
                        'success_rate': (s[2] / s[1] * 100) if s[1] > 0 else 0,
                        'avg_duration_ms': s[4],
                        'p95_duration_ms': s[8]
                    } for s in summaries
                ],
                'slow_hooks': [
                    {
                        'name': s[0],
                        'slow_executions': s[1]
                    } for s in slow_hooks
                ]
            }
        
        conn.close()
        return report
    
    def get_alerts(self, severity: Optional[str] = None, 
                   hours: int = 24) -> List[Dict[str, Any]]:
        """Get recent performance alerts"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        since = datetime.now() - timedelta(hours=hours)
        
        if severity:
            cursor.execute('''
                SELECT * FROM hook_alerts
                WHERE severity = ? AND created_at > ?
                ORDER BY created_at DESC
            ''', (severity, since))
        else:
            cursor.execute('''
                SELECT * FROM hook_alerts
                WHERE created_at > ?
                ORDER BY created_at DESC
            ''', (since,))
        
        alerts = cursor.fetchall()
        conn.close()
        
        return [
            {
                'id': a[0],
                'hook_name': a[1],
                'type': a[2],
                'severity': a[3],
                'message': a[4],
                'duration_ms': a[5],
                'threshold_ms': a[6],
                'timestamp': a[7]
            } for a in alerts
        ]
    
    def configure_thresholds(self, warning_ms: Optional[int] = None,
                            critical_ms: Optional[int] = None,
                            timeout_ms: Optional[int] = None):
        """Configure performance thresholds"""
        if warning_ms is not None:
            self.thresholds['warning_ms'] = warning_ms
        if critical_ms is not None:
            self.thresholds['critical_ms'] = critical_ms
        if timeout_ms is not None:
            self.thresholds['timeout_ms'] = timeout_ms
        
        # Save to config file
        config_path = self.metrics_dir / "thresholds.json"
        with open(config_path, 'w') as f:
            json.dump(self.thresholds, f, indent=2)
    
    def cleanup_old_metrics(self, days: int = 30):
        """Clean up old metrics data"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cutoff = datetime.now() - timedelta(days=days)
        
        cursor.execute('DELETE FROM hook_executions WHERE created_at < ?', (cutoff,))
        cursor.execute('DELETE FROM hook_alerts WHERE created_at < ?', (cutoff,))
        
        deleted = cursor.rowcount
        conn.commit()
        conn.close()
        
        return deleted