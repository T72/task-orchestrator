#!/usr/bin/env python3
"""
Comprehensive integration tests for Task Orchestrator components.
Tests the integration between various modules and requirement fulfillment.

@implements FR-020: Integration testing framework
@implements FR-021: End-to-end workflow testing
@implements FR-022: Automated validation testing
@implements FR-023: System integration verification
@implements FR-025: Multi-component testing
@implements FR-026: Workflow integration testing
"""

import unittest
import tempfile
import shutil
import sys
import json
from pathlib import Path
from datetime import datetime

# Add src to path
sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

from tm_production import TaskManager
from context_manager import ProjectContextManager
from dependency_graph import DependencyGraph
from event_broadcaster import EventBroadcaster, EventType
from retry_utils import calculate_backoff_delay, RetryConfig


class TestTraceabilityIntegration(unittest.TestCase):
    """
    Integration tests verifying multiple components work together.
    @implements FR-020: Test coverage for integrated workflows
    """
    
    def setUp(self):
        """Set up test environment."""
        self.test_dir = tempfile.mkdtemp(prefix="test_integration_")
        self.original_cwd = Path.cwd()
        
        # Change to test directory
        import os
        os.chdir(self.test_dir)
        
        # Initialize components
        self.task_manager = TaskManager()
        self.context_manager = ProjectContextManager()
        self.dependency_graph = DependencyGraph()
        self.event_broadcaster = EventBroadcaster()
        
    def tearDown(self):
        """Clean up test environment."""
        import os
        os.chdir(self.original_cwd)
        if Path(self.test_dir).exists():
            shutil.rmtree(self.test_dir)
    
    def test_task_creation_with_context(self):
        """Test task creation integrates with context management."""
        # @implements FR-041: Context integration with task creation
        
        # Create task
        task_id = self.task_manager.add("Implement feature X", description="Working implementation")
        self.assertIsNotNone(task_id)
        
        # Save context about the task
        context_data = {
            "task_id": task_id,
            "requirements": ["REQ-001", "REQ-002"],
            "priority": "high",
            "estimated_hours": 8
        }
        
        context_path = self.context_manager.save_context(f"task_{task_id}", context_data)
        self.assertTrue(context_path.exists())
        
        # Verify context can be loaded
        loaded_context = self.context_manager.load_context(f"task_{task_id}")
        self.assertEqual(loaded_context["task_id"], task_id)
        self.assertEqual(loaded_context["priority"], "high")
    
    def test_dependency_graph_integration(self):
        """Test dependency graph works with task manager."""
        # @implements FR-042: Dependency graph integration
        
        # Create tasks with dependencies
        task1 = self.task_manager.add_task("Database setup")
        task2 = self.task_manager.add_task("API implementation", depends_on=[task1])
        task3 = self.task_manager.add_task("Frontend integration", depends_on=[task2])
        
        # Build dependency graph
        self.dependency_graph.add_node(task1, weight=4.0)
        self.dependency_graph.add_node(task2, weight=6.0)
        self.dependency_graph.add_node(task3, weight=3.0)
        
        self.dependency_graph.add_edge(task1, task2)
        self.dependency_graph.add_edge(task2, task3)
        
        # Test topological ordering
        topo_order = self.dependency_graph.topological_sort()
        self.assertEqual(len(topo_order), 3)
        self.assertEqual(topo_order.index(task1), 0)  # First task
        self.assertEqual(topo_order.index(task3), 2)  # Last task
        
        # Test critical path
        critical_path = self.dependency_graph.calculate_critical_path()
        self.assertIn(task1, critical_path)
        self.assertIn(task2, critical_path)
        self.assertIn(task3, critical_path)
    
    def test_event_broadcasting_workflow(self):
        """Test event broadcasting integrates with task workflow."""
        # @implements FR-015: Event broadcasting integration
        # @implements FR-016: Workflow event handling
        
        # Create task
        task_id = self.task_manager.add_task("Test event broadcasting")
        
        # Broadcast task creation event
        self.event_broadcaster.broadcast(
            event_type=EventType.TASK_CREATED,
            message=f"Task {task_id} created",
            details={"task_id": task_id, "status": "pending"}
        )
        
        # Update task status
        self.task_manager.update_task_status(task_id, "in_progress")
        
        # Broadcast status change
        self.event_broadcaster.broadcast(
            event_type=EventType.TASK_STATUS_CHANGED,
            message=f"Task {task_id} now in progress",
            details={"task_id": task_id, "old_status": "pending", "new_status": "in_progress"}
        )
        
        # Verify events were broadcasted (check notification file exists)
        notification_file = Path(".task-orchestrator/notifications/broadcast.md")
        self.assertTrue(notification_file.exists())
    
    def test_retry_mechanism_integration(self):
        """Test retry mechanism works with task operations."""
        # @implements FR-045: Retry mechanism integration
        
        # Test backoff calculation
        delay1 = calculate_backoff_delay(0, base_delay=1.0)
        delay2 = calculate_backoff_delay(1, base_delay=1.0)
        delay3 = calculate_backoff_delay(2, base_delay=1.0)
        
        # Verify exponential backoff
        self.assertGreater(delay2, delay1)
        self.assertGreater(delay3, delay2)
        
        # Test retry config
        config = RetryConfig(max_retries=3, base_delay=0.5, max_delay=10.0)
        self.assertEqual(config.max_retries, 3)
        self.assertEqual(config.base_delay, 0.5)
        
        # Create note about retry attempts
        retry_note = f"""# Retry Integration Test
        
Test executed at: {datetime.now().isoformat()}
- Backoff delay 0: {delay1}s
- Backoff delay 1: {delay2}s  
- Backoff delay 2: {delay3}s
- Max retries: {config.max_retries}
"""
        
        note_path = self.context_manager.save_note("retry_test", retry_note)
        self.assertTrue(note_path.exists())
    
    def test_full_workflow_integration(self):
        """Test complete workflow from task creation to completion."""
        # @implements FR-021: End-to-end workflow testing
        
        # 1. Create project context
        project_context = {
            "name": "Integration Test Project",
            "started": datetime.now().isoformat(),
            "requirements": ["FR-020", "FR-021", "FR-022"],
            "team": ["developer", "tester", "reviewer"]
        }
        
        context_path = self.context_manager.save_context("project_overview", project_context)
        self.assertTrue(context_path.exists())
        
        # 2. Create dependent tasks
        setup_task = self.task_manager.add_task("Project setup", criteria="Environment ready")
        develop_task = self.task_manager.add_task("Develop feature", depends_on=[setup_task])
        test_task = self.task_manager.add_task("Test feature", depends_on=[develop_task])
        
        # 3. Build dependency graph
        self.dependency_graph.add_node(setup_task, weight=2.0)
        self.dependency_graph.add_node(develop_task, weight=8.0)
        self.dependency_graph.add_node(test_task, weight=4.0)
        
        self.dependency_graph.add_edge(setup_task, develop_task)
        self.dependency_graph.add_edge(develop_task, test_task)
        
        # 4. Verify no circular dependencies
        cycle = self.dependency_graph.detect_cycle()
        self.assertIsNone(cycle, "No circular dependencies should exist")
        
        # 5. Process tasks in dependency order
        topo_order = self.dependency_graph.topological_sort()
        
        for task_id in topo_order:
            # Update to in_progress
            self.task_manager.update_task_status(task_id, "in_progress")
            
            # Broadcast start event
            self.event_broadcaster.broadcast(
                event_type=EventType.TASK_STARTED,
                message=f"Task {task_id} started",
                details={"task_id": task_id}
            )
            
            # Complete task
            self.task_manager.complete_task(task_id)
            
            # Broadcast completion
            self.event_broadcaster.broadcast(
                event_type=EventType.TASK_COMPLETED,
                message=f"Task {task_id} completed",
                details={"task_id": task_id}
            )
        
        # 6. Verify all tasks completed
        tasks = self.task_manager.list_tasks()
        for task in tasks:
            if task['id'] in [setup_task, develop_task, test_task]:
                self.assertEqual(task['status'], 'completed')
        
        # 7. Archive project context
        archive_path = self.context_manager.archive_context(
            "project_overview", 
            "Project completed successfully"
        )
        self.assertTrue(archive_path.exists())
        
        # 8. Generate project summary
        summary = self.context_manager.get_context_summary()
        self.assertGreater(summary['context_files'], 0)
        self.assertGreater(summary['archives_count'], 0)
    
    def test_error_handling_integration(self):
        """Test error handling across components."""
        # @implements FR-023: Error handling integration
        
        # Test invalid task operations
        with self.assertRaises(ValueError):
            self.task_manager.update_task_status("nonexistent", "completed")
        
        # Test circular dependency detection
        self.dependency_graph.add_node("A")
        self.dependency_graph.add_node("B")
        self.dependency_graph.add_node("C")
        
        self.dependency_graph.add_edge("A", "B")
        self.dependency_graph.add_edge("B", "C")
        self.dependency_graph.add_edge("C", "A")  # Creates cycle
        
        cycle = self.dependency_graph.detect_cycle()
        self.assertIsNotNone(cycle, "Circular dependency should be detected")
        self.assertIn("A", cycle)
        
        # Test context error handling
        nonexistent_context = self.context_manager.load_context("nonexistent")
        self.assertIsNone(nonexistent_context)
        
        nonexistent_note = self.context_manager.load_note("nonexistent")
        self.assertIsNone(nonexistent_note)
    
    def test_performance_integration(self):
        """Test system performance with multiple components."""
        # @implements FR-025: Performance integration testing
        
        start_time = datetime.now()
        
        # Create multiple tasks quickly
        task_ids = []
        for i in range(10):
            task_id = self.task_manager.add_task(f"Performance test task {i}")
            task_ids.append(task_id)
            
            # Add to dependency graph
            self.dependency_graph.add_node(task_id, weight=1.0)
            
            # Create context
            self.context_manager.save_context(f"perf_task_{i}", {"index": i})
            
            # Broadcast event
            self.event_broadcaster.broadcast(
                event_type=EventType.TASK_CREATED,
                message=f"Performance task {i}",
                details={"index": i}
            )
        
        end_time = datetime.now()
        total_time = (end_time - start_time).total_seconds()
        
        # Should complete in reasonable time (under 5 seconds)
        self.assertLess(total_time, 5.0, "Performance test should complete quickly")
        
        # Verify all tasks created
        self.assertEqual(len(task_ids), 10)
        
        # Verify contexts saved
        for i in range(10):
            context = self.context_manager.load_context(f"perf_task_{i}")
            self.assertIsNotNone(context)
            self.assertEqual(context["index"], i)


if __name__ == "__main__":
    unittest.main()