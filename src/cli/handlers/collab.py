from __future__ import annotations

from typing import Optional

from cli.context import CLIContext


COLLAB_COMMANDS = {
    "join",
    "share",
    "note",
    "sync",
    "context",
    "discover",
    "progress",
    "feedback",
}


def _parse_feedback(argv: list[str]) -> tuple[Optional[int], Optional[int], Optional[str]]:
    quality = None
    timeliness = None
    note = None

    if "--quality" in argv:
        idx = argv.index("--quality")
        if idx + 1 < len(argv):
            quality = int(argv[idx + 1])

    if "--timeliness" in argv:
        idx = argv.index("--timeliness")
        if idx + 1 < len(argv):
            timeliness = int(argv[idx + 1])

    if "--note" in argv:
        idx = argv.index("--note")
        if idx + 1 < len(argv):
            end_idx = len(argv)
            for i in range(idx + 2, len(argv)):
                if argv[i].startswith("--"):
                    end_idx = i
                    break
            note = " ".join(argv[idx + 1:end_idx])

    return quality, timeliness, note


def handle_collab(command: str, context: CLIContext) -> Optional[int]:
    argv = context.argv
    tm = context.tm

    if command == "join":
        if len(argv) < 3:
            print("Usage: tm join <task_id>")
            return 1
        if tm.join(argv[2]):
            print(f"Joined task: {argv[2]}")
            return 0
        print(f"Failed to join task {argv[2]}")
        return 1

    if command == "context":
        if len(argv) < 3:
            print("Usage: tm context <task_id>")
            return 1
        task_id = argv[2]
        data = tm.context(task_id)
        print(f"Task: {task_id}")
        shared = data.get("shared", {})
        contributions = shared.get("contributions", [])
        if contributions:
            print("\nShared Context:")
            for contrib in contributions[-20:]:
                print(f"  [{contrib['type']}] {contrib['agent']}: {contrib['content']}")
        else:
            print("\nNo shared context")

        notes = data.get("notes")
        if notes:
            print("\nYour Notes:")
            print(notes)
        return 0

    if command in {"share", "note", "sync", "discover", "progress"}:
        if len(argv) < 4:
            if command == "progress":
                print("Usage: tm progress <task_id> <update_message>")
            elif command == "discover":
                print("Usage: tm discover <task_id> <message>")
            else:
                print(f"Usage: tm {command} <task_id> <message>")
            return 1

        task_id = argv[2]
        message = " ".join(argv[3:])

        if command == "share":
            ok = tm.share(task_id, message)
            print(f"Shared update for task {task_id}" if ok else f"Failed to share update for task {task_id}")
            return 0 if ok else 1

        if command == "note":
            ok = tm.note(task_id, message)
            print(f"Added private note for task {task_id}" if ok else f"Failed to add private note for task {task_id}")
            return 0 if ok else 1

        if command == "sync":
            ok = tm.sync(task_id, message)
            print(f"Created sync point for task {task_id}" if ok else f"Failed to create sync point for task {task_id}")
            return 0 if ok else 1

        if command == "discover":
            ok = tm.discover(task_id, message)
            print(f"Discovery shared for task {task_id}" if ok else "Failed to share discovery")
            return 0 if ok else 1

        if command == "progress":
            ok = tm.progress(task_id, message)
            print("Progress update added" if ok else f"Failed to add progress update to task {task_id}")
            return 0 if ok else 1

    if command == "feedback":
        if len(argv) < 3:
            print("Usage: tm feedback <task_id> [--quality N] [--timeliness N] [--note text]")
            return 1
        task_id = argv[2]
        quality, timeliness, note = _parse_feedback(argv)
        ok = tm.feedback(task_id, quality=quality, timeliness=timeliness, notes=note)
        print("Feedback recorded" if ok else f"Failed to record feedback for task {task_id}")
        return 0 if ok else 1

    return None
