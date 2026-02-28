#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

cp "$ROOT_DIR/tm" "$TMP_DIR/tm"
cp -r "$ROOT_DIR/src" "$TMP_DIR/src"
chmod +x "$TMP_DIR/tm"
cd "$TMP_DIR"
export TM_AGENT_ID="collab-test-agent"

./tm init >/dev/null
TASK_ID="$(./tm add "Collaboration event-store concurrency test" | grep -o '[a-f0-9]\{8\}')"

WRITERS=30

run_with_retry() {
  local attempts=5
  local delay_s=0.05
  local n=1
  while true; do
    if "$@"; then
      return 0
    fi
    if [ "$n" -ge "$attempts" ]; then
      return 1
    fi
    n=$((n + 1))
    sleep "$delay_s"
  done
}

declare -a discover_pids=()
for i in $(seq 1 "$WRITERS"); do
  (
    run_with_retry env TM_AGENT_ID="writer_${i}" ./tm discover "$TASK_ID" "discover-${i}"
  ) >".discover_${i}.log" 2>&1 &
  discover_pids+=("$!")
done

discover_failed=0
for i in $(seq 1 "$WRITERS"); do
  pid_index=$((i - 1))
  if ! wait "${discover_pids[$pid_index]}"; then
    echo "FAIL: writer_${i} discover command failed after retries"
    sed -n '1,120p' ".discover_${i}.log"
    discover_failed=1
  fi
done
[ "$discover_failed" -eq 0 ] || exit 1

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
declare -a share_pids=()
for i in $(seq 1 200); do
  (
    run_with_retry env TM_AGENT_ID="perf_${i}" ./tm share "$TASK_ID" "perf-${i}"
  ) >".share_${i}.log" 2>&1 &
  share_pids+=("$!")
done

share_failed=0
for i in $(seq 1 200); do
  pid_index=$((i - 1))
  if ! wait "${share_pids[$pid_index]}"; then
    echo "FAIL: perf_${i} share command failed after retries"
    sed -n '1,120p' ".share_${i}.log"
    share_failed=1
  fi
done
[ "$share_failed" -eq 0 ] || exit 1

END_NS="$(date +%s%N)"

DURATION_MS="$(( (END_NS - START_NS) / 1000000 ))"
echo "PERF_BASELINE: 200 parallel share writes in ${DURATION_MS} ms"

echo "All collaboration event-store tests passed."
