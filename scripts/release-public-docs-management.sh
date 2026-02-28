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

required_docs=(
  "README.md"
  "CONTRIBUTING.md"
)

optional_docs=(
  "INSTALL.md"
  "USAGE.md"
)

for doc in "${required_docs[@]}"; do
  if [[ ! -f "$staging/$doc" ]]; then
    echo "Missing required public doc in staging: $doc" >&2
    exit 1
  fi
  cp "$staging/$doc" "$release_dir/$doc"
done

for doc in "${optional_docs[@]}"; do
  if [[ -f "$staging/$doc" ]]; then
    cp "$staging/$doc" "$release_dir/$doc"
  fi
done

version_token="${version#v}"

# Basic consistency checks for public docs.
if ! grep -Eq "${version_token}|${version}" "$staging/CHANGELOG.md"; then
  echo "CHANGELOG.md does not contain release version marker: $version" >&2
  exit 1
fi

if ! grep -Eq "${version_token}|${version}" "$release_dir/README.md"; then
  echo "README.md does not contain release version marker: $version" >&2
  exit 1
fi

cat > "$release_dir/RELEASE_PUBLIC_DOCS_MANAGEMENT.md" <<EOF
# Public Docs Management Evidence

- Manager: scripts/release-public-docs-management.sh
- Version: $version
- Required docs validated:
  - README.md
  - CONTRIBUTING.md
- Optional docs included when present:
  - INSTALL.md
  - USAGE.md
- Consistency checks:
  - CHANGELOG.md contains release version marker
  - README.md contains release version marker
EOF

echo "release-public-docs-management completed for $version"
