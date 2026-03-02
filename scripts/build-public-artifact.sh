#!/bin/bash
# Build deterministic public artifact from release/public-manifest.yaml

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/python-resolver.sh"

tm_python_run "$SCRIPT_DIR/public_manifest_tool.py" build "$@"
