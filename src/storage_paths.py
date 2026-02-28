"""
Shared storage path resolver for Task Orchestrator.

Precedence:
1) TM_DB_PATH env var
   - if value ends with ".db": treated as explicit DB file path
   - otherwise: treated as storage root directory containing tasks.db
2) Default project-local storage root: <cwd>/.task-orchestrator
"""

from __future__ import annotations

import os
from pathlib import Path
from typing import Optional


def resolve_storage_root(cwd: Optional[Path] = None) -> Path:
    """Resolve canonical storage root directory."""
    env_value = os.environ.get("TM_DB_PATH", "").strip()
    if env_value:
        raw = Path(env_value).expanduser()
        if raw.suffix == ".db":
            return raw.parent
        return raw

    base = cwd if cwd is not None else Path.cwd()
    return base / ".task-orchestrator"


def resolve_db_path(cwd: Optional[Path] = None) -> Path:
    """Resolve canonical tasks DB file path."""
    env_value = os.environ.get("TM_DB_PATH", "").strip()
    if env_value:
        raw = Path(env_value).expanduser()
        if raw.suffix == ".db":
            return raw
        return raw / "tasks.db"

    return resolve_storage_root(cwd) / "tasks.db"


def resolve_config_path(cwd: Optional[Path] = None) -> Path:
    """Resolve canonical config file path."""
    return resolve_storage_root(cwd) / "config.yaml"
