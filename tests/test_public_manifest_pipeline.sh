#!/bin/bash
# Integration tests for manifest-driven public artifact pipeline

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VALIDATOR="$ROOT_DIR/scripts/validate-public-manifest.sh"
BUILDER="$ROOT_DIR/scripts/build-public-artifact.sh"
TMP_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

pass() {
  echo "PASS: $1"
}

fail() {
  echo "FAIL: $1"
  exit 1
}

expect_success() {
  local desc="$1"
  shift
  if "$@"; then
    pass "$desc"
  else
    fail "$desc"
  fi
}

expect_failure() {
  local desc="$1"
  shift
  if "$@"; then
    fail "$desc"
  else
    pass "$desc"
  fi
}

BASE_MANIFEST="$TMP_DIR/public-manifest.yaml"
cat > "$BASE_MANIFEST" << 'EOF'
include_paths:
  - src
  - docs/guides
  - README.md
  - LICENSE
exclude_globs:
  - "**/*.tmp"
required_files:
  - README.md
  - LICENSE
forbidden_patterns:
  - "AGENTS.md"
  - "**/AGENTS.md"
  - "CLAUDE.md"
  - "**/CLAUDE.md"
  - ".claude/**"
forbidden_content_patterns:
  - "CONFIDENTIAL"
EOF

make_base_tree() {
  local root="$1"
  mkdir -p "$root/src" "$root/docs/guides"
  cat > "$root/README.md" << 'EOF'
# Public README
EOF
  cat > "$root/LICENSE" << 'EOF'
MIT
EOF
  cat > "$root/src/main.py" << 'EOF'
print("ok")
EOF
  cat > "$root/docs/guides/user-guide.md" << 'EOF'
# User Guide
EOF
}

TEST_ROOT="$TMP_DIR/work"
make_base_tree "$TEST_ROOT"

expect_success \
  "validator accepts clean tree" \
  "$VALIDATOR" --root "$TEST_ROOT" --manifest "$BASE_MANIFEST"

mkdir -p "$TEST_ROOT/docs/internal"
echo "internal agent instructions" > "$TEST_ROOT/docs/internal/AGENTS.md"
expect_failure \
  "validator rejects nested AGENTS.md" \
  "$VALIDATOR" --root "$TEST_ROOT" --manifest "$BASE_MANIFEST"
rm -f "$TEST_ROOT/docs/internal/AGENTS.md"

mkdir -p "$TEST_ROOT/docs/hidden"
echo "private instructions" > "$TEST_ROOT/docs/hidden/CLAUDE.md"
expect_failure \
  "validator rejects nested CLAUDE.md" \
  "$VALIDATOR" --root "$TEST_ROOT" --manifest "$BASE_MANIFEST"
rm -f "$TEST_ROOT/docs/hidden/CLAUDE.md"

rm -f "$TEST_ROOT/LICENSE"
expect_failure \
  "validator rejects missing required file" \
  "$VALIDATOR" --root "$TEST_ROOT" --manifest "$BASE_MANIFEST"
echo "MIT" > "$TEST_ROOT/LICENSE"

BUILD_ROOT="$TMP_DIR/build-src"
make_base_tree "$BUILD_ROOT"
mkdir -p "$BUILD_ROOT/archive"
echo "should never be included" > "$BUILD_ROOT/archive/private.md"
echo "ignore temp" > "$BUILD_ROOT/src/ignore.tmp"

ARTIFACT_DIR="$TMP_DIR/artifact"
expect_success \
  "builder creates deterministic artifact" \
  "$BUILDER" --root "$BUILD_ROOT" --manifest "$BASE_MANIFEST" --output "$ARTIFACT_DIR"

[ -f "$ARTIFACT_DIR/src/main.py" ] || fail "artifact contains src/main.py"
[ -f "$ARTIFACT_DIR/README.md" ] || fail "artifact contains README.md"
[ -f "$ARTIFACT_DIR/LICENSE" ] || fail "artifact contains LICENSE"
[ ! -e "$ARTIFACT_DIR/archive/private.md" ] || fail "artifact excludes archive/private.md"
[ ! -e "$ARTIFACT_DIR/src/ignore.tmp" ] || fail "artifact excludes tmp by glob"
pass "artifact includes only allowed content"

echo "All manifest pipeline tests passed."
