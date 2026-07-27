#!/usr/bin/env python3
"""
generate_systems_index.py -- regenerate the systems table in docs/gdd/systems-index.md
from data/_schemas/system_registry.json.

WHY THIS EXISTS
    The registry is the SOURCE of built-state truth; the systems index is a
    human-readable VIEW of it. Hand-maintaining both guarantees they drift, and a
    drifted index is worse than no index -- a session trusts it and plans against
    a system that shipped three weeks ago.

WHAT IT TOUCHES
    Exactly one region of exactly one file: the text between

        <!-- SYSTEMS-TABLE:BEGIN -->
        <!-- SYSTEMS-TABLE:END -->

    Everything else in systems-index.md is hand-authored (overview, categories,
    priority tiers, dependency map, risk register) and is never rewritten. If the
    markers are absent the tool changes nothing and tells you how to add them --
    it will not guess where the table belongs, and it will not overwrite prose.

WHO RUNS IT
    - hooks/sync-systems-index.sh, on every write to system_registry.json
    - /design-system, at the end of its Finalize phase
    - you, by hand: `python tools/generate_systems_index.py`

EXIT CODES
    0  the marked region was rewritten (or was already correct)
    3  nothing to do -- registry, index file, or markers absent. NOT an error:
       a project that has not run /map-systems yet has no index, and that is the
       correct day-one state.
    1  the registry exists but could not be parsed. That IS an error.
"""

from __future__ import annotations

import argparse
import json
import pathlib
import sys

BEGIN = "<!-- SYSTEMS-TABLE:BEGIN -->"
END = "<!-- SYSTEMS-TABLE:END -->"

DEFAULT_REGISTRY = "data/_schemas/system_registry.json"
DEFAULT_INDEX = "docs/gdd/systems-index.md"

HEADER = (
    "| # | System Name | Category | Priority | Status | Design Doc | Depends On |\n"
    "|---|-------------|----------|----------|--------|------------|------------|\n"
)


def say(msg: str) -> None:
    """Print without exploding on a legacy console codepage."""
    sys.stdout.write(msg.encode("ascii", "replace").decode("ascii") + "\n")


def cell(value: object) -> str:
    """One table cell: never empty, never breaks the pipe table."""
    if value is None:
        return "-"
    if isinstance(value, (list, tuple)):
        joined = ", ".join(str(v) for v in value if str(v).strip())
        return joined.replace("|", "\\|") if joined else "-"
    text = str(value).strip()
    return text.replace("|", "\\|") if text else "-"


def build_table(systems: list) -> str:
    if not systems:
        return (
            HEADER
            + "| - | _no systems registered yet_ | - | - | - | - | - |\n"
            + "\n> The registry lists no systems. Run `/map-systems` to decompose the\n"
            + "> concept, and this table fills itself in.\n"
        )

    rows = []
    for n, s in enumerate(systems, start=1):
        if not isinstance(s, dict):
            continue
        rows.append(
            "| {n} | {name} | {layer} | {priority} | {status} | {gdd} | {deps} |".format(
                n=n,
                name=cell(s.get("name") or s.get("id")),
                layer=cell(s.get("layer") or s.get("category")),
                priority=cell(s.get("priority")),
                status=cell(s.get("status")),
                gdd=cell(s.get("gdd")),
                deps=cell(s.get("dependencies")),
            )
        )
    return HEADER + "\n".join(rows) + "\n"


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--registry", default=DEFAULT_REGISTRY, help=f"default: {DEFAULT_REGISTRY}")
    ap.add_argument("--index", default=DEFAULT_INDEX, help=f"default: {DEFAULT_INDEX}")
    ap.add_argument("--check", action="store_true", help="report whether the table is stale; write nothing")
    args = ap.parse_args()

    registry = pathlib.Path(args.registry)
    index = pathlib.Path(args.index)

    # --- graceful degradation: an artifact named here may simply not exist yet ---
    if not registry.is_file():
        say(f"nothing to do: {registry} is absent (no registry yet -- correct before /map-systems).")
        return 3
    if not index.is_file():
        say(f"nothing to do: {index} is absent (no systems index yet -- run /map-systems).")
        return 3

    try:
        data = json.loads(registry.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, UnicodeDecodeError) as exc:
        say(f"ERROR: {registry} exists but is not valid JSON: {exc}")
        return 1

    systems = data.get("systems") or []
    if not isinstance(systems, list):
        say(f"ERROR: {registry} -> 'systems' must be a list, found {type(systems).__name__}.")
        return 1

    text = index.read_text(encoding="utf-8")
    start = text.find(BEGIN)
    stop = text.find(END)
    if start == -1 or stop == -1 or stop < start:
        say(f"nothing to do: {index} has no {BEGIN} / {END} region.")
        say("            Add those two markers around the systems table to enable auto-sync.")
        return 3

    new_body = f"{BEGIN}\n<!-- generated from {registry.as_posix()} by tools/generate_systems_index.py -- edits inside this block are overwritten -->\n\n{build_table(systems)}\n{END}"
    updated = text[:start] + new_body + text[stop + len(END):]

    if updated == text:
        say(f"up to date: {index} ({len(systems)} system(s)).")
        return 0

    if args.check:
        say(f"STALE: {index} does not match the registry ({len(systems)} system(s)). Run without --check to sync.")
        return 0

    index.write_text(updated, encoding="utf-8")
    say(f"wrote {index} ({len(systems)} system(s)) from {registry}.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
