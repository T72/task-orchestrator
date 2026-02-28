#!/usr/bin/env bash
set -euo pipefail

version=""
staging=""
release_dir=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)
      version="${2:-}"
      shift 2
      ;;
    --staging)
      staging="${2:-}"
      shift 2
      ;;
    --release-dir)
      release_dir="${2:-}"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$version" || -z "$staging" || -z "$release_dir" ]]; then
  echo "Usage: $0 --version <vX.Y.Z> --staging <path> --release-dir <path>" >&2
  exit 1
fi

if [[ ! -f "$staging/CHANGELOG.md" ]]; then
  echo "Missing changelog in staging: $staging/CHANGELOG.md" >&2
  exit 1
fi

if ! grep -q "${version#v}" "$staging/CHANGELOG.md"; then
  {
    echo "## $version"
    echo
    echo "- Added: release and changelog management guardrails."
    echo "- Changed: release process now requires manager execution."
    echo
    cat "$staging/CHANGELOG.md"
  } > "$release_dir/.tmp_changelog"
  mv "$release_dir/.tmp_changelog" "$release_dir/CHANGELOG.md"
else
  cp "$staging/CHANGELOG.md" "$release_dir/CHANGELOG.md"
fi

if [[ ! -f "$release_dir/RELEASE_NOTES.md" ]]; then
  cat > "$release_dir/RELEASE_NOTES.md" <<EOF
# Release Notes - $version

## Release Summary
Release generated with enforced release-and-changelog-management workflow.

## New Features
- Release governance hardening and workflow enforcement.

## Bug Fixes
- Stability and guardrail improvements integrated from develop.

## Breaking Changes
- None identified.

## Upgrade Guide
1. Pull tag $version.
2. Run \`./tm init\`.
3. Set \`TM_AGENT_ID\` before task operations.

## Known Limitations
- None critical for baseline usage.

## Support Information
- Repository: https://github.com/T72/task-orchestrator
EOF
fi

cat > "$release_dir/RELEASE_CHANGELOG_MANAGEMENT.md" <<EOF
# Release And Changelog Management Evidence

- Manager: scripts/release-and-changelog-management.sh
- Version: $version
- Staging source: $staging
- Release output: $release_dir
EOF

echo "release-and-changelog-management completed for $version"
