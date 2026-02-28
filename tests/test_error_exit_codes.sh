#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

cp "$ROOT_DIR/tm" "$TMP_DIR/tm"
cp -r "$ROOT_DIR/src" "$TMP_DIR/src"
chmod +x "$TMP_DIR/tm"
cd "$TMP_DIR"
export TM_AGENT_ID="exit-code-test-agent"

./tm init >/dev/null

expect_fail() {
  local name="$1"
  shift
  if "$@" >/tmp/cmd.out 2>/tmp/cmd.err; then
    echo "FAIL: $name (expected non-zero exit)"
    return 1
  fi
  echo "PASS: $name"
}

expect_fail "add without title exits non-zero" ./tm add
expect_fail "discover without message exits non-zero" ./tm discover abc123
expect_fail "share without task id exits non-zero" ./tm share
expect_fail "invalid config feature exits non-zero" ./tm config --enable invalid-feature

echo "All command error exit-code tests passed."
