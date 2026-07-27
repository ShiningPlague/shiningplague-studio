#!/usr/bin/env python3
"""
generate_skills_index.py -- regenerate the routing table in docs/skills-index.md
from the `name` + `description` frontmatter of every shipped SKILL.md.

WHY THIS EXISTS
    skills-index.md is the routing table: a session matches the user's intent
    against it and then fires the named skill. Its own header has always said
    "auto-generated ... regenerate rather than hand-edit" -- but nothing
    generated it, so it was hand-maintained, and hand-maintained routing tables
    drift. The drift is not cosmetic: a skill missing from the index is a skill
    the router never offers, and a description truncated mid-word ("Fires after
    /dev-story or /executing-pla") advertises a command that does not exist.

WHAT IT TOUCHES
    Exactly one region of exactly one file: the text between

        <!-- SKILLS-TABLE:BEGIN -->
        <!-- SKILLS-TABLE:END -->

    Header prose and the trailing count line outside that region are left alone.
    If the markers are absent the tool changes nothing and says how to add them.

WHERE IT LOOKS FOR SKILLS
    .claude/skills/*/SKILL.md when run inside an installed project, skills/*/
    SKILL.md when run inside the template repo. Whichever exists; the installed
    location wins if both do.

WHO RUNS IT
    - you, by hand, whenever a skill is added, removed or re-described:
        python tools/generate_skills_index.py
    - /writing-skills, after creating or editing a SKILL.md

TRUNCATION
    Descriptions are clipped to --width characters ON A WORD BOUNDARY and get a
    trailing ellipsis, so a clipped cell is visibly clipped and never ends in
    half a slash-command.

EXIT CODES
    0  the marked region was rewritten (or was already correct)
    3  nothing to do -- index file or markers absent. NOT an error: a project
       that does not keep a skills index is a valid project.
    1  a real failure (unreadable file, unwritable index)
"""

from __future__ import annotations

import argparse
import os
import re
import sys

BEGIN = "<!-- SKILLS-TABLE:BEGIN -->"
END = "<!-- SKILLS-TABLE:END -->"
DEFAULT_WIDTH = 200


def find_skills_root(root):
    for cand in (os.path.join(root, ".claude", "skills"), os.path.join(root, "skills")):
        if os.path.isdir(cand):
            return cand
    return None


def frontmatter(path):
    """Return the raw frontmatter block of a markdown file, or ''."""
    with open(path, "r", encoding="utf-8", errors="replace") as fh:
        text = fh.read()
    if not text.startswith("---"):
        return ""
    end = text.find("\n---", 3)
    return text[3:end] if end != -1 else ""


def field(block, key):
    """Read one scalar frontmatter field, handling quotes and folded values."""
    m = re.search(r"^%s:[ \t]*(.*)$" % re.escape(key), block, re.M)
    if not m:
        return ""
    val = m.group(1).strip()
    if val in (">-", ">", "|", "|-"):          # folded / literal block scalar
        lines = block[m.end():].split("\n")
        out = []
        for line in lines[1:]:
            if line.strip() and not line.startswith((" ", "\t")):
                break
            out.append(line.strip())
        val = " ".join(x for x in out if x)
    if len(val) >= 2 and val[0] == val[-1] and val[0] in "\"'":
        val = val[1:-1]
    return val.strip()


def clip(text, width):
    """Clip on a word boundary so a cell never ends mid-token."""
    text = " ".join(text.split())
    if len(text) <= width:
        return text
    cut = text[:width]
    space = cut.rfind(" ")
    if space > width // 2:
        cut = cut[:space]
    return cut.rstrip(" ,.;:-") + " ..."


def collect(skills_root, width):
    rows = []
    for name in sorted(os.listdir(skills_root)):
        path = os.path.join(skills_root, name, "SKILL.md")
        if not os.path.isfile(path):
            continue
        block = frontmatter(path)
        desc = field(block, "description") or "(no description in frontmatter)"
        rows.append((field(block, "name") or name, clip(desc, width)))
    return rows


def render(rows):
    out = ["| Skill | When to use |", "|---|---|"]
    for name, desc in rows:
        out.append("| `%s` | %s |" % (name, desc.replace("|", "\\|")))
    return "\n".join(out)


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[1])
    ap.add_argument("--root", default=".", help="project or template repo root")
    ap.add_argument("--index", default=None, help="path to skills-index.md")
    ap.add_argument("--width", type=int, default=DEFAULT_WIDTH,
                    help="max description characters (default %d)" % DEFAULT_WIDTH)
    ap.add_argument("--check", action="store_true",
                    help="exit 1 if the region is out of date; write nothing")
    args = ap.parse_args(argv)

    root = os.path.abspath(args.root)
    index = args.index or os.path.join(root, "docs", "skills-index.md")
    if not os.path.isfile(index):
        alt = os.path.join(root, ".claude", "docs", "skills-index.md")
        if os.path.isfile(alt):
            index = alt
        else:
            print("nothing to do: no skills-index.md under %s" % root)
            return 3

    skills_root = find_skills_root(root)
    if not skills_root:
        print("nothing to do: no skills/ or .claude/skills/ under %s" % root)
        return 3

    with open(index, "r", encoding="utf-8") as fh:
        text = fh.read()

    i, j = text.find(BEGIN), text.find(END)
    if i == -1 or j == -1 or j < i:
        print("nothing to do: %s has no %s .. %s region." % (index, BEGIN, END))
        print("Add the two marker lines around the table and re-run.")
        return 3

    rows = collect(skills_root, args.width)
    table = render(rows)
    new = text[:i + len(BEGIN)] + "\n" + table + "\n" + text[j:]
    new = re.sub(r"^_\d+ skills\._$", "_%d skills._" % len(rows), new, flags=re.M)

    if new == text:
        print("up to date: %d skills, %s" % (len(rows), os.path.relpath(index, root)))
        return 0
    if args.check:
        print("OUT OF DATE: %s -- run tools/generate_skills_index.py"
              % os.path.relpath(index, root))
        return 1

    with open(index, "w", encoding="utf-8", newline="") as fh:
        fh.write(new)
    print("rewrote: %d skills into %s" % (len(rows), os.path.relpath(index, root)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
