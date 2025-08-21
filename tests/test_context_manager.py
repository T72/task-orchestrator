#!/usr/bin/env python3
"""
Test suite for Project Context Manager
@implements FR-041: Project Context Preservation testing
@implements FR-020: Test coverage for context management
@implements FR-021: Integration testing for project isolation
"""

import unittest
import json
import tempfile
import shutil
from pathlib import Path
import sys
import os

# Add src to path
sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

from context_manager import ProjectContextManager


class TestProjectContextManager(unittest.TestCase):
    """
    Test cases for Project Context Manager.
    @implements FR-041: Verify context preservation functionality
    """
    
    def setUp(self):
        """Set up test environment with temporary directory."""
        self.test_dir = tempfile.mkdtemp(prefix="test_context_")
        self.test_project = Path(self.test_dir) / "test_project"
        self.test_project.mkdir(parents=True, exist_ok=True)
        
        # Create context manager for test project
        self.manager = ProjectContextManager(self.test_project)
    
    def tearDown(self):
        """Clean up test environment."""
        if Path(self.test_dir).exists():
            shutil.rmtree(self.test_dir)
    
    def test_directory_creation(self):
        """Test that required directories are created."""
        # @implements FR-041: Context files stored in project .task-orchestrator/context/
        self.assertTrue(self.manager.context_dir.exists())
        self.assertTrue(self.manager.notes_dir.exists())
        self.assertTrue(self.manager.archive_dir.exists())
        
        # Verify they're in the correct location
        self.assertEqual(
            self.manager.context_dir,
            self.test_project / ".task-orchestrator" / "context"
        )
    
    def test_save_and_load_context(self):
        """Test saving and loading context data."""
        # @implements FR-041: Context preservation functionality
        context_data = {
            "tasks": ["task1", "task2"],
            "priority": "high",
            "metadata": {"version": "2.5.0"}
        }
        
        # Save context
        saved_path = self.manager.save_context("test_context", context_data)
        self.assertTrue(saved_path.exists())
        
        # Load context
        loaded_data = self.manager.load_context("test_context")
        self.assertIsNotNone(loaded_data)
        self.assertEqual(loaded_data["tasks"], context_data["tasks"])
        self.assertEqual(loaded_data["priority"], context_data["priority"])
        
        # Verify metadata was added
        self.assertIn("_metadata", loaded_data)
        self.assertIn("created_at", loaded_data["_metadata"])
        self.assertEqual(loaded_data["_metadata"]["context_version"], "2.5.0")
    
    def test_save_and_load_notes(self):
        """Test saving and loading project notes."""
        # @implements FR-041: Notes remain with project when moving/cloning
        note_content = """# Project Notes
        
This is a test note for the project.
- Item 1
- Item 2
"""
        
        # Save note
        note_path = self.manager.save_note("test_note", note_content, {"author": "test"})
        self.assertTrue(note_path.exists())
        
        # Load note
        loaded_note = self.manager.load_note("test_note")
        self.assertIsNotNone(loaded_note)
        self.assertIn("Project Notes", loaded_note)
        self.assertIn("author: test", loaded_note)
    
    def test_list_notes(self):
        """Test listing all project notes."""
        # Create multiple notes
        self.manager.save_note("note1", "Content 1")
        self.manager.save_note("note2", "Content 2")
        self.manager.save_note("note3", "Content 3")
        
        # List notes
        notes = self.manager.list_notes()
        self.assertEqual(len(notes), 3)
        
        # Verify note structure
        for note in notes:
            self.assertIn("id", note)
            self.assertIn("file", note)
            self.assertIn("preview", note)
            self.assertIn("modified", note)
    
    def test_archive_context(self):
        """Test archiving context to project-local archive."""
        # @implements FR-041: Archive stays project-local
        
        # Create context and notes
        self.manager.save_context("to_archive", {"data": "test"})
        self.manager.save_note("to_archive_note", "Note content")
        
        # Archive context
        archive_path = self.manager.archive_context("to_archive", "Testing archive")
        self.assertTrue(archive_path.exists())
        self.assertTrue((archive_path / "to_archive.json").exists())
        self.assertTrue((archive_path / "archive_metadata.json").exists())
        
        # Verify archive is project-local
        self.assertTrue(str(archive_path).startswith(str(self.manager.archive_dir)))
    
    def test_restore_from_archive(self):
        """Test restoring context from archive."""
        # Create and archive context
        original_data = {"original": "data", "version": 1}
        self.manager.save_context("restorable", original_data)
        archive_path = self.manager.archive_context("restorable", "Before changes")
        archive_name = archive_path.name
        
        # Modify context
        self.manager.save_context("restorable", {"modified": "data", "version": 2})
        
        # Restore from archive
        success = self.manager.restore_from_archive(archive_name)
        self.assertTrue(success)
        
        # Verify original data is restored
        restored_data = self.manager.load_context("restorable")
        self.assertEqual(restored_data["original"], "data")
        self.assertEqual(restored_data["version"], 1)
    
    def test_export_import_context(self):
        """Test exporting and importing entire project context."""
        # Create various context items
        self.manager.save_context("export_test", {"data": "to export"})
        self.manager.save_note("export_note", "Note to export")
        
        # Export context
        export_path = self.test_project
        export_file = self.manager.export_context(export_path)
        self.assertTrue(export_file.exists())
        self.assertTrue(str(export_file).endswith(".tar.gz"))
        
        # Create new project and import
        new_project = Path(self.test_dir) / "new_project"
        new_project.mkdir(parents=True, exist_ok=True)
        new_manager = ProjectContextManager(new_project)
        
        # Import context
        success = new_manager.import_context(export_file)
        self.assertTrue(success)
        
        # Verify imported data
        imported_data = new_manager.load_context("export_test")
        self.assertIsNotNone(imported_data)
        self.assertEqual(imported_data["data"], "to export")
        
        imported_note = new_manager.load_note("export_note")
        self.assertIsNotNone(imported_note)
        self.assertIn("Note to export", imported_note)
    
    def test_context_summary(self):
        """Test getting context summary."""
        # Create various items
        self.manager.save_context("ctx1", {"data": 1})
        self.manager.save_context("ctx2", {"data": 2})
        self.manager.save_note("note1", "Content")
        self.manager.archive_context("ctx1", "Test")
        
        # Get summary
        summary = self.manager.get_context_summary()
        
        self.assertEqual(summary["context_files"], 2)  # ctx1 and ctx2
        self.assertEqual(summary["notes_count"], 1)    # note1
        self.assertEqual(summary["archives_count"], 1)  # archived ctx1
        self.assertIn("total_size_mb", summary)
        self.assertIn("last_modified", summary)
    
    def test_nonexistent_context_load(self):
        """Test loading nonexistent context returns None."""
        result = self.manager.load_context("nonexistent")
        self.assertIsNone(result)
    
    def test_nonexistent_note_load(self):
        """Test loading nonexistent note returns None."""
        result = self.manager.load_note("nonexistent")
        self.assertIsNone(result)
    
    def test_project_isolation(self):
        """Test that contexts are isolated between projects."""
        # @implements FR-040: Project-Local Database Isolation
        
        # Create context in first project
        self.manager.save_context("project1_context", {"project": 1})
        
        # Create second project
        project2 = Path(self.test_dir) / "project2"
        project2.mkdir(parents=True, exist_ok=True)
        manager2 = ProjectContextManager(project2)
        
        # Verify second project doesn't see first project's context
        result = manager2.load_context("project1_context")
        self.assertIsNone(result)
        
        # Create different context in second project
        manager2.save_context("project2_context", {"project": 2})
        
        # Verify first project doesn't see second project's context
        result = self.manager.load_context("project2_context")
        self.assertIsNone(result)


if __name__ == "__main__":
    unittest.main()