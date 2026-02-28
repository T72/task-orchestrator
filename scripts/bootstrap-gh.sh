  #!/usr/bin/env bash
  set -euo pipefail

  REPO_DIR="${1:-$(pwd)}"
  SYNC_LABELS="${2:-false}"   # true|false

  retry() {
    local n=0 max=5 delay=2
    until "$@"; do
      n=$((n+1))
      if [ "$n" -ge "$max" ]; then
        echo "FAILED: $*" >&2
        return 1
      fi
      sleep "$delay"
    done
  }

  cd "$REPO_DIR"

  echo "== Repo =="
  pwd
  git remote -v

  echo "== Detect origin repo =="
  ORIGIN_URL="$(git remote get-url origin)"
  if [[ "$ORIGIN_URL" =~ github\.com[:/]([^/]+)/([^/.]+)(\.git)?$ ]]; then
    OWNER="${BASH_REMATCH[1]}"
    NAME="${BASH_REMATCH[2]}"
    REPO="${OWNER}/${NAME}"
  else
    echo "Could not parse GitHub repo from origin URL: $ORIGIN_URL" >&2
    exit 1
  fi
  echo "Repo: $REPO"

  echo "== GitHub auth check =="
  if ! retry gh api user >/dev/null 2>&1; then
    echo "gh auth is not working. Run: gh auth login -h github.com"
    exit 1
  fi
  gh api user --jq '.login'

  echo "== Set default repo =="
  gh repo set-default "$REPO"
  gh repo view --json nameWithOwner --jq '.nameWithOwner'

  echo "== Label access check =="
  if [[ "$SYNC_LABELS" == "true" ]]; then
    echo "== Sync labels workflow =="
    if gh workflow list -R "$REPO" | grep -q "sync-labels.yml"; then
      gh workflow run sync-labels.yml -R "$REPO"
      echo "sync-labels.yml not found in this repo; skipping"
    fi
  fi

  echo "== Done =="