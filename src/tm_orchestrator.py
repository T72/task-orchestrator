#!/usr/bin/env python3
"""
Task Orchestrator - Orchestrator Interface
For orchestrating agents to create, assign, and monitor tasks

@implements FR-CORE-1: Orchestrating agent interface for task management
@implements FR-027: Agent specialization routing and coordination
@implements FR-028: Cross-agent task delegation capabilities
@implements FR-030: Agent performance monitoring and tracking
"""

import json
import sqlite3
import uuid
from datetime import datetime
from pathlib import Path
from typing import List, Dict, Optional
import hashlib
import yaml
import sys

class Orchestrator:
    """Interface specifically for orchestrating agents"""
    
    def __init__(self, orchestrator_id: str = None):
        self.orchestrator_id = orchestrator_id or self._generate_id()
        self.repo_root = self._find_repo_root()
        self.db_dir = self.repo_root / ".task-orchestrator"
        self.db_path = self.db_dir / "tasks.db"
        self.handoff_dir = self.db_dir / "handoffs"
        self._init_storage()
    
    def _generate_id(self) -> str:
        return f"orchestrator_{hashlib.md5(str(datetime.now()).encode()).hexdigest()[:6]}"
    
    def _find_repo_root(self) -> Path:
        try:
            import subprocess
            result = subprocess.run(
                ["git", "rev-parse", "--show-toplevel"],
                capture_output=True, text=True, check=True
            )
            return Path(result.stdout.strip())
        except:
            return Path.cwd()
    
    def _init_storage(self):
        """Initialize storage structure"""
        self.db_dir.mkdir(parents=True, exist_ok=True)
        self.handoff_dir.mkdir(parents=True, exist_ok=True)
        
        with sqlite3.connect(str(self.db_path)) as conn:
            conn.execute("""
                CREATE TABLE IF NOT EXISTS orchestration (
                    project_id TEXT PRIMARY KEY,
                    title TEXT NOT NULL,
                    description TEXT,
                    orchestrator_id TEXT NOT NULL,
                    created_at TEXT NOT NULL,
                    status TEXT DEFAULT 'planning'
                )
            """)
            
            conn.execute("""
                CREATE TABLE IF NOT EXISTS work_items (
                    item_id TEXT PRIMARY KEY,
                    project_id TEXT NOT NULL,
                    title TEXT NOT NULL,
                    description TEXT,
                    requirements TEXT,
                    assigned_to TEXT,
                    status TEXT DEFAULT 'pending',
                    dependencies TEXT,
                    created_at TEXT NOT NULL,
                    assigned_at TEXT,
                    completed_at TEXT,
                    deliverables TEXT
                )
            """)
            
            conn.commit()
    
    def create_project(self, title: str, description: str = None) -> str:
        """Create a new orchestration project"""
        project_id = uuid.uuid4().hex[:8]
        now = datetime.now().isoformat()
        
        with sqlite3.connect(str(self.db_path)) as conn:
            conn.execute("""
                INSERT INTO orchestration (project_id, title, description, orchestrator_id, created_at)
                VALUES (?, ?, ?, ?, ?)
            """, (project_id, title, description, self.orchestrator_id, now))
            conn.commit()
        
        # Create project context file
        context_file = self.handoff_dir / f"{project_id}_context.yaml"
        context = {
            "project_id": project_id,
            "title": title,
            "description": description,
            "orchestrator": self.orchestrator_id,
            "created": now,
            "global_requirements": [],
            "shared_resources": [],
            "coordination_points": []
        }
        
        with open(context_file, 'w') as f:
            yaml.dump(context, f)
        
        print(f"✓ Project created: {project_id}")
        return project_id
    
    def create_work_item(self, project_id: str, title: str, 
                        description: str = None,
                        requirements: List[str] = None,
                        dependencies: List[str] = None) -> str:
        """Create a work item for delegation"""
        item_id = uuid.uuid4().hex[:8]
        now = datetime.now().isoformat()
        
        with sqlite3.connect(str(self.db_path)) as conn:
            conn.execute("""
                INSERT INTO work_items 
                (item_id, project_id, title, description, requirements, dependencies, created_at, status)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                item_id, 
                project_id, 
                title, 
                description,
                json.dumps(requirements or []),
                json.dumps(dependencies or []),
                now,
                'pending'
            ))
            conn.commit()
        
        print(f"✓ Work item created: {item_id} - {title}")
        return item_id
    
    def assign_work(self, item_id: str, agent_id: str, 
                   context: Dict = None, resources: List[str] = None) -> str:
        """Assign work item to a specialist agent with handoff package"""
        
        # Get work item details
        with sqlite3.connect(str(self.db_path)) as conn:
            cursor = conn.execute("""
                SELECT w.*, o.title as project_title, o.description as project_desc
                FROM work_items w
                JOIN orchestration o ON w.project_id = o.project_id
                WHERE w.item_id = ?
            """, (item_id,))
            work_item = cursor.fetchone()
            
            if not work_item:
                raise ValueError(f"Work item {item_id} not found")
            
            # Update assignment
            conn.execute("""
                UPDATE work_items 
                SET assigned_to = ?, assigned_at = ?, status = 'assigned'
                WHERE item_id = ?
            """, (agent_id, datetime.now().isoformat(), item_id))
            conn.commit()
        
        # Create handoff package
        handoff_file = self.handoff_dir / f"{item_id}_handoff.json"
        handoff_package = {
            "handoff_version": "1.0",
            "item_id": item_id,
            "assigned_to": agent_id,
            "assigned_by": self.orchestrator_id,
            "assigned_at": datetime.now().isoformat(),
            
            "task": {
                "title": work_item[2],  # title
                "description": work_item[3],  # description
                "requirements": json.loads(work_item[4] or "[]"),
                "dependencies": json.loads(work_item[6] or "[]")
            },
            
            "project_context": {
                "project_id": work_item[1],
                "project_title": work_item[11],
                "project_description": work_item[12]
            },
            
            "provided_context": context or {},
            "provided_resources": resources or [],
            
            "expected_deliverables": [
                "Status updates via progress reports",
                "Completion notification",
                "Any discoveries or blockers"
            ],
            
            "communication": {
                "progress_file": f"{item_id}_progress.json",
                "completion_file": f"{item_id}_completion.json",
                "discovery_file": f"{item_id}_discoveries.json"
            }
        }
        
        with open(handoff_file, 'w') as f:
            json.dump(handoff_package, f, indent=2)
        
        print(f"✓ Work item {item_id} assigned to {agent_id}")
        print(f"  Handoff package: {handoff_file}")
        
        # Also create a simple notification file for the agent
        notification_file = self.handoff_dir / f"pending_{agent_id}.txt"
        with open(notification_file, 'a') as f:
            f.write(f"{item_id}\n")
        
        return str(handoff_file)
    
    def check_progress(self, item_id: str = None, project_id: str = None) -> List[Dict]:
        """Check progress on work items"""
        progress_reports = []
        
        if item_id:
            # Check specific item
            progress_file = self.handoff_dir / f"{item_id}_progress.json"
            if progress_file.exists():
                with open(progress_file, 'r') as f:
                    progress_reports.append(json.load(f))
        
        elif project_id:
            # Check all items in project
            with sqlite3.connect(str(self.db_path)) as conn:
                cursor = conn.execute("""
                    SELECT item_id, title, assigned_to, status
                    FROM work_items
                    WHERE project_id = ?
                """, (project_id,))
                
                for row in cursor:
                    item_id = row[0]
                    progress_file = self.handoff_dir / f"{item_id}_progress.json"
                    if progress_file.exists():
                        with open(progress_file, 'r') as f:
                            data = json.load(f)
                            data['title'] = row[1]
                            data['assigned_to'] = row[2]
                            data['status'] = row[3]
                            progress_reports.append(data)
                    else:
                        progress_reports.append({
                            'item_id': item_id,
                            'title': row[1],
                            'assigned_to': row[2],
                            'status': row[3],
                            'updates': []
                        })
        
        return progress_reports
    
    def get_discoveries(self, project_id: str) -> List[Dict]:
        """Get all discoveries from work items"""
        discoveries = []
        
        with sqlite3.connect(str(self.db_path)) as conn:
            cursor = conn.execute("""
                SELECT item_id FROM work_items WHERE project_id = ?
            """, (project_id,))
            
            for row in cursor:
                item_id = row[0]
                discovery_file = self.handoff_dir / f"{item_id}_discoveries.json"
                if discovery_file.exists():
                    with open(discovery_file, 'r') as f:
                        item_discoveries = json.load(f)
                        discoveries.extend(item_discoveries)
        
        return discoveries
    
    def complete_project(self, project_id: str) -> Dict:
        """Complete orchestration project and gather deliverables"""
        deliverables = {
            "project_id": project_id,
            "completed_at": datetime.now().isoformat(),
            "work_items": []
        }
        
        with sqlite3.connect(str(self.db_path)) as conn:
            cursor = conn.execute("""
                SELECT item_id, title, assigned_to, status
                FROM work_items
                WHERE project_id = ?
            """, (project_id,))
            
            for row in cursor:
                item_id = row[0]
                completion_file = self.handoff_dir / f"{item_id}_completion.json"
                
                item_deliverable = {
                    "item_id": item_id,
                    "title": row[1],
                    "assigned_to": row[2],
                    "status": row[3]
                }
                
                if completion_file.exists():
                    with open(completion_file, 'r') as f:
                        item_deliverable["completion"] = json.load(f)
                
                deliverables["work_items"].append(item_deliverable)
            
            # Update project status
            conn.execute("""
                UPDATE orchestration SET status = 'completed' WHERE project_id = ?
            """, (project_id,))
            conn.commit()
        
        return deliverables
    
    def get_unassigned_work(self, project_id: str = None) -> List[Dict]:
        """Get list of unassigned work items"""
        query = "SELECT * FROM work_items WHERE assigned_to IS NULL"
        params = []
        
        if project_id:
            query += " AND project_id = ?"
            params.append(project_id)
        
        with sqlite3.connect(str(self.db_path)) as conn:
            conn.row_factory = sqlite3.Row
            cursor = conn.execute(query, params)
            return [dict(row) for row in cursor]
    
    def update_coordination(self, project_id: str, checkpoint: str, ready_for: List[str] = None):
        """Add coordination checkpoint"""
        context_file = self.handoff_dir / f"{project_id}_context.yaml"
        
        if context_file.exists():
            with open(context_file, 'r') as f:
                context = yaml.safe_load(f)
            
            context["coordination_points"].append({
                "timestamp": datetime.now().isoformat(),
                "checkpoint": checkpoint,
                "ready_for": ready_for or []
            })
            
            with open(context_file, 'w') as f:
                yaml.dump(context, f)
            
            print(f"✓ Coordination point added: {checkpoint}")


def main():
    """CLI for orchestrator"""
    import argparse
    
    parser = argparse.ArgumentParser(
        description="Task Orchestrator - For orchestrating agents",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Example Workflow:
  1. orchestrate project "Build API"
  2. orchestrate create PROJECT_ID "Database design" 
  3. orchestrate assign ITEM_ID database_expert
  4. orchestrate progress PROJECT_ID
        """
    )
    
    parser.add_argument("--id", help="Orchestrator ID", default=None)
    
    subparsers = parser.add_subparsers(dest="command", help="Commands")
    
    # Create project
    project_parser = subparsers.add_parser("project", help="Create orchestration project")
    project_parser.add_argument("title", help="Project title")
    project_parser.add_argument("-d", "--description", help="Project description")
    
    # Create work item
    create_parser = subparsers.add_parser("create", help="Create work item")
    create_parser.add_argument("project_id", help="Project ID")
    create_parser.add_argument("title", help="Work item title")
    create_parser.add_argument("-d", "--description", help="Description")
    create_parser.add_argument("-r", "--requirements", nargs="+", help="Requirements")
    create_parser.add_argument("--depends-on", nargs="+", help="Dependencies")
    
    # Assign work
    assign_parser = subparsers.add_parser("assign", help="Assign work to agent")
    assign_parser.add_argument("item_id", help="Work item ID")
    assign_parser.add_argument("agent_id", help="Agent to assign to")
    
    # Check progress
    progress_parser = subparsers.add_parser("progress", help="Check progress")
    progress_parser.add_argument("id", help="Project or item ID")
    progress_parser.add_argument("--type", choices=["project", "item"], default="project")
    
    # Get discoveries
    discover_parser = subparsers.add_parser("discoveries", help="Get discoveries")
    discover_parser.add_argument("project_id", help="Project ID")
    
    # Complete project
    complete_parser = subparsers.add_parser("complete", help="Complete project")
    complete_parser.add_argument("project_id", help="Project ID")
    
    # List unassigned
    unassigned_parser = subparsers.add_parser("unassigned", help="List unassigned work")
    unassigned_parser.add_argument("--project", help="Filter by project")
    
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        return
    
    orchestrator = Orchestrator(args.id)
    
    if args.command == "project":
        project_id = orchestrator.create_project(args.title, args.description)
        print(f"Project ID: {project_id}")
    
    elif args.command == "create":
        item_id = orchestrator.create_work_item(
            args.project_id, 
            args.title,
            args.description,
            args.requirements,
            args.depends_on
        )
        print(f"Work item ID: {item_id}")
    
    elif args.command == "assign":
        handoff = orchestrator.assign_work(args.item_id, args.agent_id)
        print(f"Handoff created: {handoff}")
    
    elif args.command == "progress":
        if args.type == "item":
            reports = orchestrator.check_progress(item_id=args.id)
        else:
            reports = orchestrator.check_progress(project_id=args.id)
        
        for report in reports:
            print(f"\n{report.get('title', report.get('item_id'))}: {report.get('status')}")
            for update in report.get('updates', []):
                print(f"  - {update}")
    
    elif args.command == "discoveries":
        discoveries = orchestrator.get_discoveries(args.project_id)
        for discovery in discoveries:
            print(f"- {discovery.get('timestamp')}: {discovery.get('discovery')}")
    
    elif args.command == "complete":
        deliverables = orchestrator.complete_project(args.project_id)
        print(f"Project completed: {len(deliverables['work_items'])} items")
    
    elif args.command == "unassigned":
        items = orchestrator.get_unassigned_work(args.project)
        for item in items:
            print(f"- {item['item_id']}: {item['title']}")


if __name__ == "__main__":
    main()