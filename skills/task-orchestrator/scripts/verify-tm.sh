#!/usr/bin/env bash
set -euo pipefail

show_help() {
  cat <<'EOF'
Usage: scripts/verify-tm.sh [--json]

Validate Task Orchestrator skill prerequisites in the current project.

Options:
  --json   Print machine-readable JSON result to stdout
  --help   Show this help

Exit codes:
  0  All checks passed
  2  tm executable missing
  3  task orchestrator not initialized (.task-orchestrator missing)
  4  TM_AGENT_ID not set
EOF
}

emit_json() {
  local ok="$1"
  local code="$2"
  local message="$3"
  printf '{"ok":%s,"exit_code":%s,"message":"%s"}\n' "$ok" "$code" "$message"
}

json_mode=0
case "${1:-}" in
  --help|-h) show_help; exit 0 ;;
  --json) json_mode=1 ;;
  "") ;;
  *) echo "Error: unknown argument '$1'. Use --help." >&2; exit 1 ;;
esac

if [[ ! -x "./tm" ]]; then
  msg="tm executable not found in current directory. Expected ./tm"
  if [[ "$json_mode" -eq 1 ]]; then emit_json false 2 "$msg"; else echo "$msg" >&2; fi
  exit 2
fi

if [[ ! -d ".task-orchestrator" ]]; then
  msg="Task Orchestrator not initialized. Run ./tm init"
  if [[ "$json_mode" -eq 1 ]]; then emit_json false 3 "$msg"; else echo "$msg" >&2; fi
  exit 3
fi

if [[ -z "${TM_AGENT_ID:-}" ]]; then
  msg="TM_AGENT_ID is not set. Export TM_AGENT_ID before orchestrating"
  if [[ "$json_mode" -eq 1 ]]; then emit_json false 4 "$msg"; else echo "$msg" >&2; fi
  exit 4
fi

msg="Task Orchestrator skill prerequisites satisfied"
if [[ "$json_mode" -eq 1 ]]; then emit_json true 0 "$msg"; else echo "$msg"; fi
exit 0

