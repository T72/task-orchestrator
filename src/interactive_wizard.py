#!/usr/bin/env python3
"""
Interactive Wizard for Task Orchestrator
Provides guided task creation with templates and explanations
@implements FR-048: Interactive Wizard
"""

import sys
import json
import os
from pathlib import Path
from typing import Dict, List, Optional, Any
from datetime import datetime

class InteractiveWizard:
    """
    Interactive wizard for guided task creation
    @implements FR-048: Interactive task creation wizard
    """
    
    def __init__(self, template_parser=None, template_instantiator=None, task_manager=None):
        """Initialize the interactive wizard with required components"""
        self.template_parser = template_parser
        self.template_instantiator = template_instantiator
        self.task_manager = task_manager
        self.templates_dir = Path(".task-orchestrator/templates")
        
    def run(self) -> bool:
        """
        Run the interactive wizard for task creation
        @implements FR-048: Guided task creation flow
        """
        print("\n" + "=" * 60)
        print("  Task Orchestrator Interactive Wizard")
        print("=" * 60)
        print("\nThis wizard will guide you through creating tasks.")
        print("You can use templates or create custom tasks.\n")
        
        # Step 1: Choose creation method
        method = self._choose_creation_method()
        
        if method == "template":
            return self._template_based_creation()
        elif method == "custom":
            return self._custom_task_creation()
        elif method == "batch":
            return self._batch_task_creation()
        else:
            print("\nWizard cancelled.")
            return False
    
    def _choose_creation_method(self) -> str:
        """Let user choose how to create tasks"""
        print("How would you like to create tasks?")
        print("\n1. Use a template (recommended for common workflows)")
        print("2. Create a custom task (full control)")
        print("3. Batch create multiple tasks")
        print("4. Exit wizard")
        
        while True:
            choice = self._get_input("\nSelect an option (1-4): ").strip()
            if choice == "1":
                return "template"
            elif choice == "2":
                return "custom"
            elif choice == "3":
                return "batch"
            elif choice == "4":
                return "exit"
            else:
                print("Please enter a number between 1 and 4.")
    
    def _template_based_creation(self) -> bool:
        """
        Create tasks using templates
        @implements FR-048: Template selection interface
        """
        # List available templates
        templates = self.template_parser.list_templates() if self.template_parser else []
        
        if not templates:
            print("\nNo templates found. Creating a custom task instead.")
            return self._custom_task_creation()
        
        print("\nAvailable Templates:")
        print("-" * 40)
        for i, tmpl in enumerate(templates, 1):
            print(f"{i}. {tmpl['name']} (v{tmpl['version']})")
            print(f"   {tmpl['description']}")
            if tmpl.get('tags'):
                print(f"   Tags: {', '.join(tmpl['tags'])}")
        
        # Select template
        while True:
            choice = self._get_input(f"\nSelect a template (1-{len(templates)}) or 'q' to quit: ").strip()
            if choice.lower() == 'q':
                return False
            try:
                idx = int(choice) - 1
                if 0 <= idx < len(templates):
                    selected_template = templates[idx]
                    break
                else:
                    print(f"Please enter a number between 1 and {len(templates)}.")
            except ValueError:
                print("Please enter a valid number.")
        
        # Load full template
        template_path = self.templates_dir / f"{selected_template['name']}.yaml"
        if not template_path.exists():
            template_path = self.templates_dir / f"{selected_template['name']}.json"
        
        if not template_path.exists():
            print(f"Error: Template file not found for {selected_template['name']}")
            return False
        
        template = self.template_parser.parse_template(str(template_path))
        if not template:
            print("Error: Failed to parse template")
            return False
        
        # Collect variables
        print(f"\n--- {template['name']} Template ---")
        print(f"Description: {template['description']}\n")
        
        variables = {}
        if template.get('variables'):
            print("This template requires the following information:")
            print("-" * 40)
            
            # Variables is a dict, not a list
            for var_name, var_config in template['variables'].items():
                # Show variable info
                print(f"\n{var_name}:")
                print(f"  {var_config.get('description', 'No description')}")
                if 'example' in var_config:
                    print(f"  Example: {var_config['example']}")
                
                # Get value with validation
                while True:
                    if 'default' in var_config:
                        prompt = f"  Enter value (default: {var_config['default']}): "
                        value = self._get_input(prompt).strip()
                        if not value:
                            value = var_config['default']
                    else:
                        value = self._get_input("  Enter value: ").strip()
                        if not value and var_config.get('required', True):
                            print("  This field is required.")
                            continue
                    
                    # Type validation
                    if var_config.get('type') == 'number':
                        try:
                            value = float(value) if '.' in str(value) else int(value)
                        except ValueError:
                            print("  Please enter a valid number.")
                            continue
                    elif var_config.get('type') == 'array':
                        # Parse comma-separated values
                        value = [v.strip() for v in value.split(',') if v.strip()]
                    
                    # Enum validation
                    if 'validation' in var_config and 'enum' in var_config['validation']:
                        valid_options = var_config['validation']['enum']
                        if value not in valid_options:
                            print(f"  Please choose from: {', '.join(valid_options)}")
                            continue
                    
                    variables[var_name] = value
                    break
        
        # Preview tasks
        print("\n" + "=" * 60)
        print("Template will create the following tasks:")
        print("-" * 60)
        
        # Instantiate template (returns a list of tasks)
        tasks = self.template_instantiator.instantiate(template, variables)
        
        for i, task in enumerate(tasks, 1):
            print(f"\n{i}. {task['title']}")
            if task.get('description'):
                # Truncate long descriptions
                desc = task['description']
                if len(desc) > 100:
                    desc = desc[:97] + "..."
                print(f"   {desc}")
            if task.get('priority'):
                print(f"   Priority: {task['priority']}")
            if task.get('depends_on'):
                print(f"   Dependencies: {', '.join(task['depends_on'])}")
        
        # Confirm creation
        confirm = self._get_input("\nCreate these tasks? (y/n): ").strip().lower()
        if confirm != 'y':
            print("Task creation cancelled.")
            return False
        
        # Create tasks
        print("\nCreating tasks...")
        created_tasks = []
        task_id_map = {}  # Map template task IDs to actual task IDs
        
        for task in tasks:
            # Prepare task data
            title = task['title']
            description = task.get('description', '')
            priority = task.get('priority', 'medium')
            assignee = task.get('assignee')
            tags = task.get('tags', [])
            
            # Create task
            if self.task_manager:
                task_id = self.task_manager.add(
                    title=title,
                    description=description,
                    priority=priority,
                    assignee=assignee,
                    tags=tags
                )
                
                if task_id:
                    created_tasks.append(task_id)
                    if task.get('id'):
                        task_id_map[task['id']] = task_id
                    print(f"  ✓ Created task {task_id}: {title}")
                else:
                    print(f"  ✗ Failed to create task: {title}")
        
        # Handle dependencies
        for task in tasks:
            if task.get('depends_on') and task.get('id') in task_id_map:
                task_id = task_id_map[task['id']]
                for dep in task['depends_on']:
                    if dep in task_id_map:
                        # Add dependency
                        # Note: This would need a method in TaskManager to add dependencies
                        pass
        
        print(f"\n✓ Successfully created {len(created_tasks)} tasks")
        if created_tasks:
            print(f"Task IDs: {', '.join(created_tasks)}")
        
        return True
    
    def _custom_task_creation(self) -> bool:
        """
        Create a custom task with guided input
        @implements FR-048: Guided task creation with explanations
        """
        print("\n--- Custom Task Creation ---")
        print("Let's create a custom task step by step.\n")
        
        # Title (required)
        print("Task Title (required):")
        print("  A brief, descriptive name for your task.")
        title = self._get_input("  Title: ").strip()
        if not title:
            print("Task title is required.")
            return False
        
        # Description (optional)
        print("\nTask Description (optional):")
        print("  Detailed information about what needs to be done.")
        print("  Press Enter twice to finish, or just Enter to skip.")
        description_lines = []
        while True:
            line = self._get_input("  ").rstrip()
            if not line and not description_lines:
                break  # Skip description
            if not line and description_lines:
                break  # End of description
            description_lines.append(line)
        description = '\n'.join(description_lines)
        
        # Priority
        print("\nTask Priority:")
        print("  1. Low - Can be done whenever")
        print("  2. Medium - Should be done soon (default)")
        print("  3. High - Important, prioritize this")
        print("  4. Critical - Urgent, needs immediate attention")
        priority_map = {'1': 'low', '2': 'medium', '3': 'high', '4': 'critical'}
        choice = self._get_input("  Select priority (1-4, default: 2): ").strip()
        priority = priority_map.get(choice, 'medium')
        
        # Assignee
        print("\nAssignee (optional):")
        print("  Who should work on this task? (agent name or person)")
        assignee = self._get_input("  Assignee: ").strip() or None
        
        # Tags
        print("\nTags (optional):")
        print("  Categories or labels for this task (comma-separated)")
        tags_input = self._get_input("  Tags: ").strip()
        tags = [t.strip() for t in tags_input.split(',') if t.strip()] if tags_input else []
        
        # Dependencies
        print("\nDependencies (optional):")
        print("  Task IDs that must be completed first (comma-separated)")
        deps_input = self._get_input("  Dependencies: ").strip()
        dependencies = [d.strip() for d in deps_input.split(',') if d.strip()] if deps_input else []
        
        # Files
        print("\nFile References (optional):")
        print("  Files related to this task (comma-separated paths)")
        files_input = self._get_input("  Files: ").strip()
        files = [f.strip() for f in files_input.split(',') if f.strip()] if files_input else []
        
        # Preview
        print("\n" + "=" * 60)
        print("Task Preview:")
        print("-" * 60)
        print(f"Title: {title}")
        if description:
            print(f"Description: {description[:100]}{'...' if len(description) > 100 else ''}")
        print(f"Priority: {priority}")
        if assignee:
            print(f"Assignee: {assignee}")
        if tags:
            print(f"Tags: {', '.join(tags)}")
        if dependencies:
            print(f"Dependencies: {', '.join(dependencies)}")
        if files:
            print(f"Files: {', '.join(files)}")
        
        # Confirm
        confirm = self._get_input("\nCreate this task? (y/n): ").strip().lower()
        if confirm != 'y':
            print("Task creation cancelled.")
            return False
        
        # Create task
        if self.task_manager:
            # Build description with files if provided
            full_description = description
            if files:
                full_description += f"\n\nFiles: {', '.join(files)}"
            
            task_id = self.task_manager.add(
                title=title,
                description=full_description,
                priority=priority,
                assignee=assignee,
                tags=tags,
                depends_on=dependencies
            )
            
            if task_id:
                print(f"\n✓ Task created successfully!")
                print(f"Task ID: {task_id}")
            else:
                print("\n✗ Failed to create task")
                return False
        else:
            print("\n✓ Task created successfully! (simulation mode)")
        
        return True
    
    def _batch_task_creation(self) -> bool:
        """Create multiple tasks in batch mode"""
        print("\n--- Batch Task Creation ---")
        print("Create multiple tasks quickly. Enter tasks one per line.")
        print("Format: <title> [#tag1 #tag2] [@assignee] [!priority]")
        print("Example: Fix login bug #bug #urgent @backend !high")
        print("\nEnter tasks (empty line to finish):\n")
        
        tasks = []
        while True:
            line = self._get_input(f"Task {len(tasks) + 1}: ").strip()
            if not line:
                break
            
            # Parse the line
            task_data = self._parse_batch_line(line)
            if task_data:
                tasks.append(task_data)
        
        if not tasks:
            print("No tasks entered.")
            return False
        
        # Preview
        print("\n" + "=" * 60)
        print(f"Ready to create {len(tasks)} tasks:")
        print("-" * 60)
        for i, task in enumerate(tasks, 1):
            print(f"{i}. {task['title']}")
            if task.get('tags'):
                print(f"   Tags: {', '.join(task['tags'])}")
            if task.get('assignee'):
                print(f"   Assignee: {task['assignee']}")
            if task.get('priority') and task['priority'] != 'medium':
                print(f"   Priority: {task['priority']}")
        
        # Confirm
        confirm = self._get_input("\nCreate these tasks? (y/n): ").strip().lower()
        if confirm != 'y':
            print("Task creation cancelled.")
            return False
        
        # Create tasks
        created = 0
        for task in tasks:
            if self.task_manager:
                task_id = self.task_manager.add(
                    title=task['title'],
                    priority=task.get('priority', 'medium'),
                    assignee=task.get('assignee'),
                    tags=task.get('tags', [])
                )
                if task_id:
                    created += 1
                    print(f"  ✓ Created: {task['title']} ({task_id})")
            else:
                created += 1
                print(f"  ✓ Created: {task['title']} (simulation)")
        
        print(f"\n✓ Successfully created {created} tasks")
        return True
    
    def _parse_batch_line(self, line: str) -> Optional[Dict[str, Any]]:
        """Parse a batch task line into task data"""
        import re
        
        # Extract components
        tags = re.findall(r'#(\w+)', line)
        assignee_match = re.search(r'@([\w-]+)', line)  # Allow hyphens in assignee names
        priority_match = re.search(r'!(low|medium|high|critical)', line)
        
        # Remove special markers to get title
        title = re.sub(r'[#@!][\w-]+', '', line).strip()
        
        if not title:
            return None
        
        task = {'title': title}
        if tags:
            task['tags'] = tags
        if assignee_match:
            task['assignee'] = assignee_match.group(1)
        if priority_match:
            task['priority'] = priority_match.group(1)
        
        return task
    
    def _get_input(self, prompt: str) -> str:
        """Get input from user with proper handling"""
        try:
            return input(prompt)
        except (EOFError, KeyboardInterrupt):
            print("\n\nWizard interrupted.")
            sys.exit(0)
    
    def quick_start(self) -> bool:
        """
        Quick start mode for experienced users
        @implements FR-048: Quick task creation option
        """
        print("\n=== Quick Task Creation ===")
        print("Enter: <title> [description] [#tags] [@assignee] [!priority]")
        
        line = self._get_input("\nTask: ").strip()
        if not line:
            return False
        
        # Parse quick format
        task_data = self._parse_batch_line(line)
        if not task_data:
            print("Invalid format.")
            return False
        
        # Extract description if present (text in brackets)
        import re
        desc_match = re.search(r'\[([^\]]+)\]', line)
        if desc_match:
            task_data['description'] = desc_match.group(1)
            # Remove description from title
            task_data['title'] = task_data['title'].replace(f"[{desc_match.group(1)}]", "").strip()
        
        # Create task
        if self.task_manager:
            task_id = self.task_manager.add(
                title=task_data['title'],
                description=task_data.get('description', ''),
                priority=task_data.get('priority', 'medium'),
                assignee=task_data.get('assignee'),
                tags=task_data.get('tags', [])
            )
            
            if task_id:
                print(f"✓ Task created: {task_id}")
                return True
        
        return False