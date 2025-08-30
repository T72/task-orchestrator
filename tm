#!/usr/bin/env python3
"""
Enhanced Task Manager with Collaboration Features
Extends the base tm with share, note, discover, sync, context, and join commands
"""

import sys
import os
import subprocess
import shutil
import json
from pathlib import Path

# Add src directory to path
script_dir = Path(__file__).parent
src_dir = script_dir / "src"
if src_dir.exists():
    sys.path.insert(0, str(src_dir))

# Import the collaboration module
try:
    from tm_collaboration import CollaborationManager
except ImportError:
    print("Warning: Collaboration module not found. Some commands will be unavailable.")
    CollaborationManager = None

def main():
    """Enhanced main function with collaboration commands"""
    
    # Import TaskManager for all commands
    try:
        from tm_production import TaskManager
        tm = TaskManager()
    except ImportError as e:
        print(f"Error importing production module: {e}")
        sys.exit(1)
    
    # Check if this is a collaboration command that needs special handling
    if len(sys.argv) > 1 and sys.argv[1] in ['join', 'share', 'note', 'sync', 'context']:
        if CollaborationManager is None:
            print("Error: Collaboration features not available")
            sys.exit(1)
        
        # Handle collaboration commands
        repo_root = find_repo_root()
        collab = CollaborationManager(repo_root)
        
        command = sys.argv[1]
        
        if len(sys.argv) < 3:
            print(f"Usage: tm {command} <task_id> [message]")
            sys.exit(1)
        
        task_id = sys.argv[2]
        
        if command == 'join':
            collab.join(task_id)
        elif command == 'context':
            print(collab.context(task_id))
        else:
            # Commands that require a message
            if len(sys.argv) < 4:
                print(f"Usage: tm {command} <task_id> <message>")
                sys.exit(1)
            
            message = ' '.join(sys.argv[3:])
            
            if command == 'share':
                collab.share(task_id, message)
            elif command == 'note':
                collab.note(task_id, message)
            elif command == 'sync':
                collab.sync(task_id, message)
    elif len(sys.argv) > 1 and sys.argv[1] == 'discover':
        # Route discover through tm_production for notifications
        if len(sys.argv) < 4:
            print("Usage: tm discover <task_id> <message>")
            sys.exit(1)
        
        task_id = sys.argv[2]
        message = ' '.join(sys.argv[3:])
        
        if tm.discover(task_id, message):
            print(f"Discovery shared for task {task_id}")
        else:
            print(f"Failed to share discovery")
            sys.exit(1)
    else:
        # Handle standard tm commands using tm_production module
        if len(sys.argv) < 2:
            print("Usage: tm <command> [args]")
            print("Commands: init, add, list, show, update, complete, export, etc.")
            sys.exit(1)
        
        command = sys.argv[1]
        
        # Route to appropriate TaskManager method
        if command == "init":
            tm._init_db()
            print("Task database initialized")
        elif command == "add":
            if len(sys.argv) < 3:
                print("Usage: tm add <title> [-d description] [-p priority] [--depends-on task_id] [--file path:line]")
                print("       [--criteria JSON] [--deadline ISO8601] [--estimated-hours N] [--assignee name]")
                sys.exit(1)
            # Simple argument parsing for add command
            title = sys.argv[2]
            description = None
            priority = None
            depends_on = []
            file_refs = []
            success_criteria = None
            deadline = None
            estimated_hours = None
            assignee = None
            
            # Parse additional arguments
            i = 3
            while i < len(sys.argv):
                if sys.argv[i] == "-d" and i + 1 < len(sys.argv):
                    description = sys.argv[i + 1]
                    i += 2
                elif sys.argv[i] == "-p" and i + 1 < len(sys.argv):
                    priority = sys.argv[i + 1]
                    i += 2
                elif sys.argv[i] == "--depends-on" and i + 1 < len(sys.argv):
                    depends_on.append(sys.argv[i + 1])
                    i += 2
                elif sys.argv[i] == "--file" and i + 1 < len(sys.argv):
                    file_refs.append(sys.argv[i + 1])
                    i += 2
                elif sys.argv[i] == "--criteria" and i + 1 < len(sys.argv):
                    success_criteria = sys.argv[i + 1]
                    i += 2
                elif sys.argv[i] == "--deadline" and i + 1 < len(sys.argv):
                    deadline = sys.argv[i + 1]
                    i += 2
                elif sys.argv[i] == "--estimated-hours" and i + 1 < len(sys.argv):
                    estimated_hours = float(sys.argv[i + 1])
                    i += 2
                elif sys.argv[i] == "--assignee" and i + 1 < len(sys.argv):
                    assignee = sys.argv[i + 1]
                    i += 2
                else:
                    i += 1
            
            # Add file references to description if provided
            if file_refs:
                file_info = "Files: " + ", ".join(file_refs)
                if description:
                    description = f"{description}\n{file_info}"
                else:
                    description = file_info
            
            try:
                task_id = tm.add(title, description=description, priority=priority, 
                               depends_on=depends_on if depends_on else None,
                               success_criteria=success_criteria, deadline=deadline,
                               estimated_hours=estimated_hours, assignee=assignee)
                print(f"Task created with ID: {task_id}")
            except ValueError as e:
                print(f"Error: {e}")
                sys.exit(1)
        elif command == "list":
            # Parse list filters
            status_filter = None
            assignee_filter = None
            has_deps = "--has-deps" in sys.argv
            
            if "--status" in sys.argv:
                idx = sys.argv.index("--status")
                if idx + 1 < len(sys.argv):
                    status_filter = sys.argv[idx + 1]
            
            if "--assignee" in sys.argv:
                idx = sys.argv.index("--assignee")
                if idx + 1 < len(sys.argv):
                    assignee_filter = sys.argv[idx + 1]
            
            tasks = tm.list(status=status_filter, assignee=assignee_filter, has_deps=has_deps)
            
            if not tasks:
                print("No tasks found")
            else:
                for task in tasks:
                    print(f"[{task['id']}] {task['title']} - {task['status']}")
        elif command == "show":
            if len(sys.argv) < 3:
                print("Usage: tm show <task_id>")
                sys.exit(1)
            task_id = sys.argv[2]
            task = tm.show(task_id)
            if task:
                for key, value in task.items():
                    print(f"{key}: {value}")
            else:
                print(f"Task {task_id} not found")
                sys.exit(1)
        elif command == "update":
            if len(sys.argv) < 3:
                print("Usage: tm update <task_id> --status <status>")
                sys.exit(1)
            task_id = sys.argv[2]
            # Simple status update handling
            if "--status" in sys.argv:
                idx = sys.argv.index("--status")
                if idx + 1 < len(sys.argv):
                    status = sys.argv[idx + 1]
                    tm.update(task_id, status=status)
                    print(f"Task {task_id} updated")
        elif command == "complete":
            if len(sys.argv) < 3:
                print("Usage: tm complete <task_id> [--impact-review] [--summary text] [--actual-hours N] [--validate]")
                sys.exit(1)
            task_id = sys.argv[2]
            impact_review = "--impact-review" in sys.argv
            validate = "--validate" in sys.argv
            completion_summary = None
            actual_hours = None
            
            # Parse completion arguments
            if "--summary" in sys.argv:
                idx = sys.argv.index("--summary")
                if idx + 1 < len(sys.argv):
                    # Get all text after --summary until next flag or end
                    end_idx = len(sys.argv)
                    for i in range(idx + 2, len(sys.argv)):
                        if sys.argv[i].startswith("--"):
                            end_idx = i
                            break
                    completion_summary = ' '.join(sys.argv[idx + 1:end_idx])
            
            if "--actual-hours" in sys.argv:
                idx = sys.argv.index("--actual-hours")
                if idx + 1 < len(sys.argv):
                    actual_hours = float(sys.argv[idx + 1])
            
            # Complete the task
            tm.complete(task_id, completion_summary=completion_summary, 
                       actual_hours=actual_hours, validate=validate)
            print(f"Task {task_id} completed")
            
            # If impact review requested, show potentially affected tasks
            if impact_review:
                # Get the completed task details to find file references
                task = tm.show(task_id)
                if task and task.get('description') and 'Files:' in task['description']:
                    print("\n=== Impact Review ===")
                    print("This task referenced files. Other tasks may be affected.")
                    print("Consider reviewing tasks that reference the same files.")
                    # Create a notification for impact review
                    tm.discover(task_id, f"Task completed with impact review - check related file references")
        elif command == "delete":
            if len(sys.argv) < 3:
                print("Usage: tm delete <task_id>")
                sys.exit(1)
            task_id = sys.argv[2]
            if tm.delete(task_id):
                print(f"Task {task_id} deleted")
            else:
                print(f"Failed to delete task {task_id}")
                sys.exit(1)
        elif command == "assign":
            if len(sys.argv) < 4:
                print("Usage: tm assign <task_id> <assignee>")
                sys.exit(1)
            task_id = sys.argv[2]
            assignee = sys.argv[3]
            if tm.update(task_id, assignee=assignee):
                print(f"Task {task_id} assigned to {assignee}")
            else:
                print(f"Failed to assign task {task_id}")
                sys.exit(1)
        elif command == "export":
            # Export implementation using tm_production method
            format_type = "json"  # default
            if "--format" in sys.argv:
                idx = sys.argv.index("--format")
                if idx + 1 < len(sys.argv):
                    format_type = sys.argv[idx + 1]
            
            output = tm.export(format=format_type)
            print(output)
        elif command == "watch":
            # Watch for notifications
            notifications = tm.watch()
            if not notifications:
                print("No new notifications")
            else:
                print(f"=== {len(notifications)} New Notification(s) ===")
                for notif in notifications:
                    print(f"[{notif['type'].upper()}] {notif['message']}")
                    if notif['created_at']:
                        print(f"  Time: {notif['created_at']}")
                    print()
        elif command == "progress":
            # Handle progress updates
            if len(sys.argv) < 4:
                print("Usage: tm progress <task_id> <update_message>")
                sys.exit(1)
            task_id = sys.argv[2]
            update_message = ' '.join(sys.argv[3:])
            
            if tm.progress(task_id, update_message):
                print("Progress update added")
            else:
                print(f"Failed to add progress update to task {task_id}")
                sys.exit(1)
        elif command == "feedback":
            # Handle feedback recording
            if len(sys.argv) < 3:
                print("Usage: tm feedback <task_id> [--quality N] [--timeliness N] [--note text]")
                sys.exit(1)
            task_id = sys.argv[2]
            quality = None
            timeliness = None
            note = None
            
            # Parse feedback arguments
            if "--quality" in sys.argv:
                idx = sys.argv.index("--quality")
                if idx + 1 < len(sys.argv):
                    quality = int(sys.argv[idx + 1])
            
            if "--timeliness" in sys.argv:
                idx = sys.argv.index("--timeliness")
                if idx + 1 < len(sys.argv):
                    timeliness = int(sys.argv[idx + 1])
            
            if "--note" in sys.argv:
                idx = sys.argv.index("--note")
                if idx + 1 < len(sys.argv):
                    # Get all text after --note until next flag or end
                    end_idx = len(sys.argv)
                    for i in range(idx + 2, len(sys.argv)):
                        if sys.argv[i].startswith("--"):
                            end_idx = i
                            break
                    note = ' '.join(sys.argv[idx + 1:end_idx])
            
            if tm.feedback(task_id, quality=quality, timeliness=timeliness, notes=note):
                print("Feedback recorded")
            else:
                print(f"Failed to record feedback for task {task_id}")
                sys.exit(1)
        elif command == "migrate":
            # Handle database migrations
            from migrations import MigrationManager
            
            db_path = os.path.join(os.path.expanduser("~"), ".task-orchestrator", "tasks.db")
            migrator = MigrationManager(db_path)
            
            if "--status" in sys.argv:
                status = migrator.get_status()
                print(f"Applied migrations: {', '.join(status['applied']) or 'None'}")
                print(f"Pending migrations: {', '.join(status['pending']) or 'None'}")
                print(f"Up to date: {'Yes' if status['up_to_date'] else 'No'}")
            elif "--apply" in sys.argv:
                # Create backup first
                backup_path = migrator.create_backup()
                print(f"Backup created: {backup_path}")
                
                # Apply pending migrations
                pending = migrator.get_pending_migrations()
                if not pending:
                    print("No pending migrations")
                else:
                    for migration in pending:
                        print(f"Applying migration {migration['version']}: {migration['description']}")
                        migrator.apply_migration(
                            migration['version'],
                            migration['up_sql'],
                            migration['description']
                        )
                        print(f"✓ Migration {migration['version']} applied")
            elif "--rollback" in sys.argv:
                print("Rollback will restore from backup")
                backups = sorted(Path(migrator.backups_dir).glob("*.db"))
                if backups:
                    latest_backup = backups[-1]
                    print(f"Restoring from: {latest_backup}")
                    shutil.copy2(latest_backup, db_path)
                    print("Database restored from backup")
                else:
                    print("No backups available")
            elif "--dry-run" in sys.argv:
                pending = migrator.get_pending_migrations()
                if not pending:
                    print("No pending migrations")
                else:
                    for migration in pending:
                        print(f"Would apply: {migration['version']} - {migration['description']}")
                        changes = migrator.dry_run(migration['version'], migration['up_sql'])
                        for change in changes:
                            print(f"  - {change}")
            else:
                print("Usage: tm migrate [--status|--apply|--rollback|--dry-run]")
        elif command == "config":
            # Handle configuration management
            from config_manager import ConfigManager
            
            config_path = os.path.join(os.path.expanduser("~"), ".task-orchestrator", "config.yaml")
            config = ConfigManager(config_path)
            
            if "--enable" in sys.argv:
                idx = sys.argv.index("--enable")
                if idx + 1 < len(sys.argv):
                    feature = sys.argv[idx + 1]
                    config.enable_feature(feature)
                    print(f"Feature '{feature}' enabled")
            elif "--disable" in sys.argv:
                idx = sys.argv.index("--disable")
                if idx + 1 < len(sys.argv):
                    feature = sys.argv[idx + 1]
                    config.disable_feature(feature)
                    print(f"Feature '{feature}' disabled")
            elif "--minimal-mode" in sys.argv:
                config.set_minimal_mode(True)
                print("Minimal mode enabled - all Core Loop features disabled")
            elif "--show" in sys.argv:
                settings = config.get_all_settings()
                print("Current configuration:")
                for key, value in settings.items():
                    print(f"  {key}: {value}")
            elif "--reset" in sys.argv:
                config.reset_to_defaults()
                print("Configuration reset to defaults")
            else:
                print("Usage: tm config [--enable|--disable <feature>|--minimal-mode|--show|--reset]")
        elif command == "feedback":
            # Handle feedback command
            if len(sys.argv) < 3:
                print("Usage: tm feedback <task_id> [--quality N] [--timeliness N] [--note text]")
                sys.exit(1)
            
            task_id = sys.argv[2]
            quality = None
            timeliness = None
            note = None
            
            # Parse feedback arguments
            if "--quality" in sys.argv:
                idx = sys.argv.index("--quality")
                if idx + 1 < len(sys.argv):
                    quality = int(sys.argv[idx + 1])
            
            if "--timeliness" in sys.argv:
                idx = sys.argv.index("--timeliness")
                if idx + 1 < len(sys.argv):
                    timeliness = int(sys.argv[idx + 1])
            
            if "--note" in sys.argv:
                idx = sys.argv.index("--note")
                if idx + 1 < len(sys.argv):
                    note = ' '.join(sys.argv[idx + 1:])
            
            # Store feedback using TaskManager
            if tm.feedback(task_id, quality, timeliness, note):
                print(f"Feedback recorded for task {task_id}")
            else:
                print(f"Failed to record feedback for task {task_id}")
                sys.exit(1)
        elif command == "progress":
            # Handle progress updates
            if len(sys.argv) < 4:
                print("Usage: tm progress <task_id> <update_message>")
                sys.exit(1)
            
            task_id = sys.argv[2]
            update = ' '.join(sys.argv[3:])
            
            if tm.progress(task_id, update):
                print(f"Progress update added to task {task_id}")
            else:
                print(f"Failed to add progress update")
                sys.exit(1)
        elif command == "metrics":
            # Handle metrics command with real calculations
            if "--feedback" in sys.argv:
                from metrics_calculator import MetricsCalculator
                calculator = MetricsCalculator(tm.db_path)
                metrics = calculator.get_feedback_metrics()
                
                print("Feedback metrics:")
                print(f"  Average quality: {metrics['avg_quality']:.1f}/5")
                print(f"  Average timeliness: {metrics['avg_timeliness']:.1f}/5")
                print(f"  Tasks with feedback: {metrics['tasks_with_feedback']}")
                print(f"  Total tasks: {metrics['total_tasks']}")
                print(f"  Feedback coverage: {metrics['feedback_coverage']:.1%}")
            else:
                print("Usage: tm metrics [--feedback]")
        elif command == "critical-path":
            # Critical path visualization
            # @implements FR-043: Critical Path Visualization Support
            
            # Import dependency graph
            sys.path.insert(0, str(Path(__file__).parent / "src"))
            from dependency_graph import DependencyGraph
            
            # Get all tasks (exclude completed)
            tasks = tm.list(status="pending")
            
            if not tasks:
                print("No active tasks to analyze")
                sys.exit(0)
            
            # Build dependency graph
            graph = DependencyGraph()
            task_map = {}  # Map task ID to task details
            
            # Add nodes
            for task in tasks:
                task_id = task.get('id', '')
                task_map[task_id] = task
                estimated_hours = task.get('estimated_hours', 1.0)
                graph.add_node(task_id, weight=estimated_hours)
            
            # Add edges based on dependencies
            for task in tasks:
                task_id = task.get('id', '')
                depends_on = task.get('depends_on', [])
                for dep_id in depends_on:
                    # Note: task depends on dep_id
                    graph.add_edge(task_id, dep_id)
            
            # Find critical path
            critical_path, total_hours = graph.find_critical_path()
            
            if not critical_path:
                print("No critical path found (possible cycle or no dependencies)")
                sys.exit(0)
            
            # Identify blocking tasks
            blocking_scores = graph.identify_blocking_tasks()
            
            # Sort tasks by blocking score
            sorted_blockers = sorted(
                blocking_scores.items(), 
                key=lambda x: x[1], 
                reverse=True
            )[:5]  # Top 5 blockers
            
            # Display results
            print("\n🎯 CRITICAL PATH ANALYSIS")
            print("=" * 60)
            
            print(f"\n📊 Critical Path ({total_hours:.1f} hours total):")
            print("-" * 40)
            for i, node_id in enumerate(critical_path, 1):
                task = task_map.get(node_id, {})
                description = task.get('description') or task.get('title') or 'Unknown task'
                description = description[:50] if description else 'Unknown'
                hours = graph.weights.get(node_id, 1.0)
                print(f"{i}. [{node_id[:8]}] {description} ({hours:.1f}h)")
            
            print(f"\n⏱️  Total Critical Path Duration: {total_hours:.1f} hours")
            
            print("\n🚫 Top Blocking Tasks:")
            print("-" * 40)
            for node_id, score in sorted_blockers:
                task = task_map.get(node_id, {})
                description = task.get('description') or task.get('title') or 'Unknown task'
                description = description[:50] if description else 'Unknown'
                dependents = len(graph.get_dependents(node_id))
                on_critical = "🔴 CRITICAL" if node_id in critical_path else ""
                print(f"• [{node_id[:8]}] {description}")
                print(f"  Blocks: {dependents} tasks | Score: {score:.1f} {on_critical}")
            
            # Optional: Generate DOT file for graphical visualization
            if len(sys.argv) > 2 and sys.argv[2] == "--dot":
                dot_content = graph.to_dot()
                dot_file = Path(".task-orchestrator/critical-path.dot")
                dot_file.parent.mkdir(parents=True, exist_ok=True)
                dot_file.write_text(dot_content)
                print(f"\n📈 DOT file saved to: {dot_file}")
                print("   Visualize with: dot -Tpng critical-path.dot -o critical-path.png")
        
        elif command == "report":
            # Handle assessment report generation (FR-037)
            if "--assessment" in sys.argv:
                from assessment_reporter import AssessmentReporter
                reporter = AssessmentReporter(tm.db_path)
                
                # Generate comprehensive assessment
                assessment_data = reporter.generate_30_day_assessment()
                
                # Format and display report
                formatted_report = reporter.format_assessment_report(assessment_data)
                print(formatted_report)
                
                # Save report to file
                report_file = Path(".task-orchestrator/reports/30_day_assessment.txt")
                report_file.parent.mkdir(parents=True, exist_ok=True)
                report_file.write_text(formatted_report)
                print(f"\nReport saved to: {report_file}")
                
                # Also save raw JSON data
                json_file = Path(".task-orchestrator/reports/30_day_assessment.json")
                json_file.write_text(json.dumps(assessment_data, indent=2))
                print(f"Raw data saved to: {json_file}")
            else:
                print("Usage: tm report [--assessment]")
        elif command == "template":
            # Template management commands
            from template_parser import TemplateParser
            from template_instantiator import TemplateInstantiator
            
            parser = TemplateParser()
            instantiator = TemplateInstantiator()
            
            if len(sys.argv) < 3:
                print("Usage: tm template <subcommand> [options]")
                print("Subcommands:")
                print("  list                    List available templates")
                print("  show <name>            Show template details")
                print("  apply <name> [vars]    Apply template with variables")
                print("  create                 Interactive template builder")
                sys.exit(1)
            
            subcommand = sys.argv[2]
            
            if subcommand == "list":
                # List all available templates
                templates = parser.list_templates()
                if not templates:
                    print("No templates found in .task-orchestrator/templates/")
                else:
                    print("Available Templates:")
                    print("=" * 50)
                    for tmpl in templates:
                        print(f"\n{tmpl['name']} (v{tmpl['version']})")
                        print(f"  {tmpl['description']}")
                        if tmpl['tags']:
                            print(f"  Tags: {', '.join(tmpl['tags'])}")
                            
            elif subcommand == "show":
                # Show template details
                if len(sys.argv) < 4:
                    print("Usage: tm template show <name>")
                    sys.exit(1)
                    
                template_name = sys.argv[3]
                try:
                    template = parser.get_template(template_name)
                    print(f"Template: {template['name']} (v{template['version']})")
                    print(f"Description: {template['description']}")
                    print("\nVariables:")
                    for var_name, var_def in template.get('variables', {}).items():
                        required = " (required)" if var_def.get('required', False) else ""
                        default = f" [default: {var_def.get('default')}]" if 'default' in var_def else ""
                        print(f"  {var_name}: {var_def['type']}{required}{default}")
                        print(f"    {var_def['description']}")
                    print(f"\nTasks: {len(template['tasks'])} tasks will be created")
                    for i, task in enumerate(template['tasks']):
                        print(f"  {i+1}. {task['title']}")
                except Exception as e:
                    print(f"Error: {e}")
                    sys.exit(1)
                    
            elif subcommand == "apply":
                # Apply a template
                if len(sys.argv) < 4:
                    print("Usage: tm template apply <name> [--var name=value ...]")
                    sys.exit(1)
                    
                template_name = sys.argv[3]
                variables = {}
                
                # Parse variable arguments
                i = 4
                while i < len(sys.argv):
                    if sys.argv[i] == "--var" and i + 1 < len(sys.argv):
                        var_assignment = sys.argv[i + 1]
                        if '=' in var_assignment:
                            var_name, var_value = var_assignment.split('=', 1)
                            # Try to parse as number or boolean
                            if var_value.lower() in ['true', 'false']:
                                variables[var_name] = var_value.lower() == 'true'
                            elif var_value.isdigit():
                                variables[var_name] = int(var_value)
                            elif '.' in var_value and var_value.replace('.', '').isdigit():
                                variables[var_name] = float(var_value)
                            else:
                                variables[var_name] = var_value
                        i += 2
                    else:
                        i += 1
                
                try:
                    # Load and instantiate template
                    template = parser.get_template(template_name)
                    tasks = instantiator.instantiate(template, variables)
                    
                    # Create tasks in Task Orchestrator
                    created_ids = []
                    for task in tasks:
                        # Build add command arguments
                        title = task['title']
                        
                        # Create the task
                        task_id = tm.add(title, 
                                       description=task.get('description'),
                                       priority=task.get('priority'),
                                       assignee=task.get('assignee'),
                                       depends_on=None,  # We'll handle dependencies separately
                                       estimated_hours=task.get('estimated_hours'))
                        
                        if task_id:
                            created_ids.append(task_id)
                            print(f"Created task {task_id}: {title}")
                            
                            # Update with dependencies if present
                            if 'depends_on' in task and task['depends_on']:
                                # Dependencies already have the correct IDs from instantiator
                                for dep_id in task['depends_on']:
                                    # Find the actual created ID that corresponds to this template ID
                                    actual_dep_id = None
                                    for orig_idx, template_task_id in instantiator.task_id_map.items():
                                        if template_task_id == dep_id:
                                            # This is the index, get the created ID
                                            if orig_idx < len(created_ids):
                                                actual_dep_id = created_ids[orig_idx]
                                                break
                                    
                                    if actual_dep_id:
                                        # Update task to add dependency
                                        # Note: This would need to be implemented in tm_production
                                        pass
                        else:
                            print(f"Failed to create task: {title}")
                    
                    print(f"\nSuccessfully created {len(created_ids)} tasks from template '{template_name}'")
                    
                except Exception as e:
                    print(f"Error applying template: {e}")
                    import traceback
                    traceback.print_exc()
                    sys.exit(1)
                    
            elif subcommand == "create":
                # Interactive template builder
                print("Interactive template builder - Coming soon!")
                print("For now, create templates manually in .task-orchestrator/templates/")
                
            else:
                print(f"Unknown template subcommand: {subcommand}")
                sys.exit(1)
        elif command == "wizard":
            # Interactive wizard for guided task creation
            from interactive_wizard import InteractiveWizard
            from template_parser import TemplateParser
            from template_instantiator import TemplateInstantiator
            
            parser = TemplateParser()
            instantiator = TemplateInstantiator()
            wizard = InteractiveWizard(parser, instantiator, tm)
            
            # Check for quick mode
            if len(sys.argv) > 2 and sys.argv[2] == "--quick":
                success = wizard.quick_start()
            else:
                success = wizard.run()
            
            if not success:
                sys.exit(1)
        elif command == "hooks":
            # Hook performance monitoring commands
            from hook_performance_monitor import HookPerformanceMonitor
            
            monitor = HookPerformanceMonitor()
            
            if len(sys.argv) < 3:
                print("Usage: tm hooks <subcommand> [options]")
                print("Subcommands:")
                print("  report [hook_name]     Show performance report")
                print("  alerts [severity]      Show recent alerts")
                print("  thresholds             Configure performance thresholds")
                print("  cleanup [days]         Clean up old metrics")
                sys.exit(1)
            
            subcommand = sys.argv[2]
            
            if subcommand == "report":
                # Generate performance report
                hook_name = sys.argv[3] if len(sys.argv) > 3 else None
                days = int(sys.argv[4]) if len(sys.argv) > 4 else 7
                
                report = monitor.get_performance_report(hook_name, days)
                
                if hook_name:
                    # Specific hook report
                    print(f"\n=== Performance Report: {hook_name} ===")
                    print(f"Period: Last {days} days\n")
                    
                    summary = report.get('summary', {})
                    print("Summary Statistics:")
                    print(f"  Total Executions: {summary.get('total_executions', 0)}")
                    print(f"  Success Rate: {summary.get('success_rate', 0):.1f}%")
                    print(f"  Avg Duration: {summary.get('avg_duration_ms', 0):.1f}ms")
                    print(f"  P50 Duration: {summary.get('p50_duration_ms', 0):.1f}ms")
                    print(f"  P95 Duration: {summary.get('p95_duration_ms', 0):.1f}ms")
                    print(f"  P99 Duration: {summary.get('p99_duration_ms', 0):.1f}ms")
                    
                    if report.get('alerts'):
                        print(f"\nRecent Alerts ({len(report['alerts'])}):")
                        for alert in report['alerts'][:5]:
                            print(f"  [{alert['severity'].upper()}] {alert['message']}")
                else:
                    # Overall report
                    print(f"\n=== Hook Performance Report ===")
                    print(f"Period: Last {days} days\n")
                    
                    overall = report.get('overall', {})
                    print("Overall Statistics:")
                    print(f"  Total Executions: {overall.get('total_executions', 0)}")
                    print(f"  Success Rate: {overall.get('success_rate', 0):.1f}%")
                    print(f"  Avg Duration: {overall.get('avg_duration_ms', 0):.1f}ms")
                    
                    if report.get('hooks'):
                        print("\nTop Hooks by Executions:")
                        for hook in report['hooks'][:10]:
                            print(f"  {hook['name']}:")
                            print(f"    Executions: {hook['total']}")
                            print(f"    Success Rate: {hook['success_rate']:.1f}%")
                            print(f"    Avg Duration: {hook['avg_duration_ms']:.1f}ms")
                            print(f"    P95 Duration: {hook['p95_duration_ms']:.1f}ms")
                    
                    if report.get('slow_hooks'):
                        print("\nSlow Hooks (>" + str(monitor.thresholds['warning_ms']) + "ms):")
                        for hook in report['slow_hooks']:
                            print(f"  {hook['name']}: {hook['slow_executions']} slow executions")
                            
            elif subcommand == "alerts":
                # Show recent alerts
                severity = sys.argv[3] if len(sys.argv) > 3 else None
                hours = int(sys.argv[4]) if len(sys.argv) > 4 else 24
                
                alerts = monitor.get_alerts(severity, hours)
                
                if alerts:
                    print(f"\n=== Hook Performance Alerts ===")
                    print(f"Last {hours} hours")
                    if severity:
                        print(f"Severity: {severity}\n")
                    
                    for alert in alerts:
                        timestamp = alert['timestamp'].split('.')[0] if alert['timestamp'] else 'Unknown'
                        print(f"[{timestamp}] {alert['severity'].upper()}: {alert['hook_name']}")
                        print(f"  {alert['message']}")
                        if alert['duration_ms']:
                            print(f"  Duration: {alert['duration_ms']:.0f}ms")
                        print()
                else:
                    print(f"No alerts in the last {hours} hours")
                    
            elif subcommand == "thresholds":
                # Configure thresholds
                if len(sys.argv) > 3:
                    # Set thresholds
                    warning = int(sys.argv[3]) if len(sys.argv) > 3 else None
                    critical = int(sys.argv[4]) if len(sys.argv) > 4 else None
                    timeout = int(sys.argv[5]) if len(sys.argv) > 5 else None
                    
                    monitor.configure_thresholds(warning, critical, timeout)
                    print("Thresholds updated successfully")
                
                # Show current thresholds
                print("\nCurrent Performance Thresholds:")
                print(f"  Warning: {monitor.thresholds['warning_ms']}ms")
                print(f"  Critical: {monitor.thresholds['critical_ms']}ms")
                print(f"  Timeout: {monitor.thresholds['timeout_ms']}ms")
                
            elif subcommand == "cleanup":
                # Clean up old metrics
                days = int(sys.argv[3]) if len(sys.argv) > 3 else 30
                deleted = monitor.cleanup_old_metrics(days)
                print(f"Cleaned up {deleted} old metric records (older than {days} days)")
                
            else:
                print(f"Unknown hooks subcommand: {subcommand}")
                sys.exit(1)
        else:
            print(f"Command '{command}' not yet implemented in enhanced wrapper")
            print("Please use the production module directly for full functionality")

def find_repo_root() -> Path:
    """Find git repository root"""
    try:
        result = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            capture_output=True, text=True, check=True
        )
        return Path(result.stdout.strip())
    except subprocess.CalledProcessError:
        return Path.cwd()

if __name__ == "__main__":
    # Show enhanced help if requested
    if len(sys.argv) > 1 and sys.argv[1] in ['--help', '-h', 'help']:
        print("""Task Manager - Enhanced with Collaboration Features

Standard Commands:
  init                Initialize task database
  add <title>         Add a new task
  list                List all tasks
  show <id>           Show task details
  update <id>         Update task properties
  delete <id>         Delete a task
  complete <id>       Mark task as complete
  assign <id> <agent> Assign task to agent
  watch               Check for notifications
  export              Export tasks

Collaboration Commands:
  join <id>           Join a task's collaboration
  share <id> <msg>    Share update with all agents
  note <id> <msg>     Add private note (only you see)
  discover <id> <msg> Share critical finding (alerts all)
  sync <id> <msg>     Create synchronization point
  context <id>        View all shared context

Template Commands:
  template list       List available templates
  template show <name> Show template details
  template apply <name> Apply template with variables
  template create     Interactive template builder

Interactive Mode:
  wizard              Interactive guided task creation
  wizard --quick      Quick task creation mode

Hook Performance:
  hooks report        Show hook performance metrics
  hooks alerts        View performance alerts
  hooks thresholds    Configure alert thresholds
  hooks cleanup       Clean up old metrics

Environment Variables:
  TM_AGENT_ID         Set your agent identifier
  TM_DB_PATH          Custom database location

Examples:
  tm add "Build feature"
  tm join task_123
  tm share task_123 "Database schema complete"
  tm note task_123 "Consider using Redis for cache"
  tm discover task_123 "Security issue in auth flow"
  tm context task_123
""")
        sys.exit(0)
    
    main()