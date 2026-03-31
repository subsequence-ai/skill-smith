#!/usr/bin/env python3
"""Build skill catalog JSON from ~/.claude/skills/*/SKILL.md files."""

import json
import re
from pathlib import Path


def extract_description(skill_path: Path) -> str | None:
    """Extract description from SKILL.md YAML frontmatter."""
    skill_md = skill_path / "SKILL.md"
    if not skill_md.exists():
        return None

    text = skill_md.read_text()
    match = re.match(r"^---\s*\n(.*?)\n---", text, re.DOTALL)
    if not match:
        return None

    for line in match.group(1).splitlines():
        if line.startswith("description:"):
            return line[len("description:"):].strip()

    return None


def main() -> None:
    skills_dir = Path.home() / ".claude" / "skills"
    catalog: list[dict[str, str]] = []

    for skill_path in sorted(skills_dir.iterdir()):
        if not skill_path.is_dir():
            continue

        description = extract_description(skill_path)
        if description is None:
            print(f"WARNING: skipping {skill_path.name} — no description found")
            continue

        catalog.append({
            "name": skill_path.name,
            "description": description,
        })

    output = Path(__file__).parent / "skill-catalog.json"
    output.write_text(json.dumps(catalog, indent=2) + "\n")
    print(f"Wrote {len(catalog)} skills to {output}")


if __name__ == "__main__":
    main()
