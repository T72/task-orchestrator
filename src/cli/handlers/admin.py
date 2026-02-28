from __future__ import annotations

import json
import shutil
import sys
from pathlib import Path
from typing import Optional

from cli.context import CLIContext
from storage_paths import resolve_config_path, resolve_db_path


ADMIN_COMMANDS = {
    "migrate",
    "config",
    "metrics",
    "critical-path",
    "report",
    "template",
    "wizard",
    "hooks",
    "phase-create",
    "phase-list",
    "phase-show",
    "phase-update",
    "phase-add-dependency",
    "phase-add-gate",
    "agent-register",
    "agent-list",
    "agent-status",
    "agent-workload",
    "agent-metrics",
    "agent-message",
    "agent-redistribute",
}


def handle_admin(command: str, context: CLIContext) -> Optional[int]:
    argv = context.argv
    tm = context.tm

    if command == "migrate":
        from migrations import MigrationManager

        db_path = str(resolve_db_path())
        migrator = MigrationManager(db_path)

        if "--status" in argv:
            status = migrator.get_status()
            print(f"Applied migrations: {', '.join(status['applied']) or 'None'}")
            print(f"Pending migrations: {', '.join(status['pending']) or 'None'}")
            print(f"Up to date: {'Yes' if status['up_to_date'] else 'No'}")
            return 0
        if "--apply" in argv:
            backup_path = migrator.create_backup()
            print(f"Backup created: {backup_path}")
            pending = migrator.get_pending_migrations()
            if not pending:
                print("No pending migrations")
                return 0
            for migration in pending:
                print(f"Applying migration {migration['version']}: {migration['description']}")
                migrator.apply_migration(migration['version'], migration['up_sql'], migration['description'])
                print(f"✓ Migration {migration['version']} applied")
            return 0
        if "--rollback" in argv:
            print("Rollback will restore from backup")
            backups = sorted(Path(migrator.backups_dir).glob("*.db"))
            if backups:
                latest_backup = backups[-1]
                print(f"Restoring from: {latest_backup}")
                shutil.copy2(latest_backup, db_path)
                print("Database restored from backup")
                return 0
            print("No backups available")
            return 1
        if "--dry-run" in argv:
            pending = migrator.get_pending_migrations()
            if not pending:
                print("No pending migrations")
                return 0
            for migration in pending:
                print(f"Would apply: {migration['version']} - {migration['description']}")
                changes = migrator.dry_run(migration['version'], migration['up_sql'])
                for change in changes:
                    print(f"  - {change}")
            return 0

        print("Usage: tm migrate [--status|--apply|--rollback|--dry-run]")
        return 1

    if command == "config":
        from config_manager import ConfigManager

        config = ConfigManager(str(resolve_config_path()))

        if "--enable" in argv:
            idx = argv.index("--enable")
            if idx + 1 < len(argv):
                feature = argv[idx + 1]
                config.enable_feature(feature)
                print(f"Feature '{feature}' enabled")
                return 0
        elif "--disable" in argv:
            idx = argv.index("--disable")
            if idx + 1 < len(argv):
                feature = argv[idx + 1]
                config.disable_feature(feature)
                print(f"Feature '{feature}' disabled")
                return 0
        elif "--minimal-mode" in argv:
            config.set_minimal_mode(True)
            print("Minimal mode enabled - all Core Loop features disabled")
            return 0
        elif "--show" in argv:
            settings = config.get_all_settings()
            print("Current configuration:")
            for key, value in settings.items():
                print(f"  {key}: {value}")
            return 0
        elif "--reset" in argv:
            config.reset_to_defaults()
            print("Configuration reset to defaults")
            return 0

        print("Usage: tm config [--enable|--disable <feature>|--minimal-mode|--show|--reset]")
        return 1

    if command == "metrics":
        if "--feedback" in argv:
            from metrics_calculator import MetricsCalculator

            calculator = MetricsCalculator(tm.db_path)
            metrics = calculator.get_feedback_metrics()

            print("Feedback metrics:")
            print(f"  Average quality: {metrics['avg_quality']:.1f}/5")
            print(f"  Average timeliness: {metrics['avg_timeliness']:.1f}/5")
            print(f"  Tasks with feedback: {metrics['tasks_with_feedback']}")
            print(f"  Total tasks: {metrics['total_tasks']}")
            print(f"  Feedback coverage: {metrics['feedback_coverage']:.1%}")
            return 0

        print("Usage: tm metrics [--feedback]")
        return 1

    if command == "critical-path":
        from dependency_graph import DependencyGraph

        tasks = tm.list(status="pending")
        if not tasks:
            print("No active tasks to analyze")
            return 0

        graph = DependencyGraph()
        task_map = {}

        for task in tasks:
            task_id = task.get("id", "")
            task_map[task_id] = task
            graph.add_node(task_id, weight=task.get("estimated_hours", 1.0))

        for task in tasks:
            task_id = task.get("id", "")
            for dep_id in task.get("depends_on", []):
                graph.add_edge(task_id, dep_id)

        critical_path, total_hours = graph.find_critical_path()
        if not critical_path:
            print("No critical path found (possible cycle or no dependencies)")
            return 0

        blocking_scores = graph.identify_blocking_tasks()
        sorted_blockers = sorted(blocking_scores.items(), key=lambda x: x[1], reverse=True)[:5]

        print("\n🎯 CRITICAL PATH ANALYSIS")
        print("=" * 60)
        print(f"\n📊 Critical Path ({total_hours:.1f} hours total):")
        print("-" * 40)
        for i, node_id in enumerate(critical_path, 1):
            task = task_map.get(node_id, {})
            description = task.get("description") or task.get("title") or "Unknown task"
            description = description[:50] if description else "Unknown"
            hours = graph.weights.get(node_id, 1.0)
            print(f"{i}. [{node_id[:8]}] {description} ({hours:.1f}h)")

        print(f"\n⏱️  Total Critical Path Duration: {total_hours:.1f} hours")
        print("\n🚫 Top Blocking Tasks:")
        print("-" * 40)
        for node_id, score in sorted_blockers:
            task = task_map.get(node_id, {})
            description = task.get("description") or task.get("title") or "Unknown task"
            description = description[:50] if description else "Unknown"
            dependents = len(graph.get_dependents(node_id))
            on_critical = "🔴 CRITICAL" if node_id in critical_path else ""
            print(f"• [{node_id[:8]}] {description}")
            print(f"  Blocks: {dependents} tasks | Score: {score:.1f} {on_critical}")

        if len(argv) > 2 and argv[2] == "--dot":
            dot_content = graph.to_dot()
            dot_file = Path(".task-orchestrator/critical-path.dot")
            dot_file.parent.mkdir(parents=True, exist_ok=True)
            dot_file.write_text(dot_content)
            print(f"\n📈 DOT file saved to: {dot_file}")
            print("   Visualize with: dot -Tpng critical-path.dot -o critical-path.png")

        return 0

    if command == "report":
        if "--assessment" in argv:
            from assessment_reporter import AssessmentReporter

            reporter = AssessmentReporter(tm.db_path)
            assessment_data = reporter.generate_30_day_assessment()
            formatted_report = reporter.format_assessment_report(assessment_data)
            print(formatted_report)

            report_file = Path(".task-orchestrator/reports/30_day_assessment.txt")
            report_file.parent.mkdir(parents=True, exist_ok=True)
            report_file.write_text(formatted_report)
            print(f"\nReport saved to: {report_file}")

            json_file = Path(".task-orchestrator/reports/30_day_assessment.json")
            json_file.write_text(json.dumps(assessment_data, indent=2))
            print(f"Raw data saved to: {json_file}")
            return 0

        print("Usage: tm report [--assessment]")
        return 1

    if command == "template":
        from template_parser import TemplateParser
        from template_instantiator import TemplateInstantiator

        parser = TemplateParser()
        instantiator = TemplateInstantiator()

        if len(argv) < 3:
            print("Usage: tm template <subcommand> [options]")
            print("Subcommands:")
            print("  list                    List available templates")
            print("  show <name>            Show template details")
            print("  apply <name> [vars]    Apply template with variables")
            print("  create                 Interactive template builder")
            return 1

        subcommand = argv[2]

        if subcommand == "list":
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
            return 0

        if subcommand == "show":
            if len(argv) < 4:
                print("Usage: tm template show <name>")
                return 1
            template_name = argv[3]
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
                return 0
            except Exception as e:
                print(f"Error: {e}")
                return 1

        if subcommand == "apply":
            if len(argv) < 4:
                print("Usage: tm template apply <name> [--var name=value ...]")
                return 1
            template_name = argv[3]
            variables = {}
            i = 4
            while i < len(argv):
                if argv[i] == "--var" and i + 1 < len(argv):
                    var_assignment = argv[i + 1]
                    if '=' in var_assignment:
                        var_name, var_value = var_assignment.split('=', 1)
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
                template = parser.get_template(template_name)
                tasks = instantiator.instantiate(template, variables)
                created_ids = []
                for task in tasks:
                    title = task['title']
                    task_id = tm.add(
                        title,
                        description=task.get('description'),
                        priority=task.get('priority'),
                        assignee=task.get('assignee'),
                        depends_on=None,
                        estimated_hours=task.get('estimated_hours')
                    )
                    if task_id:
                        created_ids.append(task_id)
                        print(f"Created task {task_id}: {title}")
                    else:
                        print(f"Failed to create task: {title}")
                print(f"\nSuccessfully created {len(created_ids)} tasks from template '{template_name}'")
                return 0
            except Exception as e:
                print(f"Error applying template: {e}")
                import traceback
                traceback.print_exc()
                return 1

        if subcommand == "create":
            print("Interactive template builder - Coming soon!")
            print("For now, create templates manually in .task-orchestrator/templates/")
            return 0

        print(f"Unknown template subcommand: {subcommand}")
        return 1

    if command == "wizard":
        from interactive_wizard import InteractiveWizard
        from template_parser import TemplateParser
        from template_instantiator import TemplateInstantiator

        parser = TemplateParser()
        instantiator = TemplateInstantiator()
        wizard = InteractiveWizard(parser, instantiator, tm)
        success = wizard.quick_start() if len(argv) > 2 and argv[2] == "--quick" else wizard.run()
        return 0 if success else 1

    if command == "hooks":
        from hook_performance_monitor import HookPerformanceMonitor

        monitor = HookPerformanceMonitor()
        if len(argv) < 3:
            print("Usage: tm hooks <subcommand> [options]")
            return 1

        subcommand = argv[2]
        if subcommand == "report":
            hook_name = argv[3] if len(argv) > 3 else None
            days = int(argv[4]) if len(argv) > 4 else 7
            report = monitor.get_performance_report(hook_name, days)
            if hook_name:
                print(f"\n=== Performance Report: {hook_name} ===")
                print(f"Period: Last {days} days\n")
                summary = report.get('summary', {})
                print("Summary Statistics:")
                print(f"  Total Executions: {summary.get('total_executions', 0)}")
                print(f"  Success Rate: {summary.get('success_rate', 0):.1f}%")
                print(f"  Avg Duration: {summary.get('avg_duration_ms', 0):.1f}ms")
            else:
                print(f"\n=== Hook Performance Report ===")
                print(f"Period: Last {days} days\n")
                overall = report.get('overall', {})
                print("Overall Statistics:")
                print(f"  Total Executions: {overall.get('total_executions', 0)}")
                print(f"  Success Rate: {overall.get('success_rate', 0):.1f}%")
                print(f"  Avg Duration: {overall.get('avg_duration_ms', 0):.1f}ms")
            return 0

        if subcommand == "alerts":
            severity = argv[3] if len(argv) > 3 else None
            hours = int(argv[4]) if len(argv) > 4 else 24
            alerts = monitor.get_alerts(severity, hours)
            if alerts:
                print(f"\n=== Hook Performance Alerts ===")
                print(f"Last {hours} hours")
                for alert in alerts:
                    ts = alert['timestamp'].split('.')[0] if alert.get('timestamp') else 'Unknown'
                    print(f"[{ts}] {alert['severity'].upper()}: {alert['hook_name']}")
                    print(f"  {alert['message']}")
            else:
                print(f"No alerts in the last {hours} hours")
            return 0

        if subcommand == "thresholds":
            if len(argv) > 3:
                warning = int(argv[3]) if len(argv) > 3 else None
                critical = int(argv[4]) if len(argv) > 4 else None
                timeout = int(argv[5]) if len(argv) > 5 else None
                monitor.configure_thresholds(warning, critical, timeout)
                print("Thresholds updated successfully")
            print("\nCurrent Performance Thresholds:")
            print(f"  Warning: {monitor.thresholds['warning_ms']}ms")
            print(f"  Critical: {monitor.thresholds['critical_ms']}ms")
            print(f"  Timeout: {monitor.thresholds['timeout_ms']}ms")
            return 0

        if subcommand == "cleanup":
            days = int(argv[3]) if len(argv) > 3 else 30
            deleted = monitor.cleanup_old_metrics(days)
            print(f"Cleaned up {deleted} old metric records (older than {days} days)")
            return 0

        print(f"Unknown hooks subcommand: {subcommand}")
        return 1

    if command.startswith("phase-"):
        pm = tm.phase_manager
        if pm is None:
            print("Phase management is unavailable in this distribution.")
            return 1

        if command == "phase-create":
            if len(argv) < 3:
                print("Usage: tm phase-create <name> [--description desc] [--parent phase_id]")
                return 1
            name = argv[2]
            description = None
            parent_id = None
            i = 3
            while i < len(argv):
                if argv[i] == "--description" and i + 1 < len(argv):
                    description = argv[i + 1]
                    i += 2
                elif argv[i] == "--parent" and i + 1 < len(argv):
                    parent_id = argv[i + 1]
                    i += 2
                else:
                    i += 1
            try:
                phase_id = pm.create_phase(name, description, parent_id)
                print(f"Phase created with ID: {phase_id}")
                return 0
            except Exception as e:
                print(f"Error creating phase: {e}")
                return 1

        if command == "phase-list":
            status = None
            parent_id = None
            i = 2
            while i < len(argv):
                if argv[i] == "--status" and i + 1 < len(argv):
                    status = argv[i + 1]
                    i += 2
                elif argv[i] == "--parent" and i + 1 < len(argv):
                    parent_id = argv[i + 1]
                    i += 2
                else:
                    i += 1
            phases = pm.list_phases(status, parent_id)
            if not phases:
                print("No phases found")
            else:
                print(f"{'ID':<10} {'Name':<30} {'Status':<12} {'Progress'}")
                print("-" * 60)
                for phase in phases:
                    progress = pm.get_phase_progress(phase['id'])
                    print(f"{phase['id']:<10} {phase['name'][:30]:<30} {phase['status']:<12} {progress:.0f}%")
            return 0

        if command == "phase-show":
            if len(argv) < 3:
                print("Usage: tm phase-show <phase_id>")
                return 1
            try:
                phase = pm.show_phase(argv[2])
                print(f"\n=== Phase: {phase['name']} ===")
                print(f"ID: {phase['id']}")
                print(f"Status: {phase['status']}")
                return 0
            except Exception as e:
                print(f"Error showing phase: {e}")
                return 1

        if command == "phase-update":
            if len(argv) < 3:
                print("Usage: tm phase-update <phase_id> [--name name] [--status status] [--description desc]")
                return 1
            phase_id = argv[2]
            updates = {}
            i = 3
            while i < len(argv):
                if argv[i] == "--name" and i + 1 < len(argv):
                    updates['name'] = argv[i + 1]
                    i += 2
                elif argv[i] == "--status" and i + 1 < len(argv):
                    updates['status'] = argv[i + 1]
                    i += 2
                elif argv[i] == "--description" and i + 1 < len(argv):
                    updates['description'] = argv[i + 1]
                    i += 2
                else:
                    i += 1
            if not updates:
                print("No updates specified")
                return 1
            try:
                pm.update_phase(phase_id, **updates)
                print(f"Phase {phase_id} updated successfully")
                return 0
            except Exception as e:
                print(f"Error updating phase: {e}")
                return 1

        if command == "phase-add-dependency":
            if len(argv) < 4:
                print("Usage: tm phase-add-dependency <phase_id> <depends_on_phase_id>")
                return 1
            try:
                pm.add_phase_dependency(argv[2], argv[3])
                print(f"Dependency added: {argv[2]} depends on {argv[3]}")
                return 0
            except Exception as e:
                print(f"Error adding dependency: {e}")
                return 1

        if command == "phase-add-gate":
            if len(argv) < 4:
                print("Usage: tm phase-add-gate <phase_id> <gate_type> [--threshold N]")
                return 1
            phase_id = argv[2]
            gate_type = argv[3]
            criteria = {}
            i = 4
            while i < len(argv):
                if argv[i] == "--threshold" and i + 1 < len(argv):
                    criteria['threshold'] = float(argv[i + 1])
                    i += 2
                else:
                    i += 1
            if gate_type == "task_completion" and 'threshold' not in criteria:
                criteria['threshold'] = 100
            try:
                gate_id = pm.add_phase_gate(phase_id, gate_type, criteria)
                print(f"Gate added with ID: {gate_id}")
                return 0
            except Exception as e:
                print(f"Error adding gate: {e}")
                return 1

    if command.startswith("agent-"):
        from src.agent_manager import AgentManager

        if command == "agent-register":
            if len(argv) < 4:
                print("Usage: tm agent-register <agent_id> <name> [--type <type>] [--capabilities <cap1,cap2>]")
                return 1
            agent_id = argv[2]
            name = argv[3]
            agent_type = None
            capabilities = []
            if "--type" in argv:
                idx = argv.index("--type")
                if idx + 1 < len(argv):
                    agent_type = argv[idx + 1]
            if "--capabilities" in argv:
                idx = argv.index("--capabilities")
                if idx + 1 < len(argv):
                    capabilities = argv[idx + 1].split(',')
            with AgentManager() as am:
                if am.register_agent(agent_id, name, agent_type, capabilities):
                    print(f"✅ Agent '{agent_id}' registered successfully")
                    return 0
                print(f"❌ Failed to register agent '{agent_id}'")
                return 1

        if command == "agent-list":
            status_filter = "active"
            type_filter = None
            if "--status" in argv:
                idx = argv.index("--status")
                if idx + 1 < len(argv):
                    status_filter = argv[idx + 1]
            if "--type" in argv:
                idx = argv.index("--type")
                if idx + 1 < len(argv):
                    type_filter = argv[idx + 1]
            with AgentManager() as am:
                agents = am.discover_agents(status_filter, type_filter)
                if agents:
                    print(f"{'ID':<20} {'Name':<30} {'Type':<15} {'Status':<10}")
                    print("-" * 75)
                    for agent in agents:
                        print(f"{agent['id']:<20} {agent['name']:<30} {agent.get('type', 'N/A'):<15} {agent['status']:<10}")
                else:
                    print("No agents found")
            return 0

        if command == "agent-status":
            if len(argv) < 3:
                print("Usage: tm agent-status <agent_id>")
                return 1
            with AgentManager() as am:
                agent = am.get_agent(argv[2])
                if agent:
                    print(f"Agent: {agent['name']} ({agent['id']})")
                    print(f"Type: {agent.get('type', 'N/A')}")
                    print(f"Status: {agent['status']}")
                    print(f"Capabilities: {', '.join(agent.get('capabilities', []))}")
                    return 0
                print(f"Agent '{argv[2]}' not found")
                return 1

        if command == "agent-workload":
            with AgentManager() as am:
                agents = am.discover_agents(status='active')
                if agents:
                    print(f"{'Agent':<20} {'Tasks':<10} {'Hours':<10} {'Load':<10}")
                    print("-" * 50)
                    for agent in agents:
                        workload = am.track_workload(agent['id'])
                        print(f"{agent['id']:<20} {workload.get('task_count', 0):<10} {workload.get('estimated_hours', 0):<10.1f} {workload.get('load_score', 0):<10.0f}%")
                else:
                    print("No active agents found")
            return 0

        if command == "agent-metrics":
            if len(argv) < 3:
                print("Usage: tm agent-metrics <agent_id> [--range daily|weekly|monthly]")
                return 1
            time_range = "daily"
            if "--range" in argv:
                idx = argv.index("--range")
                if idx + 1 < len(argv):
                    time_range = argv[idx + 1]
            with AgentManager() as am:
                metrics = am.get_agent_metrics(argv[2], time_range)
                if metrics:
                    print(f"Performance Metrics for {argv[2]} ({time_range}):")
                    print(f"  Completion Rate: {metrics['completion_rate']}%")
                    return 0
                print(f"No metrics available for agent '{argv[2]}'")
                return 1

        if command == "agent-message":
            if len(argv) < 5:
                print("Usage: tm agent-message <from_agent> <to_agent> <message> [--priority low|normal|high|critical]")
                return 1
            from_agent = argv[2]
            to_agent = argv[3]
            message = argv[4]
            priority = "normal"
            if "--priority" in argv:
                idx = argv.index("--priority")
                if idx + 1 < len(argv):
                    priority = argv[idx + 1]
            with AgentManager() as am:
                if to_agent == "broadcast":
                    ok = am.broadcast_message(from_agent, message, priority)
                else:
                    ok = am.send_message(from_agent, to_agent, message, priority)
                print("✅ Message sent" if ok else "❌ Failed to send message")
                return 0 if ok else 1

        if command == "agent-redistribute":
            threshold = 80
            if "--threshold" in argv:
                idx = argv.index("--threshold")
                if idx + 1 < len(argv):
                    threshold = float(argv[idx + 1])
            with AgentManager() as am:
                redistributed = am.redistribute_tasks(threshold)
                if redistributed > 0:
                    print(f"✅ Redistributed {redistributed} tasks from overloaded agents")
                else:
                    print("No tasks needed redistribution")
            return 0

    return None
