#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <tag>" >&2
  echo "Example: $0 v2.9.0" >&2
  exit 1
fi

tag="$1"

if [[ ! "$tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+([.-][A-Za-z0-9]+)?$ ]]; then
  echo "Invalid tag format: $tag" >&2
  echo "Expected semantic version tag such as v2.9.0 or v2.9.0-rc1" >&2
  exit 1
fi

if ! git rev-parse -q --verify "refs/tags/$tag" >/dev/null; then
  echo "Local tag not found: $tag" >&2
  exit 1
fi

# Intentionally push only one explicit tag to avoid accidental bulk publication.
git push origin "refs/tags/$tag:refs/tags/$tag"
echo "Published tag: $tag"
