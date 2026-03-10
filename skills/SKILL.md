---
name: claude-skills-enumerator
description: >
  Enumerate Claude Code skills metadata (name, description, path) and enable
  progressive loading in Codex. Use when you need to find the right Claude skill
  for a task, or when the user asks what skills are available. Run the enumerator
  first to get a JSON list, then load only the matching SKILL.md on demand.
allowed-tools:
  - Bash
---

# Claude Skills Enumerator

## Purpose

Bridge Claude Code skills into Codex by listing metadata first,
then loading full SKILL.md only when needed (progressive disclosure).

## Workflow

1. Run the enumerator script to get a JSON list of all Claude Code skills.
2. Match the current task against each skill's `description` field.
3. Read **only** the matching skill's full `SKILL.md` via its `path` field.
4. Follow the loaded skill's instructions to complete the task.
5. If no skill matches, proceed normally without loading any skill.

## Commands

Default scan (scans ~/.claude/skills):

```bash
python $HOME/.codex/skills/claude-skills-enumerator/scripts/list-skills.py
```

Custom directory:

```bash
python $HOME/.codex/skills/claude-skills-enumerator/scripts/list-skills.py C:\path\to\skills
```

## Output Format

```json
[
  {
    "name": "skill-name",
    "description": "What this skill does and when to use it",
    "path": "C:\\Users\\YourUsername\\.claude\\skills\\skill-name\\SKILL.md",
    "allowed-tools": ["Read", "Bash"]
  }
]
```

## Important

- **Do NOT load all SKILL.md files at once** - Only load what matches.
- Output is UTF-8 JSON, stably sorted by skill name.
- Only skills with valid name AND description frontmatter are included.
- On Windows, ensure paths use backslashes or forward slashes consistently.
