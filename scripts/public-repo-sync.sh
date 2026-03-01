#!/usr/bin/env bash
set -euo pipefail

# Contract-driven sync/check for public release subset paths.
#
# Modes:
# - sync  : copy allowlisted files from source to target
# - check : verify allowlisted files are identical between source and target
#
# Usage:
#   scripts/public-repo-sync.sh sync  --source <repo> --target <staging-dir> [--allowlist <file>] [--report <file>]
#   scripts/public-repo-sync.sh check --source <repo> --target <staging-dir> [--allowlist <file>] [--report <file>]

MODE="${1:-}"
shift || true

ALLOWLIST_FILE=".github/public-sync-allowlist.txt"
SOURCE_DIR=""
TARGET_DIR=""
REPORT_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --allowlist)
      ALLOWLIST_FILE="$2"
      shift 2
      ;;
    --source)
      SOURCE_DIR="$2"
      shift 2
      ;;
    --target)
      TARGET_DIR="$2"
      shift 2
      ;;
    --report)
      REPORT_FILE="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

if [[ "$MODE" != "sync" && "$MODE" != "check" ]]; then
  echo "Mode must be 'sync' or 'check'" >&2
  exit 2
fi

if [[ -z "$SOURCE_DIR" || -z "$TARGET_DIR" ]]; then
  echo "--source and --target are required" >&2
  exit 2
fi

if [[ ! -d "$SOURCE_DIR" ]]; then
  echo "Source directory not found: $SOURCE_DIR" >&2
  exit 2
fi

if [[ ! -d "$TARGET_DIR" ]]; then
  echo "Target directory not found: $TARGET_DIR" >&2
  exit 2
fi

if [[ ! -f "$SOURCE_DIR/$ALLOWLIST_FILE" ]]; then
  echo "Allowlist file not found: $SOURCE_DIR/$ALLOWLIST_FILE" >&2
  exit 2
fi

tmp_report="$(mktemp)"
trap 'rm -f "$tmp_report"' EXIT

read_allowlist() {
  grep -vE '^\s*#|^\s*$' "$SOURCE_DIR/$ALLOWLIST_FILE"
}

run_sync() {
  while IFS= read -r rel; do
    src="$SOURCE_DIR/$rel"
    dst="$TARGET_DIR/$rel"
    if [[ ! -f "$src" ]]; then
      echo "MISSING_SOURCE $rel" | tee -a "$tmp_report" >&2
      exit 1
    fi
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
    echo "SYNCED $rel" >> "$tmp_report"
  done < <(read_allowlist)
}

run_check() {
  local drift=0
  while IFS= read -r rel; do
    src="$SOURCE_DIR/$rel"
    dst="$TARGET_DIR/$rel"
    if [[ ! -f "$src" ]]; then
      echo "MISSING_SOURCE $rel" | tee -a "$tmp_report"
      drift=1
      continue
    fi
    if [[ ! -f "$dst" ]]; then
      echo "MISSING_TARGET $rel" | tee -a "$tmp_report"
      drift=1
      continue
    fi
    src_hash="$(sha256sum "$src" | awk '{print $1}')"
    dst_hash="$(sha256sum "$dst" | awk '{print $1}')"
    if [[ "$src_hash" != "$dst_hash" ]]; then
      echo "DIFF $rel $src_hash $dst_hash" | tee -a "$tmp_report"
      drift=1
    else
      echo "MATCH $rel" >> "$tmp_report"
    fi
  done < <(read_allowlist)
  return "$drift"
}

if [[ "$MODE" == "sync" ]]; then
  run_sync
else
  run_check || check_rc=$?
  check_rc="${check_rc:-0}"
fi

if [[ -n "$REPORT_FILE" ]]; then
  mkdir -p "$(dirname "$REPORT_FILE")"
  cp "$tmp_report" "$REPORT_FILE"
fi

if [[ "$MODE" == "check" && "${check_rc:-0}" -ne 0 ]]; then
  echo "Public subset drift detected against allowlist contract." >&2
  exit 1
fi

echo "public-repo-sync: $MODE completed"
