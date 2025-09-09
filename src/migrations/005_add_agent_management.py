#!/usr/bin/env python3
"""
Migration: Add Agent Management Tables
Version: 005
Date: 2025-09-09
Description: Adds tables for agent workload distribution (FR-017), 
            performance metrics (FR-019), and communication channels (FR-020)

@implements FR-017: Agent Workload Distribution
@implements FR-019: Agent Performance Metrics  
@implements FR-020: Agent Communication Channels
"""

import sqlite3
import json
from datetime import datetime
from pathlib import Path

def get_db_path():
    """Get the database path from environment or default"""
    import os
    db_path = os.environ.get('TM_DB_PATH', '.task-orchestrator/tasks.db')
    return db_path

def migrate_up(conn=None):
    """Apply the migration - create agent management tables"""
    close_conn = False
    if conn is None:
        db_path = get_db_path()
        Path(db_path).parent.mkdir(parents=True, exist_ok=True)
        conn = sqlite3.connect(db_path)
        close_conn = True
    
    cursor = conn.cursor()
    
    try:
        # Ensure schema_migrations table exists
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS schema_migrations (
                version TEXT PRIMARY KEY,
                applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        
        # Create agents table for agent registration and discovery
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS agents (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                type TEXT,
                capabilities TEXT,  -- JSON array of capabilities
                status TEXT DEFAULT 'active',  -- active, inactive, busy
                last_heartbeat TIMESTAMP,
                registered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                metadata TEXT  -- JSON for additional agent data
            )
        ''')
        
        # Create agent_workload table for tracking workload (FR-017)
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS agent_workload (
                agent_id TEXT NOT NULL,
                task_count INTEGER DEFAULT 0,
                estimated_hours REAL DEFAULT 0,
                completed_today INTEGER DEFAULT 0,
                average_completion_time REAL,
                current_load_score REAL,  -- Calculated load score
                last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                PRIMARY KEY (agent_id),
                FOREIGN KEY (agent_id) REFERENCES agents(id)
            )
        ''')
        
        # Create agent_metrics table for performance tracking (FR-019)
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS agent_metrics (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                agent_id TEXT NOT NULL,
                metric_type TEXT NOT NULL,  -- completion_rate, speed, quality, etc.
                metric_value REAL NOT NULL,
                task_id TEXT,  -- Optional reference to specific task
                recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                time_window TEXT,  -- daily, weekly, monthly
                metadata TEXT,  -- JSON for additional context
                FOREIGN KEY (agent_id) REFERENCES agents(id)
            )
        ''')
        
        # Create agent_messages table for communication (FR-020)
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS agent_messages (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                from_agent TEXT NOT NULL,
                to_agent TEXT,  -- NULL for broadcasts
                message_type TEXT NOT NULL,  -- direct, broadcast, system
                priority TEXT DEFAULT 'normal',  -- low, normal, high, critical
                content TEXT NOT NULL,
                status TEXT DEFAULT 'unread',  -- unread, read, acknowledged
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                read_at TIMESTAMP,
                metadata TEXT,  -- JSON for additional message data
                FOREIGN KEY (from_agent) REFERENCES agents(id),
                FOREIGN KEY (to_agent) REFERENCES agents(id)
            )
        ''')
        
        # Create agent_task_history for tracking agent-task relationships
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS agent_task_history (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                agent_id TEXT NOT NULL,
                task_id TEXT NOT NULL,
                action TEXT NOT NULL,  -- assigned, completed, failed, reassigned
                timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                duration_minutes REAL,
                metadata TEXT,  -- JSON for additional context
                FOREIGN KEY (agent_id) REFERENCES agents(id)
            )
        ''')
        
        # Create indexes for performance
        cursor.execute('CREATE INDEX IF NOT EXISTS idx_agent_workload_load ON agent_workload(current_load_score)')
        cursor.execute('CREATE INDEX IF NOT EXISTS idx_agent_metrics_agent ON agent_metrics(agent_id, metric_type)')
        cursor.execute('CREATE INDEX IF NOT EXISTS idx_agent_messages_recipient ON agent_messages(to_agent, status)')
        cursor.execute('CREATE INDEX IF NOT EXISTS idx_agent_task_history ON agent_task_history(agent_id, task_id)')
        
        # Record migration
        cursor.execute('''
            INSERT OR IGNORE INTO schema_migrations (version, applied_at)
            VALUES (?, ?)
        ''', ('005_add_agent_management', datetime.now().isoformat()))
        
        conn.commit()
        print("✅ Agent management tables created successfully")
        
    except Exception as e:
        conn.rollback()
        print(f"❌ Migration failed: {e}")
        raise
    finally:
        if close_conn:
            conn.close()

def migrate_down(conn=None):
    """Rollback the migration - remove agent management tables"""
    close_conn = False
    if conn is None:
        db_path = get_db_path()
        conn = sqlite3.connect(db_path)
        close_conn = True
    
    cursor = conn.cursor()
    
    try:
        # Drop indexes first
        cursor.execute('DROP INDEX IF EXISTS idx_agent_workload_load')
        cursor.execute('DROP INDEX IF EXISTS idx_agent_metrics_agent')
        cursor.execute('DROP INDEX IF EXISTS idx_agent_messages_recipient')
        cursor.execute('DROP INDEX IF EXISTS idx_agent_task_history')
        
        # Drop tables in reverse order of dependencies
        cursor.execute('DROP TABLE IF EXISTS agent_task_history')
        cursor.execute('DROP TABLE IF EXISTS agent_messages')
        cursor.execute('DROP TABLE IF EXISTS agent_metrics')
        cursor.execute('DROP TABLE IF EXISTS agent_workload')
        cursor.execute('DROP TABLE IF EXISTS agents')
        
        # Remove migration record
        cursor.execute('''
            DELETE FROM schema_migrations WHERE version = ?
        ''', ('005_add_agent_management',))
        
        conn.commit()
        print("✅ Agent management tables removed successfully")
        
    except Exception as e:
        conn.rollback()
        print(f"❌ Rollback failed: {e}")
        raise
    finally:
        if close_conn:
            conn.close()

if __name__ == '__main__':
    import sys
    
    if len(sys.argv) > 1 and sys.argv[1] == 'down':
        migrate_down()
    else:
        migrate_up()