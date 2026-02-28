#!/usr/bin/env python3
"""Task Orchestrator CLI entrypoint (thin bootstrap + command dispatch)."""

from __future__ import annotations

import logging
import subprocess
import sys
from pathlib import Path

LOGGER = logging.getLogger("task_orchestrator.tm")

# Add src directory to path
SCRIPT_DIR = Path(__file__).parent
SRC_DIR = SCRIPT_DIR / "src"
if SRC_DIR.exists():
    sys.path.insert(0, str(SRC_DIR))

from cli.context import CLIContext
from cli.dispatcher import CommandDispatcher
from cli.handlers.admin import ADMIN_COMMANDS, handle_admin
from cli.handlers.collab import COLLAB_COMMANDS, handle_collab
from cli.handlers.core import CORE_COMMANDS, handle_core
from cli.handlers.enforcement import handle_enforcement
from storage_paths import resolve_db_path, resolve_storage_root


def update_orchestrator_md(tm: object) -> None:
    """Update ORCHESTRATOR.md after task lifecycle changes."""
    try:
        from orchestrator_discovery import OrchestratorDiscovery

        discovery = OrchestratorDiscovery(tm)
        discovery.update_orchestrator_md()
    except Exception as e:
        print(f"Warning: Failed to update ORCHESTRATOR.md: {e}", file=sys.stderr)


def parse_agent_id(argv: list[str]) -> tuple[list[str], str | None]:
    """Parse and strip --agent-id from argv."""
    args = list(argv)
    agent_id_override = None
    if "--agent-id" in args:
        idx = args.index("--agent-id")
        if idx + 1 >= len(args):
            print("Error: --agent-id requires a value")
            raise SystemExit(1)
        agent_id_override = args[idx + 1]
        del args[idx : idx + 2]
    return args, agent_id_override


def build_enforcement_engine() -> object | None:
    """Initialize optional enforcement engine."""
    try:
        from enforcement import EnforcementEngine

        db_dir = resolve_storage_root()
        db_dir.mkdir(exist_ok=True)
        return EnforcementEngine(resolve_db_path())
    except ImportError:
        LOGGER.debug("Enforcement module unavailable; continuing without enforcement engine")
        return None


def build_dispatcher() -> CommandDispatcher:
    """Build command registry."""
    dispatcher = CommandDispatcher()
    dispatcher.register(CORE_COMMANDS, handle_core)
    dispatcher.register(COLLAB_COMMANDS, handle_collab)
    dispatcher.register(ADMIN_COMMANDS, handle_admin)
    return dispatcher


def print_help() -> None:
    print(
        """Task Manager - Modular CLI

Core:
  init | add | list | show | update | complete | delete | assign | export | watch

Collaboration:
  join | share | note | discover | sync | context | progress | feedback

Admin:
  migrate | config | metrics | critical-path | report | template | wizard | hooks
  phase-* | agent-*

Enforcement:
  validate-orchestration | fix-orchestration --interactive
  config --enforce-usage true|false | --show-enforcement | --enforcement-level

Global Options:
  --agent-id <id>

Environment:
  TM_DB_PATH
"""
    )


def main() -> int:
    argv, agent_id_override = parse_agent_id(sys.argv)

    if len(argv) < 2:
        print("Usage: tm <command> [args]")
        print("Commands: init, add, list, show, update, complete, export, etc.")
        return 1

    command = argv[1]
    if command in {"--help", "-h", "help"}:
        print_help()
        return 0

    enforcement_engine = build_enforcement_engine()

    enforcement_result = handle_enforcement(command, argv, enforcement_engine)
    if enforcement_result is not None:
        return enforcement_result

    if enforcement_engine and command in {
        "add",
        "join",
        "share",
        "note",
        "discover",
        "sync",
        "context",
        "assign",
        "watch",
        "template",
    }:
        if not enforcement_engine.enforce_orchestration(command):
            return 1

    try:
        from tm_production import TaskManager

        tm = TaskManager(agent_id_override=agent_id_override)
    except ImportError as e:
        print(f"Error importing production module: {e}")
        return 1

    context = CLIContext(argv=argv, tm=tm, update_orchestrator_md=update_orchestrator_md)

    dispatcher = build_dispatcher()
    result = dispatcher.dispatch(command, context)
    if result is None:
        print(f"Command '{command}' not yet implemented in modular CLI")
        return 1
    return result


def find_repo_root() -> Path:
    """Find git repository root."""
    try:
        result = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True, check=True
        )
        return Path(result.stdout.strip())
    except subprocess.CalledProcessError:
        return Path.cwd()


if __name__ == "__main__":
    raise SystemExit(main())
