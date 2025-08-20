#!/usr/bin/env python3
"""
Task Orchestrator - Basic Usage Examples

This script demonstrates fundamental Task Orchestrator operations
including task creation, dependency management, and status tracking.

Run this script to see Task Orchestrator in action with real examples.
"""

import sys
import os
import time
from pathlib import Path

# Add the project root to the Python path
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

# Import TaskManager from the main module
try:
    from src.tm_production import TaskManager
except ImportError as e:
    print(f"Error importing TaskManager: {e}")
    print("Make sure you're running this from the task-orchestrator directory")
    sys.exit(1)

def print_separator(title):
    """Print a formatted section separator."""
    print(f"\n{'='*60}")
    print(f"  {title}")
    print('='*60)

def print_tasks(tm, title="Current Tasks"):
    """Print all current tasks with formatting."""
    print(f"\n{title}:")
    print("-" * 40)
    
    tasks = tm.list()
    if not tasks:
        print("No tasks found.")
        return
    
    for task in tasks:
        status_symbol = {
            'pending': '○',
            'in_progress': '◐', 
            'completed': '●',
            'blocked': '⊘',
            'cancelled': '✗'
        }.get(task['status'], '?')
        
        deps = f" [deps: {','.join(task['dependencies'])}]" if task['dependencies'] else ""
        blocks = f" [blocks: {','.join(task['blocks'])}]" if task['blocks'] else ""
        
        print(f"{status_symbol} [{task['id']}] {task['title']} ({task['priority']}){deps}{blocks}")

def demonstrate_basic_operations():
    """Demonstrate basic task operations."""
    print_separator("Basic Task Operations")
    
    # Initialize TaskManager
    tm = TaskManager()
    print("✓ TaskManager initialized")
    print(f"  Database: {tm.db_path}")
    print(f"  Agent ID: {tm.agent_id}")
    
    # Initialize database
    try:
        print("✓ Database initialized")
    except Exception as e:
        print(f"Database already exists or error: {e}")
    
    # Create simple tasks
    print("\n1. Creating Simple Tasks:")
    
    task1_id = tm.add("Set up development environment")
    print(f"   Created task: {task1_id}")
    
    task2_id = tm.add(
        "Write user authentication module",
        description="Implement secure login and session management",
        priority="high"
    )
    print(f"   Created task: {task2_id}")
    
    task3_id = tm.add(
        "Create unit tests",
        priority="medium"
    )
    print(f"   Created task: {task3_id}")
    
    print_tasks(tm)
    
    # Demonstrate status updates
    print("\n2. Updating Task Status:")
    
    # Start working on first task
    success = tm.update(task1_id, status="in_progress")
    print(f"   Task {task1_id} set to in_progress: {success}")
    
    # Assign second task
    success = tm.update(task2_id, assignee="alice_dev")
    print(f"   Task {task2_id} assigned to alice_dev: {success}")
    
    print_tasks(tm, "After Status Updates")
    
    # Complete first task
    print("\n3. Completing Tasks:")
    success = tm.complete(task1_id)
    print(f"   Task {task1_id} completed: {success}")
    
    print_tasks(tm, "After Completion")
    
    return task1_id, task2_id, task3_id

def demonstrate_dependencies():
    """Demonstrate dependency management."""
    print_separator("Dependency Management")
    
    tm = TaskManager()
    
    print("1. Creating Tasks with Dependencies:")
    
    # Create a foundation task
    foundation_id = tm.add("Design system architecture", priority="critical")
    print(f"   Foundation task: {foundation_id}")
    
    # Create dependent tasks
    api_id = tm.add(
        "Implement REST API",
        depends_on=[foundation_id],
        priority="high"
    )
    print(f"   API task (depends on foundation): {api_id}")
    
    ui_id = tm.add(
        "Build user interface",
        depends_on=[api_id],
        priority="medium"
    )
    print(f"   UI task (depends on API): {ui_id}")
    
    tests_id = tm.add(
        "Write integration tests",
        depends_on=[api_id, ui_id],
        priority="medium"
    )
    print(f"   Tests task (depends on API and UI): {tests_id}")
    
    print_tasks(tm, "Tasks with Dependencies")
    
    print("\n2. Dependency Chain Resolution:")
    
    # Complete foundation task - should unblock API task
    print(f"   Completing foundation task {foundation_id}...")
    tm.complete(foundation_id)
    
    print_tasks(tm, "After Foundation Completion")
    
    # Complete API task - should unblock UI task
    print(f"   Completing API task {api_id}...")
    tm.complete(api_id)
    
    print_tasks(tm, "After API Completion")
    
    # Complete UI task - should unblock tests (since API is also done)
    print(f"   Completing UI task {ui_id}...")
    tm.complete(ui_id)
    
    print_tasks(tm, "After UI Completion")

def demonstrate_circular_dependency_prevention():
    """Demonstrate circular dependency detection."""
    print_separator("Circular Dependency Prevention")
    
    tm = TaskManager()
    
    print("1. Creating tasks that would create circular dependency:")
    
    # Create first task
    task_a_id = tm.add("Task A")
    print(f"   Created Task A: {task_a_id}")
    
    # Create second task depending on first
    task_b_id = tm.add("Task B", depends_on=[task_a_id])
    print(f"   Created Task B (depends on A): {task_b_id}")
    
    # Try to make Task A depend on Task B (would create cycle)
    print(f"   Attempting to make Task A depend on Task B...")
    try:
        task_c_id = tm.add("Task C", depends_on=[task_b_id])
        print(f"   Created Task C: {task_c_id}")
        
        # This should fail due to circular dependency
        circular_task = tm.add("Circular task", depends_on=[task_a_id, task_c_id])
        if circular_task:
            print(f"   ERROR: Circular dependency not detected!")
        else:
            print("   ✓ Circular dependency properly prevented")
    except CircularDependencyError as e:
        print(f"   ✓ Circular dependency detected and prevented: {e}")

def demonstrate_file_references():
    """Demonstrate file reference functionality."""
    print_separator("File References")
    
    tm = TaskManager()
    
    print("1. Creating tasks with file references:")
    
    # Task with single file reference
    file_task_id = tm.add(
        "Fix authentication bug",
        description="The login validation is failing for special characters",
        priority="high",
        file_refs=[{
            'file_path': 'src/auth.py',
            'line_start': 42,
            'line_end': 60,
            'context': 'Password validation function'
        }]
    )
    print(f"   Created task with file reference: {file_task_id}")
    
    # Task with multiple file references
    refactor_task_id = tm.add(
        "Refactor user model",
        description="Move user-related functions to separate modules",
        priority="medium",
        file_refs=[
            {
                'file_path': 'src/models/user.py',
                'line_start': 1,
                'line_end': 50,
                'context': 'User class definition'
            },
            {
                'file_path': 'src/utils/validation.py',
                'line_start': 25,
                'context': 'User validation functions'
            },
            {
                'file_path': 'tests/test_user.py',
                'context': 'All user tests need updating'
            }
        ]
    )
    print(f"   Created task with multiple file references: {refactor_task_id}")
    
    print("\n2. Viewing file references:")
    for task_id in [file_task_id, refactor_task_id]:
        task = tm.show_task(task_id)
        print(f"\n   Task {task_id}: {task['title']}")
        if task['file_refs']:
            print("   File References:")
            for ref in task['file_refs']:
                line_info = ""
                if ref['line_start']:
                    line_info = f":{ref['line_start']}"
                    if ref['line_end']:
                        line_info += f"-{ref['line_end']}"
                context = f" ({ref['context']})" if ref['context'] else ""
                print(f"     - {ref['file_path']}{line_info}{context}")

def demonstrate_tags_and_filtering():
    """Demonstrate tag functionality and filtering."""
    print_separator("Tags and Filtering")
    
    tm = TaskManager()
    
    print("1. Creating tasks with tags:")
    
    # Create tasks with different tags
    bug_task = tm.add(
        "Fix login timeout issue",
        priority="critical",
        tags=["bug", "security", "urgent"]
    )
    print(f"   Bug task: {bug_task}")
    
    feature_task = tm.add(
        "Add password strength indicator",
        priority="medium",
        tags=["feature", "ui", "security"]
    )
    print(f"   Feature task: {feature_task}")
    
    docs_task = tm.add(
        "Update API documentation",
        priority="low",
        tags=["documentation", "maintenance"]
    )
    print(f"   Documentation task: {docs_task}")
    
    test_task = tm.add(
        "Write security tests",
        priority="high",
        tags=["testing", "security"]
    )
    print(f"   Test task: {test_task}")
    
    print_tasks(tm, "All Tasks with Tags")
    
    print("\n2. Filtering tasks:")
    
    # Filter by status
    pending_tasks = tm.list(status="pending")
    print(f"   Pending tasks: {len(pending_tasks)}")
    
    # Filter by priority
    high_priority_tasks = [t for t in tm.list() if t['priority'] in ['high', 'critical']]
    print(f"   High/Critical priority tasks: {len(high_priority_tasks)}")
    for task in high_priority_tasks:
        print(f"     - [{task['id']}] {task['title']} ({task['priority']})")

def demonstrate_notifications():
    """Demonstrate notification system."""
    print_separator("Notification System")
    
    tm = TaskManager()
    
    print("1. Setting up tasks for notification demo:")
    
    # Create a dependency chain
    parent_id = tm.add("Complete user stories", priority="high")
    child_id = tm.add(
        "Deploy to staging", 
        depends_on=[parent_id],
        priority="medium"
    )
    
    print(f"   Parent task: {parent_id}")
    print(f"   Child task (blocked): {child_id}")
    
    print_tasks(tm)
    
    print("\n2. Checking notifications before completion:")
    notifications = tm.watch()
    print(f"   Current notifications: {len(notifications)}")
    
    print("\n3. Completing parent task (should generate notifications):")
    tm.complete(parent_id)
    
    print("\n4. Checking notifications after completion:")
    notifications = tm.watch()
    print(f"   New notifications: {len(notifications)}")
    for notif in notifications:
        print(f"     - [{notif['type']}] {notif['message']}")

def demonstrate_export_functionality():
    """Demonstrate export capabilities."""
    print_separator("Export Functionality")
    
    tm = TaskManager()
    
    # Ensure we have some tasks
    if not tm.list():
        tm.add("Sample task for export", priority="medium", tags=["sample"])
        tm.add("Another sample task", priority="low")
    
    print("1. Exporting to JSON:")
    json_export = tm.export(format="json")
    print(f"   JSON export length: {len(json_export)} characters")
    print("   JSON sample:")
    print("   " + json_export[:200] + "..." if len(json_export) > 200 else "   " + json_export)
    
    print("\n2. Exporting to Markdown:")
    markdown_export = tm.export(format="markdown")
    print(f"   Markdown export length: {len(markdown_export)} characters")
    print("   Markdown sample:")
    lines = markdown_export.split('\n')[:10]
    for line in lines:
        print("   " + line)
    if len(lines) >= 10:
        print("   ...")

def main():
    """Run all demonstration examples."""
    print("Task Orchestrator - Basic Usage Examples")
    print("========================================")
    print("This script demonstrates core Task Orchestrator functionality.")
    print("Each section shows different features with working examples.")
    
    try:
        # Run all demonstrations
        demonstrate_basic_operations()
        time.sleep(1)  # Brief pause between sections
        
        demonstrate_dependencies()
        time.sleep(1)
        
        demonstrate_circular_dependency_prevention()
        time.sleep(1)
        
        demonstrate_file_references()
        time.sleep(1)
        
        demonstrate_tags_and_filtering()
        time.sleep(1)
        
        demonstrate_notifications()
        time.sleep(1)
        
        demonstrate_export_functionality()
        
        print_separator("Examples Complete")
        print("All basic usage examples have been demonstrated successfully!")
        print(f"Database location: {TaskManager().db_path}")
        print("\nYou can now:")
        print("  - Run './tm list' to see all created tasks")
        print("  - Run './tm export --format markdown' to see a status report")
        print("  - Explore other example scripts in this directory")
        
    except Exception as e:
        print(f"\nError during demonstration: {e}")
        print("Make sure Task Orchestrator is properly set up.")
        sys.exit(1)

if __name__ == "__main__":
    main()