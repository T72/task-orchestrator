#!/usr/bin/env python3
"""
Task Orchestrator - Worker Interface
For specialized agents to receive and complete assigned work
"""

import json
import os
from datetime import datetime
from pathlib import Path
from typing import List, Dict, Optional

class Worker:
    """Interface specifically for worker/specialist agents"""
    
    def __init__(self, agent_id: str = None):
        self.agent_id = agent_id or os.environ.get('AGENT_ID', 'worker_' + str(os.getpid()))
        self.repo_root = self._find_repo_root()
        self.handoff_dir = self.repo_root / ".task-orchestrator" / "handoffs"
        self.workspace_dir = self.repo_root / ".task-orchestrator" / "workspace" / self.agent_id
        self.workspace_dir.mkdir(parents=True, exist_ok=True)
    
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
    
    def check_assignments(self) -> List[str]:
        """Check for assigned work items"""
        assignments = []
        
        # Check notification file
        notification_file = self.handoff_dir / f"pending_{self.agent_id}.txt"
        if notification_file.exists():
            with open(notification_file, 'r') as f:
                assignments = [line.strip() for line in f if line.strip()]
            
            # Clear notification after reading
            notification_file.unlink()
        
        # Also check for any handoff files assigned to us
        for handoff_file in self.handoff_dir.glob("*_handoff.json"):
            with open(handoff_file, 'r') as f:
                handoff = json.load(f)
                if handoff.get('assigned_to') == self.agent_id:
                    item_id = handoff.get('item_id')
                    if item_id not in assignments:
                        assignments.append(item_id)
        
        return assignments
    
    def get_work(self, item_id: str) -> Dict:
        """Get work item details from handoff package"""
        handoff_file = self.handoff_dir / f"{item_id}_handoff.json"
        
        if not handoff_file.exists():
            raise FileNotFoundError(f"No work item {item_id} found for {self.agent_id}")
        
        with open(handoff_file, 'r') as f:
            handoff = json.load(f)
        
        # Verify assignment
        if handoff.get('assigned_to') != self.agent_id:
            raise PermissionError(f"Work item {item_id} is assigned to {handoff.get('assigned_to')}, not {self.agent_id}")
        
        # Create simplified work view
        work = {
            "item_id": item_id,
            "title": handoff['task']['title'],
            "description": handoff['task']['description'],
            "requirements": handoff['task']['requirements'],
            "context": handoff.get('provided_context', {}),
            "resources": handoff.get('provided_resources', []),
            "project": handoff['project_context']['project_title'],
            "deliverables": handoff.get('expected_deliverables', [])
        }
        
        return work
    
    def update_progress(self, item_id: str, update: str, percentage: int = None):
        """Report progress on work item"""
        progress_file = self.handoff_dir / f"{item_id}_progress.json"
        
        # Load existing progress or create new
        if progress_file.exists():
            with open(progress_file, 'r') as f:
                progress = json.load(f)
        else:
            progress = {
                "item_id": item_id,
                "agent_id": self.agent_id,
                "updates": []
            }
        
        # Add update
        progress_update = {
            "timestamp": datetime.now().isoformat(),
            "message": update,
            "percentage": percentage
        }
        progress["updates"].append(progress_update)
        
        # Save progress
        with open(progress_file, 'w') as f:
            json.dump(progress, f, indent=2)
        
        print(f"✓ Progress updated for {item_id}")
    
    def share_discovery(self, item_id: str, discovery: str, impact: str = None):
        """Share a discovery or finding"""
        discovery_file = self.handoff_dir / f"{item_id}_discoveries.json"
        
        # Load existing discoveries or create new
        if discovery_file.exists():
            with open(discovery_file, 'r') as f:
                discoveries = json.load(f)
        else:
            discoveries = []
        
        # Add discovery
        discoveries.append({
            "timestamp": datetime.now().isoformat(),
            "agent_id": self.agent_id,
            "discovery": discovery,
            "impact": impact,
            "item_id": item_id
        })
        
        # Save discoveries
        with open(discovery_file, 'w') as f:
            json.dump(discoveries, f, indent=2)
        
        print(f"✓ Discovery shared for {item_id}")
    
    def report_blocker(self, item_id: str, blocker: str, needs: str = None):
        """Report a blocking issue"""
        # This is a special type of discovery
        self.share_discovery(
            item_id,
            f"BLOCKER: {blocker}",
            f"Needs: {needs}" if needs else "Blocking progress"
        )
        
        # Also update progress to show blocked
        self.update_progress(item_id, f"⚠️ Blocked: {blocker}")
    
    def complete_work(self, item_id: str, summary: str, deliverables: Dict = None):
        """Complete work item with deliverables"""
        completion_file = self.handoff_dir / f"{item_id}_completion.json"
        
        completion = {
            "item_id": item_id,
            "agent_id": self.agent_id,
            "completed_at": datetime.now().isoformat(),
            "summary": summary,
            "deliverables": deliverables or {},
            "final_status": "completed"
        }
        
        with open(completion_file, 'w') as f:
            json.dump(completion, f, indent=2)
        
        # Final progress update
        self.update_progress(item_id, "✅ Work completed", 100)
        
        print(f"✓ Work item {item_id} completed")
    
    def save_notes(self, item_id: str, notes: str):
        """Save private working notes"""
        notes_file = self.workspace_dir / f"{item_id}_notes.md"
        
        with open(notes_file, 'a') as f:
            f.write(f"\n\n---\n{datetime.now().isoformat()}\n---\n")
            f.write(notes)
        
        print(f"✓ Notes saved for {item_id}")
    
    def get_notes(self, item_id: str) -> Optional[str]:
        """Get private working notes"""
        notes_file = self.workspace_dir / f"{item_id}_notes.md"
        
        if notes_file.exists():
            with open(notes_file, 'r') as f:
                return f.read()
        return None


def main():
    """CLI for workers"""
    import argparse
    
    parser = argparse.ArgumentParser(
        description="Task Worker - For specialist agents",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Example Workflow:
  1. worker check                     # Check for assignments
  2. worker get ITEM_ID               # Get work details
  3. worker progress ITEM_ID "Starting implementation"
  4. worker discover ITEM_ID "Found optimization opportunity"
  5. worker complete ITEM_ID "All requirements met"
        """
    )
    
    parser.add_argument("--agent-id", help="Your agent ID", 
                       default=os.environ.get('AGENT_ID'))
    
    subparsers = parser.add_subparsers(dest="command", help="Commands")
    
    # Check assignments
    subparsers.add_parser("check", help="Check for assigned work")
    
    # Get work details
    get_parser = subparsers.add_parser("get", help="Get work item details")
    get_parser.add_argument("item_id", help="Work item ID")
    
    # Update progress
    progress_parser = subparsers.add_parser("progress", help="Update progress")
    progress_parser.add_argument("item_id", help="Work item ID")
    progress_parser.add_argument("message", help="Progress message")
    progress_parser.add_argument("--percent", type=int, help="Completion percentage")
    
    # Share discovery
    discover_parser = subparsers.add_parser("discover", help="Share discovery")
    discover_parser.add_argument("item_id", help="Work item ID")
    discover_parser.add_argument("discovery", help="Discovery description")
    discover_parser.add_argument("--impact", help="Impact description")
    
    # Report blocker
    blocker_parser = subparsers.add_parser("blocker", help="Report blocker")
    blocker_parser.add_argument("item_id", help="Work item ID")
    blocker_parser.add_argument("issue", help="Blocking issue")
    blocker_parser.add_argument("--needs", help="What's needed to unblock")
    
    # Complete work
    complete_parser = subparsers.add_parser("complete", help="Complete work")
    complete_parser.add_argument("item_id", help="Work item ID")
    complete_parser.add_argument("summary", help="Completion summary")
    
    # Save notes
    notes_parser = subparsers.add_parser("notes", help="Save private notes")
    notes_parser.add_argument("item_id", help="Work item ID")
    notes_parser.add_argument("content", help="Note content")
    
    # Get notes
    get_notes_parser = subparsers.add_parser("get-notes", help="Get private notes")
    get_notes_parser.add_argument("item_id", help="Work item ID")
    
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        return
    
    if not args.agent_id:
        print("Error: Agent ID required. Set AGENT_ID environment variable or use --agent-id")
        return
    
    worker = Worker(args.agent_id)
    
    if args.command == "check":
        assignments = worker.check_assignments()
        if assignments:
            print(f"You have {len(assignments)} assigned work items:")
            for item_id in assignments:
                print(f"  - {item_id}")
        else:
            print("No work assigned")
    
    elif args.command == "get":
        work = worker.get_work(args.item_id)
        print(f"\n=== Work Item: {work['item_id']} ===")
        print(f"Title: {work['title']}")
        print(f"Project: {work['project']}")
        if work['description']:
            print(f"\nDescription:\n{work['description']}")
        if work['requirements']:
            print(f"\nRequirements:")
            for req in work['requirements']:
                print(f"  - {req}")
        if work['deliverables']:
            print(f"\nExpected Deliverables:")
            for deliverable in work['deliverables']:
                print(f"  - {deliverable}")
    
    elif args.command == "progress":
        worker.update_progress(args.item_id, args.message, args.percent)
    
    elif args.command == "discover":
        worker.share_discovery(args.item_id, args.discovery, args.impact)
    
    elif args.command == "blocker":
        worker.report_blocker(args.item_id, args.issue, args.needs)
    
    elif args.command == "complete":
        worker.complete_work(args.item_id, args.summary)
    
    elif args.command == "notes":
        worker.save_notes(args.item_id, args.content)
    
    elif args.command == "get-notes":
        notes = worker.get_notes(args.item_id)
        if notes:
            print(notes)
        else:
            print(f"No notes found for {args.item_id}")


if __name__ == "__main__":
    main()