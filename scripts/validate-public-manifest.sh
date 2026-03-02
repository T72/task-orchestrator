#!/bin/bash
# Validate release boundaries using release/public-manifest.yaml

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/lib/python-resolver.sh"

tm_python_run "$SCRIPT_DIR/public_manifest_tool.py" validate "$@"
