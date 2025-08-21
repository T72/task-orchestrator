#!/usr/bin/env python3
"""
Project Context Manager for Task Orchestrator
@implements FR-041: Project Context Preservation
@implements FR-CORE-1: Read-Only Shared Context File
@implements FR5.2: Coordination via shared context

Manages project-specific context, notes, and archives locally.
Ensures context travels with the project when moved or cloned.
"""

import json
import os
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Any
import shutil


class ProjectContextManager:
    """
    Manages project-specific context preservation.
    @implements FR-041: Context files stored in project .task-orchestrator/context/
    @implements FR-041: Notes remain with project when moving/cloning
    @implements FR-041: Archive stays project-local
    """
    
    def __init__(self, project_root: Optional[Path] = None):
        """Initialize context manager with project root."""
        self.project_root = project_root or Path.cwd()
        self.context_dir = self.project_root / ".task-orchestrator" / "context"
        self.notes_dir = self.project_root / ".task-orchestrator" / "notes"
        self.archive_dir = self.project_root / ".task-orchestrator" / "archive"
        
        # Ensure directories exist
        self._ensure_directories()
    
    def _ensure_directories(self) -> None:
        """Ensure all context directories exist."""
        for directory in [self.context_dir, self.notes_dir, self.archive_dir]:
            directory.mkdir(parents=True, exist_ok=True)
    
    def save_context(self, context_name: str, content: Dict[str, Any]) -> Path:
        """
        Save context to project-local storage.
        @implements FR-041: Context files stored in project .task-orchestrator/context/
        """
        context_file = self.context_dir / f"{context_name}.json"
        
        # Add metadata
        content['_metadata'] = {
            'created_at': datetime.now().isoformat(),
            'project_root': str(self.project_root),
            'context_version': '2.5.0'
        }
        
        with open(context_file, 'w') as f:
            json.dump(content, f, indent=2)
        
        return context_file
    
    def load_context(self, context_name: str) -> Optional[Dict[str, Any]]:
        """Load context from project-local storage."""
        context_file = self.context_dir / f"{context_name}.json"
        
        if not context_file.exists():
            return None
        
        with open(context_file, 'r') as f:
            return json.load(f)
    
    def save_note(self, note_id: str, content: str, metadata: Optional[Dict] = None) -> Path:
        """
        Save project-specific note.
        @implements FR-041: Notes remain with project when moving/cloning
        """
        note_file = self.notes_dir / f"{note_id}.md"
        
        # Add metadata header
        header = f"""---
id: {note_id}
created: {datetime.now().isoformat()}
project: {self.project_root.name}
"""
        if metadata:
            for key, value in metadata.items():
                header += f"{key}: {value}\n"
        header += "---\n\n"
        
        with open(note_file, 'w') as f:
            f.write(header + content)
        
        return note_file
    
    def load_note(self, note_id: str) -> Optional[str]:
        """Load project-specific note."""
        note_file = self.notes_dir / f"{note_id}.md"
        
        if not note_file.exists():
            return None
        
        with open(note_file, 'r') as f:
            return f.read()
    
    def list_notes(self) -> List[Dict[str, str]]:
        """List all project notes with metadata."""
        notes = []
        for note_file in self.notes_dir.glob("*.md"):
            note_id = note_file.stem
            # Extract first line after metadata as preview
            with open(note_file, 'r') as f:
                lines = f.readlines()
                preview = ""
                in_metadata = False
                for line in lines:
                    if line.strip() == "---":
                        in_metadata = not in_metadata
                        continue
                    if not in_metadata and line.strip():
                        preview = line.strip()[:100]
                        break
            
            notes.append({
                'id': note_id,
                'file': str(note_file.relative_to(self.project_root)),
                'preview': preview,
                'modified': datetime.fromtimestamp(note_file.stat().st_mtime).isoformat()
            })
        
        return sorted(notes, key=lambda x: x['modified'], reverse=True)
    
    def archive_context(self, context_name: str, reason: str = "") -> Path:
        """
        Archive context to project-local archive.
        @implements FR-041: Archive stays project-local
        """
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        archive_name = f"{context_name}_{timestamp}"
        archive_path = self.archive_dir / archive_name
        archive_path.mkdir(parents=True, exist_ok=True)
        
        # Copy context files
        context_file = self.context_dir / f"{context_name}.json"
        if context_file.exists():
            shutil.copy2(context_file, archive_path / f"{context_name}.json")
        
        # Copy related notes
        for note_file in self.notes_dir.glob(f"{context_name}_*.md"):
            shutil.copy2(note_file, archive_path / note_file.name)
        
        # Create archive metadata
        metadata = {
            'archived_at': datetime.now().isoformat(),
            'context_name': context_name,
            'reason': reason,
            'original_project': str(self.project_root),
            'files_archived': len(list(archive_path.iterdir()))
        }
        
        with open(archive_path / "archive_metadata.json", 'w') as f:
            json.dump(metadata, f, indent=2)
        
        return archive_path
    
    def restore_from_archive(self, archive_name: str) -> bool:
        """Restore context from archive."""
        archive_path = self.archive_dir / archive_name
        
        if not archive_path.exists():
            return False
        
        # Restore context files
        for json_file in archive_path.glob("*.json"):
            if json_file.name != "archive_metadata.json":
                shutil.copy2(json_file, self.context_dir / json_file.name)
        
        # Restore notes
        for md_file in archive_path.glob("*.md"):
            shutil.copy2(md_file, self.notes_dir / md_file.name)
        
        return True
    
    def export_context(self, output_path: Path) -> Path:
        """
        Export entire project context for backup or sharing.
        Maintains project-local structure.
        """
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        export_name = f"context_export_{self.project_root.name}_{timestamp}.tar.gz"
        export_file = output_path / export_name
        
        import tarfile
        with tarfile.open(export_file, "w:gz") as tar:
            # Add context directory
            tar.add(self.context_dir, arcname="context")
            # Add notes directory
            tar.add(self.notes_dir, arcname="notes")
            # Add archive directory
            tar.add(self.archive_dir, arcname="archive")
        
        return export_file
    
    def import_context(self, import_file: Path) -> bool:
        """Import context from exported file."""
        if not import_file.exists():
            return False
        
        import tarfile
        with tarfile.open(import_file, "r:gz") as tar:
            # Extract to temporary directory first
            temp_dir = self.project_root / ".task-orchestrator" / "temp_import"
            temp_dir.mkdir(parents=True, exist_ok=True)
            tar.extractall(temp_dir)
            
            # Merge with existing context
            for item in temp_dir.iterdir():
                if item.name == "context":
                    for file in item.iterdir():
                        shutil.copy2(file, self.context_dir / file.name)
                elif item.name == "notes":
                    for file in item.iterdir():
                        shutil.copy2(file, self.notes_dir / file.name)
                elif item.name == "archive":
                    for file in item.iterdir():
                        if file.is_dir():
                            shutil.copytree(file, self.archive_dir / file.name, dirs_exist_ok=True)
                        else:
                            shutil.copy2(file, self.archive_dir / file.name)
            
            # Clean up temp directory
            shutil.rmtree(temp_dir)
        
        return True
    
    def get_context_summary(self) -> Dict[str, Any]:
        """Get summary of all project context."""
        return {
            'project_root': str(self.project_root),
            'context_files': len(list(self.context_dir.glob("*.json"))),
            'notes_count': len(list(self.notes_dir.glob("*.md"))),
            'archives_count': len(list(self.archive_dir.iterdir())),
            'total_size_mb': sum(
                f.stat().st_size for f in self.context_dir.rglob("*") 
                if f.is_file()
            ) / (1024 * 1024),
            'last_modified': max(
                (f.stat().st_mtime for f in self.context_dir.rglob("*") if f.is_file()),
                default=0
            )
        }


# CLI integration
if __name__ == "__main__":
    import sys
    
    manager = ProjectContextManager()
    
    if len(sys.argv) < 2:
        print("Usage: python context_manager.py [save|load|archive|summary] [args...]")
        sys.exit(1)
    
    command = sys.argv[1]
    
    if command == "save" and len(sys.argv) >= 4:
        context_name = sys.argv[2]
        content = {"data": sys.argv[3]}
        path = manager.save_context(context_name, content)
        print(f"Context saved to: {path}")
    
    elif command == "load" and len(sys.argv) >= 3:
        context_name = sys.argv[2]
        content = manager.load_context(context_name)
        if content:
            print(json.dumps(content, indent=2))
        else:
            print(f"Context '{context_name}' not found")
    
    elif command == "archive" and len(sys.argv) >= 3:
        context_name = sys.argv[2]
        reason = sys.argv[3] if len(sys.argv) > 3 else ""
        path = manager.archive_context(context_name, reason)
        print(f"Context archived to: {path}")
    
    elif command == "summary":
        summary = manager.get_context_summary()
        print(json.dumps(summary, indent=2))
    
    else:
        print("Invalid command or arguments")
        sys.exit(1)