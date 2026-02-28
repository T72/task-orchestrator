from __future__ import annotations

from typing import Callable, Dict, Iterable, Optional

from .context import CLIContext

Handler = Callable[[str, CLIContext], Optional[int]]


class CommandDispatcher:
    def __init__(self) -> None:
        self._handlers: Dict[str, Handler] = {}

    def register(self, commands: Iterable[str], handler: Handler) -> None:
        for command in commands:
            if command in self._handlers:
                raise ValueError(f"Duplicate command handler registration: {command}")
            self._handlers[command] = handler

    def dispatch(self, command: str, context: CLIContext) -> Optional[int]:
        handler = self._handlers.get(command)
        if not handler:
            return None
        return handler(command, context)

    @property
    def commands(self) -> Dict[str, Handler]:
        return dict(self._handlers)
