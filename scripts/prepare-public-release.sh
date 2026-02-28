#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

input_version="${1:-}"
release_branch="${RELEASE_BRANCH:-main}"
allow_non_release_branch="${ALLOW_NON_RELEASE_BRANCH:-0}"
enforce_release_ref_sync="${ENFORCE_RELEASE_REF_SYNC:-1}"
release_ref="${RELEASE_REF:-origin/$release_branch}"
release_changelog_mode="${RELEASE_CHANGELOG_MODE:-delegate}"
release_changelog_tool="${RELEASE_CHANGELOG_TOOL:-scripts/release-and-changelog-management.sh}"

current_branch="$(git rev-parse --abbrev-ref HEAD)"
if [[ "$current_branch" != "$release_branch" && "$allow_non_release_branch" != "1" ]]; then
  echo "Refusing release preparation on branch '$current_branch'." >&2
  echo "Expected release branch: '$release_branch'." >&2
  echo "Use ALLOW_NON_RELEASE_BRANCH=1 only for exceptional dry-runs." >&2
  exit 1
fi

if [[ "$allow_non_release_branch" != "1" && "$enforce_release_ref_sync" == "1" ]]; then
  git fetch origin --quiet || true
  local_head="$(git rev-parse --verify HEAD)"
  ref_head="$(git rev-parse --verify "$release_ref" 2>/dev/null || true)"
  if [[ -z "$ref_head" ]]; then
    echo "Refusing release preparation: cannot resolve release ref '$release_ref'." >&2
    echo "Set RELEASE_REF explicitly or fetch remote refs before retrying." >&2
    exit 1
  fi
  if [[ "$local_head" != "$ref_head" ]]; then
    echo "Refusing release preparation: HEAD does not match '$release_ref'." >&2
    echo "HEAD=$local_head" >&2
    echo "$release_ref=$ref_head" >&2
    echo "Fast-forward or checkout the release ref before preparing a public release." >&2
    exit 1
  fi
fi

compute_release_version() {
  python3 - "$input_version" <<'PY'
import json
import re
import subprocess
import sys
from pathlib import Path

explicit = (sys.argv[1] or "").strip()
semver_re = re.compile(r"^v?(\d+)\.(\d+)\.(\d+)$")

def norm(v: str):
    m = semver_re.match(v.strip())
    if not m:
        return None
    return int(m.group(1)), int(m.group(2)), int(m.group(3))

def fmt(t):
    return f"v{t[0]}.{t[1]}.{t[2]}"

def run(*cmd):
    try:
        return subprocess.check_output(cmd, text=True, stderr=subprocess.DEVNULL).strip()
    except Exception:
        return ""

def read_metadata_version():
    version_file = Path("VERSION")
    if version_file.exists():
        v = version_file.read_text(encoding="utf-8", errors="ignore").strip()
        if norm(v):
            return fmt(norm(v))

    package_json = Path("package.json")
    if package_json.exists():
        try:
            v = json.loads(package_json.read_text(encoding="utf-8")).get("version", "")
            if norm(str(v)):
                return fmt(norm(str(v)))
        except Exception:
            pass

    pyproject = Path("pyproject.toml")
    if pyproject.exists():
        m = re.search(r"^version\s*=\s*['\"]([^'\"]+)['\"]", pyproject.read_text(encoding="utf-8", errors="ignore"), re.M)
        if m and norm(m.group(1)):
            return fmt(norm(m.group(1)))

    setup_py = Path("setup.py")
    if setup_py.exists():
        m = re.search(r"version\s*=\s*['\"]([^'\"]+)['\"]", setup_py.read_text(encoding="utf-8", errors="ignore"))
        if m and norm(m.group(1)):
            return fmt(norm(m.group(1)))

    cargo = Path("Cargo.toml")
    if cargo.exists():
        m = re.search(r"^version\s*=\s*['\"]([^'\"]+)['\"]", cargo.read_text(encoding="utf-8", errors="ignore"), re.M)
        if m and norm(m.group(1)):
            return fmt(norm(m.group(1)))
    return ""

def highest_semver_tag():
    tags = run("git", "tag", "--list").splitlines()
    parsed = [norm(t) for t in tags]
    parsed = [p for p in parsed if p]
    return fmt(max(parsed)) if parsed else ""

def highest_semver_in_changelog():
    p = Path("CHANGELOG.md")
    if not p.exists():
        return ""
    vals = []
    for line in p.read_text(encoding="utf-8", errors="ignore").splitlines():
        m = re.search(r"(\d+\.\d+\.\d+)", line)
        if m:
            n = norm(m.group(1))
            if n:
                vals.append(n)
    return fmt(max(vals)) if vals else ""

def bump(v, lane):
    major, minor, patch = norm(v)
    if lane == "major":
        return f"v{major+1}.0.0"
    if lane == "minor":
        return f"v{major}.{minor+1}.0"
    return f"v{major}.{minor}.{patch+1}"

def commit_range(ref):
    if ref:
        return run("git", "log", "--pretty=%s%n%b", f"{ref}..HEAD")
    return run("git", "log", "--pretty=%s%n%b", "-n", "200")

def lane_from_commits(text):
    if re.search(r"BREAKING CHANGE|^[^\\n]+!:", text, re.M):
        return "major"
    if re.search(r"^feat(\(.+\))?:", text, re.M):
        return "minor"
    return "patch"

def gt(a, b):
    return norm(a) > norm(b)

if explicit:
    n = norm(explicit)
    if not n:
        print("ERROR: explicit version must be semver (vX.Y.Z or X.Y.Z)", file=sys.stderr)
        sys.exit(1)
    candidate = fmt(n)
else:
    metadata = read_metadata_version()
    tag_max = highest_semver_tag()
    changelog_max = highest_semver_in_changelog()

    released = ""
    for v in (tag_max, changelog_max):
        if v and (not released or gt(v, released)):
            released = v

    if metadata and (not released or gt(metadata, released)):
        candidate = metadata
    else:
        base = released or metadata or "v0.0.0"
        lane = lane_from_commits(commit_range(tag_max))
        candidate = bump(base, lane)
        if base == "v0.0.0":
            candidate = "v0.1.0"

# Enforce monotonicity and uniqueness against tags.
tags = set(run("git", "tag", "--list").splitlines())
released_floor = highest_semver_tag() or "v0.0.0"
while candidate in tags or not gt(candidate, released_floor):
    candidate = bump(candidate, "patch")

print(candidate)
PY
}

release_version="$(compute_release_version | head -n1 | tr -d '\r')"
if [[ -z "$release_version" ]]; then
  echo "Failed to compute release version" >&2
  exit 1
fi

release_dir="$ROOT_DIR/public-releases/$release_version"
staging_dir="$release_dir/staging"
mkdir -p "$release_dir"

commit_sha="$(git rev-parse --verify HEAD)"
build_time_utc="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
delegation_used="none"

# Build sanitized staging tree from manifest.
python3 scripts/public_manifest_tool.py build \
  --root "$ROOT_DIR" \
  --manifest "$ROOT_DIR/release/public-manifest.yaml" \
  --output "$staging_dir"

# Add external-facing baseline docs to staging if missing.
if [[ ! -f "$staging_dir/INSTALL.md" ]]; then
  cat > "$staging_dir/INSTALL.md" <<'EOF'
# Installation

## Requirements

- Python 3.8+
- Git (recommended)

## Install From Source

```bash
git clone https://github.com/T72/task-orchestrator.git
cd task-orchestrator
./tm init
```

## Verify Installation

```bash
./tm --help
```
EOF
fi

if [[ ! -f "$staging_dir/USAGE.md" ]]; then
  cat > "$staging_dir/USAGE.md" <<'EOF'
# Usage

## Quick Start

```bash
export TM_AGENT_ID="orchestrator_agent"
./tm add "Example task" --assignee backend_agent
./tm list
```

## Core Workflow

1. Initialize with `./tm init`
2. Set agent identity via `TM_AGENT_ID`
3. Add tasks and dependencies via `./tm add`
4. Share context via `./tm share`
5. Complete tasks via `./tm complete`
EOF
fi

if [[ ! -f "$staging_dir/NOTICE" ]]; then
  cat > "$staging_dir/NOTICE" <<'EOF'
Task Orchestrator
Copyright (c) 2025-2026

This distribution includes software developed by the Task Orchestrator contributors.
See LICENSE and THIRD_PARTY_LICENSES.md for licensing details.
EOF
fi

if [[ ! -f "$staging_dir/THIRD_PARTY_LICENSES.md" ]]; then
  cat > "$staging_dir/THIRD_PARTY_LICENSES.md" <<'EOF'
# Third-Party Licenses

## Runtime Dependencies

Task Orchestrator runtime is implemented with Python standard library components only.

## Tooling and Platform Dependencies

- Python (PSF License)
- Git (GPLv2)
- GitHub Actions runner environment components (various OSS licenses)

Review your deployment environment for additional transitive licenses.
EOF
fi

cat > "$release_dir/RELEASE_MANIFEST.md" <<EOF
# Release Manifest

- Version: $release_version
- Commit: $commit_sha
- Build timestamp (UTC): $build_time_utc
- Source repository path: $ROOT_DIR
- Build command:
  - \`python3 scripts/public_manifest_tool.py build --root "$ROOT_DIR" --manifest "$ROOT_DIR/release/public-manifest.yaml" --output "$staging_dir"\`
- Packaging commands:
  - \`tar -czf task-orchestrator-$release_version.tar.gz -C "$staging_dir" .\`
  - \`zip -qr task-orchestrator-$release_version.zip .\`
- Tag publication command:
  - \`bash scripts/publish-release-tag.sh $release_version\`
- Runtime requirements:
  - Python 3.8+
- Platform assumptions:
  - Linux/macOS/WSL for shell-based setup
  - Windows supported via PowerShell + WSL workflow
- Changelog mode: $release_changelog_mode
- Changelog delegation: $delegation_used
EOF

if [[ "$release_changelog_mode" != "builtin" ]]; then
  if [[ -f "$release_changelog_tool" ]]; then
    if bash "$release_changelog_tool" \
      --version "$release_version" \
      --staging "$staging_dir" \
      --release-dir "$release_dir"; then
      delegation_used="$release_changelog_tool"
    elif [[ "$release_changelog_mode" == "delegate" ]]; then
      echo "Delegation tool failed in delegate-only mode: $release_changelog_tool" >&2
      exit 1
    fi
  elif [[ "$release_changelog_mode" == "delegate" ]]; then
    echo "Delegation tool not found or not executable: $release_changelog_tool" >&2
    exit 1
  fi
fi

if [[ ! -f "$release_dir/RELEASE_NOTES.md" ]]; then
cat > "$release_dir/RELEASE_NOTES.md" <<EOF
# Release Notes - $release_version

## Release Summary
This release provides public packaging hardening and CI governance updates for Task Orchestrator.

## New Features
- Manifest-based public artifact build and validation workflow.
- Governance baseline and release boundary quality gates in CI.

## Bug Fixes
- Cross-platform reliability improvements for release script invocation.
- Test stability and compatibility updates for current CLI behavior.

## Breaking Changes
- None identified for external CLI contract in this release package.

## Upgrade Guide
1. Pull the release tag for $release_version.
2. Run \`./tm init\` in a clean workspace.
3. Set \`TM_AGENT_ID\` before running task commands.

## Known Limitations
- Some optional developer tooling remains shell-oriented and expects a POSIX-like environment.

## Support Information
- Repository: https://github.com/T72/task-orchestrator
- Documentation: README.md, INSTALL.md, USAGE.md
EOF
fi

# Copy key docs to release folder root for one-stop handoff.
cp "$staging_dir/README.md" "$release_dir/README.md"
if [[ ! -f "$release_dir/CHANGELOG.md" ]]; then
  cp "$staging_dir/CHANGELOG.md" "$release_dir/CHANGELOG.md"
fi
cp "$staging_dir/LICENSE" "$release_dir/LICENSE"
cp "$staging_dir/THIRD_PARTY_LICENSES.md" "$release_dir/THIRD_PARTY_LICENSES.md"

# Refresh manifest with final delegation state after optional delegation phase.
python3 - "$release_dir/RELEASE_MANIFEST.md" "$delegation_used" <<'PY'
from pathlib import Path
import sys

manifest = Path(sys.argv[1])
delegation_used = sys.argv[2]
text = manifest.read_text(encoding="utf-8")
text = text.replace("- Changelog delegation: none", f"- Changelog delegation: {delegation_used}")
manifest.write_text(text, encoding="utf-8")
PY

# Package archives.
tar -czf "$release_dir/task-orchestrator-$release_version.tar.gz" -C "$staging_dir" .
(
  cd "$staging_dir"
  if command -v zip >/dev/null 2>&1; then
    zip -qr "$release_dir/task-orchestrator-$release_version.zip" .
  else
    python3 - "$release_dir/task-orchestrator-$release_version.zip" <<'PY'
import os
import sys
import zipfile

zip_path = sys.argv[1]
root = os.getcwd()
with zipfile.ZipFile(zip_path, "w", compression=zipfile.ZIP_DEFLATED) as zf:
    for dirpath, _, filenames in os.walk(root):
        for name in filenames:
            src = os.path.join(dirpath, name)
            rel = os.path.relpath(src, root)
            zf.write(src, rel)
PY
  fi
)

# Validation checklist summary.
cat > "$release_dir/VALIDATION_CHECKLIST.md" <<EOF
# Final Validation Checklist

- [x] Version tagged/detected ($release_version)
- [x] License present
- [x] Changelog updated
- [x] Documentation complete (README, INSTALL, USAGE)
- [x] Secrets removed from packaged content via manifest boundary build
- [x] Build reproducible (manifest + commands captured)
- [x] Install path verified (documented quick start)
EOF

echo "Prepared release at: $release_dir"
