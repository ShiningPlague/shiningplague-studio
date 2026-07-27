#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
doc_stack_check.py — the ShiningPlague Studio doc-stack regression guard.

WHAT IT GUARDS
    Every project path this bundle COMMANDS at a reader must be a path something
    CREATES. A skill that says "run tools/consistency_check.py" or "read
    design/gdd/systems-index.md" is making a promise; this script checks the
    promise is kept, and that all the docs promise the SAME layout.

WHY IT EXISTS
    A real project drifted for weeks because its close ritual commanded files
    that were never scaffolded: /session-close crashed on a runner
    (tools/consistency_check.py) that the consistency-check skill advertises in
    its own description but that has never shipped, and three further steps
    named documents nothing had created -- while 44 files said design/gdd, 11
    said docs/gdd and 6 said docs/GDD.md, so no session could tell which was
    real. Absence and self-contradiction both look like "the doc is wrong" to a
    fresh session, and both are invisible until someone actually runs the path.
    This script runs them.

TWO MODES
    (default)            Bundle mode. Run from the template repo root. Classifies
                         every path reference in skills/ agents/ docs/ templates/
                         rules/ + CLAUDE.md.template. Fails on PHANTOM (nothing
                         creates it), KILLED (a retired convention) and
                         UNSCAFFOLDED (the manifest promises it, the installer
                         does not create it).
    --project <dir>      Install mode. Run against an INSTALLED game project.
                         Asserts the installer actually landed, and that every
                         path the skills read-as-gate or execute exists there.
                         This is the check a user runs to prove their install is
                         coherent.

HOW TO ADD A LEGITIMATE NEW PATH
    Never edit this file. Edit tools/doc_stack.manifest.json, which is the single
    machine-readable source of truth, and add ONE entry to the block that says
    how the path comes into existence:
        install_map    - the installer copies it out of this bundle
        scaffold       - the installer's scaffold step must create it in a project
        created_on_use - a skill writes it while it runs (absent until then)
        ignore         - the user's own game code/assets; not ours to create
    Every entry carries a one-line "why". An entry without a "why" is a smell:
    if you cannot say what creates the path, it is a phantom.

EXIT CODES
    0  PASS   no phantom, no killed convention, no unscaffolded promise
    1  FAIL   at least one of the above (details printed)
    2  ERROR  bad usage / manifest could not be loaded

Pure Python 3 standard library. No dependencies. Windows and POSIX.
"""

from __future__ import annotations

import argparse
import glob as globlib
import json
import os
import posixpath
import re
import sys
from collections import defaultdict

# --------------------------------------------------------------------------
# constants
# --------------------------------------------------------------------------

MANIFEST_NAME = "doc_stack.manifest.json"

# Reference classes, in resolution order. The first one that matches wins.
IGNORED = "IGNORED"
KILLED = "KILLED"
SHIPPED = "SHIPPED"
SCAFFOLDED = "SCAFFOLDED"
CREATED_ON_USE = "CREATED-ON-USE"
TEMPLATED = "TEMPLATED"
PHANTOM = "PHANTOM"

CLASS_ORDER = [SHIPPED, SCAFFOLDED, CREATED_ON_USE, TEMPLATED, IGNORED, KILLED, PHANTOM]

CLASS_BLURB = {
    SHIPPED: "installed by scripts/install.sh out of this bundle",
    SCAFFOLDED: "created in a fresh project by the installer's scaffold step",
    CREATED_ON_USE: "written by a skill while it runs; absent until then",
    TEMPLATED: "carries a placeholder; not a literal path",
    IGNORED: "the user's own game code/assets; not ours to create",
    KILLED: "a retired convention this repair removes",
    PHANTOM: "nothing in this bundle creates it",
}

FAILING_CLASSES = (PHANTOM, KILLED)

RULE = "=" * 78
THIN = "-" * 78

# A placeholder segment: {{TOKEN}}, <token> or [token].
PLACEHOLDER_RE = re.compile(r"\{\{[^}\n]{1,60}\}\}|<[^<>\s/]{1,60}>|\[[^\[\]\s/]{1,60}\]")

# Reference-bearing spans we harvest from a line of prose or YAML.
SPAN_PATTERNS = [
    re.compile(r"`([^`\n]{2,160})`"),          # `docs/GDD.md`      markdown code span
    re.compile(r"\]\(([^)\n]{2,160})\)"),      # [text](docs/x.md)  markdown link
    re.compile(r'"([^"\n]{2,160})"'),          # glob: "docs/x.md"  YAML / JSON string
    re.compile(r"'([^'\n]{2,160})'"),          # glob: 'docs/x.md'  YAML string
]

# Prose punctuation that clings to a reference. Bracket stripping is balance
# aware: '[path/to/x.md' loses its bracket, '[epic-slug]/story.md' keeps both --
# there the brackets are a placeholder segment, not a bracketed aside. '<' is
# never stripped from the front for the same reason ('<name>/foo.md').
BRACKET_PAIRS = {"(": ")", "[": "]", "{": "}"}
TRAILING_JUNK = ",.;:!?"


# --------------------------------------------------------------------------
# manifest
# --------------------------------------------------------------------------

def load_manifest(repo_root):
    path = os.path.join(repo_root, "tools", MANIFEST_NAME)
    if not os.path.isfile(path):
        # also allow running with the script's own directory as the anchor
        path = os.path.join(os.path.dirname(os.path.abspath(__file__)), MANIFEST_NAME)
    if not os.path.isfile(path):
        raise SystemExit("ERROR: cannot find tools/%s (looked from %s)" % (MANIFEST_NAME, repo_root))
    with open(path, "r", encoding="utf-8") as fh:
        return json.load(fh), path


# --------------------------------------------------------------------------
# glob / path matching
# --------------------------------------------------------------------------

def glob_to_regex(pattern):
    """Shell-style glob -> regex. '*' stays inside one segment, '**' crosses."""
    out = []
    i = 0
    n = len(pattern)
    while i < n:
        ch = pattern[i]
        if ch == "*":
            if pattern[i:i + 2] == "**":
                out.append(".*")
                i += 2
                continue
            out.append("[^/]*")
            i += 1
            continue
        if ch == "?":
            out.append("[^/]")
            i += 1
            continue
        out.append(re.escape(ch))
        i += 1
    return re.compile("^" + "".join(out) + "$")


def pattern_matches(pattern, ref):
    """True if `ref` (a normalised project path) is covered by `pattern`.

    A pattern ending in '/' means "this directory and everything under it".
    """
    ref = ref.rstrip("/")
    if pattern.endswith("/"):
        # Build the directory body through glob_to_regex, not re.escape, so a
        # pattern like 'agents/engine-packs/*/' keeps its wildcard.
        body = glob_to_regex(pattern.rstrip("/")).pattern
        return re.match(body[:-1] + "(/.*)?$", ref) is not None
    return glob_to_regex(pattern).match(ref) is not None


def prefix_matches(prefix, ref):
    """Substring-prefix test used for killed conventions ('docs/architecture/adr-')."""
    return (ref.rstrip("/") + "/").startswith(prefix)


def bundle_has(repo_root, rel_pattern):
    """Does the bundle physically contain a file/dir matching this pattern?

    THIS is the evidence step. A path is only SHIPPED when the thing the
    installer would copy actually exists here -- which is exactly the check
    tools/consistency_check.py fails.
    """
    rel_pattern = rel_pattern.rstrip("/")
    if not rel_pattern:
        return True
    # glob's '**' is only meaningful as a whole segment; degrade the rest to '*'
    safe = re.sub(r"(?<!/)\*\*|\*\*(?!/)", "*", rel_pattern)
    full = os.path.join(repo_root, safe.replace("/", os.sep))
    if os.path.exists(full):
        return True
    return bool(globlib.glob(full, recursive=True))


# --------------------------------------------------------------------------
# reference extraction
# --------------------------------------------------------------------------

def normalise(raw):
    """Placeholders -> '*' so a templated ref can still match a real pattern."""
    return PLACEHOLDER_RE.sub("*", raw)


class Extractor(object):
    def __init__(self, manifest):
        ex = manifest["extraction"]
        self.exts = set(ex["path_extensions"])
        self.asset_exts = set(ex["engine_asset_suffixes"]["list"])
        self.root_files = set(ex["root_files"].keys())
        self.reject_prefixes = tuple(ex["reject_prefixes"].keys())
        self.skipped_bare = set()
        self.skipped_asset = set()

    def candidate(self, raw):
        """Return a cleaned project-relative path, or None if not path-like."""
        cand = raw.strip().strip("*_").strip()
        changed = True
        while cand and changed:
            changed = False
            while cand and cand[-1] in TRAILING_JUNK:
                cand, changed = cand[:-1], True
            if cand and cand[0] in BRACKET_PAIRS:
                opener, closer = cand[0], BRACKET_PAIRS[cand[0]]
                if cand.count(opener) > cand.count(closer):
                    cand, changed = cand[1:], True
            if cand and cand[-1] in BRACKET_PAIRS.values():
                closer = cand[-1]
                opener = [o for o, c in BRACKET_PAIRS.items() if c == closer][0]
                if cand.count(closer) > cand.count(opener):
                    cand, changed = cand[:-1], True
        if not cand or len(cand) > 160:
            return None
        if any(c in cand for c in " \t|`$(),;"):
            return None
        if "://" in cand:
            return None
        if cand.startswith(self.reject_prefixes):
            return None
        cand = cand.replace("\\", "/")
        while cand.startswith("./"):
            cand = cand[2:]
        if not cand or cand.startswith("/"):
            return None

        base = cand.rstrip("/").rsplit("/", 1)[-1]
        ext = base.rsplit(".", 1)[-1].lower() if "." in base else ""
        is_dir_ref = cand.endswith("/")
        has_slash = "/" in cand.rstrip("/")

        if cand in self.root_files:
            return cand
        if not has_slash:
            # A bare filename ("active.md") is a shorthand, not an addressable
            # path -- recorded so the report can say what it declined to judge.
            if ext in self.exts:
                self.skipped_bare.add(cand)
            return None
        if is_dir_ref:
            return cand
        if ext in self.asset_exts:
            self.skipped_asset.add(cand)
            return None
        if ext in self.exts:
            return cand
        return None

    def from_line(self, line):
        seen = []
        for pat in SPAN_PATTERNS:
            for m in pat.finditer(line):
                got = self.candidate(m.group(1))
                if got:
                    seen.append(got)
        return seen


def scan_files(root, manifest):
    """Yield every file whose contents COMMAND paths at a reader."""
    scan = manifest["scan"]
    suffixes = tuple(scan["file_suffixes"])
    found = []
    for sub in scan["roots"]:
        base = os.path.join(root, sub)
        if not os.path.isdir(base):
            continue
        for dirpath, dirnames, filenames in os.walk(base):
            dirnames[:] = [d for d in dirnames if d != ".git"]
            for name in sorted(filenames):
                if name.endswith(suffixes):
                    found.append(os.path.join(dirpath, name))
    for extra in scan["extra_files"]:
        p = os.path.join(root, extra)
        if os.path.isfile(p):
            found.append(p)
    return sorted(found)


def installed_location(rel_source, install_map):
    """Where a bundle file ENDS UP in an installed project.

    skills/foo/SKILL.md -> .claude/skills/foo/SKILL.md. Needed because skills
    address the project with relative paths ('../../../CLAUDE.md'), which only
    resolve from the installed location, never from the bundle layout.
    """
    best = None
    for entry in install_map:
        for bundle in entry["bundle"]:
            if not bundle.endswith("/"):          # exact file map, e.g. CLAUDE.md.template
                if rel_source == bundle:
                    return entry["project"]
                continue
            if "*" in bundle:                     # flattening map, e.g. agents/engine-packs/*/
                if glob_to_regex(bundle.rstrip("/")).match(posixpath.dirname(rel_source)):
                    cand = entry["project"] + posixpath.basename(rel_source)
                    if best is None or len(bundle) > best[0]:
                        best = (len(bundle), cand)
                continue
            if rel_source.startswith(bundle):     # tree map, e.g. skills/ -> .claude/skills/
                cand = entry["project"] + rel_source[len(bundle):]
                if best is None or len(bundle) > best[0]:
                    best = (len(bundle), cand)
    return best[1] if best else rel_source


def resolve_ref(cand, installed_src):
    """Resolve a relative reference against the citing file's installed home."""
    if not (cand.startswith("../") or cand.startswith("..\\")):
        return cand
    trailing = "/" if cand.endswith("/") else ""
    joined = posixpath.normpath(posixpath.join(posixpath.dirname(installed_src), cand))
    joined = joined.lstrip("/")
    return (joined + trailing) if joined else cand


def collect_references(root, manifest, extractor):
    """path -> set of (file, line) citations, keyed by project-relative path."""
    refs = defaultdict(set)
    files = scan_files(root, manifest)
    imap = sorted(manifest["install_map"], key=lambda e: len(e["project"]), reverse=True)
    for path in files:
        rel = os.path.relpath(path, root).replace(os.sep, "/")
        installed_src = installed_location(rel, imap)
        try:
            with open(path, "r", encoding="utf-8", errors="replace") as fh:
                for lineno, line in enumerate(fh, 1):
                    for cand in extractor.from_line(line):
                        refs[resolve_ref(cand, installed_src)].add((rel, lineno))
        except OSError as exc:
            print("WARN: could not read %s (%s)" % (rel, exc), file=sys.stderr)
    return refs, files


# --------------------------------------------------------------------------
# classification
# --------------------------------------------------------------------------

class Classifier(object):
    def __init__(self, repo_root, manifest):
        self.root = repo_root
        self.m = manifest
        # longest project prefix first, so .claude/docs/templates/ beats .claude/docs/
        self.install_map = sorted(
            manifest["install_map"], key=lambda e: len(e["project"]), reverse=True
        )

    def shipped(self, ref):
        for entry in self.install_map:
            proj = entry["project"]
            bundles = entry["bundle"]
            if not proj.endswith("/"):
                if ref.rstrip("/") == proj:
                    for b in bundles:
                        if bundle_has(self.root, b):
                            return entry
                continue
            if ref == proj.rstrip("/") or ref.startswith(proj):
                rel = ref[len(proj):] if ref.startswith(proj) else ""
                for b in bundles:
                    if bundle_has(self.root, b.rstrip("/") + ("/" + rel if rel else "")):
                        return entry
        return None

    def rooted(self, literal_dir):
        """Is this literal directory prefix anchored in a real convention?

        Guards against a placeholder laundering a dead path: without this,
        'docs/engine-reference/[engine]/VERSION.md' would pass as TEMPLATED
        while the identical 'docs/engine-reference/godot/VERSION.md' fails as a
        phantom. The bracket is not what makes a path real -- its root is.
        """
        d = literal_dir.rstrip("/")
        if not d:
            return True
        if self.shipped(d + "/"):
            return True
        for entry in self.m["scaffold"]:
            p = entry["path"].rstrip("/")
            if p == d or p.startswith(d + "/"):
                return True
        for entry in self.m["created_on_use"]:
            if pattern_matches(entry["pattern"], d) or entry["pattern"].startswith(d + "/"):
                return True
        for entry in self.m["ignore"]:
            if pattern_matches(entry["pattern"], d):
                return True
        return False

    def classify(self, ref):
        """-> (class, reason). Order matches the contract: killed defects are
        reported as their own defect, never double-counted as phantoms."""
        norm = normalise(ref)

        for entry in self.m["killed_conventions"]:
            if prefix_matches(entry["pattern"], norm):
                return KILLED, "retired '%s' -> use '%s'" % (entry["pattern"], entry["replacement"])

        for entry in self.m["ignore"]:
            if pattern_matches(entry["pattern"], norm):
                return IGNORED, entry["why"]

        hit = self.shipped(norm)
        if hit:
            return SHIPPED, hit["why"]

        for entry in self.m["scaffold"]:
            if norm.rstrip("/") == entry["path"].rstrip("/"):
                return SCAFFOLDED, entry["why"]

        for entry in self.m["created_on_use"]:
            if pattern_matches(entry["pattern"], norm):
                return CREATED_ON_USE, entry["why"]

        hole = PLACEHOLDER_RE.search(ref)
        if hole:
            literal = ref[:hole.start()]
            if "/" not in literal.rstrip("/"):
                # The whole root is the variable ('{{DATA_DIR}}/enemies/') --
                # the project supplies it, so there is nothing to verify here.
                return TEMPLATED, "placeholder root; the project resolves it"
            stem = literal.rsplit("/", 1)[0]
            if self.rooted(stem):
                return TEMPLATED, "placeholder under the known root '%s/'" % stem
            return PHANTOM, "placeholder path rooted at '%s/', which nothing creates" % stem

        return PHANTOM, "no install_map / scaffold / created_on_use entry covers it"


# --------------------------------------------------------------------------
# installer coverage (does the scaffold step actually exist?)
# --------------------------------------------------------------------------

def installer_coverage(repo_root, manifest):
    """A manifest promise the installer does not keep is still a broken path.

    Extension of the contract, for the same reason the contract exists: an
    allow-list nothing enforces is just a comment. Only text INSIDE the declared
    scaffold region counts -- otherwise 'docs/' in a copy comment would read as
    proof that docs/ gets scaffolded.
    """
    inst = manifest["installer"]
    begin = inst["scaffold_region"]["begin"]
    end = inst["scaffold_region"]["end"]
    regions, present, no_region = [], [], []
    for name in inst["scripts"]:
        p = os.path.join(repo_root, name.replace("/", os.sep))
        if not os.path.isfile(p):
            continue
        present.append(name)
        with open(p, "r", encoding="utf-8", errors="replace") as fh:
            text = fh.read()
        i, j = text.find(begin), text.rfind(end)
        if i == -1 or j == -1 or j <= i:
            no_region.append(name)
            continue
        regions.append((name, text[i:j]))

    covered, missing = [], []
    for entry in manifest["scaffold"]:
        needle = entry["path"]
        where = [name for name, region in regions if needle in region]
        (covered if where else missing).append((entry, where))
    return covered, missing, present, no_region


# --------------------------------------------------------------------------
# reporting
# --------------------------------------------------------------------------

def banner(title, subtitle):
    print(RULE)
    print(" " + title)
    print(" " + subtitle)
    print(RULE)


def cite(citations, limit):
    """Render 'file:line' citations, collapsed per file."""
    per_file = defaultdict(list)
    for f, ln in sorted(citations):
        per_file[f].append(ln)
    rows = []
    for f in sorted(per_file):
        lns = per_file[f]
        rows.append("%s:%s" % (f, ",".join(str(x) for x in lns[:4]) + ("+" if len(lns) > 4 else "")))
    extra = ""
    if limit and len(rows) > limit:
        extra = "  ... and %d more file(s)" % (len(rows) - limit)
        rows = rows[:limit]
    return rows, extra


def report_failures(title, note, items, cite_limit):
    print("")
    print(THIN)
    print(" %s  (%d)" % (title, len(items)))
    print(" %s" % note)
    print(THIN)
    for ref, reason, citations in items:
        print("")
        print("  %s" % ref)
        print("      why it fails : %s" % reason)
        rows, extra = cite(citations, cite_limit)
        print("      commanded by : %s" % rows[0])
        for r in rows[1:]:
            print("                     %s" % r)
        if extra:
            print("                    %s" % extra)


# --------------------------------------------------------------------------
# MODE 1 -- bundle
# --------------------------------------------------------------------------

def run_bundle_mode(repo_root, manifest, manifest_path, args):
    extractor = Extractor(manifest)
    refs, files = collect_references(repo_root, manifest, extractor)
    clf = Classifier(repo_root, manifest)

    buckets = defaultdict(list)
    for ref in sorted(refs):
        cls, reason = clf.classify(ref)
        buckets[cls].append((ref, reason, refs[ref]))

    citations = sum(len(v) for v in refs.values())

    banner("doc-stack check   MODE 1 (bundle)",
           "%s" % repo_root.replace(os.sep, "/"))
    print("")
    print("  manifest : %s" % os.path.relpath(manifest_path, repo_root).replace(os.sep, "/"))
    print("  scanned  : %d files under %s + %s"
          % (len(files),
             ", ".join(s + "/" for s in manifest["scan"]["roots"]),
             ", ".join(manifest["scan"]["extra_files"])))
    print("  found    : %d distinct path references (%d citations)" % (len(refs), citations))
    print("")
    print("  REFERENCE CLASSES")
    for cls in CLASS_ORDER:
        n = len(buckets.get(cls, []))
        flag = "  <-- FAIL" if (cls in FAILING_CLASSES and n) else ""
        print("    %-16s %5d   %s%s" % (cls, n, CLASS_BLURB[cls], flag))

    if extractor.skipped_bare or extractor.skipped_asset:
        print("")
        print("  NOT JUDGED (declared out of scope, for transparency)")
        print("    %-16s %5d   bare filenames with no directory component"
              % ("bare-name", len(extractor.skipped_bare)))
        print("    %-16s %5d   engine/source/binary assets (the user's game content)"
              % ("engine-asset", len(extractor.skipped_asset)))

    covered, uncovered, sources, no_region = installer_coverage(repo_root, manifest)
    region = manifest["installer"]["scaffold_region"]
    print("")
    print("  INSTALLER SCAFFOLD COVERAGE  (%s)" % (", ".join(sources) if sources else "no installer found"))
    print("    %-16s %5d   scaffold paths created inside the %s..%s region"
          % ("covered", len(covered), region["begin"], region["end"]))
    flag = "  <-- FAIL" if uncovered else ""
    print("    %-16s %5d   scaffold paths the manifest promises and the installer never creates%s"
          % ("uncovered", len(uncovered), flag))
    for name in no_region:
        print("    (%s has no %s..%s region at all -- there is no scaffold step)"
              % (name, region["begin"], region["end"]))

    if buckets.get(PHANTOM):
        report_failures(
            "PHANTOM PATHS",
            "Commanded by a doc. Nothing in this bundle creates them. A session that "
            "follows the instruction hits a missing file.",
            buckets[PHANTOM], args.cite_limit)

    if buckets.get(KILLED):
        report_failures(
            "KILLED CONVENTIONS",
            "A different defect from a phantom: not absence but self-contradiction -- "
            "the docs disagree with each other about where things live.",
            buckets[KILLED], args.cite_limit)

    if uncovered:
        print("")
        print(THIN)
        print(" UNSCAFFOLDED PROMISES  (%d)" % len(uncovered))
        print(" tools/%s lists these as scaffold paths, but no installer script" % MANIFEST_NAME)
        print(" creates them -- so in a fresh install they are phantoms too.")
        print(THIN)
        for entry, _ in uncovered:
            print("")
            print("  %s" % entry["path"])
            print("      needed for   : %s" % entry["why"])

    if args.list_class:
        want = args.list_class.upper()
        print("")
        print(THIN)
        print(" LISTING CLASS: %s" % want)
        print(THIN)
        for ref, reason, _ in buckets.get(want, []):
            print("  %-52s %s" % (ref, reason))

    n_phantom = len(buckets.get(PHANTOM, []))
    n_killed = len(buckets.get(KILLED, []))
    n_unscaf = len(uncovered)
    failed = n_phantom + n_killed + n_unscaf

    print("")
    print(RULE)
    if failed:
        print(" VERDICT: FAIL -- %d phantom path(s), %d killed-convention reference(s), "
              "%d unscaffolded promise(s)." % (n_phantom, n_killed, n_unscaf))
        print(" Every one is a doc telling a session to open a file that will not be there.")
    else:
        print(" VERDICT: PASS -- every commanded path is shipped, scaffolded, "
              "created-on-use or templated.")
    print(RULE)
    return 1 if failed else 0


# --------------------------------------------------------------------------
# MODE 2 -- installed project
# --------------------------------------------------------------------------

def run_project_mode(repo_root, manifest, manifest_path, args):
    proj = os.path.abspath(args.project)
    if not os.path.isdir(proj):
        print("ERROR: --project directory does not exist: %s" % proj, file=sys.stderr)
        return 2

    def exists(rel):
        return os.path.exists(os.path.join(proj, rel.replace("/", os.sep).rstrip(os.sep)))

    banner("doc-stack check   MODE 2 (installed project)", proj.replace(os.sep, "/"))
    print("")
    print("  manifest : %s" % os.path.relpath(manifest_path, repo_root).replace(os.sep, "/"))

    # 1. did the install land?
    landed, not_landed = [], []
    for entry in manifest["install_map"]:
        (landed if exists(entry["project"]) else not_landed).append(entry)

    # 2. gate + exec contract
    ok_gate, missing_gate = [], []
    for entry in manifest["project_contract"]:
        (ok_gate if exists(entry["path"]) else missing_gate).append(entry)

    # 3. retired conventions must not have shipped into a real project
    killed_hits = []
    extractor = Extractor(manifest)
    sub_manifest = dict(manifest)
    sub_manifest["scan"] = {
        "roots": [".claude", "tools"],
        "extra_files": ["CLAUDE.md"],
        "file_suffixes": manifest["scan"]["file_suffixes"],
    }
    proj_refs, proj_files = collect_references(proj, sub_manifest, extractor)
    for ref in sorted(proj_refs):
        norm = normalise(ref)
        for entry in manifest["killed_conventions"]:
            if prefix_matches(entry["pattern"], norm):
                killed_hits.append((ref, "retired '%s' -> use '%s'"
                                    % (entry["pattern"], entry["replacement"]), proj_refs[ref]))
                break

    # 4. informational: documented outputs not written yet (that is fine)
    pending = [e for e in manifest["scaffold"] if not exists(e["path"])]

    print("  scanned  : %d installed doc files under .claude/, tools/ + CLAUDE.md" % len(proj_files))
    print("")
    print("  INSTALL LANDED")
    print("    %-16s %5d   install targets present" % ("present", len(landed)))
    flag = "  <-- FAIL" if not_landed else ""
    print("    %-16s %5d   install targets missing%s" % ("missing", len(not_landed), flag))
    print("")
    print("  READ-AS-GATE / EXECUTE CONTRACT")
    print("    %-16s %5d   paths the skills read or run, present" % ("present", len(ok_gate)))
    flag = "  <-- FAIL" if missing_gate else ""
    print("    %-16s %5d   paths the skills read or run, MISSING%s" % ("missing", len(missing_gate), flag))
    print("")
    print("  RETIRED CONVENTIONS IN THE INSTALL")
    flag = "  <-- FAIL" if killed_hits else ""
    print("    %-16s %5d   references to conventions this template retired%s"
          % ("killed", len(killed_hits), flag))
    print("")
    print("  NOT YET WRITTEN (informational, not a failure)")
    print("    %-16s %5d   scaffold paths absent -- expected in a young project"
          % ("pending", len(pending)))

    if not_landed:
        print("")
        print(THIN)
        print(" INSTALL TARGETS MISSING  (%d)" % len(not_landed))
        print(" The installer was supposed to create these. Re-run scripts/install.sh.")
        print(THIN)
        for entry in not_landed:
            print("")
            print("  %s" % entry["project"])
            print("      why        : %s" % entry["why"])

    if missing_gate:
        print("")
        print(THIN)
        print(" GATE / EXEC PATHS MISSING  (%d)" % len(missing_gate))
        print(" A skill reads or runs each of these. Missing = that skill fails mid-run.")
        print(THIN)
        for entry in missing_gate:
            print("")
            print("  %s   [%s, expected from: %s]" % (entry["path"], entry["kind"], entry["source"]))
            print("      why        : %s" % entry["why"])

    if killed_hits:
        report_failures(
            "RETIRED CONVENTIONS PRESENT",
            "The installed docs still point at a layout this template no longer uses.",
            killed_hits, args.cite_limit)

    failed = len(not_landed) + len(missing_gate) + len(killed_hits)
    print("")
    print(RULE)
    if failed:
        print(" VERDICT: FAIL -- %d missing install target(s), %d missing gate/exec path(s), "
              "%d retired reference(s)." % (len(not_landed), len(missing_gate), len(killed_hits)))
    else:
        print(" VERDICT: PASS -- the install landed and every gate/exec path exists.")
    print(RULE)
    return 1 if failed else 0


# --------------------------------------------------------------------------
# entry point
# --------------------------------------------------------------------------

def main(argv=None):
    parser = argparse.ArgumentParser(
        prog="doc_stack_check.py",
        description="Regression guard: every path the docs command must be a path something creates.",
        epilog="Add new paths in tools/%s, never in this script." % MANIFEST_NAME,
    )
    parser.add_argument("--project", metavar="DIR",
                        help="check an INSTALLED project instead of this bundle")
    parser.add_argument("--repo", metavar="DIR", default=None,
                        help="template repo root (default: the parent of tools/)")
    parser.add_argument("--list", dest="list_class", metavar="CLASS", default=None,
                        help="also list every reference in CLASS (e.g. SHIPPED, TEMPLATED)")
    parser.add_argument("--cite-limit", type=int, default=4, metavar="N",
                        help="max citing files shown per failure (0 = all; default 4)")
    args = parser.parse_args(argv)

    try:
        sys.stdout.reconfigure(encoding="utf-8")  # py3.7+; report itself is ASCII
    except Exception:
        pass

    repo_root = args.repo or os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    repo_root = os.path.abspath(repo_root)

    try:
        manifest, manifest_path = load_manifest(repo_root)
    except (OSError, ValueError) as exc:
        print("ERROR: could not load manifest: %s" % exc, file=sys.stderr)
        return 2

    if args.project:
        return run_project_mode(repo_root, manifest, manifest_path, args)
    return run_bundle_mode(repo_root, manifest, manifest_path, args)


if __name__ == "__main__":
    sys.exit(main())
