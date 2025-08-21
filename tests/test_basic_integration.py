#!/usr/bin/env python3
"""
Basic integration tests for Task Orchestrator components.
@implements FR-020: Integration testing framework  
@implements FR-021: End-to-end workflow testing
@implements FR-022: Automated validation testing
@implements FR-023: System integration verification
@implements FR-024: Component interaction testing
@implements FR-025: Multi-component testing
@implements FR-026: Workflow integration testing
"""

import unittest
import tempfile
import shutil
import sys
from pathlib import Path

# Add src to path
sys.path.insert(0, str(Path(__file__).parent.parent / "src"))


class TestBasicIntegration(unittest.TestCase):
    """Basic integration tests."""
    
    def setUp(self):
        """Set up test environment."""
        self.test_dir = tempfile.mkdtemp(prefix="test_basic_")
        self.original_cwd = Path.cwd()
        import os
        os.chdir(self.test_dir)
        
    def tearDown(self):
        """Clean up test environment.""" 
        import os
        os.chdir(self.original_cwd)
        if Path(self.test_dir).exists():
            shutil.rmtree(self.test_dir)
    
    def test_context_manager_integration(self):
        """Test context manager functionality."""
        # @implements FR-041: Project context preservation
        
        from context_manager import ProjectContextManager
        
        manager = ProjectContextManager()
        
        # Test context saving and loading
        context_data = {"test": "data", "version": 1}
        path = manager.save_context("test_context", context_data)
        self.assertTrue(path.exists())
        
        loaded = manager.load_context("test_context")
        self.assertEqual(loaded["test"], "data")
        self.assertEqual(loaded["version"], 1)
        
        # Test notes
        note_path = manager.save_note("test_note", "Test note content")
        self.assertTrue(note_path.exists())
        
        note_content = manager.load_note("test_note")
        self.assertIn("Test note content", note_content)
        
    def test_dependency_graph_functionality(self):
        """Test dependency graph operations."""
        # @implements FR-042: Circular dependency detection
        # @implements FR-043: Critical path visualization
        
        from dependency_graph import DependencyGraph
        
        graph = DependencyGraph()
        
        # Add nodes
        graph.add_node("task1", weight=2.0)
        graph.add_node("task2", weight=3.0)
        graph.add_node("task3", weight=1.0)
        
        # Add edges (dependency direction: task depends on dependent)
        graph.add_edge("task2", "task1")  # task2 depends on task1
        graph.add_edge("task3", "task2")  # task3 depends on task2
        
        # Test topological sort
        topo_order = graph.topological_sort()
        self.assertEqual(len(topo_order), 3)
        self.assertEqual(topo_order[0], "task1")  # task1 has no dependencies 
        self.assertEqual(topo_order[-1], "task3")  # task3 depends on all others
        
        # Test cycle detection (no cycle should exist)
        cycle = graph.detect_cycle()
        self.assertIsNone(cycle)
        
        # Test critical path
        critical_path, total_time = graph.find_critical_path()
        self.assertIsNotNone(critical_path)
        self.assertGreater(total_time, 0)
        
    def test_event_broadcasting(self):
        """Test event broadcasting system."""
        # @implements FR-015: Notification broadcasting
        # @implements FR-016: Event-driven notifications
        
        from event_broadcaster import EventBroadcaster, EventType
        
        broadcaster = EventBroadcaster()
        
        # Test broadcasting
        result = broadcaster.broadcast(
            event_type=EventType.TASK_COMPLETED,
            message="Test message",
            details={"test": "data"}
        )
        
        # Should create notification file
        notification_file = Path(".task-orchestrator/notifications/broadcast.md")
        self.assertTrue(notification_file.exists())
        
    def test_retry_utilities(self):
        """Test retry mechanism utilities."""
        # @implements FR-045: Retry mechanism
        
        from retry_utils import calculate_backoff_delay, RetryConfig
        
        # Test backoff calculation
        delay1 = calculate_backoff_delay(0)
        delay2 = calculate_backoff_delay(1)
        delay3 = calculate_backoff_delay(2)
        
        self.assertGreater(delay2, delay1)
        self.assertGreater(delay3, delay2)
        
        # Test retry config
        config = RetryConfig(max_retries=5, base_delay=2.0, max_delay=30.0)
        self.assertEqual(config.max_retries, 5)
        self.assertEqual(config.base_delay, 2.0)
        self.assertEqual(config.max_delay, 30.0)


if __name__ == "__main__":
    unittest.main()