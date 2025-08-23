"""
Migration system for Task Orchestrator database schema changes.
Provides safe, reversible schema migrations with backup capabilities.

@implements NFR-001: Performance requirements through efficient database operations
@implements NFR-002: Scalability support through schema migration system
@implements FR-032: Database persistence with migration capabilities
"""

import os
import sqlite3
import shutil
from datetime import datetime
from pathlib import Path
from typing import Optional, List, Dict, Any
import json


class MigrationManager:
    """
    Manages database schema migrations for Task Orchestrator.
    
    @implements NFR-007: Migration Safety with automatic backup
    @implements TECH-001: Database Path management and schema evolution
    @implements SYS-002: Error Recovery through rollback capabilities
    """
    
    def __init__(self, db_path: str):
        self.db_path = db_path
        self.base_dir = Path(db_path).parent
        self.backups_dir = self.base_dir / "backups"
        self.migrations_dir = Path(__file__).parent
        self.backups_dir.mkdir(exist_ok=True)
        
        # Initialize migrations tracking table
        self._init_migrations_table()
    
    def _init_migrations_table(self):
        """Create migrations tracking table if it doesn't exist."""
        with sqlite3.connect(self.db_path) as conn:
            conn.execute("""
                CREATE TABLE IF NOT EXISTS schema_migrations (
                    version TEXT PRIMARY KEY,
                    applied_at TEXT NOT NULL,
                    description TEXT
                )
            """)
            conn.commit()
    
    def get_applied_migrations(self) -> List[str]:
        """Get list of already applied migration versions."""
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.execute(
                "SELECT version FROM schema_migrations ORDER BY version"
            )
            return [row[0] for row in cursor.fetchall()]
    
    def get_pending_migrations(self) -> List[Dict[str, Any]]:
        """Get list of migrations that haven't been applied yet."""
        applied = set(self.get_applied_migrations())
        pending = []
        
        # Load migration definitions
        migrations_file = self.migrations_dir / "migrations.json"
        if migrations_file.exists():
            with open(migrations_file) as f:
                all_migrations = json.load(f)
                
            for migration in all_migrations:
                if migration["version"] not in applied:
                    pending.append(migration)
        
        return pending
    
    def create_backup(self) -> str:
        """Create a backup of the current database."""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_path = self.backups_dir / f"tasks_backup_{timestamp}.db"
        
        # Copy the database file
        shutil.copy2(self.db_path, backup_path)
        
        return str(backup_path)
    
    def apply_migration(self, version: str, up_sql: str, description: str = "") -> bool:
        """Apply a single migration."""
        try:
            with sqlite3.connect(self.db_path) as conn:
                # Start transaction
                conn.execute("BEGIN TRANSACTION")
                
                # Apply the migration SQL
                for statement in up_sql.split(';'):
                    if statement.strip():
                        # Make ALTER TABLE ADD COLUMN idempotent
                        if "ALTER TABLE" in statement and "ADD COLUMN" in statement:
                            # Check if column already exists
                            parts = statement.split()
                            if len(parts) >= 5:
                                table_name = parts[2]
                                column_name = parts[5]
                                cursor = conn.execute(f"PRAGMA table_info({table_name})")
                                columns = [row[1] for row in cursor.fetchall()]
                                if column_name in columns:
                                    print(f"  Column {column_name} already exists, skipping")
                                    continue
                        conn.execute(statement)
                
                # Record the migration
                conn.execute(
                    "INSERT INTO schema_migrations (version, applied_at, description) VALUES (?, ?, ?)",
                    (version, datetime.now().isoformat(), description)
                )
                
                # Commit transaction
                conn.commit()
                return True
                
        except Exception as e:
            # Rollback on error
            conn.rollback()
            raise Exception(f"Migration {version} failed: {e}")
    
    def rollback_migration(self, version: str, down_sql: str) -> bool:
        """Rollback a single migration."""
        try:
            with sqlite3.connect(self.db_path) as conn:
                # Start transaction
                conn.execute("BEGIN TRANSACTION")
                
                # Apply the rollback SQL
                for statement in down_sql.split(';'):
                    if statement.strip():
                        conn.execute(statement)
                
                # Remove migration record
                conn.execute(
                    "DELETE FROM schema_migrations WHERE version = ?",
                    (version,)
                )
                
                # Commit transaction
                conn.commit()
                return True
                
        except Exception as e:
            # Rollback on error
            conn.rollback()
            raise Exception(f"Rollback of {version} failed: {e}")
    
    def get_status(self) -> Dict[str, Any]:
        """Get current migration status."""
        applied = self.get_applied_migrations()
        pending = self.get_pending_migrations()
        
        return {
            "applied": applied,
            "pending": [m["version"] for m in pending],
            "current_version": applied[-1] if applied else None,
            "up_to_date": len(pending) == 0
        }
    
    def dry_run(self, version: str, up_sql: str) -> List[str]:
        """Preview what a migration would do without applying it."""
        changes = []
        
        # Parse SQL to describe changes
        for statement in up_sql.split(';'):
            stmt = statement.strip().upper()
            if stmt.startswith('ALTER TABLE'):
                if 'ADD COLUMN' in stmt:
                    changes.append(f"Would add column to table")
                elif 'DROP COLUMN' in stmt:
                    changes.append(f"Would remove column from table")
            elif stmt.startswith('CREATE TABLE'):
                changes.append(f"Would create new table")
            elif stmt.startswith('CREATE INDEX'):
                changes.append(f"Would create new index")
        
        return changes