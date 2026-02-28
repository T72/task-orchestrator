#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

cp "$ROOT_DIR/tm" "$TMP_DIR/tm"
cp -r "$ROOT_DIR/src" "$TMP_DIR/src"
chmod +x "$TMP_DIR/tm"
cd "$TMP_DIR"

export HOME="$TMP_DIR/home"
export TM_DB_PATH="$TMP_DIR/custom-store"

./tm init >/dev/null
TASK_ID="$(./tm add "storage-contract-test" | grep -o '[a-f0-9]\{8\}')"

if [ ! -f "$TM_DB_PATH/tasks.db" ]; then
  echo "FAIL: tasks DB not created under TM_DB_PATH root"
  exit 1
fi

python3 - "$TM_DB_PATH/tasks.db" "$TASK_ID" <<'PY'
import sqlite3
import sys
db_path, task_id = sys.argv[1], sys.argv[2]
conn = sqlite3.connect(db_path)
cur = conn.cursor()
cur.execute("SELECT COUNT(*) FROM tasks WHERE id=?", (task_id,))
count = cur.fetchone()[0]
if count != 1:
    print(f"FAIL: expected task {task_id} in resolved DB, got count={count}")
    sys.exit(1)
print("PASS: add command writes to resolved DB path")
PY

./tm migrate --status >/dev/null
./tm config --show >/dev/null

if [ -e "$HOME/.task-orchestrator/tasks.db" ]; then
  echo "FAIL: migrate command touched home-directory DB path"
  exit 1
fi

if [ -e "$HOME/.task-orchestrator/config.yaml" ]; then
  echo "FAIL: config command touched home-directory config path"
  exit 1
fi

if [ ! -e "$TM_DB_PATH/config.yaml" ]; then
  echo "FAIL: config command did not use resolved config path"
  exit 1
fi

echo "All storage contract tests passed."
