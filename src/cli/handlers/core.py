from __future__ import annotations

import os
from typing import Optional

from cli.context import CLIContext


CORE_COMMANDS = {
    "init",
    "add",
    "list",
    "show",
    "update",
    "complete",
    "delete",
    "assign",
    "export",
    "watch",
}


def handle_core(command: str, context: CLIContext) -> Optional[int]:
    argv = context.argv
    tm = context.tm

    if command == "init":
        tm._init_db()
        print("Task database initialized")
        try:
            from orchestrator_discovery import setup_discovery
            setup_discovery(tm)
        except ImportError:
            print("ℹ️ AI agent discovery module not found, skipping ORCHESTRATOR.md setup")
        except Exception as e:
            print(f"ℹ️ Could not set up AI discovery: {e}")
        return 0

    if command == "add":
        if len(argv) < 3:
            print("Usage: tm add <title> [-d description] [-p priority] [--depends-on task_id] [--file path:line]")
            print("       [--criteria JSON] [--deadline ISO8601] [--estimated-hours N] [--assignee name]")
            print("       [--phase phase_id] [--context 'WHY: reason WHAT: deliverables DONE: criteria']")
            return 1

        title = argv[2]
        description = None
        priority = None
        depends_on = []
        meta_entries = []
        file_refs = []
        success_criteria = None
        deadline = None
        estimated_hours = None
        assignee = None
        phase_id = None
        intent_context = None

        i = 3
        while i < len(argv):
            if argv[i] == "-d" and i + 1 < len(argv):
                description = argv[i + 1]
                i += 2
            elif argv[i] == "-p" and i + 1 < len(argv):
                priority = argv[i + 1]
                i += 2
            elif argv[i] == "--depends-on" and i + 1 < len(argv):
                j = i + 1
                while j < len(argv) and not argv[j].startswith("-"):
                    depends_on.append(argv[j])
                    j += 1
                i = j
            elif argv[i] == "--file" and i + 1 < len(argv):
                j = i + 1
                while j < len(argv) and not argv[j].startswith("--"):
                    file_refs.append(argv[j])
                    j += 1
                i = j
            elif argv[i] == "--meta" and i + 1 < len(argv):
                meta_entries.append(argv[i + 1])
                i += 2
            elif argv[i] == "--criteria" and i + 1 < len(argv):
                success_criteria = argv[i + 1]
                i += 2
            elif argv[i] == "--deadline" and i + 1 < len(argv):
                deadline = argv[i + 1]
                i += 2
            elif argv[i] == "--estimated-hours" and i + 1 < len(argv):
                estimated_hours = float(argv[i + 1])
                i += 2
            elif argv[i] == "--assignee" and i + 1 < len(argv):
                assignee = argv[i + 1]
                i += 2
            elif argv[i] == "--phase" and i + 1 < len(argv):
                phase_id = argv[i + 1]
                i += 2
            elif argv[i] == "--context" and i + 1 < len(argv):
                intent_context = argv[i + 1]
                i += 2
            else:
                i += 1

        if file_refs:
            file_info = "Files: " + ", ".join(file_refs)
            description = f"{description}\n{file_info}" if description else file_info
        if meta_entries:
            meta_info = "Meta: " + ", ".join(meta_entries)
            description = f"{description}\n{meta_info}" if description else meta_info

        try:
            task_id = tm.add(
                title,
                description=description,
                priority=priority,
                depends_on=depends_on if depends_on else None,
                success_criteria=success_criteria,
                deadline=deadline,
                estimated_hours=estimated_hours,
                assignee=assignee,
                phase_id=phase_id,
                context=intent_context,
            )
            print(f"Task created with ID: {task_id}")
            context.update_orchestrator_md(tm)
            return 0
        except ValueError as e:
            print(f"Error: {e}")
            return 1

    if command == "list":
        status_filter = None
        assignee_filter = None
        limit_filter = None
        has_deps = "--has-deps" in argv

        if "--status" in argv:
            idx = argv.index("--status")
            if idx + 1 < len(argv):
                status_filter = argv[idx + 1]

        if "--assignee" in argv:
            idx = argv.index("--assignee")
            if idx + 1 < len(argv):
                assignee_filter = argv[idx + 1]

        if "--limit" in argv:
            idx = argv.index("--limit")
            if idx + 1 < len(argv):
                limit_filter = int(argv[idx + 1])

        tasks = tm.list(
            status=status_filter,
            assignee=assignee_filter,
            has_deps=has_deps,
            limit=limit_filter,
        )
        if not tasks:
            print("No tasks found")
        else:
            for task in tasks:
                print(f"[{task['id']}] {task['title']} - {task['status']}")
        return 0

    if command == "show":
        if len(argv) < 3:
            print("Usage: tm show <task_id>")
            return 1
        task = tm.show(argv[2])
        if not task:
            print(f"Task {argv[2]} not found")
            return 1
        for key, value in task.items():
            print(f"{key}: {value}")
        return 0

    if command == "update":
        if len(argv) < 3:
            print("Usage: tm update <task_id> --status <status>")
            return 1
        if "--status" in argv:
            idx = argv.index("--status")
            if idx + 1 < len(argv):
                if tm.update(argv[2], status=argv[idx + 1]):
                    print(f"Task {argv[2]} updated")
                    return 0
                print(f"Invalid task ID: {argv[2]}")
                return 1
        print("Usage: tm update <task_id> --status <status>")
        return 1

    if command == "complete":
        if len(argv) < 3:
            print("Usage: tm complete <task_id> [--impact-review] [--summary text] [--actual-hours N] [--validate]")
            return 1
        task_id = argv[2]
        impact_review = "--impact-review" in argv
        validate = "--validate" in argv
        completion_summary = None
        actual_hours = None

        if "--summary" in argv:
            idx = argv.index("--summary")
            if idx + 1 < len(argv):
                end_idx = len(argv)
                for i in range(idx + 2, len(argv)):
                    if argv[i].startswith("--"):
                        end_idx = i
                        break
                completion_summary = " ".join(argv[idx + 1:end_idx])

        if "--actual-hours" in argv:
            idx = argv.index("--actual-hours")
            if idx + 1 < len(argv):
                actual_hours = float(argv[idx + 1])

        tm.complete(task_id, completion_summary=completion_summary, actual_hours=actual_hours, validate=validate)
        print(f"Task {task_id} completed")
        context.update_orchestrator_md(tm)

        if impact_review:
            task = tm.show(task_id)
            if task and task.get("description") and "Files:" in task["description"]:
                print("\n=== Impact Review ===")
                print("This task referenced files. Other tasks may be affected.")
                print("Consider reviewing tasks that reference the same files.")
                tm.discover(task_id, "Task completed with impact review - check related file references")
        return 0

    if command == "delete":
        if len(argv) < 3:
            print("Usage: tm delete <task_id>")
            return 1
        if tm.delete(argv[2]):
            print(f"Task {argv[2]} deleted")
            return 0
        print(f"Task {argv[2]} not found or cannot be deleted")
        return 1

    if command == "assign":
        if len(argv) < 4:
            print("Usage: tm assign <task_id> <assignee>")
            return 1
        agent_specialty = os.environ.get("TM_AGENT_SPECIALTY")
        if agent_specialty:
            task = tm.show(argv[2]) or {}
            description = task.get("description") or ""
            required_specialty = None
            for token in description.replace("\n", " ").split():
                if token.startswith("specialist:"):
                    required_specialty = token.split("specialist:", 1)[1].rstrip(",")
                    break
            if required_specialty and required_specialty != agent_specialty:
                print(
                    f"warning: specialist mismatch (required={required_specialty}, agent={agent_specialty})"
                )
        if tm.update(argv[2], assignee=argv[3]):
            print(f"Task {argv[2]} assigned to {argv[3]}")
            return 0
        print(f"Failed to assign task {argv[2]}")
        return 1

    if command == "export":
        fmt = "json"
        if "--format" in argv:
            idx = argv.index("--format")
            if idx + 1 < len(argv):
                fmt = argv[idx + 1]
        print(tm.export(format=fmt))
        return 0

    if command == "watch":
        notifications = tm.watch()
        if not notifications:
            print("No new notifications")
            return 0
        print(f"=== {len(notifications)} New Notification(s) ===")
        for notif in notifications:
            print(f"[{notif['type'].upper()}] {notif['message']}")
            if notif.get("created_at"):
                print(f"  Time: {notif['created_at']}")
            print()
        return 0

    return None
