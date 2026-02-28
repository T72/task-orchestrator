#!/bin/bash
# Wrapper for manifest boundary validation used by quality gate

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

bash "$SCRIPT_DIR/validate-public-manifest.sh" \
  --root "$ROOT_DIR" \
  --manifest "$ROOT_DIR/release/public-manifest.yaml" \
  --only-included
