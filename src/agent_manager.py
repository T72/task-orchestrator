#!/usr/bin/env python3
"""
Agent Manager Module - Core agent management functionality
Implements agent workload distribution, performance metrics, and communication channels

@implements FR-017: Agent Workload Distribution
@implements FR-019: Agent Performance Metrics
@implements FR-020: Agent Communication Channels
"""

import sqlite3
import json
import logging
from datetime import datetime, timedelta
from typing import List, Dict, Optional, Tuple, Any
from pathlib import Path
import os

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class AgentManager:
    """
    Manages agent registration, workload distribution, performance metrics,
    and inter-agent communication for the Task Orchestrator system.
    """
    
    def __init__(self, db_path: str = None):
        """
        Initialize the AgentManager with database connection
        
        @implements FR-017: Initialize workload tracking
        @implements FR-019: Initialize metrics system
        @implements FR-020: Initialize communication channels
        """
        if db_path is None:
            db_path = os.environ.get('TM_DB_PATH', '.task-orchestrator/tasks.db')
        
        self.db_path = db_path
        Path(db_path).parent.mkdir(parents=True, exist_ok=True)
        
        # Initialize database connection
        self.conn = sqlite3.connect(db_path, check_same_thread=False)
        self.conn.row_factory = sqlite3.Row
        
        # Ensure tables exist
        self._ensure_tables_exist()
        
        logger.info(f"AgentManager initialized with database: {db_path}")
    
    def _ensure_tables_exist(self):
        """Ensure all required tables exist by running migration if needed"""
        cursor = self.conn.cursor()
        
        # Check if agents table exists
        cursor.execute("""
            SELECT name FROM sqlite_master 
            WHERE type='table' AND name='agents'
        """)
        
        if not cursor.fetchone():
            # Tables don't exist, run migration
            # Import and run the migration directly
            import sys
            import os
            sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
            # Import the migration module directly by its filename
            import importlib.util
            spec = importlib.util.spec_from_file_location(
                "migration_005", 
                os.path.join(os.path.dirname(__file__), "migrations", "005_add_agent_management.py")
            )
            migration = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(migration)
            migration.migrate_up(self.conn)
            logger.info("Agent management tables created")
    
    def __enter__(self):
        """Context manager entry"""
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        """Context manager exit - close database connection"""
        if self.conn:
            self.conn.close()
    
    # ========== Agent Registration & Discovery (Foundation) ==========
    
    def register_agent(self, agent_id: str, name: str, agent_type: str = None, 
                      capabilities: List[str] = None) -> bool:
        """
        Register a new agent or update existing agent
        
        Args:
            agent_id: Unique identifier for the agent
            name: Human-readable name for the agent
            agent_type: Type of agent (e.g., 'backend', 'frontend', 'database')
            capabilities: List of capabilities the agent has
        
        Returns:
            True if registration successful, False otherwise
        """
        try:
            cursor = self.conn.cursor()
            
            # Convert capabilities to JSON
            capabilities_json = json.dumps(capabilities) if capabilities else '[]'
            
            # Insert or update agent
            cursor.execute("""
                INSERT OR REPLACE INTO agents 
                (id, name, type, capabilities, status, last_heartbeat, registered_at)
                VALUES (?, ?, ?, ?, 'active', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
            """, (agent_id, name, agent_type, capabilities_json))
            
            # Initialize workload entry
            cursor.execute("""
                INSERT OR IGNORE INTO agent_workload (agent_id)
                VALUES (?)
            """, (agent_id,))
            
            self.conn.commit()
            logger.info(f"Agent registered: {agent_id} ({name})")
            return True
            
        except Exception as e:
            logger.error(f"Failed to register agent {agent_id}: {e}")
            self.conn.rollback()
            return False
    
    def discover_agents(self, status: str = 'active', agent_type: str = None) -> List[Dict]:
        """
        Discover available agents
        
        Args:
            status: Filter by status (active, inactive, busy)
            agent_type: Filter by agent type
        
        Returns:
            List of agent dictionaries
        """
        try:
            cursor = self.conn.cursor()
            
            query = "SELECT * FROM agents WHERE 1=1"
            params = []
            
            if status:
                query += " AND status = ?"
                params.append(status)
            
            if agent_type:
                query += " AND type = ?"
                params.append(agent_type)
            
            cursor.execute(query, params)
            
            agents = []
            for row in cursor.fetchall():
                agent = dict(row)
                agent['capabilities'] = json.loads(agent.get('capabilities', '[]'))
                agents.append(agent)
            
            return agents
            
        except Exception as e:
            logger.error(f"Failed to discover agents: {e}")
            return []
    
    def get_agent(self, agent_id: str) -> Optional[Dict]:
        """
        Get details for a specific agent
        
        Args:
            agent_id: Agent identifier
        
        Returns:
            Agent dictionary or None if not found
        """
        try:
            cursor = self.conn.cursor()
            cursor.execute("SELECT * FROM agents WHERE id = ?", (agent_id,))
            
            row = cursor.fetchone()
            if row:
                agent = dict(row)
                agent['capabilities'] = json.loads(agent.get('capabilities', '[]'))
                return agent
            
            return None
            
        except Exception as e:
            logger.error(f"Failed to get agent {agent_id}: {e}")
            return None
    
    def update_heartbeat(self, agent_id: str) -> bool:
        """
        Update agent heartbeat timestamp
        
        Args:
            agent_id: Agent identifier
        
        Returns:
            True if update successful
        """
        try:
            cursor = self.conn.cursor()
            cursor.execute("""
                UPDATE agents 
                SET last_heartbeat = CURRENT_TIMESTAMP 
                WHERE id = ?
            """, (agent_id,))
            
            self.conn.commit()
            return cursor.rowcount > 0
            
        except Exception as e:
            logger.error(f"Failed to update heartbeat for {agent_id}: {e}")
            return False
    
    def set_agent_status(self, agent_id: str, status: str) -> bool:
        """
        Update agent status
        
        Args:
            agent_id: Agent identifier
            status: New status (active, inactive, busy)
        
        Returns:
            True if update successful
        """
        try:
            cursor = self.conn.cursor()
            cursor.execute("""
                UPDATE agents 
                SET status = ? 
                WHERE id = ?
            """, (status, agent_id))
            
            self.conn.commit()
            return cursor.rowcount > 0
            
        except Exception as e:
            logger.error(f"Failed to update status for {agent_id}: {e}")
            return False
    
    # ========== Workload Distribution (FR-017) ==========
    
    def track_workload(self, agent_id: str) -> Dict:
        """
        Track and update workload for a specific agent
        
        @implements FR-017: Agent Workload Distribution
        
        Args:
            agent_id: Agent identifier
        
        Returns:
            Dictionary with workload information
        """
        try:
            cursor = self.conn.cursor()
            
            # Count active tasks assigned to this agent
            cursor.execute("""
                SELECT COUNT(*) as task_count,
                       SUM(COALESCE(estimated_hours, 1)) as total_hours
                FROM tasks 
                WHERE assignee = ? AND status IN ('pending', 'in_progress')
            """, (agent_id,))
            
            result = cursor.fetchone()
            task_count = result['task_count'] if result else 0
            total_hours = result['total_hours'] if result and result['total_hours'] else 0
            
            # Count completed tasks today
            cursor.execute("""
                SELECT COUNT(*) as completed_today
                FROM tasks
                WHERE assignee = ? 
                AND status = 'completed'
                AND DATE(updated_at) = DATE('now')
            """, (agent_id,))
            
            completed = cursor.fetchone()
            completed_today = completed['completed_today'] if completed else 0
            
            # Calculate average completion time
            cursor.execute("""
                SELECT AVG(duration_minutes) as avg_time
                FROM agent_task_history
                WHERE agent_id = ? AND action = 'completed'
                AND timestamp > datetime('now', '-7 days')
            """, (agent_id,))
            
            avg_result = cursor.fetchone()
            avg_completion_time = avg_result['avg_time'] if avg_result and avg_result['avg_time'] else 0
            
            # Calculate load score (0-100)
            # Formula: (task_count * 10) + (total_hours * 5) - (completed_today * 5)
            load_score = min(100, max(0, (task_count * 10) + (total_hours * 5) - (completed_today * 5)))
            
            # Update workload table
            cursor.execute("""
                INSERT OR REPLACE INTO agent_workload
                (agent_id, task_count, estimated_hours, completed_today, 
                 average_completion_time, current_load_score, last_updated)
                VALUES (?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
            """, (agent_id, task_count, total_hours, completed_today, 
                  avg_completion_time, load_score))
            
            self.conn.commit()
            
            return {
                'agent_id': agent_id,
                'task_count': task_count,
                'estimated_hours': total_hours,
                'completed_today': completed_today,
                'average_completion_time': avg_completion_time,
                'load_score': load_score
            }
            
        except Exception as e:
            logger.error(f"Failed to track workload for {agent_id}: {e}")
            return {}
    
    def calculate_agent_load(self, agent_id: str) -> float:
        """
        Calculate current load score for an agent
        
        @implements FR-017: Agent Workload Distribution
        
        Args:
            agent_id: Agent identifier
        
        Returns:
            Load score (0-100, where 0 is no load, 100 is overloaded)
        """
        workload = self.track_workload(agent_id)
        return workload.get('load_score', 0) if workload else 0
    
    def find_least_loaded_agent(self, capabilities: List[str] = None) -> Optional[str]:
        """
        Find the least loaded agent, optionally filtered by capabilities
        
        @implements FR-017: Agent Workload Distribution
        
        Args:
            capabilities: Optional list of required capabilities
        
        Returns:
            Agent ID of the least loaded agent, or None if no suitable agent found
        """
        try:
            cursor = self.conn.cursor()
            
            # Build query based on capabilities filter
            if capabilities:
                # Find agents that have all required capabilities
                capability_conditions = []
                for cap in capabilities:
                    capability_conditions.append(f"a.capabilities LIKE '%\"{cap}\"%'")
                
                capability_filter = " AND ".join(capability_conditions)
                
                query = f"""
                    SELECT a.id, COALESCE(w.current_load_score, 0) as load_score
                    FROM agents a
                    LEFT JOIN agent_workload w ON a.id = w.agent_id
                    WHERE a.status = 'active' AND ({capability_filter})
                    ORDER BY load_score ASC
                    LIMIT 1
                """
            else:
                query = """
                    SELECT a.id, COALESCE(w.current_load_score, 0) as load_score
                    FROM agents a
                    LEFT JOIN agent_workload w ON a.id = w.agent_id
                    WHERE a.status = 'active'
                    ORDER BY load_score ASC
                    LIMIT 1
                """
            
            cursor.execute(query)
            result = cursor.fetchone()
            
            if result:
                logger.info(f"Found least loaded agent: {result['id']} (load: {result['load_score']})")
                return result['id']
            
            return None
            
        except Exception as e:
            logger.error(f"Failed to find least loaded agent: {e}")
            return None
    
    def redistribute_tasks(self, overload_threshold: float = 80) -> int:
        """
        Redistribute tasks from overloaded agents to less loaded ones
        
        @implements FR-017: Agent Workload Distribution
        
        Args:
            overload_threshold: Load score above which an agent is considered overloaded
        
        Returns:
            Number of tasks redistributed
        """
        try:
            cursor = self.conn.cursor()
            redistributed = 0
            
            # Find overloaded agents
            cursor.execute("""
                SELECT agent_id, current_load_score
                FROM agent_workload
                WHERE current_load_score > ?
                ORDER BY current_load_score DESC
            """, (overload_threshold,))
            
            overloaded_agents = cursor.fetchall()
            
            for agent_row in overloaded_agents:
                agent_id = agent_row['agent_id']
                
                # Get agent's capabilities
                agent = self.get_agent(agent_id)
                if not agent:
                    continue
                
                capabilities = agent.get('capabilities', [])
                
                # Find tasks that can be redistributed (pending tasks only)
                cursor.execute("""
                    SELECT id, title, estimated_hours
                    FROM tasks
                    WHERE assignee = ? AND status = 'pending'
                    ORDER BY priority ASC, created_at DESC
                    LIMIT 5
                """, (agent_id,))
                
                tasks_to_redistribute = cursor.fetchall()
                
                for task in tasks_to_redistribute:
                    # Find a less loaded agent with matching capabilities
                    target_agent = self.find_least_loaded_agent(capabilities)
                    
                    if target_agent and target_agent != agent_id:
                        # Check target agent's load is significantly lower
                        target_load = self.calculate_agent_load(target_agent)
                        
                        if target_load < (overload_threshold - 20):  # At least 20 points lower
                            # Reassign the task
                            cursor.execute("""
                                UPDATE tasks
                                SET assignee = ?, updated_at = CURRENT_TIMESTAMP
                                WHERE id = ?
                            """, (target_agent, task['id']))
                            
                            # Record in task history
                            cursor.execute("""
                                INSERT INTO agent_task_history
                                (agent_id, task_id, action, metadata)
                                VALUES (?, ?, 'reassigned', ?)
                            """, (agent_id, task['id'], 
                                  json.dumps({'from': agent_id, 'to': target_agent, 
                                            'reason': 'workload_redistribution'})))
                            
                            redistributed += 1
                            logger.info(f"Redistributed task {task['id']} from {agent_id} to {target_agent}")
                            
                            # Update workload for both agents
                            self.track_workload(agent_id)
                            self.track_workload(target_agent)
                            
                            # Stop if agent is no longer overloaded
                            if self.calculate_agent_load(agent_id) < overload_threshold:
                                break
            
            self.conn.commit()
            
            if redistributed > 0:
                logger.info(f"Successfully redistributed {redistributed} tasks")
            
            return redistributed
            
        except Exception as e:
            logger.error(f"Failed to redistribute tasks: {e}")
            self.conn.rollback()
            return 0
    
    # ========== Performance Metrics (FR-019) ==========
    
    def record_metric(self, agent_id: str, metric_type: str, value: float, 
                     task_id: str = None) -> bool:
        """
        Record a performance metric for an agent
        
        @implements FR-019: Agent Performance Metrics
        
        Args:
            agent_id: Agent identifier
            metric_type: Type of metric (completion_rate, speed, quality, etc.)
            value: Metric value
            task_id: Optional task ID for task-specific metrics
        
        Returns:
            True if metric recorded successfully
        """
        try:
            cursor = self.conn.cursor()
            
            cursor.execute("""
                INSERT INTO agent_metrics
                (agent_id, metric_type, metric_value, task_id, recorded_at)
                VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP)
            """, (agent_id, metric_type, value, task_id))
            
            self.conn.commit()
            logger.debug(f"Recorded metric {metric_type}={value} for agent {agent_id}")
            return True
            
        except Exception as e:
            logger.error(f"Failed to record metric for {agent_id}: {e}")
            return False
    
    def get_agent_metrics(self, agent_id: str, time_range: str = 'daily') -> Dict:
        """
        Get aggregated performance metrics for an agent
        
        @implements FR-019: Agent Performance Metrics
        
        Args:
            agent_id: Agent identifier
            time_range: Time range for metrics (daily, weekly, monthly)
        
        Returns:
            Dictionary of aggregated metrics
        """
        try:
            cursor = self.conn.cursor()
            
            # Determine time filter
            if time_range == 'daily':
                time_filter = "datetime('now', '-1 day')"
            elif time_range == 'weekly':
                time_filter = "datetime('now', '-7 days')"
            elif time_range == 'monthly':
                time_filter = "datetime('now', '-30 days')"
            else:
                time_filter = "datetime('now', '-1 day')"
            
            # Get completion rate
            cursor.execute(f"""
                SELECT COUNT(*) as total,
                       SUM(CASE WHEN metric_value > 0 THEN 1 ELSE 0 END) as successful
                FROM agent_metrics
                WHERE agent_id = ? 
                AND metric_type = 'task_completion'
                AND recorded_at > {time_filter}
            """, (agent_id,))
            
            completion_data = cursor.fetchone()
            completion_rate = 0
            if completion_data and completion_data['total'] > 0:
                completion_rate = (completion_data['successful'] / completion_data['total']) * 100
            
            # Get average task duration
            cursor.execute(f"""
                SELECT AVG(metric_value) as avg_duration
                FROM agent_metrics
                WHERE agent_id = ? 
                AND metric_type = 'task_duration'
                AND recorded_at > {time_filter}
            """, (agent_id,))
            
            duration_data = cursor.fetchone()
            avg_duration = duration_data['avg_duration'] if duration_data and duration_data['avg_duration'] else 0
            
            # Get quality score (if tracked)
            cursor.execute(f"""
                SELECT AVG(metric_value) as avg_quality
                FROM agent_metrics
                WHERE agent_id = ? 
                AND metric_type = 'quality_score'
                AND recorded_at > {time_filter}
            """, (agent_id,))
            
            quality_data = cursor.fetchone()
            avg_quality = quality_data['avg_quality'] if quality_data and quality_data['avg_quality'] else 0
            
            # Count total tasks handled
            cursor.execute(f"""
                SELECT COUNT(DISTINCT task_id) as task_count
                FROM agent_metrics
                WHERE agent_id = ? 
                AND task_id IS NOT NULL
                AND recorded_at > {time_filter}
            """, (agent_id,))
            
            task_data = cursor.fetchone()
            task_count = task_data['task_count'] if task_data else 0
            
            # Calculate performance score (0-100)
            # Formula: (completion_rate * 0.4) + (100 - min(avg_duration, 100)) * 0.3 + (avg_quality * 0.3)
            performance_score = (
                (completion_rate * 0.4) + 
                ((100 - min(avg_duration, 100)) * 0.3) + 
                (avg_quality * 0.3)
            )
            
            return {
                'agent_id': agent_id,
                'time_range': time_range,
                'completion_rate': round(completion_rate, 2),
                'average_task_duration': round(avg_duration, 2),
                'quality_score': round(avg_quality, 2),
                'tasks_handled': task_count,
                'performance_score': round(performance_score, 2)
            }
            
        except Exception as e:
            logger.error(f"Failed to get metrics for {agent_id}: {e}")
            return {}
    
    # ========== Communication Channels (FR-020) ==========
    
    def send_message(self, from_agent: str, to_agent: str, content: str, 
                    priority: str = 'normal') -> bool:
        """
        Send a direct message from one agent to another
        
        @implements FR-020: Agent Communication Channels
        
        Args:
            from_agent: Sender agent ID
            to_agent: Recipient agent ID
            content: Message content
            priority: Message priority (low, normal, high, critical)
        
        Returns:
            True if message sent successfully
        """
        try:
            cursor = self.conn.cursor()
            
            cursor.execute("""
                INSERT INTO agent_messages
                (from_agent, to_agent, message_type, priority, content, created_at)
                VALUES (?, ?, 'direct', ?, ?, CURRENT_TIMESTAMP)
            """, (from_agent, to_agent, priority, content))
            
            self.conn.commit()
            logger.info(f"Message sent from {from_agent} to {to_agent}")
            return True
            
        except Exception as e:
            logger.error(f"Failed to send message: {e}")
            return False
    
    def broadcast_message(self, from_agent: str, content: str, 
                         priority: str = 'normal') -> bool:
        """
        Broadcast a message to all active agents
        
        @implements FR-020: Agent Communication Channels
        
        Args:
            from_agent: Sender agent ID
            content: Message content
            priority: Message priority (low, normal, high, critical)
        
        Returns:
            True if broadcast sent successfully
        """
        try:
            cursor = self.conn.cursor()
            
            cursor.execute("""
                INSERT INTO agent_messages
                (from_agent, to_agent, message_type, priority, content, created_at)
                VALUES (?, NULL, 'broadcast', ?, ?, CURRENT_TIMESTAMP)
            """, (from_agent, priority, content))
            
            self.conn.commit()
            logger.info(f"Broadcast message sent from {from_agent}")
            return True
            
        except Exception as e:
            logger.error(f"Failed to broadcast message: {e}")
            return False
    
    def receive_messages(self, agent_id: str, status: str = 'unread') -> List[Dict]:
        """
        Receive messages for an agent
        
        @implements FR-020: Agent Communication Channels
        
        Args:
            agent_id: Recipient agent ID
            status: Filter by message status (unread, read, acknowledged)
        
        Returns:
            List of message dictionaries
        """
        try:
            cursor = self.conn.cursor()
            
            # Get direct messages and broadcasts
            cursor.execute("""
                SELECT m.*, a.name as sender_name
                FROM agent_messages m
                JOIN agents a ON m.from_agent = a.id
                WHERE (m.to_agent = ? OR (m.to_agent IS NULL AND m.message_type = 'broadcast'))
                AND m.status = ?
                ORDER BY 
                    CASE m.priority 
                        WHEN 'critical' THEN 0
                        WHEN 'high' THEN 1
                        WHEN 'normal' THEN 2
                        WHEN 'low' THEN 3
                    END,
                    m.created_at DESC
            """, (agent_id, status))
            
            messages = []
            for row in cursor.fetchall():
                message = dict(row)
                
                # Mark as read if it was unread
                if status == 'unread':
                    cursor.execute("""
                        UPDATE agent_messages
                        SET status = 'read', read_at = CURRENT_TIMESTAMP
                        WHERE id = ?
                    """, (message['id'],))
                
                messages.append(message)
            
            if status == 'unread' and messages:
                self.conn.commit()
                logger.debug(f"Marked {len(messages)} messages as read for {agent_id}")
            
            return messages
            
        except Exception as e:
            logger.error(f"Failed to receive messages for {agent_id}: {e}")
            return []
    
    def acknowledge_message(self, message_id: int, agent_id: str) -> bool:
        """
        Acknowledge receipt of a message
        
        @implements FR-020: Agent Communication Channels
        
        Args:
            message_id: Message ID to acknowledge
            agent_id: Agent acknowledging the message
        
        Returns:
            True if acknowledgment successful
        """
        try:
            cursor = self.conn.cursor()
            
            cursor.execute("""
                UPDATE agent_messages
                SET status = 'acknowledged', read_at = CURRENT_TIMESTAMP
                WHERE id = ? AND (to_agent = ? OR to_agent IS NULL)
            """, (message_id, agent_id))
            
            self.conn.commit()
            return cursor.rowcount > 0
            
        except Exception as e:
            logger.error(f"Failed to acknowledge message {message_id}: {e}")
            return False