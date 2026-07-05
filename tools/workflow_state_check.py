"""
workflow_state_check.py — mechanical (zero-LLM) workflow-state detection.

WHAT IT DOES
  Reads the canonical pipeline (.claude/docs/workflow-catalog.yaml) + the project's
  flow ledger (production/flow-ledger.yaml), cross-checks each step's LEDGER claim
  against EVIDENCE on disk, and derives the recommended next step.

  Pure evidence logic. No LLM, no network. stdlib + PyYAML only (falls back to a
  tiny built-in YAML subset parser if PyYAML is absent, so it runs on a bare repo).

PORTABILITY (the "anyone downloads this from git" story)
  The SCRIPT is generic. Everything project-specific lives in the ledger + catalog.
  If production/flow-ledger.yaml is MISSING -> BOOTSTRAP MODE: infer a draft ledger
  from artifact existence alone, write production/flow-ledger.draft.yaml, and tell the
  user to review + rename it. That is all a downstream framework user has to do.

CROSS-CHECK VERDICTS (per step)
  OK              ledger status matches evidence on disk
  CONFLICT        ledger=done but evidence missing/empty     -> exit 1
  UNRECORDED      evidence exists but ledger=not-started      (work done, not logged)
  ILLEGITIMATE    status=skipped/leapfrogged with no reason   -> exit 1
  (n-a / not-started with no evidence are fine and silent-ish)

OUTPUT
  Default: posture line + per-step table + RULE-PENDING blockers + RECOMMENDED NEXT STEP.
  --brief: posture + rule-pending + recommended-next + conflict count only (for hooks).

EXIT CODES
  0  clean
  1  conflicts or illegitimate-skips found (so hooks / CI can gate)

USAGE
  python tools/workflow_state_check.py            # full report
  python tools/workflow_state_check.py --brief    # compact (session-start hook)
  python tools/workflow_state_check.py --json      # machine-readable
"""
import glob
import os
import sys

# ---------------------------------------------------------------------------
# Paths (repo-root-relative; resolved from this file's location so the tool
# works from any cwd and from a worktree).
# ---------------------------------------------------------------------------
TOOLS_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.dirname(TOOLS_DIR)

CATALOG_PATH = os.path.join(REPO_ROOT, ".claude", "docs", "workflow-catalog.yaml")
LEDGER_PATH = os.path.join(REPO_ROOT, "production", "flow-ledger.yaml")
DRAFT_PATH = os.path.join(REPO_ROOT, "production", "flow-ledger.draft.yaml")

# Statuses that mean "this step no longer needs doing".
DONE_STATES = {"done", "leapfrogged", "skipped", "n-a"}
# Statuses whose skip must carry a reason or they are illegitimate.
SKIP_STATES = {"skipped", "leapfrogged"}


# ---------------------------------------------------------------------------
# YAML loading — prefer PyYAML; fall back to a minimal subset parser so the
# tool runs on a bare repo with no third-party deps (portability requirement).
# ---------------------------------------------------------------------------
def load_yaml(path):
    with open(path, "r", encoding="utf-8") as f:
        text = f.read()
    try:
        import yaml  # noqa: WPS433 (intentional optional import)
        return yaml.safe_load(text)
    except ImportError:
        return _mini_yaml(text)


def _mini_yaml(text):
    """
    Tiny YAML-subset parser. Handles only the shapes this tool's files use:
    top-level scalars, top-level lists of mappings, mappings with scalar and
    inline-list ([a, b]) values, and one level of nested list-of-mappings.
    Good enough for workflow-catalog.yaml and flow-ledger.yaml when PyYAML is
    absent. If your ledger uses richer YAML, install PyYAML (pip install pyyaml).
    """
    root = {}
    lines = [ln.rstrip() for ln in text.split("\n")]
    # Strip comments (outside quotes) and blank lines, keep indentation.
    cleaned = []
    for ln in lines:
        if not ln.strip() or ln.lstrip().startswith("#"):
            continue
        # remove trailing ' # comment' (naive; fine for our files)
        if " #" in ln and not _in_quotes(ln, ln.index(" #")):
            ln = ln[: ln.index(" #")].rstrip()
        cleaned.append(ln)

    i = 0
    n = len(cleaned)

    def indent_of(s):
        return len(s) - len(s.lstrip())

    def parse_block(lines_block):
        """Parse a list of same-or-deeper-indented lines into python objects."""
        result_map = {}
        result_list = []
        idx = 0
        blen = len(lines_block)
        while idx < blen:
            line = lines_block[idx]
            ind = indent_of(line)
            stripped = line.strip()
            if stripped.startswith("- "):
                # list item
                item_body = stripped[2:]
                # gather child lines that are more indented than this '- '
                child = []
                j = idx + 1
                while j < blen and indent_of(lines_block[j]) > ind:
                    child.append(lines_block[j])
                    j += 1
                if ":" in item_body:
                    # inline first key of a mapping list item
                    first_line = " " * (ind + 2) + item_body
                    obj = parse_block([first_line] + child)
                    result_list.append(obj)
                else:
                    result_list.append(_scalar(item_body))
                idx = j
                continue
            if stripped == "- ":
                child = []
                j = idx + 1
                while j < blen and indent_of(lines_block[j]) > ind:
                    child.append(lines_block[j])
                    j += 1
                result_list.append(parse_block(child))
                idx = j
                continue
            # mapping key
            if ":" in stripped:
                key, _, val = stripped.partition(":")
                key = key.strip()
                val = val.strip()
                if val == "":
                    # nested block
                    child = []
                    j = idx + 1
                    while j < blen and indent_of(lines_block[j]) > ind:
                        child.append(lines_block[j])
                        j += 1
                    result_map[key] = parse_block(child)
                    idx = j
                else:
                    result_map[key] = _scalar(val)
                    idx += 1
                continue
            idx += 1
        if result_list and not result_map:
            return result_list
        return result_map

    parsed = parse_block(cleaned[i:n])
    if isinstance(parsed, dict):
        root = parsed
    else:
        root = {"_list": parsed}
    return root


def _in_quotes(s, pos):
    return s[:pos].count('"') % 2 == 1


def _scalar(v):
    v = v.strip()
    if v.startswith("[") and v.endswith("]"):
        inner = v[1:-1].strip()
        if not inner:
            return []
        return [_scalar(x) for x in _split_inline_list(inner)]
    if (v.startswith('"') and v.endswith('"')) or (v.startswith("'") and v.endswith("'")):
        return v[1:-1]
    low = v.lower()
    if low in ("true", "yes"):
        return True
    if low in ("false", "no"):
        return False
    if low in ("null", "~", "none"):
        return None
    return v


def _split_inline_list(inner):
    """Split 'a, b, c' respecting quotes."""
    out, buf, q = [], "", None
    for ch in inner:
        if q:
            if ch == q:
                q = None
            buf += ch
        elif ch in ("'", '"'):
            q = ch
            buf += ch
        elif ch == ",":
            out.append(buf.strip())
            buf = ""
        else:
            buf += ch
    if buf.strip():
        out.append(buf.strip())
    return out


# ---------------------------------------------------------------------------
# Evidence checking
# ---------------------------------------------------------------------------
def evidence_exists(patterns):
    """
    True if at least one path (glob OK) matches an existing non-empty file
    OR a non-empty directory. Returns (found_bool, matched_paths).
    """
    matched = []
    for pat in patterns or []:
        abspat = pat if os.path.isabs(pat) else os.path.join(REPO_ROOT, pat)
        hits = glob.glob(abspat, recursive=True)
        for h in hits:
            if os.path.isdir(h):
                if os.listdir(h):
                    matched.append(h)
            elif os.path.isfile(h) and os.path.getsize(h) > 0:
                matched.append(h)
    return (len(matched) > 0, matched)


# ---------------------------------------------------------------------------
# Catalog helpers — flatten canonical steps into ordered (phase, step) pairs.
# ---------------------------------------------------------------------------
def catalog_steps(catalog):
    """Return ordered list of dicts: {id, name, phase, required, artifact}."""
    steps = []
    phases = (catalog or {}).get("phases", {}) or {}
    for phase_name, phase in phases.items():
        for st in (phase.get("steps", []) or []):
            steps.append(
                {
                    "id": st.get("id"),
                    "name": st.get("name", st.get("id")),
                    "phase": phase_name,
                    "required": st.get("required", False),
                    "artifact": st.get("artifact") or {},
                }
            )
    return steps


def catalog_phase_order(catalog):
    return list(((catalog or {}).get("phases", {}) or {}).keys())


def _dedupe_by_id(steps):
    """
    Some step ids recur across phases (e.g. sprint-plan in pre-production AND
    production). Keep the FIRST occurrence so the table + recommendation don't
    double-count. First occurrence = earliest phase = the one that gates.
    """
    seen = set()
    out = []
    for s in steps:
        if s["id"] in seen:
            continue
        seen.add(s["id"])
        out.append(s)
    return out


# ---------------------------------------------------------------------------
# Cross-check: ledger vs evidence
# ---------------------------------------------------------------------------
def crosscheck(catalog, ledger):
    """
    Returns (rows, problems).
      rows: list of dicts {id, phase, ledger_status, verdict, note, custom, evidence}
      problems: list of (kind, id, detail) for exit-code gating
    """
    cat_steps = _dedupe_by_id(catalog_steps(catalog))
    cat_ids = [s["id"] for s in cat_steps]
    cat_by_id = {s["id"]: s for s in cat_steps}

    ledger_steps = ledger.get("steps", []) or []
    led_by_id = {s.get("id"): s for s in ledger_steps}

    rows = []
    problems = []

    # Ordered union: canonical order first, then custom ledger-only steps appended.
    ordered_ids = list(cat_ids)
    for ls in ledger_steps:
        if ls.get("id") not in ordered_ids:
            ordered_ids.append(ls.get("id"))

    for sid in ordered_ids:
        led = led_by_id.get(sid)
        cat = cat_by_id.get(sid)
        custom = bool(led and led.get("custom"))
        phase = (cat or {}).get("phase", "custom" if custom else "?")

        if led is None:
            # Canonical step with no ledger entry — infer from artifact evidence.
            # Only trust the glob when the catalog does NOT also carry a `note`
            # (a note signals "completion can't be auto-detected" — the glob is
            # then just a hint, e.g. scope-check pointing at sprint-*.md). Avoids
            # false UNRECORDED on repeatable/action steps.
            art = (cat or {}).get("artifact", {}) or {}
            has_note = bool(art.get("note"))
            pats = [] if has_note else _artifact_patterns(art)
            found, matched = evidence_exists(pats)
            status = "(unlogged)"
            if found:
                verdict = "UNRECORDED"
                note = "evidence present but NOT in ledger — log it"
                problems.append(("unrecorded", sid, ", ".join(_rel(matched)[:2])))
            else:
                verdict = "-"
                note = "no ledger entry, no evidence"
            rows.append(
                {
                    "id": sid, "phase": phase, "ledger_status": status,
                    "verdict": verdict, "note": note, "custom": custom,
                    "evidence": matched,
                }
            )
            continue

        status = (led.get("status") or "?").lower()
        ev_patterns = led.get("evidence") or []
        found, matched = evidence_exists(ev_patterns)
        reason = (led.get("reason") or "").strip()

        verdict = "OK"
        note = ""

        if status == "done":
            if not ev_patterns:
                verdict = "CONFLICT"
                note = "status=done but NO evidence paths listed"
                problems.append(("conflict", sid, "done with no evidence paths"))
            elif not found:
                verdict = "CONFLICT"
                note = "status=done but evidence MISSING/empty: " + ", ".join(ev_patterns)
                problems.append(("conflict", sid, "done but evidence missing"))
            else:
                note = "verified: " + ", ".join(_rel(matched)[:2])
        elif status in SKIP_STATES:
            if not reason:
                verdict = "ILLEGITIMATE"
                note = "status=%s with NO reason" % status
                problems.append(("illegitimate-skip", sid, "no reason given"))
            else:
                note = "legit " + status
        elif status == "in-progress":
            note = "in progress" + (" (evidence present)" if found else "")
        elif status == "not-started":
            if found:
                verdict = "UNRECORDED"
                note = "ledger=not-started but evidence EXISTS: " + ", ".join(_rel(matched)[:2])
                problems.append(("unrecorded", sid, "evidence exists but not-started"))
            else:
                note = "not started"
        elif status == "n-a":
            note = "n/a"
        else:
            verdict = "?"
            note = "unknown status '%s'" % status

        rows.append(
            {
                "id": sid, "phase": phase, "ledger_status": status,
                "verdict": verdict, "note": note, "custom": custom,
                "evidence": matched,
            }
        )

    return rows, problems


def _artifact_patterns(art):
    g = art.get("glob")
    return [g] if g else []


def _rel(paths):
    out = []
    for p in paths:
        try:
            out.append(os.path.relpath(p, REPO_ROOT).replace("\\", "/"))
        except ValueError:
            out.append(p)
    return out


# ---------------------------------------------------------------------------
# Recommended next step
# ---------------------------------------------------------------------------
def rule_pending_blocked(ledger):
    """Set of step ids blocked by an OPEN rule_pending item (designer decision)."""
    blocked = set()
    for rp in (ledger.get("rule_pending") or []):
        for sid in (rp.get("blocks") or []):
            blocked.add(sid)
    return blocked


def recommend_next(catalog, ledger, rows):
    """
    First canonical step (in phase order) that is:
      - NOT done/leapfrogged/skipped/n-a,
      - NOT gated by an open rule_pending blocker,
      - and whose dependencies are satisfied.
    Custom steps are anchors, not gates, so they are excluded from the walk.
    A rule_pending-blocked step is deferred (the blocker prints before the
    recommendation), so the recommendation lands on the first UNBLOCKED work.
    """
    led_by_id = {s.get("id"): s for s in (ledger.get("steps", []) or [])}
    cat_steps = _dedupe_by_id(catalog_steps(catalog))
    blocked = rule_pending_blocked(ledger)

    def is_settled(sid):
        led = led_by_id.get(sid)
        if led is None:
            row = next((r for r in rows if r["id"] == sid), None)
            return bool(row and row["verdict"] not in ("UNRECORDED", "-", "?"))
        return (led.get("status") or "").lower() in DONE_STATES

    def deps_met(led):
        for dep in (led.get("depends_on") or []):
            if not is_settled(dep):
                return False
        return True

    # Pass 1: first UNBLOCKED, REQUIRED, not-started step whose deps are met.
    # Optional steps (required: false — reviews, checks, repeatable actions) are
    # enhancements, not gates, so they never become the forward recommendation.
    for st in cat_steps:
        sid = st["id"]
        if sid in blocked:
            continue
        if not st.get("required"):
            continue
        led = led_by_id.get(sid, {})
        status = (led.get("status") or "not-started").lower()
        if status in DONE_STATES:
            continue
        if status == "in-progress":
            # keep looking for a genuine not-started gate before recommending
            # an already-moving step
            continue
        if deps_met(led):
            return st, led
    # Pass 2: allow in-progress required steps (work already underway).
    for st in cat_steps:
        sid = st["id"]
        if sid in blocked:
            continue
        led = led_by_id.get(sid, {})
        if (led.get("status") or "").lower() == "in-progress" and st.get("required"):
            if deps_met(led):
                return st, led
    # Pass 3: any in-progress step at all.
    for st in cat_steps:
        led = led_by_id.get(st["id"], {})
        if (led.get("status") or "").lower() == "in-progress":
            return st, led
    return None, None


# ---------------------------------------------------------------------------
# Bootstrap mode (no ledger present)
# ---------------------------------------------------------------------------
def bootstrap(catalog):
    """
    Infer a draft ledger from artifact existence alone and write it to
    flow-ledger.draft.yaml. This is the downstream-user story: drop the tool in,
    run it, get a draft, review + rename to flow-ledger.yaml.
    """
    lines = [
        "# flow-ledger.draft.yaml — AUTO-INFERRED from artifact existence.",
        "# REVIEW every status + reason, then rename to production/flow-ledger.yaml.",
        "# The tool inferred 'done' where a step's catalog artifact glob matched a",
        "# non-empty file, else 'not-started'. It CANNOT know your leapfrogs,",
        "# skips, or custom steps — you must add those by hand.",
        "",
        "posture: unknown   # set to your project posture (e.g. concept / production / slice-proven-backfilling)",
        "",
        "rule_pending: []",
        "rule_resolved: []",
        "",
        "steps:",
    ]
    for st in catalog_steps(catalog):
        art = st.get("artifact", {}) or {}
        pats = _artifact_patterns(art)
        found, matched = evidence_exists(pats)
        status = "done" if found else "not-started"
        lines.append("  - id: %s" % st["id"])
        lines.append("    status: %s" % status)
        if found:
            ev = ", ".join(_rel(matched)[:3])
            lines.append("    evidence: [%s]" % ev)
            lines.append('    reason: "AUTO: artifact glob matched — VERIFY this is real completion."')
        else:
            lines.append("    evidence: []")
            lines.append('    reason: "AUTO: no artifact found. If you leapfrogged/skipped this, set status + a real reason."')
    draft = "\n".join(lines) + "\n"
    with open(DRAFT_PATH, "w", encoding="utf-8") as f:
        f.write(draft)
    return DRAFT_PATH


# ---------------------------------------------------------------------------
# Reporting
# ---------------------------------------------------------------------------
def _rule_pending_block(ledger):
    out = []
    for rp in (ledger.get("rule_pending") or []):
        title = rp.get("title", rp.get("id", "?"))
        blocks = rp.get("blocks") or []
        out.append("  [RULE-PENDING] %s" % title)
        if blocks:
            out.append("               blocks: %s" % ", ".join(blocks))
    return out


def print_full(catalog, ledger, rows, problems):
    posture = ledger.get("posture", "unknown")
    print("=" * 72)
    print("WORKFLOW STATE — mechanical (zero-LLM) check")
    print("=" * 72)
    print("POSTURE: %s" % posture)
    print()

    # rule-pending FIRST (they gate the recommendation)
    rp = _rule_pending_block(ledger)
    if rp:
        print("RULE-PENDING BLOCKERS (designer decisions gating downstream work):")
        for ln in rp:
            print(ln)
        print()

    # per-step table
    hdr = "  %-22s %-14s %-13s %s" % ("STEP", "LEDGER", "EVIDENCE", "NOTE")
    print(hdr)
    print("  " + "-" * 70)
    for r in rows:
        tag = "*" if r["custom"] else " "
        print(
            "  %s%-21s %-14s %-13s %s"
            % (tag, r["id"], r["ledger_status"], r["verdict"], r["note"][:60])
        )
    print("  (* = custom / non-canonical step)")
    print()

    # recommended next
    st, led = recommend_next(catalog, ledger, rows)
    print("RECOMMENDED NEXT STEP:")
    if rp:
        print("  (resolve the RULE-PENDING blockers above first — they gate downstream work)")
    if st:
        print("  -> %s  [%s phase]" % (st["id"], st["phase"]))
        reason = (led or {}).get("reason", "")
        if reason:
            print("     %s" % reason[:200])
    else:
        print("  (all canonical steps settled — you are past the catalog; drive from sprints)")
    print()

    # summary
    n_conf = sum(1 for k, _, _ in problems if k in ("conflict", "illegitimate-skip"))
    n_unrec = sum(1 for k, _, _ in problems if k == "unrecorded")
    print("SUMMARY: %d conflict/illegitimate-skip, %d unrecorded" % (n_conf, n_unrec))
    if problems:
        for kind, sid, detail in problems:
            print("  - %-16s %-22s %s" % (kind, sid, detail))
    print("=" * 72)


def print_brief(catalog, ledger, rows, problems):
    """Compact mode for the session-start hook."""
    posture = ledger.get("posture", "unknown")
    n_conf = sum(1 for k, _, _ in problems if k in ("conflict", "illegitimate-skip"))
    print("POSTURE: %s" % posture)
    for rp in (ledger.get("rule_pending") or []):
        print("  RULE-PENDING: %s" % rp.get("title", rp.get("id", "?")))
    st, led = recommend_next(catalog, ledger, rows)
    if st:
        print("  NEXT: %s (%s phase)" % (st["id"], st["phase"]))
        reason = (led or {}).get("reason", "")
        if reason:
            print("        %s" % reason[:140])
    else:
        print("  NEXT: catalog complete — drive from sprints")
    print("  CONFLICTS: %d" % n_conf)


def print_json(catalog, ledger, rows, problems):
    import json
    st, led = recommend_next(catalog, ledger, rows)
    payload = {
        "posture": ledger.get("posture", "unknown"),
        "rule_pending": ledger.get("rule_pending", []),
        "recommended_next": (st or {}).get("id") if st else None,
        "recommended_phase": (st or {}).get("phase") if st else None,
        "steps": [
            {k: r[k] for k in ("id", "phase", "ledger_status", "verdict", "note", "custom")}
            for r in rows
        ],
        "problems": [{"kind": k, "step": s, "detail": d} for (k, s, d) in problems],
    }
    print(json.dumps(payload, indent=2))


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def main(argv):
    brief = "--brief" in argv
    as_json = "--json" in argv

    if not os.path.exists(CATALOG_PATH):
        print("ERROR: canonical catalog not found at %s" % CATALOG_PATH, file=sys.stderr)
        return 2
    catalog = load_yaml(CATALOG_PATH)

    if not os.path.exists(LEDGER_PATH):
        # BOOTSTRAP MODE — the downstream-user portability path.
        draft = bootstrap(catalog)
        print("=" * 72)
        print("BOOTSTRAP MODE — no production/flow-ledger.yaml found.")
        print("=" * 72)
        print("Inferred a draft ledger from artifact existence and wrote it to:")
        print("  %s" % os.path.relpath(draft, REPO_ROOT).replace("\\", "/"))
        print()
        print("NEXT: open the draft, correct every status + reason (the tool cannot")
        print("know your leapfrogs / skips / custom steps), then rename it to:")
        print("  production/flow-ledger.yaml")
        print("Re-run this tool to get the real state report.")
        print("=" * 72)
        # Bootstrap is an actionable state, not a failure — exit 0.
        return 0

    ledger = load_yaml(LEDGER_PATH)
    rows, problems = crosscheck(catalog, ledger)

    if as_json:
        print_json(catalog, ledger, rows, problems)
    elif brief:
        print_brief(catalog, ledger, rows, problems)
    else:
        print_full(catalog, ledger, rows, problems)

    # Exit 1 on conflicts or illegitimate skips (gate-able). Unrecorded is a
    # warning, not a gate (it means "log your work", not "broken state").
    gating = [k for (k, _, _) in problems if k in ("conflict", "illegitimate-skip")]
    return 1 if gating else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
