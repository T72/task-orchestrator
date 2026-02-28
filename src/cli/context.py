from __future__ import annotations

from dataclasses import dataclass
from typing import Callable, List


@dataclass
class CLIContext:
    argv: List[str]
    tm: object
    update_orchestrator_md: Callable[[object], None]
