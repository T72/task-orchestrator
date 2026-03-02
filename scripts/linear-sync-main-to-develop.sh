#!/usr/bin/env bash
set -euo pipefail

# Linear sync helper: copy selected main-only commits onto a develop-based branch.
# Default behavior is dry-run listing candidate commits.

source_branch="main"
target_branch="develop"
sync_branch=""
apply_mode=0
commit_list=()

usage() {
  cat <<'EOF'
Usage:
  scripts/linear-sync-main-to-develop.sh [--apply] [--sync-branch <name>] [--commit <sha> ...]

Options:
  --apply                Create sync branch and cherry-pick commits (default is dry-run).
  --sync-branch <name>   Sync branch name when --apply is used.
  --commit <sha>         Commit SHA to cherry-pick (repeatable). If omitted, uses detected candidates.
  --help                 Show this help.

Dry-run output:
  - non-merge commits present in main and missing in develop by patch-id

Apply mode:
  - checks out target branch
  - creates sync branch
  - cherry-picks commits oldest -> newest
  - fails if merge commits are introduced
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply)
      apply_mode=1
      shift
      ;;
    --sync-branch)
      sync_branch="${2:-}"
      shift 2
      ;;
    --commit)
      commit_list+=("${2:-}")
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "${sync_branch}" ]]; then
  sync_branch="chore/linear-sync-main-to-develop-$(date +%Y%m%d)"
fi

git fetch origin --prune

mapfile -t detected < <(git log --format='%H' --reverse --no-merges --right-only --cherry-pick "origin/${target_branch}...origin/${source_branch}")

if [[ ${#commit_list[@]} -eq 0 ]]; then
  commit_list=("${detected[@]}")
fi

echo "Source branch: ${source_branch}"
echo "Target branch: ${target_branch}"
echo "Detected candidates: ${#detected[@]}"
echo "Selected commits: ${#commit_list[@]}"

if [[ ${#commit_list[@]} -eq 0 ]]; then
  echo "No patch-missing non-merge commits to sync."
  exit 0
fi

echo "--- Selected commit list (oldest -> newest) ---"
for c in "${commit_list[@]}"; do
  git log --oneline -n 1 "$c"
done

if [[ "${apply_mode}" -ne 1 ]]; then
  echo "Dry-run only. Re-run with --apply to execute cherry-picks."
  exit 0
fi

if [[ -n "$(git status --porcelain)" ]]; then
  echo "Working tree must be clean before --apply." >&2
  exit 1
fi

git checkout "${target_branch}"
git pull --ff-only origin "${target_branch}"
git checkout -b "${sync_branch}"

for c in "${commit_list[@]}"; do
  if git cherry-pick "${c}"; then
    echo "Picked: ${c}"
    continue
  fi

  if [[ -f .git/CHERRY_PICK_HEAD ]]; then
    # If empty pick or already present after conflict resolution, skip safely.
    if git diff --quiet && git diff --cached --quiet; then
      git cherry-pick --skip
      echo "Skipped empty: ${c}"
      continue
    fi
    echo "Conflict while cherry-picking ${c}. Resolve and run: git cherry-pick --continue" >&2
    exit 1
  fi

  echo "Failed to cherry-pick ${c}" >&2
  exit 1
done

if git rev-list --merges "origin/${target_branch}..HEAD" | grep -q .; then
  echo "Sync branch contains merge commits, which violates policy." >&2
  exit 1
fi

echo "Linear sync branch ready: ${sync_branch}"
echo "Next:"
echo "  git push -u origin ${sync_branch}"
echo "  gh pr create --base ${target_branch} --head ${sync_branch} --title \"chore(sync): linear main->develop sync\" --body-file <body.md>"

