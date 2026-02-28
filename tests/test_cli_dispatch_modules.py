#!/usr/bin/env python3
"""Contract tests for modular CLI dispatch structure."""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"
if str(SRC) not in sys.path:
    sys.path.insert(0, str(SRC))


def test_tm_entrypoint_is_thin() -> None:
    tm_path = ROOT / "tm"
    lines = tm_path.read_text(encoding="utf-8").splitlines()
    assert len(lines) < 300, f"Expected thin entrypoint (<300 LOC), got {len(lines)}"


def test_no_duplicate_command_handlers() -> None:
    from cli.handlers.admin import ADMIN_COMMANDS
    from cli.handlers.collab import COLLAB_COMMANDS
    from cli.handlers.core import CORE_COMMANDS

    all_commands = list(CORE_COMMANDS) + list(COLLAB_COMMANDS) + list(ADMIN_COMMANDS)
    assert len(all_commands) == len(set(all_commands)), "Duplicate command registrations detected"


def test_dispatcher_covers_command_groups() -> None:
    from cli.dispatcher import CommandDispatcher
    from cli.handlers.admin import ADMIN_COMMANDS, handle_admin
    from cli.handlers.collab import COLLAB_COMMANDS, handle_collab
    from cli.handlers.core import CORE_COMMANDS, handle_core

    dispatcher = CommandDispatcher()
    dispatcher.register(CORE_COMMANDS, handle_core)
    dispatcher.register(COLLAB_COMMANDS, handle_collab)
    dispatcher.register(ADMIN_COMMANDS, handle_admin)

    for cmd in ["add", "share", "migrate", "phase-list", "agent-list"]:
        assert cmd in dispatcher.commands, f"Missing command in dispatcher: {cmd}"


if __name__ == "__main__":
    test_tm_entrypoint_is_thin()
    test_no_duplicate_command_handlers()
    test_dispatcher_covers_command_groups()
    print("All CLI dispatch module tests passed.")
