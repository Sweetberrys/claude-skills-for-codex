#!/usr/bin/env python3
"""
Enumerate Claude Code skills -> JSON metadata for Codex progressive loading.

Usage:
    python list-skills.py                     # scan ~/.claude/skills
    python list-skills.py /path/to/skills     # scan custom directory
    SKILLS_DIR=/path python list-skills.py    # env override

Requires: pip install python-frontmatter pyyaml
"""

import json
import os
import sys
from pathlib import Path

try:
    import frontmatter
except ImportError:
    print(
        "error: missing dependency. run: pip install python-frontmatter pyyaml",
        file=sys.stderr,
    )
    sys.exit(1)


def resolve_root():
    """Resolve skills root: CLI arg > env var > default ~/.claude/skills."""
    if len(sys.argv) > 1 and sys.argv[1].strip():
        return Path(sys.argv[1]).expanduser().resolve()
    env = os.environ.get("SKILLS_DIR")
    if env:
        return Path(env).expanduser().resolve()
    return Path.home() / ".claude" / "skills"


def main():
    root = resolve_root()
    if not root.exists():
        print(f"error: skills directory not found: {root}", file=sys.stderr)
        return 1

    skills = []
    for skill_file in sorted(root.rglob("SKILL.md")):
        try:
            post = frontmatter.load(skill_file)
        except Exception as exc:
            print(f"warn: parse failed {skill_file}: {exc}", file=sys.stderr)
            continue

        meta = post.metadata or {}
        name = meta.get("name")
        description = meta.get("description")

        if not isinstance(name, str) or not isinstance(description, str):
            continue

        item = {
            "name": name,
            "description": description,
            "path": str(skill_file),
        }

        if "allowed-tools" in meta:
            item["allowed-tools"] = meta["allowed-tools"]
        if "disable-model-invocation" in meta:
            item["disable-model-invocation"] = meta["disable-model-invocation"]
        if "context" in meta:
            item["context"] = meta["context"]

        skills.append(item)

    skills.sort(key=lambda s: s["name"].casefold())
    json.dump(skills, sys.stdout, ensure_ascii=False, indent=2)
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())