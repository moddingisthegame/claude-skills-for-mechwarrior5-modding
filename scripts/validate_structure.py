#!/usr/bin/env python3
"""Structural validation for the MW5 modding skills marketplace.

Checks, repo-wide:
  - .claude-plugin/marketplace.json is valid JSON with the expected shape,
    and every declared plugin's `source` resolves to a real plugin.json
  - every plugins/*/.claude-plugin/plugin.json is valid JSON with a `name`
    matching its marketplace entry
  - every plugins/*/skills/*/SKILL.md has a YAML frontmatter block with a
    `name` matching its directory and a non-empty `description`
  - every relative .md link anywhere under plugins/ resolves to a real file
  - every plugins/*/skills/*/evals/eval_set.json is valid JSON matching the
    [{"query": str, "should_trigger": bool}, ...] schema, and contains at
    least one true case and one false case (otherwise it can't measure
    anything — an eval set that's all one value is not an eval set)

Every skill is required to carry an eval set: a skill with no trigger evals
is exactly the "we have no idea if this routes correctly" state this CI
exists to catch.

Prints every failure found (not just the first) and exits non-zero if any
were found.
"""
import json
import re
import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parent.parent
FRONTMATTER_RE = re.compile(r"^---\r?\n(.*?)\r?\n---\r?\n", re.S)
MD_LINK_RE = re.compile(r"\]\(([^)]+\.md)(?:#[^)]*)?\)")

errors: list[str] = []


def fail(msg: str) -> None:
    errors.append(msg)


def load_json(path: Path):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        fail(f"{path}: file does not exist")
    except json.JSONDecodeError as e:
        fail(f"{path}: invalid JSON — {e}")
    return None


def validate_marketplace() -> list[tuple[str, Path]]:
    """Returns [(plugin_name, plugin_dir), ...] for plugins that resolved."""
    mp_path = ROOT / ".claude-plugin" / "marketplace.json"
    mp = load_json(mp_path)
    plugin_dirs: list[tuple[str, Path]] = []
    if mp is None:
        return plugin_dirs

    for key in ("name", "owner", "plugins"):
        if key not in mp:
            fail(f"{mp_path}: missing required key '{key}'")

    if not isinstance(mp.get("plugins"), list) or not mp.get("plugins"):
        fail(f"{mp_path}: 'plugins' must be a non-empty array")
        return plugin_dirs

    for entry in mp["plugins"]:
        pname = entry.get("name", "<unnamed>")
        for key in ("name", "source", "description"):
            if key not in entry:
                fail(f"{mp_path}: plugin entry '{pname}' missing '{key}'")
        src = entry.get("source", "")
        plugin_path = (ROOT / src.lstrip("./")).resolve() if src else None
        if not plugin_path or not plugin_path.is_dir():
            fail(f"{mp_path}: plugin '{pname}' source '{src}' does not resolve to a directory")
        else:
            plugin_dirs.append((pname, plugin_path))
    return plugin_dirs


def validate_plugin_json(name: str, pdir: Path) -> None:
    pj_path = pdir / ".claude-plugin" / "plugin.json"
    pj = load_json(pj_path)
    if pj is None:
        return
    for key in ("name", "version", "description"):
        if key not in pj:
            fail(f"{pj_path}: missing required key '{key}'")
    if pj.get("name") != name:
        fail(f"{pj_path}: name '{pj.get('name')}' does not match marketplace entry '{name}'")
    if not (pdir / "skills").is_dir():
        fail(f"{pdir}: plugin has no skills/ directory")


def validate_skill(sdir: Path) -> None:
    skill_md = sdir / "SKILL.md"
    if not skill_md.is_file():
        fail(f"{sdir}: no SKILL.md")
        return

    text = skill_md.read_text(encoding="utf-8")
    m = FRONTMATTER_RE.match(text)
    if not m:
        fail(f"{skill_md}: no '---' YAML frontmatter block at top of file")
        return

    try:
        fm = yaml.safe_load(m.group(1))
    except yaml.YAMLError as e:
        fail(f"{skill_md}: frontmatter is not valid YAML — {e}")
        return

    if not isinstance(fm, dict):
        fail(f"{skill_md}: frontmatter did not parse to a mapping")
        return

    if fm.get("name") != sdir.name:
        fail(f"{skill_md}: frontmatter name '{fm.get('name')}' does not match directory name '{sdir.name}'")

    desc = fm.get("description")
    if not isinstance(desc, str) or not desc.strip():
        fail(f"{skill_md}: missing or empty 'description'")

    validate_eval_set(sdir)


def validate_eval_set(sdir: Path) -> None:
    eval_path = sdir / "evals" / "eval_set.json"
    if not eval_path.is_file():
        fail(f"{sdir}: no evals/eval_set.json — every skill needs trigger evals")
        return

    evals = load_json(eval_path)
    if evals is None:
        return
    if not isinstance(evals, list) or not evals:
        fail(f"{eval_path}: must be a non-empty JSON array")
        return

    trues = falses = 0
    for i, item in enumerate(evals):
        if not isinstance(item, dict) or "query" not in item or "should_trigger" not in item:
            fail(f"{eval_path}[{i}]: must be an object with 'query' and 'should_trigger'")
            continue
        query, trigger = item["query"], item["should_trigger"]
        if not isinstance(query, str) or not query.strip():
            fail(f"{eval_path}[{i}]: 'query' must be a non-empty string")
        if not isinstance(trigger, bool):
            fail(f"{eval_path}[{i}]: 'should_trigger' must be a boolean")
        elif trigger:
            trues += 1
        else:
            falses += 1

    if trues == 0:
        fail(f"{eval_path}: no should_trigger:true cases — can't measure whether the skill actually fires")
    if falses == 0:
        fail(f"{eval_path}: no should_trigger:false cases — can't measure false positives")


def validate_markdown_links() -> None:
    for md_path in (ROOT / "plugins").rglob("*.md"):
        text = md_path.read_text(encoding="utf-8")
        for m in MD_LINK_RE.finditer(text):
            link = m.group(1)
            target = (md_path.parent / link).resolve()
            if not target.is_file():
                fail(f"{md_path}: broken relative link to '{link}'")


def main() -> int:
    plugin_dirs = validate_marketplace()
    for name, pdir in plugin_dirs:
        validate_plugin_json(name, pdir)

    skill_dirs = sorted((ROOT / "plugins").glob("*/skills/*"))
    if not skill_dirs:
        fail("no skills found under plugins/*/skills/*")
    for sdir in skill_dirs:
        if sdir.is_dir():
            validate_skill(sdir)

    validate_markdown_links()

    if errors:
        print(f"::error::{len(errors)} structural validation failure(s)")
        for e in errors:
            print(f" - {e}")
        return 1

    print(
        f"Structural validation passed: {len(plugin_dirs)} plugin(s), "
        f"{len(skill_dirs)} skill(s), all with valid frontmatter, eval sets, "
        f"and resolving markdown links."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
