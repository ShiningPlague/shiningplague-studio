#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
consistency_check.py -- the doc-stack consistency runner for a studio project.

WHAT IT DOES
    Reads the project's own state files and checks that they agree with each
    other and with the disk: the registry parses and is shaped the way the
    skills read it, every path a doc promises exists, the ADRs are numbered
    and statused, the spec/plan lifecycle is honoured, no markdown link points
    at a file that is not there, and the hooks + skills the install wires are
    actually on disk.

WHY IT EXISTS
    /consistency-check, /update, /red-flag-scan, /session-close and
    /verification-before-completion all execute this file by path. For a long
    time it did not exist, and the close ritual crashed on it. A runner that
    the skills command must ship with the skills.

THE ONE RULE THIS FILE OBEYS
    A fresh project has an empty registry, an empty docs/adr/ and no specs.
    That is the CORRECT day-one state, not a failure. Every check answers
    "not applicable yet -- nothing to check" and keeps going, so a brand-new
    install exits 0 with a clean report. A missing file is never a crash: it
    is a finding, or it is a SKIP.

CHECKS (12) -- see CHECKS at the bottom of this file for the live list
     1  registry parses and carries the keys the skills read
     2  registry entry shape: required keys, status vocabulary, unique ids
     3  registry references resolve: files on disk, id cross-links
     4  registry coverage: what is on disk but not in the registry
     5  doc stack: every path CLAUDE.md's reading map promises exists
     6  doc ledger: active_docs / spec_index / adr_index paths resolve
     7  spec + plan lifecycle: status agrees with location, index covers disk
     8  ADR hygiene: numbering, Status line, references that resolve
     9  cross-doc drift: registry status vs implementation-status vs stage.txt
    10  doc links: relative markdown links that point at a missing file
    11  session-state freshness: active.md vs the newest commit
    12  hook + skill integrity: wired hooks exist, SKILL.md frontmatter parses

VERDICT
    FAIL findings fail the run (exit 1). WARN findings never do -- they are
    drift worth knowing about, not a broken project. SKIP means the project
    has not grown that artifact yet.

USAGE
    python tools/consistency_check.py              # from the project root
    python tools/consistency_check.py --quiet      # findings + verdict only
    python tools/consistency_check.py --no-bump    # do not touch the registry
    python tools/consistency_check.py --fix-safe   # create absent empty dirs
    python tools/consistency_check.py --root DIR   # check another project dir

    On a run with no FAILs, `last_full_audit` in the registry is bumped to
    today (idempotent within the day). --no-bump suppresses it; use that for
    read-only spot checks and for pre-commit hooks.

EXIT CODES
    0  PASS   no FAIL findings (WARNs may be present)
    1  FAIL   at least one FAIL finding -- each one is named in the report
    2  ERROR  not run from a project root / unreadable arguments

Pure Python 3 standard library. No dependencies. Windows and POSIX.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from datetime import date, datetime
from pathlib import Path

# --------------------------------------------------------------------------
# conventions this runner reads (the canonical layout from CLAUDE.md)
# --------------------------------------------------------------------------

REGISTRY_REL = "data/_schemas/system_registry.json"
CLAUDE_MD = "CLAUDE.md"
IMPL_STATUS = "docs/implementation-status.md"
STAGE_TXT = "production/stage.txt"
ACTIVE_MD = "production/session-state/active.md"
ADR_DIR = "docs/adr"
SPEC_DIR = "docs/specs"
PLAN_DIR = "docs/plans"
SPEC_ARCHIVE = "docs/z-old/specs"
PLAN_ARCHIVE = "docs/z-old/plans"

# Doc trees whose prose is the project's own. Scanned for links and ADR refs.
DOC_ROOTS = ["docs", "production"]

# Archived prose is a historical record: a link that rotted after the doc was
# retired -- or after a snapshot was copied to a different depth -- is expected,
# so the link + reference sweeps skip these trees. Matched per directory name at
# any depth, whole name or hyphen/underscore-separated word, so a project's own
# archive convention ('vendor-backups/', 'old_reviews/') is covered as well as
# this template's docs/z-old/.
ARCHIVE_DIR_WORDS = ("z-old", "old", "archive", "archives", "archived",
                     "backup", "backups", "snapshot", "snapshots")

# Statuses a registry entry may carry. Overridden by the registry's own
# `_status_meanings` block when present, so a project can extend the
# vocabulary without editing this file.
DEFAULT_STATUSES = [
    "planned", "stub", "wip", "partial", "active",
    "phasing_out", "deprecated", "dormant", "for_review",
]

# Top-level registry keys the skills read. A missing key is a WARN: the skill
# that looks for it finds nothing and has to guess.
REGISTRY_KEYS = {
    "phase": str,
    "documentation_stack": dict,
    "systems": list,
    "tools": list,
    "data": list,
    "next_session_priorities": list,
    "flagged_for_designer_review": list,
}

# Keys per registry category (see the registry's own _schema_notes). REQUIRED is
# what a skill actually keys off -- its absence breaks a reader, so it FAILs.
# LOCATOR is "at least one of these must be present" (a tool or data entry has
# to say where it lives; `files[]` is the older way of saying `path`/`dir`).
# RECOMMENDED is shape the template asks for but nothing breaks without: WARN.
REQUIRED_ENTRY_KEYS = {
    "systems": ["id", "name", "status"],
    "tools": [],
    "data": [],
}
LOCATOR_ENTRY_KEYS = {
    "systems": [],
    "tools": ["path", "files"],
    "data": ["dir", "files"],
}
RECOMMENDED_ENTRY_KEYS = {
    "systems": ["layer"],
    "tools": ["purpose"],
    "data": ["purpose"],
}

# Entry fields that hold a path and are therefore checkable on disk.
ENTRY_PATH_KEYS = ("path", "dir", "file", "gdd", "schema", "archive_path")
ENTRY_PATH_LISTS = ("files",)

# Entry fields that hold registry ids and are therefore checkable against them.
ENTRY_ID_LISTS = ("depends_on", "dependencies", "consumed_by", "produced_by")

# Runners this framework ships. They live in tools/ of every install, belong to
# the template rather than to the game, and so do not need a registry entry.
FRAMEWORK_TOOLS = {
    "consistency_check.py",
    "doc_stack_check.py",
    "workflow_state_check.py",
    "generate_systems_index.py",
    "doc_stack.manifest.json",
}

# Illustrative names the shipped templates use in their example rows. They are
# documentation, not content, so they never count as drift.
PLACEHOLDER_PREFIXES = ("your-", "your_", "example-", "example_", "sample-",
                        "sample_", "my-", "my_", "placeholder")

# A path with one of these in it is a pattern, not an address: there is no one
# file to open, so there is nothing to verify.
PLACEHOLDER_RE = re.compile(r"\{\{[^}\n]{1,60}\}\}|<[^<>\s/]{1,60}>|\[[^\[\]\s/]{1,60}\]")

RULE = "=" * 78
THIN = "-" * 78

PASS, WARN, FAIL, SKIP = "PASS", "WARN", "FAIL", "SKIP"


# --------------------------------------------------------------------------
# result plumbing
# --------------------------------------------------------------------------

class Result(object):
    """One check's outcome. Findings carry their own severity."""

    def __init__(self, number, title):
        self.number = number
        self.title = title
        self.findings = []      # (severity, text)
        self.notes = []         # informational lines, printed under the check
        self.skipped = None     # reason string when nothing was applicable

    def fail(self, text):
        self.findings.append((FAIL, text))

    def warn(self, text):
        self.findings.append((WARN, text))

    def note(self, text):
        self.notes.append(text)

    def skip(self, reason):
        self.skipped = reason

    @property
    def status(self):
        if any(sev == FAIL for sev, _ in self.findings):
            return FAIL
        if any(sev == WARN for sev, _ in self.findings):
            return WARN
        if self.skipped:
            return SKIP
        return PASS

    def counts(self):
        f = sum(1 for sev, _ in self.findings if sev == FAIL)
        w = sum(1 for sev, _ in self.findings if sev == WARN)
        return f, w


# --------------------------------------------------------------------------
# small helpers
# --------------------------------------------------------------------------

def norm(path):
    return str(path).replace("\\", "/")


def read_text(path):
    """Read a text file, tolerating whatever encoding it happens to carry."""
    try:
        return Path(path).read_text(encoding="utf-8")
    except UnicodeDecodeError:
        return Path(path).read_text(encoding="utf-8", errors="replace")


def is_pattern(ref):
    return bool(PLACEHOLDER_RE.search(ref)) or "*" in ref or "?" in ref


def unprefix(ref):
    """Drop a leading './' -- and only that.

    str.lstrip('./') strips CHARACTERS, so it eats the dot of '.claude/...'
    and turns a real path into a phantom one. This bit once already.
    """
    out = norm(ref)
    while out.startswith("./"):
        out = out[2:]
    return out


def looks_like_path(ref):
    """A conservative test: a real, addressable, project-relative path."""
    if not ref or " " in ref or "\t" in ref:
        return False
    if is_pattern(ref):
        return False
    if ref.startswith(("http://", "https://", "mailto:", "res://", "user://",
                       "uid://", "#", "~", "$", "/", "@")):
        return False
    if "/" not in ref:
        return False
    if ref.startswith("."):                 # ./x and ../x are link-relative
        return True
    last = ref.rstrip("/").rsplit("/", 1)[-1]
    return ref.endswith("/") or "." in last


def is_archived(rel_path):
    for part in norm(rel_path).split("/")[:-1]:     # directories only
        low = part.lower()
        if low in ARCHIVE_DIR_WORDS:
            return True
        if any(word in ARCHIVE_DIR_WORDS for word in re.split(r"[-_.]", low)):
            return True
    return False


def is_placeholder_name(name):
    low = str(name).strip().strip("`").lower()
    return low.startswith(PLACEHOLDER_PREFIXES)


def strip_fences(text):
    """Yield (lineno, line) for lines outside fenced code blocks.

    Paths inside a fence are as often an illustrative snippet as a real
    command, and the two are indistinguishable -- judging them would invent
    failures. doc_stack_check.py makes the same call for the same reason.
    """
    fenced = False
    for i, line in enumerate(text.splitlines(), start=1):
        stripped = line.lstrip()
        if stripped.startswith("```") or stripped.startswith("~~~"):
            fenced = not fenced
            continue
        if not fenced:
            yield i, line


def md_files(root, rel_dirs, skip_archives=True):
    """Every markdown file under the given project-relative directories."""
    out = []
    for rel in rel_dirs:
        base = Path(root) / rel
        if not base.is_dir():
            continue
        for p in sorted(base.rglob("*.md")):
            rel_path = norm(p.relative_to(root))
            if skip_archives and is_archived(rel_path):
                continue
            out.append((rel_path, p))
    top = Path(root) / CLAUDE_MD
    if top.is_file():
        out.insert(0, (CLAUDE_MD, top))
    return out


def run_git(args, root):
    """Run git, surviving a missing binary and non-ASCII commit messages."""
    try:
        return subprocess.run(
            ["git"] + args, cwd=str(root), capture_output=True, text=True,
            encoding="utf-8", errors="replace",
        )
    except (OSError, ValueError):
        return None


def entry_label(category, entry, index):
    ident = entry.get("id") or entry.get("path") or entry.get("dir") or entry.get("name")
    return "%s[%s]" % (category, ident if ident else "#%d" % index)


# --------------------------------------------------------------------------
# project context -- loaded once, shared by every check
# --------------------------------------------------------------------------

class Project(object):
    def __init__(self, root):
        self.root = Path(root)
        self.registry = None
        self.registry_error = None
        self.registry_raw = None
        reg = self.root / REGISTRY_REL
        if reg.is_file():
            try:
                self.registry_raw = read_text(reg)
                self.registry = json.loads(self.registry_raw)
            except json.JSONDecodeError as exc:
                self.registry_error = "is not valid JSON -- %s (line %d, column %d)" % (
                    exc.msg, exc.lineno, exc.colno)
            except OSError as exc:
                self.registry_error = "could not be read -- %s" % exc
            if self.registry is not None and not isinstance(self.registry, dict):
                self.registry_error = ("has a %s at the top level, expected an object"
                                       % type(self.registry).__name__)
                self.registry = None

    # -- convenience readers, all None-safe -------------------------------

    def exists(self, rel):
        return (self.root / rel).exists()

    def category(self, name):
        if not self.registry:
            return []
        value = self.registry.get(name)
        return value if isinstance(value, list) else []

    def doc_stack(self):
        if not self.registry:
            return {}
        value = self.registry.get("documentation_stack")
        return value if isinstance(value, dict) else {}

    def specs(self):
        idx = self.doc_stack().get("spec_index")
        if isinstance(idx, dict) and isinstance(idx.get("specs"), list):
            return idx["specs"]
        return []

    def adrs(self):
        idx = self.doc_stack().get("adr_index")
        if isinstance(idx, dict) and isinstance(idx.get("adrs"), list):
            return idx["adrs"]
        return []

    def active_docs(self):
        value = self.doc_stack().get("active_docs")
        return value if isinstance(value, list) else []

    def statuses(self):
        meanings = (self.registry or {}).get("_status_meanings")
        if isinstance(meanings, dict) and meanings:
            return sorted(meanings.keys())
        return sorted(DEFAULT_STATUSES)

    def registry_ids(self):
        ids = set()
        for cat in ("systems", "tools", "data"):
            for entry in self.category(cat):
                if isinstance(entry, dict) and entry.get("id"):
                    ids.add(str(entry["id"]))
        return ids

    def registry_paths(self):
        """Every path-ish value the registry mentions, normalised."""
        out = set()
        for cat in ("systems", "tools", "data"):
            for entry in self.category(cat):
                if not isinstance(entry, dict):
                    continue
                for key in ENTRY_PATH_KEYS:
                    val = entry.get(key)
                    if isinstance(val, str) and val.strip():
                        out.add(norm(val).rstrip("/"))
                for key in ENTRY_PATH_LISTS:
                    for val in entry.get(key) or []:
                        if isinstance(val, str) and val.strip():
                            out.add(norm(val).rstrip("/"))
        return out

    def adr_files(self):
        """[(number, rel_path)] for every numbered ADR on disk."""
        found = []
        base = self.root / ADR_DIR
        if not base.is_dir():
            return found
        for p in sorted(base.glob("*.md")):
            m = re.match(r"^(\d{1,4})[-_]", p.name)
            if m:
                found.append((int(m.group(1)), norm(p.relative_to(self.root))))
        return found

    def project_name(self):
        claude = self.root / CLAUDE_MD
        if claude.is_file():
            for line in read_text(claude).splitlines():
                if line.startswith("# "):
                    return line[2:].split("--")[0].split("—")[0].strip()
        return self.root.name


# --------------------------------------------------------------------------
# CHECK 1 -- registry parses and carries the keys the skills read
# --------------------------------------------------------------------------

def check_registry_parse(pj, res, opts):
    if pj.registry_error:
        res.fail("%s %s" % (REGISTRY_REL, pj.registry_error))
        res.note("Every registry-driven check below is skipped until this parses.")
        return
    if pj.registry is None:
        res.skip("%s is not present yet -- nothing to parse" % REGISTRY_REL)
        return
    res.note("parsed OK")
    for key, want_type in sorted(REGISTRY_KEYS.items()):
        if key not in pj.registry:
            res.warn("registry has no `%s` key -- a skill that reads it finds "
                     "nothing and has to guess" % key)
        elif pj.registry[key] is not None and not isinstance(pj.registry[key], want_type):
            res.fail("registry key `%s` is %s, the skills read it as %s"
                     % (key, type(pj.registry[key]).__name__, want_type.__name__))
    counts = "%d systems, %d tools, %d data, %d specs, %d ADRs" % (
        len(pj.category("systems")), len(pj.category("tools")),
        len(pj.category("data")), len(pj.specs()), len(pj.adrs()))
    res.note(counts)


# --------------------------------------------------------------------------
# CHECK 2 -- registry entry shape
# --------------------------------------------------------------------------

def check_registry_entries(pj, res, opts):
    if not pj.registry:
        res.skip("no readable registry -- nothing to check")
        return
    total = sum(len(pj.category(c)) for c in ("systems", "tools", "data"))
    if total == 0:
        res.skip("registry has no systems, tools or data entries yet -- "
                 "the correct day-one state")
        return

    allowed = pj.statuses()
    seen_ids = {}
    for cat in ("systems", "tools", "data"):
        for i, entry in enumerate(pj.category(cat)):
            if not isinstance(entry, dict):
                res.fail("%s[#%d] is %s, expected an object"
                         % (cat, i, type(entry).__name__))
                continue
            label = entry_label(cat, entry, i)
            singular = cat[:-1] if cat.endswith("s") else cat
            for key in REQUIRED_ENTRY_KEYS[cat]:
                if not str(entry.get(key, "")).strip():
                    res.fail("%s has no `%s` -- required for a %s entry"
                             % (label, key, singular))
            locators = LOCATOR_ENTRY_KEYS[cat]
            if locators and not any(entry.get(k) for k in locators):
                res.fail("%s says nothing about where it lives -- a %s entry needs "
                         "one of %s" % (label, singular,
                                        " / ".join("`%s`" % k for k in locators)))
            for key in RECOMMENDED_ENTRY_KEYS[cat]:
                if not str(entry.get(key, "")).strip():
                    res.warn("%s has no `%s`" % (label, key))
            status = entry.get("status")
            if status is not None and str(status) not in allowed:
                res.fail("%s status=%r is not in the vocabulary (%s)"
                         % (label, status, ", ".join(allowed)))
            ident = entry.get("id")
            if ident:
                here = "%s entry #%d" % (cat, i)
                if ident in seen_ids:
                    res.fail("id %r is used by %s and %s -- ids must be unique "
                             "across systems/tools/data" % (ident, seen_ids[ident], here))
                else:
                    seen_ids[ident] = here
    res.note("%d entries checked against %d allowed status values" % (total, len(allowed)))


# --------------------------------------------------------------------------
# CHECK 3 -- registry references resolve
# --------------------------------------------------------------------------

def check_registry_refs(pj, res, opts):
    if not pj.registry:
        res.skip("no readable registry -- nothing to check")
        return
    ids = pj.registry_ids()
    checked = 0
    entries = [(c, i, e) for c in ("systems", "tools", "data")
               for i, e in enumerate(pj.category(c)) if isinstance(e, dict)]
    if not entries:
        res.skip("registry has no entries yet -- no references to resolve")
        return

    for cat, i, entry in entries:
        label = entry_label(cat, entry, i)
        values = []
        for key in ENTRY_PATH_KEYS:
            val = entry.get(key)
            if isinstance(val, str) and val.strip():
                values.append((key, val))
        for key in ENTRY_PATH_LISTS:
            for val in entry.get(key) or []:
                if isinstance(val, str) and val.strip():
                    values.append((key, val))
        for key, val in values:
            if not looks_like_path(val):
                continue
            checked += 1
            if not pj.exists(val.rstrip("/")):
                res.fail("%s.%s claims %s -- not on disk" % (label, key, norm(val)))
        for key in ENTRY_ID_LISTS:
            for ref in entry.get(key) or []:
                if not isinstance(ref, str) or not ref.strip():
                    continue
                if "/" in ref or "(" in ref or "." in ref:
                    continue        # a descriptive string, not an id
                checked += 1
                if ref not in ids:
                    res.fail("%s.%s references id %r -- no registry entry has that id"
                             % (label, key, ref))
    res.note("%d references resolved" % checked)


# --------------------------------------------------------------------------
# CHECK 4 -- registry coverage (on disk, absent from the registry)
# --------------------------------------------------------------------------

def _covered(paths, target):
    """True when the registry mentions this path, or a parent of it."""
    t = norm(target).rstrip("/")
    for p in paths:
        if p == t or t.startswith(p + "/") or p.startswith(t + "/"):
            return True
    return False


def check_registry_coverage(pj, res, opts):
    if not pj.registry:
        res.skip("no readable registry -- nothing to compare the disk against")
        return
    paths = pj.registry_paths()
    looked_at = 0

    # -- populated data/<category>/ directories ---------------------------
    data_root = pj.root / "data"
    if data_root.is_dir():
        for sub in sorted(p for p in data_root.iterdir() if p.is_dir()):
            if sub.name.startswith("_") or sub.name.startswith("."):
                continue
            looked_at += 1
            files = [f for f in sub.rglob("*") if f.is_file()]
            rel = "data/%s/" % sub.name
            if files and not _covered(paths, rel):
                res.warn("%s holds %d file(s) but no data[] entry covers it -- "
                         "architecture principle 1 is audited from the registry"
                         % (rel, len(files)))

    # -- engine autoloads (Godot-shaped projects only) --------------------
    godot = pj.root / "project.godot"
    if godot.is_file():
        text = read_text(godot)
        section = re.search(r"\[autoload\](.*?)(?=^\[|\Z)", text, re.DOTALL | re.MULTILINE)
        if section:
            for line in section.group(1).splitlines():
                m = re.match(r'\s*(\w+)\s*=\s*"\*?(res://[^"]+)"', line)
                if not m:
                    continue
                name, src = m.group(1), m.group(2)
                rel = src.replace("res://", "")
                if rel.startswith("addons/"):
                    continue            # vendor autoload, not project code
                looked_at += 1
                if not _covered(paths, rel):
                    res.warn("autoload %s -> %s is not in any registry entry" % (name, rel))

    # -- editor/engine addons --------------------------------------------
    addons = pj.root / "addons"
    if addons.is_dir():
        for cfg in sorted(addons.glob("*/plugin.cfg")):
            looked_at += 1
            rel = "addons/%s/" % cfg.parent.name
            if not _covered(paths, rel):
                res.warn("%s is not in the registry -- register it under tools[], "
                         "or ignore this line if it is a vendor addon you did not author"
                         % rel)

    # -- project-owned runners in tools/ ----------------------------------
    tools_dir = pj.root / "tools"
    if tools_dir.is_dir():
        for p in sorted(tools_dir.iterdir()):
            if not p.is_file() or p.name in FRAMEWORK_TOOLS:
                continue
            if p.suffix not in (".py", ".sh", ".ps1", ".js", ".gd"):
                continue
            looked_at += 1
            rel = "tools/%s" % p.name
            if not _covered(paths, rel):
                res.warn("%s has no tools[] entry -- /consistency-check and "
                         "/help cannot tell a session it exists" % rel)

    if looked_at == 0:
        res.skip("no data directories, addons or project tools on disk yet")
    else:
        res.note("%d disk artifact(s) compared against the registry" % looked_at)


# --------------------------------------------------------------------------
# CHECK 5 -- the doc stack CLAUDE.md's reading map promises
# --------------------------------------------------------------------------

def reading_map_paths(text):
    """Paths promised by CLAUDE.md's reading-map table, in order."""
    out = []
    for lineno, line in strip_fences(text):
        if not line.lstrip().startswith("|"):
            continue
        for span in re.findall(r"`([^`\n]{2,160})`", line):
            ref = span.strip()
            if looks_like_path(ref):
                out.append((lineno, ref))
    return out


def check_doc_stack(pj, res, opts):
    claude = pj.root / CLAUDE_MD
    if not claude.is_file():
        res.warn("%s not found -- the reading map is the one thing every fresh "
                 "session reads cold, and there is none here" % CLAUDE_MD)
        return
    promised = reading_map_paths(read_text(claude))
    if not promised:
        res.skip("%s has no reading-map rows with a path in them" % CLAUDE_MD)
        return

    seen = set()
    missing = []
    for lineno, ref in promised:
        if ref in seen:
            continue
        seen.add(ref)
        if pj.exists(ref.rstrip("/")):
            continue
        if opts.fix_safe and ref.endswith("/"):
            target = pj.root / ref
            try:
                target.mkdir(parents=True, exist_ok=True)
                (target / ".gitkeep").touch()
                res.note("--fix-safe: created %s and %s.gitkeep" % (ref, ref))
                continue
            except OSError as exc:
                res.note("--fix-safe: could not create %s (%s)" % (ref, exc))
        missing.append((lineno, ref))

    for lineno, ref in missing:
        res.fail("%s:%d promises `%s` -- it does not exist. A session that "
                 "follows the map opens nothing." % (CLAUDE_MD, lineno, ref))
    res.note("%d promised path(s) checked" % len(seen))


# --------------------------------------------------------------------------
# CHECK 6 -- the registry's own doc ledger resolves
# --------------------------------------------------------------------------

def check_doc_ledger(pj, res, opts):
    if not pj.registry:
        res.skip("no readable registry -- no ledger to resolve")
        return
    claims = 0

    for i, doc in enumerate(pj.active_docs()):
        if not isinstance(doc, dict):
            res.fail("documentation_stack.active_docs[#%d] is %s, expected an object"
                     % (i, type(doc).__name__))
            continue
        path = str(doc.get("path", "")).strip()
        if not path:
            res.warn("active_docs[#%d] has no `path`" % i)
            continue
        claims += 1
        if not pj.exists(path.rstrip("/")):
            res.fail("active_docs claims %s -- not on disk" % norm(path))

    for i, spec in enumerate(pj.specs()):
        if not isinstance(spec, dict):
            res.fail("spec_index.specs[#%d] is %s, expected an object"
                     % (i, type(spec).__name__))
            continue
        state = str(spec.get("state", "")).strip().lower()
        wanted = spec.get("archive_path") if state == "archived" else spec.get("file")
        label = spec.get("title") or spec.get("id") or ("spec #%d" % i)
        if not wanted:
            res.warn("spec_index %r (state=%s) names no file" % (label, state or "?"))
            continue
        claims += 1
        if not pj.exists(str(wanted).rstrip("/")):
            res.fail("spec_index %r (state=%s) claims %s -- not on disk"
                     % (label, state or "?", norm(wanted)))
        plan = spec.get("plan")
        if isinstance(plan, str) and looks_like_path(plan):
            claims += 1
            if not pj.exists(plan):
                res.fail("spec_index %r links plan %s -- not on disk" % (label, norm(plan)))

    for i, adr in enumerate(pj.adrs()):
        if not isinstance(adr, dict):
            res.fail("adr_index.adrs[#%d] is %s, expected an object"
                     % (i, type(adr).__name__))
            continue
        path = str(adr.get("file", "")).strip()
        number = adr.get("number", "?")
        if not path:
            res.warn("adr_index entry %s names no file" % number)
            continue
        claims += 1
        if not pj.exists(path):
            res.fail("adr_index ADR %s claims %s -- not on disk" % (number, norm(path)))

    if claims == 0:
        res.skip("the doc ledger is empty -- nothing claimed yet")
    else:
        res.note("%d ledger claim(s) checked" % claims)


# --------------------------------------------------------------------------
# CHECK 7 -- spec + plan lifecycle
# --------------------------------------------------------------------------

def _status_marker(text):
    """The lifecycle word a spec/plan declares about itself, if any."""
    head = "\n".join(text.splitlines()[:40]).upper()
    for word in ("ARCHIVED", "SUPERSEDED", "SHIPPED", "FINAL", "IN PROGRESS", "ACTIVE", "DRAFT"):
        if word in head:
            return word
    return None


def check_spec_lifecycle(pj, res, opts):
    looked = 0
    indexed = set()
    for spec in pj.specs():
        if not isinstance(spec, dict):
            continue
        for key in ("file", "archive_path"):
            val = spec.get(key)
            if isinstance(val, str) and val.strip():
                indexed.add(unprefix(val))

    for live_dir, archive_dir, kind in ((SPEC_DIR, SPEC_ARCHIVE, "spec"),
                                        (PLAN_DIR, PLAN_ARCHIVE, "plan")):
        base = pj.root / live_dir
        if not base.is_dir():
            continue
        for p in sorted(base.glob("*.md")):
            rel = norm(p.relative_to(pj.root))
            if p.name.upper().startswith("TEMPLATE") or p.name.startswith("_"):
                continue
            looked += 1
            marker = _status_marker(read_text(p))
            if marker in ("ARCHIVED", "SUPERSEDED"):
                res.warn("%s says %s but still lives in %s/ -- the lifecycle moves it "
                         "to %s/" % (rel, marker, live_dir, archive_dir))
            if kind == "spec" and pj.specs() and rel not in indexed:
                res.warn("%s is not in the registry spec_index -- the index is the "
                         "ledger; a spec missing from it is invisible to /help" % rel)

    # An archived doc that never landed in the archive directory.
    for archive_dir in (SPEC_ARCHIVE, PLAN_ARCHIVE):
        base = pj.root / archive_dir
        if base.is_dir():
            looked += len(list(base.glob("*.md")))

    for spec in pj.specs():
        if not isinstance(spec, dict):
            continue
        state = str(spec.get("state", "")).strip().lower()
        label = spec.get("title") or spec.get("id") or "spec"
        if state == "archived":
            archive = str(spec.get("archive_path", ""))
            if archive and SPEC_ARCHIVE not in norm(archive):
                res.warn("spec_index %r is state=archived but archive_path is %s "
                         "-- archives live under %s/" % (label, norm(archive), SPEC_ARCHIVE))
            if not archive:
                res.fail("spec_index %r is state=archived with no archive_path"
                         % label)
        elif state and state not in ("in_progress", "final", "paused", "superseded"):
            res.warn("spec_index %r has state=%r -- the lifecycle words are "
                     "in_progress / final / archived" % (label, state))

    if looked == 0 and not pj.specs():
        res.skip("no specs or plans yet -- nothing to move through a lifecycle")
    else:
        res.note("%d spec/plan document(s) examined" % looked)


# --------------------------------------------------------------------------
# CHECK 8 -- ADR hygiene
# --------------------------------------------------------------------------

ADR_REF_RE = re.compile(r"\bADR[-\s]?(\d{1,4})\b", re.IGNORECASE)


def check_adr_hygiene(pj, res, opts):
    on_disk = pj.adr_files()
    numbers = {}
    for number, rel in on_disk:
        numbers.setdefault(number, []).append(rel)

    # -- duplicate + gap numbering ---------------------------------------
    for number, files in sorted(numbers.items()):
        if len(files) > 1:
            res.fail("ADR number %03d is used by %d files (%s) -- a number "
                     "addresses exactly one decision" % (number, len(files), ", ".join(files)))
    if numbers:
        expected = set(range(1, max(numbers) + 1))
        gaps = sorted(expected - set(numbers))
        if gaps:
            res.warn("ADR numbering has gaps: %s -- fine if a draft was abandoned, "
                     "a defect if a file was lost"
                     % ", ".join("%03d" % g for g in gaps))

    # -- every ADR states a Status ---------------------------------------
    for number, rel in on_disk:
        text = read_text(pj.root / rel)
        if not re.search(r"^\s*(#{1,6}\s*)?\**\s*status\s*\**\s*[:\n]", text,
                         re.IGNORECASE | re.MULTILINE):
            res.fail("%s has no Status line -- a decision with no status cannot "
                     "be trusted as accepted" % rel)

    # -- references that resolve -----------------------------------------
    # Prose only. The registry's own adr_index claims are check 6's business;
    # reporting them here too would name one defect twice.
    referenced = {}
    for rel, path in md_files(pj.root, DOC_ROOTS):
        if Path(rel).name.upper().startswith("TEMPLATE"):
            continue
        for lineno, line in strip_fences(read_text(path)):
            for m in ADR_REF_RE.finditer(line):
                number = int(m.group(1))
                if number == 0:
                    continue        # ADR-000 is the conventional stand-in number
                referenced.setdefault(number, []).append("%s:%d" % (rel, lineno))

    dangling = sorted(n for n in referenced if n not in numbers)
    for number in dangling:
        where = referenced[number]
        res.fail("ADR-%03d is referenced by %s%s -- no file in %s/ carries that number"
                 % (number, ", ".join(where[:3]),
                    " (+%d more)" % (len(where) - 3) if len(where) > 3 else "", ADR_DIR))

    if not on_disk and not referenced:
        res.skip("no ADRs written yet and none referenced -- nothing to check")
    else:
        res.note("%d ADR file(s) on disk, %d number(s) referenced across the docs"
                 % (len(on_disk), len(referenced)))


# --------------------------------------------------------------------------
# CHECK 9 -- cross-doc drift
# --------------------------------------------------------------------------

BUILT_STATUSES = {"wip", "partial", "active", "phasing_out", "for_review"}
SHIPPED_WORDS = ("shipped", "complete", "done", "built", "active", "landed")


def _mentions(text_lower, system):
    """Does the doc mention this system, by id or by name?"""
    for token in filter(None, (system.get("id"), system.get("name"))):
        token = str(token).strip().lower()
        if not token:
            continue
        for variant in {token, token.replace("-", " "), token.replace("_", " "),
                        token.replace(" ", "-"), token.replace(" ", "_")}:
            if variant and variant in text_lower:
                return True
    return False


def check_cross_doc_drift(pj, res, opts):
    systems = [s for s in pj.category("systems") if isinstance(s, dict)]
    impl_path = pj.root / IMPL_STATUS
    checked = 0

    if not impl_path.is_file():
        res.warn("%s is missing -- the reading map sends 'data / pipeline "
                 "reference' there" % IMPL_STATUS)
    elif not systems:
        res.note("registry has no systems yet -- nothing to cross-check against %s"
                 % IMPL_STATUS)
    else:
        impl_text = read_text(impl_path)
        impl_lower = impl_text.lower()
        for system in systems:
            status = str(system.get("status", "")).strip().lower()
            label = system.get("id") or system.get("name") or "?"
            checked += 1
            mentioned = _mentions(impl_lower, system)
            if status in BUILT_STATUSES and not mentioned:
                res.warn("registry says %s is `%s` but %s never mentions it -- "
                         "the built-state doc is behind" % (label, status, IMPL_STATUS))
            if status in ("planned", "stub") and mentioned:
                for line in impl_text.splitlines():
                    low = line.lower()
                    if not _mentions(low, system):
                        continue
                    if any(w in low for w in SHIPPED_WORDS) and status in low.split():
                        continue
                    if any(w in low for w in SHIPPED_WORDS):
                        res.warn("registry says %s is `%s` but %s calls it built: %s"
                                 % (label, status, IMPL_STATUS, line.strip()[:90]))
                        break

        # The reverse direction: a row in the doc that no registry entry backs.
        known = set()
        for system in systems:
            for token in filter(None, (system.get("id"), system.get("name"))):
                known.add(str(token).strip().lower())
        for line in impl_text.splitlines():
            if not line.lstrip().startswith("|"):
                continue
            cells = [c.strip() for c in line.strip().strip("|").split("|")]
            if len(cells) < 2:
                continue
            m = re.match(r"^`([^`]+)`$", cells[0])
            if not m:
                continue
            name = m.group(1).strip()
            if is_placeholder_name(name):
                continue
            if cells[1].strip().lower() not in pj.statuses():
                continue
            if name.lower() not in known:
                res.warn("%s lists `%s` but no registry system carries that id -- "
                         "the registry is authoritative" % (IMPL_STATUS, name))

    # stage.txt is authoritative for the phase; the registry mirrors it.
    stage_path = pj.root / STAGE_TXT
    if stage_path.is_file() and pj.registry:
        stage = read_text(stage_path).strip().splitlines()
        stage_value = stage[0].strip().lower() if stage else ""
        phase = str(pj.registry.get("phase", "")).strip().lower()
        if stage_value and phase and stage_value != phase:
            res.warn("%s says phase=%r, the registry mirrors phase=%r -- stage.txt "
                     "is authoritative" % (STAGE_TXT, stage_value, phase))
        elif stage_value:
            checked += 1

    if checked == 0 and not res.findings:
        res.skip("no systems registered and no phase recorded -- nothing to compare")
    elif checked:
        res.note("%d claim(s) cross-checked" % checked)


# --------------------------------------------------------------------------
# CHECK 10 -- broken relative links in the doc stack
# --------------------------------------------------------------------------

LINK_RE = re.compile(r"\[[^\]\n]{0,160}\]\(([^)\s]{1,200})\)")

# A link may cite a place IN a file: `src/thing.gd:604` or `:604:12`. The line
# number is not part of the path.
LINE_CITE_RE = re.compile(r":\d+(?::\d+)?$")


def check_doc_links(pj, res, opts):
    files = md_files(pj.root, DOC_ROOTS)
    if not files:
        res.skip("no project markdown to scan yet")
        return
    checked = 0
    for rel, path in files:
        for lineno, line in strip_fences(read_text(path)):
            for target in LINK_RE.findall(line):
                target = target.split("#", 1)[0].split("?", 1)[0].strip()
                target = LINE_CITE_RE.sub("", target)
                if not target or not looks_like_path(target):
                    continue
                if "%" in target:
                    continue                # url-encoded; not worth guessing
                checked += 1
                near = (path.parent / target).resolve()
                far = (pj.root / unprefix(target)).resolve()
                if near.exists() or far.exists():
                    continue
                res.fail("%s:%d links to `%s` -- no such file" % (rel, lineno, target))
    if checked == 0:
        res.skip("the docs carry no relative links yet")
    else:
        res.note("%d relative link(s) in %d file(s) resolved" % (checked, len(files)))


# --------------------------------------------------------------------------
# CHECK 11 -- session-state freshness
# --------------------------------------------------------------------------

def _git_iso(root, args):
    proc = run_git(args, root)
    if proc is None or proc.returncode != 0:
        return None
    out = (proc.stdout or "").strip().splitlines()
    if not out or not out[0].strip():
        return None
    try:
        return datetime.fromisoformat(out[0].strip())
    except ValueError:
        return None


def check_session_freshness(pj, res, opts):
    if not (pj.root / ACTIVE_MD).is_file():
        res.warn("%s is missing -- the session-open ritual reads it first" % ACTIVE_MD)
        return
    if not (pj.root / ".git").exists():
        res.skip("not a git repository -- no commit dates to compare against")
        return
    if run_git(["--version"], pj.root) is None:
        res.skip("git is not on PATH -- freshness cannot be measured")
        return

    dirty = run_git(["status", "--porcelain", "--", ACTIVE_MD], pj.root)
    if dirty is not None and dirty.returncode == 0 and (dirty.stdout or "").strip():
        res.note("%s has uncommitted edits -- fresh by definition" % ACTIVE_MD)
        return

    newest = _git_iso(pj.root, ["log", "-1", "--format=%cI"])
    touched = _git_iso(pj.root, ["log", "-1", "--format=%cI", "--", ACTIVE_MD])
    if newest is None:
        res.skip("no commits yet -- nothing to be stale against")
        return
    if touched is None:
        res.note("%s has never been committed -- treated as new" % ACTIVE_MD)
        return
    days = (newest - touched).days
    if days > opts.stale_days:
        res.warn("%s was last updated %d day(s) of commits ago (threshold %d) -- "
                 "the next session opens on stale state"
                 % (ACTIVE_MD, days, opts.stale_days))
    else:
        res.note("%s is %d day(s) behind the newest commit" % (ACTIVE_MD, days))


# --------------------------------------------------------------------------
# CHECK 12 -- hook + skill integrity
# --------------------------------------------------------------------------

HOOK_PATH_RE = re.compile(r"[A-Za-z0-9_./${}\\-]*\.claude/[A-Za-z0-9_./-]+\.(?:sh|py|ps1|cmd|bat|js)")


def _hook_commands(node, out):
    if isinstance(node, dict):
        for key, value in node.items():
            if key == "command" and isinstance(value, str):
                out.append(value)
            else:
                _hook_commands(value, out)
    elif isinstance(node, list):
        for item in node:
            _hook_commands(item, out)


def check_hooks_and_skills(pj, res, opts):
    looked = 0
    settings = pj.root / ".claude" / "settings.json"
    if not settings.is_file():
        res.warn(".claude/settings.json is missing -- no hook is wired, so the "
                 "session-start and skill-gate rituals never fire")
    else:
        try:
            data = json.loads(read_text(settings))
        except json.JSONDecodeError as exc:
            res.fail(".claude/settings.json is not valid JSON -- %s (line %d) -- "
                     "Claude Code silently ignores a settings file it cannot parse"
                     % (exc.msg, exc.lineno))
            data = None
        if isinstance(data, dict):
            commands = []
            _hook_commands(data.get("hooks", {}), commands)
            seen_hooks = set()
            for command in commands:
                for match in HOOK_PATH_RE.findall(command):
                    rel = unprefix(match.replace("${CLAUDE_PROJECT_DIR}/", "")
                                   .replace("$CLAUDE_PROJECT_DIR/", ""))
                    if rel in seen_hooks:
                        continue        # the same hook wired to two events
                    seen_hooks.add(rel)
                    looked += 1
                    if not pj.exists(rel):
                        res.fail(".claude/settings.json wires `%s` but %s is not on disk"
                                 % (command.strip(), rel))

    skills_dir = pj.root / ".claude" / "skills"
    if not skills_dir.is_dir():
        res.warn(".claude/skills/ is missing -- no studio skill is installed")
    else:
        skills = sorted(p for p in skills_dir.iterdir() if p.is_dir())
        for skill in skills:
            rel = ".claude/skills/%s/SKILL.md" % skill.name
            md = skill / "SKILL.md"
            looked += 1
            if not md.is_file():
                res.fail("%s/ has no SKILL.md -- the skill cannot load" % skill.name)
                continue
            text = read_text(md)
            if not text.lstrip().startswith("---"):
                res.fail("%s has no YAML frontmatter -- the router cannot read it" % rel)
                continue
            body = text.lstrip()
            end = body.find("\n---", 3)
            front = body[3:end] if end != -1 else ""
            if not front.strip():
                res.fail("%s has an unterminated frontmatter block" % rel)
                continue
            name = re.search(r"^name:\s*(\S.*)$", front, re.MULTILINE)
            desc = re.search(r"^description:\s*(\S.*)$", front, re.MULTILINE)
            if not name:
                res.fail("%s frontmatter has no `name:`" % rel)
            elif name.group(1).strip().strip("\"'") != skill.name:
                res.warn("%s declares name: %s but lives in %s/ -- invocation uses "
                         "the directory name"
                         % (rel, name.group(1).strip(), skill.name))
            if not desc:
                res.fail("%s frontmatter has no `description:` -- the router picks "
                         "skills by description" % rel)
        if skills:
            res.note("%d skill(s) checked" % len(skills))

    if looked == 0 and not res.findings:
        res.skip("no .claude/ install to verify")


# --------------------------------------------------------------------------
# the live check list
# --------------------------------------------------------------------------

CHECKS = [
    ("registry parses and carries the keys the skills read", check_registry_parse),
    ("registry entry shape: required keys, status vocabulary, unique ids", check_registry_entries),
    ("registry references resolve: files on disk, id cross-links", check_registry_refs),
    ("registry coverage: what is on disk but not in the registry", check_registry_coverage),
    ("doc stack: every path CLAUDE.md's reading map promises exists", check_doc_stack),
    ("doc ledger: active_docs / spec_index / adr_index paths resolve", check_doc_ledger),
    ("spec + plan lifecycle: status agrees with location", check_spec_lifecycle),
    ("ADR hygiene: numbering, Status line, references that resolve", check_adr_hygiene),
    ("cross-doc drift: registry vs implementation-status vs stage.txt", check_cross_doc_drift),
    ("doc links: relative markdown links that point at a missing file", check_doc_links),
    ("session-state freshness: active.md vs the newest commit", check_session_freshness),
    ("hook + skill integrity: wired hooks exist, SKILL.md frontmatter parses", check_hooks_and_skills),
]


# --------------------------------------------------------------------------
# report
# --------------------------------------------------------------------------

def print_header(pj, quiet):
    if quiet:
        return
    print(RULE)
    print(" CONSISTENCY CHECK   %s" % pj.project_name())
    print(" %s" % norm(pj.root))
    print(RULE)
    print()
    if pj.registry_error:
        print("  registry : %s -- UNREADABLE" % REGISTRY_REL)
    elif pj.registry is None:
        print("  registry : %s -- absent (a project that has not scaffolded yet)"
              % REGISTRY_REL)
    else:
        print("  registry : %s  (%d systems, %d tools, %d data, %d specs, %d ADRs)"
              % (REGISTRY_REL, len(pj.category("systems")), len(pj.category("tools")),
                 len(pj.category("data")), len(pj.specs()), len(pj.adrs())))
    print("  checks   : %d" % len(CHECKS))
    print()
    print(THIN)


def print_result(res, quiet):
    line = "[%2d/%d] %s  %s" % (res.number, len(CHECKS), res.status, res.title)
    if res.status in (FAIL, WARN):
        print(line)
        for sev, text in res.findings:
            print("         %s  %s" % (sev, text))
        for note in res.notes:
            print("         ..    %s" % note)
        return
    if quiet:
        return
    print(line)
    if res.status == SKIP:
        print("         ..    %s" % res.skipped)
    for note in res.notes:
        print("         ..    %s" % note)


def bump_audit(pj, quiet):
    """Record that a full audit ran clean today. Idempotent within the day."""
    if not pj.registry or pj.registry_error:
        return
    today = date.today().isoformat()
    if pj.registry.get("last_full_audit") == today:
        return
    pj.registry["last_full_audit"] = today
    try:
        (pj.root / REGISTRY_REL).write_text(
            json.dumps(pj.registry, indent=2, ensure_ascii=False) + "\n",
            encoding="utf-8")
    except OSError as exc:
        print("  (could not bump last_full_audit: %s)" % exc)
        return
    if not quiet:
        print("  last_full_audit -> %s" % today)


# --------------------------------------------------------------------------
# entry point
# --------------------------------------------------------------------------

def parse_args(argv):
    ap = argparse.ArgumentParser(
        prog="consistency_check.py",
        description="Check a studio project's doc stack against itself and the disk.",
    )
    ap.add_argument("--root", default=None,
                    help="project root to check (default: the current directory)")
    ap.add_argument("--quiet", action="store_true",
                    help="print only findings and the verdict")
    ap.add_argument("--no-bump", dest="bump", action="store_false", default=True,
                    help="do not write last_full_audit into the registry on a clean run")
    ap.add_argument("--fix-safe", action="store_true",
                    help="create absent empty directories the doc stack promises "
                         "(with a .gitkeep). Never edits prose or data.")
    ap.add_argument("--stale-days", type=int, default=7,
                    help="how many days of commits active.md may lag before it "
                         "warns (default: 7)")
    return ap.parse_args(argv)


def main(argv=None):
    if hasattr(sys.stdout, "reconfigure"):
        try:
            sys.stdout.reconfigure(encoding="utf-8", errors="replace")
        except (ValueError, OSError):
            pass

    opts = parse_args(argv)
    root = Path(opts.root).resolve() if opts.root else Path.cwd().resolve()
    if not root.is_dir():
        print("ERROR: %s is not a directory." % norm(root))
        return 2
    markers = [root / CLAUDE_MD, root / ".claude", root / REGISTRY_REL]
    if not any(m.exists() for m in markers):
        print("ERROR: %s does not look like a studio project root." % norm(root))
        print("       Expected one of: %s, .claude/, %s" % (CLAUDE_MD, REGISTRY_REL))
        print("       cd to your project root (or pass --root DIR) and re-run.")
        return 2

    os.chdir(str(root))
    pj = Project(root)
    print_header(pj, opts.quiet)

    results = []
    for i, (title, func) in enumerate(CHECKS, start=1):
        res = Result(i, title)
        try:
            func(pj, res, opts)
        except Exception as exc:                      # a check must never crash the run
            res.fail("check errored: %s: %s -- this is a bug in "
                     "tools/consistency_check.py, not in your project"
                     % (type(exc).__name__, exc))
        results.append(res)
        print_result(res, opts.quiet)

    fails = sum(res.counts()[0] for res in results)
    warns = sum(res.counts()[1] for res in results)
    by_status = {PASS: 0, WARN: 0, FAIL: 0, SKIP: 0}
    for res in results:
        by_status[res.status] += 1

    print()
    print(RULE)
    print(" SUMMARY  %d checks: %d PASS, %d WARN, %d FAIL, %d not applicable yet"
          % (len(results), by_status[PASS], by_status[WARN], by_status[FAIL], by_status[SKIP]))
    if fails:
        print(" VERDICT: FAIL -- %d problem(s) across %d check(s):"
              % (fails, by_status[FAIL]))
        for res in results:
            for sev, text in res.findings:
                if sev == FAIL:
                    print("   - [%d] %s" % (res.number, text))
        print(RULE)
        return 1

    if warns:
        print(" VERDICT: PASS with %d warning(s) -- drift worth knowing about, "
              "nothing broken." % warns)
    else:
        print(" VERDICT: PASS -- the doc stack agrees with itself.")
    print(RULE)
    if opts.bump:
        bump_audit(pj, opts.quiet)
    return 0


if __name__ == "__main__":
    sys.exit(main())
