from __future__ import annotations

import sys
from pathlib import Path

REQUIRED_PATHS = [
    # GitHub templates + issue config
    ".github/issue-template/config.yml",
    ".github/issue-template/engineering-issue.yml",
    ".github/pull-request-template/hotfix.md",
    ".github/pull-request-template/release.md",
    ".github/pull-request-template.md",
    ".github/labels.yml",
    ".github/workflows/backmerge-hotfix.yml",
    ".github/workflows/enforce-main-pr-template.yml",
    ".github/workflows/sync-blocked-label.yml",
    ".github/workflows/sync-labels.yml",
    ".github/workflows/validate-repo-structure.yml",
    "config",
    "config/env",
    # Governance
    "CONTRIBUTING.md",
    "docs/engineering_playbook.md",
    # Docs structure + navigation, main entry points
    "docs/README.md",
    "docs/user/README.md",
    "docs/developer/README.md",
    "docs/developer/backlog-health.md",
    "docs/developer/branching-strategy.md",
    "docs/developer/label-taxonomy.md",
    "docs/developer/milestone-phase-framework.md",
    "docs/developer/development/sessions",
    "docs/developer/reports",
    "docs/developer/setup",
    "docs/operations/README.md",
    # Branching Strategy
    "docs/developer/setup/repo_bootstrap_checklist.md",
    # ADR + reports
    "docs/developer/adr/adr-template.md",
    "docs/developer/architecture",
    # Prompts (used for prompt-based development)
    "docs/prompts/github-issues",
    "docs/prompts/github-issues/create-github-issue-prompt.md",
    "docs/prompts/github-issues/implement-github-issue-prompt.txt",
    "docs/prompts/github-issues/review-github-issue-prompt.md",
    "docs/prompts/project-init",
    "docs/prompts/project-init/codebase-analysis",
    "docs/prompts/project-init/codebase-analysis/analysis-review",
    "docs/prompts/project-init/codebase-analysis/analysis-review/document-technical-review-prompt.md",
    "docs/prompts/project-init/codebase-analysis/analysis-review/perform-analysis-review-prompt.md",
    "docs/prompts/project-init/codebase-analysis/initial-analysis",
    "docs/prompts/project-init/codebase-analysis/initial-analysis/document-technical-analysis-prompt.md",
    "docs/prompts/project-init/codebase-analysis/initial-analysis/perform-codebase-analysis-with-milestone-suggestions-prompt-alt-rev.md",
    "docs/prompts/project-init/codebase-analysis/initial-analysis/perform-codebase-analysis-with-milestone-suggestions-prompt.md",
    "docs/prompts/project-init/research",
    "docs/prompts/project-init/research/deep-research-[system-type]-boilerplate-capabilities-prompt-template.md",
    "docs/prompts/project-init/research/deep-research-state-of-the-art-[system-type]-capabilities-prompt-template.md",
    "docs/prompts/create-session-summary-prompt-template.md",
    # Tests & Test Contracts
    "tests/unit",
    "tests/contract"
]

def main() -> int:
    repo_root = Path(__file__).resolve().parents[1]
    missing: list[str] = []

    for rel in REQUIRED_PATHS:
        p = repo_root / rel
        if not p.exists():
            missing.append(rel)

    if missing:
        print("Repo structure check failed. Missing required paths:")
        for rel in missing:
            print(f"- {rel}")
        print("\nIf this repo intentionally deviates, update scripts/check_repo_structure.py.")
        return 1

    print("Repo structure check passed.")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
