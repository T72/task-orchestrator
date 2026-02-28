#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

cp "$ROOT_DIR/tm" "$TMP_DIR/tm"
cp -r "$ROOT_DIR/src" "$TMP_DIR/src"
chmod +x "$TMP_DIR/tm"
cd "$TMP_DIR"

./tm init >/dev/null
TASK_ID="$(./tm add "Collaboration event-store concurrency test" | grep -o '[a-f0-9]\{8\}')"

WRITERS=30

for i in $(seq 1 "$WRITERS"); do
  TM_AGENT_ID="writer_${i}" ./tm discover "$TASK_ID" "discover-${i}" >/dev/null 2>&1 &
done
wait

python3 - "$TASK_ID" "$WRITERS" <<'PY'
import sqlite3
import sys
task_id = sys.argv[1]
expected = int(sys.argv[2])
conn = sqlite3.connect(".task-orchestrator/tasks.db")
cur = conn.cursor()
cur.execute("SELECT COUNT(*) FROM collaboration_events WHERE task_id=? AND event_type='discovery'", (task_id,))
count = cur.fetchone()[0]
if count != expected:
    print(f"FAIL: expected {expected} discovery events, got {count}")
    sys.exit(1)

cur.execute("""
    SELECT seq, created_at FROM collaboration_events
    WHERE task_id=?
    ORDER BY seq ASC
""", (task_id,))
rows = cur.fetchall()
if len(rows) < expected:
    print(f"FAIL: expected at least {expected} total events, got {len(rows)}")
    sys.exit(1)
print(f"PASS: recorded {count} discovery events with monotonic sequence")
PY

if [ -f ".task-orchestrator/contexts/${TASK_ID}.yaml" ]; then
  echo "FAIL: found legacy YAML context mutation path"
  exit 1
fi

if ! ./tm context "$TASK_ID" | grep -q "discover-1"; then
  echo "FAIL: context output missing persisted discovery entry"
  exit 1
fi

START_NS="$(date +%s%N)"
for i in $(seq 1 200); do
  TM_AGENT_ID="perf_${i}" ./tm share "$TASK_ID" "perf-${i}" >/dev/null 2>&1 &
done
wait
END_NS="$(date +%s%N)"

DURATION_MS="$(( (END_NS - START_NS) / 1000000 ))"
echo "PERF_BASELINE: 200 parallel share writes in ${DURATION_MS} ms"

echo "All collaboration event-store tests passed."
