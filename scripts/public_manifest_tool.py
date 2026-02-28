#!/usr/bin/env python3
"""Manifest-backed validator and artifact builder for public releases."""

from __future__ import annotations

import argparse
import fnmatch
import os
import shutil
import sys
from pathlib import Path
from typing import Dict, Iterable, List


def _load_manifest(manifest_path: Path) -> Dict[str, List[str]]:
    """Load YAML manifest. Falls back to a minimal parser if PyYAML is missing."""
    text = manifest_path.read_text(encoding="utf-8")
    try:
        import yaml  # type: ignore

        data = yaml.safe_load(text) or {}
    except Exception:
        data = _parse_simple_yaml_lists(text)

    normalized: Dict[str, List[str]] = {}
    for key in (
        "include_paths",
        "exclude_globs",
        "required_files",
        "forbidden_patterns",
        "forbidden_content_patterns",
    ):
        value = data.get(key, [])
        if value is None:
            value = []
        if not isinstance(value, list):
            raise ValueError(f"Manifest key '{key}' must be a list")
        normalized[key] = [str(item).strip() for item in value if str(item).strip()]
    return normalized


def _parse_simple_yaml_lists(text: str) -> Dict[str, List[str]]:
    """Parse a minimal subset of YAML (top-level list keys)."""
    result: Dict[str, List[str]] = {}
    current_key = None
    for raw_line in text.splitlines():
        line = raw_line.split("#", 1)[0].rstrip()
        if not line.strip():
            continue
        if not line.startswith(" ") and line.endswith(":"):
            current_key = line[:-1].strip()
            result[current_key] = []
            continue
        stripped = line.lstrip()
        if stripped.startswith("- ") and current_key:
            item = stripped[2:].strip().strip("'").strip('"')
            result[current_key].append(item)
    return result


def _iter_all_files(root: Path) -> Iterable[Path]:
    for path in root.rglob("*"):
        if path.is_file():
            yield path


def _to_rel(path: Path, root: Path) -> str:
    return path.relative_to(root).as_posix()


def _matches(pattern: str, rel_path: str) -> bool:
    if fnmatch.fnmatch(rel_path, pattern):
        return True
    if "/" not in pattern and "*" not in pattern and "?" not in pattern:
        return Path(rel_path).name == pattern
    if pattern.endswith("/**"):
        prefix = pattern[:-3].rstrip("/")
        return rel_path == prefix or rel_path.startswith(prefix + "/")
    return False


def _is_included(rel_path: str, includes: List[str]) -> bool:
    for include in includes:
        include = include.strip("/")
        if not include:
            continue
        if rel_path == include or rel_path.startswith(include + "/"):
            return True
    return False


def _filter_included_files(root: Path, manifest: Dict[str, List[str]]) -> List[Path]:
    include_paths = manifest["include_paths"]
    exclude_globs = manifest["exclude_globs"]
    files: List[Path] = []
    for file_path in _iter_all_files(root):
        rel = _to_rel(file_path, root)
        if not _is_included(rel, include_paths):
            continue
        if any(_matches(pattern, rel) for pattern in exclude_globs):
            continue
        files.append(file_path)
    return files


def _check_required(root: Path, required_files: List[str], violations: List[str]) -> None:
    for required in required_files:
        if not (root / required).exists():
            violations.append(f"Missing required file: {required}")


def _check_forbidden_paths(
    files: Iterable[Path], root: Path, forbidden_patterns: List[str], violations: List[str]
) -> None:
    for file_path in files:
        rel = _to_rel(file_path, root)
        for pattern in forbidden_patterns:
            if _matches(pattern, rel):
                violations.append(f"Forbidden path pattern matched: {rel} (pattern: {pattern})")
                break


def _is_binary(path: Path) -> bool:
    try:
        with path.open("rb") as f:
            chunk = f.read(4096)
        return b"\x00" in chunk
    except Exception:
        return True


def _check_forbidden_content(
    files: Iterable[Path], root: Path, patterns: List[str], violations: List[str]
) -> None:
    if not patterns:
        return
    for file_path in files:
        if _is_binary(file_path):
            continue
        try:
            content = file_path.read_text(encoding="utf-8", errors="ignore")
        except Exception:
            continue
        rel = _to_rel(file_path, root)
        for pattern in patterns:
            if pattern in content:
                violations.append(f"Forbidden content pattern '{pattern}' found in: {rel}")


def _run_validate(root: Path, manifest_path: Path, only_included: bool) -> int:
    manifest = _load_manifest(manifest_path)
    violations: List[str] = []
    _check_required(root, manifest["required_files"], violations)

    if only_included:
        scan_files = _filter_included_files(root, manifest)
    else:
        scan_files = list(_iter_all_files(root))

    _check_forbidden_paths(scan_files, root, manifest["forbidden_patterns"], violations)
    _check_forbidden_content(scan_files, root, manifest["forbidden_content_patterns"], violations)

    if violations:
        print("Manifest validation failed:")
        for violation in violations:
            print(f"  - {violation}")
        return 1

    print("Manifest validation passed.")
    return 0


def _run_build(root: Path, manifest_path: Path, output: Path) -> int:
    manifest = _load_manifest(manifest_path)
    included_files = _filter_included_files(root, manifest)

    if output.exists():
        shutil.rmtree(output)
    output.mkdir(parents=True, exist_ok=True)

    for src in included_files:
        rel = src.relative_to(root)
        dest = output / rel
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dest)

    return _run_validate(output, manifest_path, only_included=False)


def main() -> int:
    parser = argparse.ArgumentParser(description="Public release manifest tool")
    parser.add_argument("command", choices=["validate", "build"])
    parser.add_argument("--root", required=True, help="Source root directory")
    parser.add_argument("--manifest", required=True, help="Manifest YAML path")
    parser.add_argument(
        "--only-included",
        action="store_true",
        help="Validate only files under include_paths (after exclude_globs)",
    )
    parser.add_argument("--output", help="Output directory for build command")
    args = parser.parse_args()

    root = Path(args.root).resolve()
    manifest = Path(args.manifest).resolve()

    if not root.exists():
        print(f"Root not found: {root}")
        return 1
    if not manifest.exists():
        print(f"Manifest not found: {manifest}")
        return 1

    if args.command == "validate":
        return _run_validate(root, manifest, only_included=args.only_included)

    output = Path(args.output).resolve() if args.output else None
    if output is None:
        print("--output is required for build")
        return 1
    return _run_build(root, manifest, output)


if __name__ == "__main__":
    sys.exit(main())
