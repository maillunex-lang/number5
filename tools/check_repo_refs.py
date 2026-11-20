#!/usr/bin/env python3
"""Fail if docs/code reference missing repo paths (backtick file paths)."""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SKIP_PARTS = {"node_modules", ".git", "0.1.0", "0.2.0", "0.3.0", "0.4.0", "0.5.0", "0.6.0"}
PAT = re.compile(r"`((?:docs|content|tools|scripts|scenes|admin-studio|assets)/[^`\s]+)`")
# Known intentional templates / globs — not literal files
ALLOW_MISSING = {
    "docs/content/STORY_*.md",  # glob prose
}


def main() -> int:
    missing: list[tuple[str, str]] = []
    for path in list(ROOT.rglob("*.md")) + list(ROOT.rglob("*.gd")) + list(ROOT.rglob("*.ts")) + list(ROOT.rglob("*.py")) + list(ROOT.rglob("*.sh")):
        if any(p in SKIP_PARTS for p in path.parts):
            continue
        if path.name == "check_repo_refs.py":
            continue
        text = path.read_text(encoding="utf-8", errors="replace")
        for m in PAT.finditer(text):
            rel = m.group(1).rstrip("/")
            if "*" in rel or "{" in rel:
                continue
            if not (ROOT / rel).exists():
                missing.append((str(path.relative_to(ROOT)), rel))
    # dedupe
    uniq = sorted(set(missing))
    if uniq:
        print("Broken repo path references:")
        for src, rel in uniq:
            print(f"  {src} -> {rel}")
        return 1
    print("OK: repo path references resolve")
    return 0


if __name__ == "__main__":
    sys.exit(main())
