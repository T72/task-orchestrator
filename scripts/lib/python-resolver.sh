#!/usr/bin/env bash

# Resolve a Python 3-capable interpreter portably across Linux/macOS/WSL/Windows Git Bash.
# Preference order: python3 -> python -> py -3

tm_python_run() {
  if command -v python3 >/dev/null 2>&1; then
    python3 "$@"
    return
  fi
  if command -v python >/dev/null 2>&1; then
    python "$@"
    return
  fi
  if command -v py >/dev/null 2>&1; then
    py -3 "$@"
    return
  fi

  echo "No Python interpreter found. Install Python 3 and ensure one of 'python3', 'python', or 'py' is on PATH." >&2
  return 127
}

tm_python_label() {
  if command -v python3 >/dev/null 2>&1; then
    echo "python3"
    return
  fi
  if command -v python >/dev/null 2>&1; then
    echo "python"
    return
  fi
  if command -v py >/dev/null 2>&1; then
    echo "py -3"
    return
  fi
  echo "<missing-python>"
}

