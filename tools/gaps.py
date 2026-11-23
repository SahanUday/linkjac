#!/usr/bin/env python3
"""Gap-log and project tooling: new, check, status, update, map, site.

Dependency-free except `site`, which needs the `markdown` package.
"""
from __future__ import annotations

import argparse
import datetime as dt
import html
import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
GAPS = ROOT / "gaps"
JOURNAL = ROOT / "journal"
PLAN = ROOT / "PLAN.md"
SCAN_DIRS = ["app", "parity"]
SCAN_EXT = {".jac", ".py", ".toml", ".sh", ".ts", ".tsx", ".js", ".json", ".md"}

KINDS = ["bug", "gap", "limitation", "docs", "ergonomics"]
SEVERITIES = ["blocker", "major", "minor", "nit"]
STATUSES = ["open", "worked-around", "resolved"]
AREAS = [
    "compiler", "diagnostics", "docs", "skills", "cli", "store", "auth", "transport",
    "jobs", "schedule", "files", "limits", "llm", "ui", "bundler", "port", "absorb",
    "arch", "toolchain", "test", "platform", "other",
]
REQUIRED_KEYS = ["id", "title", "kind", "severity", "status", "area", "milestone", "found", "neojac"]
SECTIONS = ["Symptom", "Repro", "Expected", "Workaround", "Cause"]
PLACEHOLDER = "_fill in_"
MARKER = re.compile(r"WORKAROUND\(([^)]*)\)")
GAP_ID = re.compile(r"GAP-\d{3,}")
SMELL = re.compile(
    r"\b(workaround|work-around|hack|for now|temporary|temporarily|fixme|xxx|kludge|"
    r"monkey-?patch|xfail|skipped?)\b",
    re.IGNORECASE,
)


# ---------- reading ----------

class Gap:
    def __init__(self, path: Path):
        self.path = path
        text = path.read_text(encoding="utf-8")
        self.meta, self.body = split_front_matter(text)

    @property
    def id(self) -> str:
        return self.meta.get("id", "")

    def get(self, key: str) -> str:
        return self.meta.get(key, "")


def split_front_matter(text: str) -> tuple[dict[str, str], str]:
    if not text.startswith("---\n"):
        return {}, text
    end = text.find("\n---\n", 4)
    if end == -1:
        return {}, text
    meta: dict[str, str] = {}
    for line in text[4:end].splitlines():
        if ":" in line:
            key, value = line.split(":", 1)
            meta[key.strip()] = value.strip().strip('"')
    return meta, text[end + 5:]


def load_gaps() -> list[Gap]:
    return [Gap(p) for p in sorted(GAPS.glob("GAP-*.md"))]


def section_text(body: str, name: str) -> str | None:
    match = re.search(rf"^## {name}\s*$(.*?)(?=^## |\Z)", body, re.MULTILINE | re.DOTALL)
    return match.group(1).strip() if match else None


def scan_code() -> tuple[dict[str, list[str]], list[str]]:
    """Return ({gap id: ['path:line', ...]}, smell warnings)."""
    refs: dict[str, list[str]] = {}
    smells: list[str] = []
    for name in SCAN_DIRS:
        base = ROOT / name
        if not base.is_dir():
            continue
        for path in sorted(base.rglob("*")):
            if not path.is_file() or path.suffix not in SCAN_EXT or path.name == "README.md":
                continue
            if any(part in {"node_modules", ".jac", "dist", "__pycache__"} for part in path.parts):
                continue
            try:
                lines = path.read_text(encoding="utf-8").splitlines()
            except (UnicodeDecodeError, OSError):
                continue
            rel = path.relative_to(ROOT)
            for number, line in enumerate(lines, 1):
                found = MARKER.search(line)
                if found:
                    for gap_id in GAP_ID.findall(found.group(1)):
                        refs.setdefault(gap_id, []).append(f"{rel}:{number}")
                elif SMELL.search(line):
                    smells.append(f"{rel}:{number}: {line.strip()[:90]}")
    return refs, smells



def module_docs() -> list[tuple[str, str]]:
    """(path relative to app/, first docstring line) for each Jac module."""
    base = ROOT / "app"
    found: list[tuple[str, str]] = []
    if not base.is_dir():
        return found
    for path in sorted(base.rglob("*.jac")):
        parts = set(path.relative_to(base).parts)
        if parts & {".jac", "dist", "node_modules", "impl"} or path.name in ("archwire.jac",) \
                or path.name.endswith(".impl.jac"):
            continue
        text = path.read_text(encoding="utf-8")
        match = re.match(r'\s*(?:#[^\n]*\n\s*)*"""(.*?)"""', text, re.DOTALL)
        doc = match.group(1).strip().splitlines()[0] if match and match.group(1).strip() else ""
        found.append((str(path.relative_to(base)), doc))
    return found


def cmd_map(_: argparse.Namespace) -> int:
    modules = module_docs()
    for path, doc in modules:
        print(f"{path}: {doc or '(NO DOCSTRING)'}")
    if not modules:
        print("no modules yet")
    return 0

# ---------- checking ----------

def validate_gap(gap: Gap, strict: bool) -> list[str]:
    errors: list[str] = []
    name = gap.path.name
    for key in REQUIRED_KEYS:
        if not gap.get(key):
            errors.append(f"{name}: missing `{key}`")
    if gap.id and not name.startswith(gap.id + "-"):
        errors.append(f"{name}: file name must start with `{gap.id}-`")
    for key, allowed in (("kind", KINDS), ("severity", SEVERITIES), ("status", STATUSES), ("area", AREAS)):
        if gap.get(key) and gap.get(key) not in allowed:
            errors.append(f"{name}: `{key}` must be one of {', '.join(allowed)}")
    if gap.get("found") and not re.fullmatch(r"\d{4}-\d{2}-\d{2}", gap.get("found")):
        errors.append(f"{name}: `found` must be YYYY-MM-DD")
    if not strict:
        return errors
    for title in SECTIONS:
        text = section_text(gap.body, title)
        if text is None:
            errors.append(f"{name}: missing section `## {title}`")
        elif not text or PLACEHOLDER in text:
            errors.append(f"{name}: section `## {title}` is empty or still a placeholder")
    repro = section_text(gap.body, "Repro") or ""
    if "```" not in repro:
        errors.append(f"{name}: `## Repro` needs a fenced block with the exact commands or file")
    cause = section_text(gap.body, "Cause") or ""
    if cause and not re.match(r"(Unknown|Guess)", cause):
        errors.append(f"{name}: `## Cause` must start with `Unknown` or `Guess:` (no source access)")
    return errors


def check_all(strict: bool = True) -> tuple[list[str], list[str]]:
    gaps = load_gaps()
    refs, smells = scan_code()
    errors: list[str] = []
    seen: dict[str, str] = {}
    for gap in gaps:
        errors += validate_gap(gap, strict)
        if gap.id in seen:
            errors.append(f"{gap.path.name}: duplicate id {gap.id} (also {seen[gap.id]})")
        seen[gap.id] = gap.path.name
    known = set(seen)
    for gap_id, places in refs.items():
        if gap_id not in known:
            errors.append(f"{places[0]}: WORKAROUND({gap_id}) has no gap file")
    for gap in gaps:
        has_marker = gap.id in refs
        if gap.get("status") == "worked-around" and not has_marker:
            errors.append(f"{gap.path.name}: status worked-around but no WORKAROUND({gap.id}) in app/ or parity/")
        if gap.get("status") == "open" and has_marker:
            errors.append(f"{gap.path.name}: code has WORKAROUND({gap.id}); set status to worked-around")
        if gap.get("status") == "resolved" and has_marker:
            errors.append(f"{gap.path.name}: resolved, but WORKAROUND({gap.id}) is still in {refs[gap.id][0]}")
    warnings = [f"{s}  (workaround-like text without a GAP marker)" for s in smells]
    warnings += [f"app/{p}: module has no one-line docstring (the map needs it)" for p, d in module_docs() if not d]
    return errors, warnings


def hook_input() -> dict:
    try:
        return json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        return {}


def cmd_check(args: argparse.Namespace) -> int:
    if args.hook_edit:
        data = hook_input()
        path = Path((data.get("tool_input") or {}).get("file_path", ""))
        errors: list[str] = []
        if path.parent.resolve() == GAPS.resolve() and path.name.startswith("GAP-") and path.exists():
            errors += validate_gap(Gap(path), strict=False)
        elif path.exists() and path.suffix in SCAN_EXT:
            known = {g.id for g in load_gaps()}
            for line_no, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
                found = MARKER.search(line)
                for gap_id in GAP_ID.findall(found.group(1)) if found else []:
                    if gap_id not in known:
                        errors.append(f"{path.name}:{line_no}: WORKAROUND({gap_id}) has no gap file yet; run `python3 tools/gaps.py new`")
        if errors:
            print("\n".join(errors), file=sys.stderr)
            return 2
        return 0
    if args.hook_stop:
        if hook_input().get("stop_hook_active"):
            return 0
        errors, _ = check_all()
        if errors:
            print("Gap log is not clean. Fix before stopping:\n" + "\n".join(errors[:15]), file=sys.stderr)
            return 2
        return 0
    errors, warnings = check_all()
    for line in errors:
        print(f"error: {line}")
    for line in warnings[: 5 if args.quiet else 40]:
        print(f"warn:  {line}")
    if not args.quiet or errors:
        print(f"{len(load_gaps())} gaps, {len(errors)} errors, {len(warnings)} warnings")
    return 1 if errors else 0


# ---------- plan and journal ----------

def read_plan() -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    if not PLAN.exists():
        return rows
    for line in PLAN.read_text(encoding="utf-8").splitlines():
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) >= 4 and re.fullmatch(r"M\d+", cells[0]):
            rows.append({"id": cells[0], "name": cells[1], "status": cells[2].lower(), "done": cells[3]})
    return rows


def current_milestone(rows: list[dict[str, str]]) -> dict[str, str] | None:
    for wanted in ("doing", "todo"):
        for row in rows:
            if row["status"] == wanted:
                return row
    return None


def journal_files() -> list[Path]:
    return sorted(JOURNAL.glob("????-??-??.md"), reverse=True)


def open_counts(gaps: list[Gap]) -> dict[str, int]:
    counts = {s: 0 for s in SEVERITIES}
    for gap in gaps:
        if gap.get("status") != "resolved" and gap.get("severity") in counts:
            counts[gap.get("severity")] += 1
    return counts


def cmd_status(args: argparse.Namespace) -> int:
    rows, gaps = read_plan(), load_gaps()
    done = sum(r["status"] in ("done", "skipped") for r in rows)
    now = current_milestone(rows)
    counts = open_counts(gaps)
    print("== linkjac status ==")
    if now:
        print(f"Now: {now['id']} {now['name']} [{now['status']}]  ({done}/{len(rows)} milestones done)")
        print(f"Done when: {now['done']}")
    print("Gaps not resolved: " + ", ".join(f"{n} {s}" for s, n in counts.items()) + f" (total {len(gaps)})")
    recent = sorted(gaps, key=lambda g: g.id)[-3:]
    for gap in recent:
        print(f"  {gap.id} [{gap.get('severity')}/{gap.get('status')}] {gap.get('title')}")
    modules = module_docs()
    if modules:
        print(f"Modules ({len(modules)}; `python3 tools/gaps.py map`):")
        for path, doc in modules[:40]:
            print(f"  {path}: {doc or '(NO DOCSTRING)'}")
        if len(modules) > 40:
            print(f"  ... {len(modules) - 40} more")
    files = journal_files()
    if files:
        print(f"Last journal: {files[0].name}")
        if not args.brief:
            print(files[0].read_text(encoding="utf-8")[:600])
    print("Reminder: before writing new code, find existing (/find-existing). Log every gap at once (/log-gap). Rules: CLAUDE.md.")
    return 0


def cmd_update(_: argparse.Namespace) -> int:
    rows, gaps = read_plan(), load_gaps()
    today = dt.date.today().isoformat()
    week = (dt.date.today() - dt.timedelta(days=7)).isoformat()
    now = current_milestone(rows)
    done = [f"{r['id']} {r['name']}" for r in rows if r["status"] == "done"]
    new_today = [g for g in gaps if g.get("found") == today]
    new_week = [g for g in gaps if g.get("found") >= week]
    counts = open_counts(gaps)
    out = [f"## Dogfooding update, {today}", ""]
    out.append(f"**Progress:** {len(done)}/{len(rows)} milestones done. Now: {now['id'] + ' ' + now['name'] if now else 'finished'}.")
    results = ROOT / "parity" / "results.json"
    if results.exists():
        try:
            data = json.loads(results.read_text(encoding="utf-8"))
            out.append(f"**Parity:** {data.get('passed')}/{data.get('total')} checks match the original.")
        except (json.JSONDecodeError, OSError):
            pass
    out.append(f"**Gaps:** {len(gaps)} recorded ({len(new_today)} today, {len(new_week)} this week). Not resolved: "
               + ", ".join(f"{n} {s}" for s, n in counts.items()) + ".")
    if new_today:
        out += ["", "**New today:**"] + [f"- {g.id} ({g.get('severity')}): {g.get('title')}" for g in new_today]
    files = journal_files()
    if files:
        match = re.search(r"\*\*Next:\*\*\s*(.+)", files[0].read_text(encoding="utf-8"))
        if match:
            out += ["", f"**Next:** {match.group(1).strip()}"]
    print("\n".join(out))
    return 0


# ---------- new ----------

def neojac_version() -> str:
    try:
        text = subprocess.run(["neojac", "--version"], capture_output=True, text=True, timeout=20).stdout
        match = re.search(r"neojac\s+(\S+)", text)
        return match.group(1) if match else (text.strip() or "unknown")
    except (OSError, subprocess.SubprocessError):
        return "unknown"


def cmd_new(args: argparse.Namespace) -> int:
    ids = [int(m.group(0)[4:]) for g in GAPS.glob("GAP-*.md") if (m := GAP_ID.match(g.name))]
    gap_id = f"GAP-{max(ids, default=0) + 1:03d}"
    slug = "-".join(re.sub(r"[^a-z0-9 ]", "", args.title.lower()).split()[:6]) or "gap"
    template = (GAPS / "_TEMPLATE.md").read_text(encoding="utf-8")
    values = {
        "id": gap_id, "title": args.title, "kind": args.kind, "severity": args.severity,
        "status": "open", "area": args.area, "milestone": args.milestone,
        "found": dt.date.today().isoformat(), "neojac": neojac_version(),
    }
    for key, value in values.items():
        template = re.sub(rf"^{key}:.*$", f"{key}: {value}", template, count=1, flags=re.MULTILINE)
    template = template.replace("GAP-000", gap_id)
    path = GAPS / f"{gap_id}-{slug}.md"
    path.write_text(template, encoding="utf-8")
    print(path.relative_to(ROOT))
    return 0


# ---------- site ----------

STYLE = """
:root{--bg:#fbfaf7;--card:#fff;--ink:#1d2433;--muted:#5b6475;--line:#e6e2d8;--accent:#0b7a75;--accent-bg:#e4f3f1;
--red:#9b2c2c;--red-bg:#fbe9e7;--amber:#7a5200;--amber-bg:#fff1cf;--green:#276749;--green-bg:#e3f4e9;--gray-bg:#eeece6}
@media (prefers-color-scheme:dark){:root{--bg:#14171f;--card:#1b1f2a;--ink:#e8eaf0;--muted:#a3abbb;--line:#2b3140;--accent:#5fd3c8;
--accent-bg:#17302e;--red:#ffb4a8;--red-bg:#3a1f1c;--amber:#f5d27a;--amber-bg:#3a2f12;--green:#8fd6a9;--green-bg:#17301f;--gray-bg:#262b38}}
*{box-sizing:border-box}
body{margin:0;background:var(--bg);color:var(--ink);font:17px/1.65 system-ui,-apple-system,"Segoe UI",Roboto,sans-serif}
a{color:var(--accent)}
header{border-bottom:1px solid var(--line);background:var(--card)}
header div,main{max-width:980px;margin:0 auto;padding:0 24px}
header div{display:flex;gap:28px;align-items:center;height:60px}
header b{font-size:19px;margin-right:auto}
header a{text-decoration:none;color:var(--muted);font-weight:500}
header a.on{color:var(--ink);border-bottom:2px solid var(--accent);padding-bottom:4px}
main{padding-top:36px;padding-bottom:80px}
h1{font-size:34px;line-height:1.2;margin:0 0 8px}
h2{font-size:22px;margin:40px 0 12px}
p.lead{color:var(--muted);font-size:19px;margin:0 0 28px}
.tiles{display:grid;grid-template-columns:repeat(auto-fit,minmax(150px,1fr));gap:14px;margin:24px 0}
.tile{background:var(--card);border:1px solid var(--line);border-radius:14px;padding:16px 18px}
.tile b{display:block;font-size:30px;line-height:1.1}
.tile span{color:var(--muted);font-size:15px}
.badge{display:inline-block;padding:1px 10px;border-radius:999px;font-size:14px;font-weight:600;background:var(--gray-bg);color:var(--muted);white-space:nowrap}
.badge.blocker{background:var(--red-bg);color:var(--red)}
.badge.major{background:var(--amber-bg);color:var(--amber)}
.badge.resolved,.badge.done{background:var(--green-bg);color:var(--green)}
.badge.worked-around,.badge.doing{background:var(--accent-bg);color:var(--accent)}
table{width:100%;border-collapse:collapse;background:var(--card);border:1px solid var(--line);border-radius:14px;overflow:hidden}
th,td{text-align:left;padding:12px 14px;border-bottom:1px solid var(--line);vertical-align:top;font-size:16px}
th{font-size:14px;color:var(--muted);font-weight:600;text-transform:uppercase;letter-spacing:.04em}
tr:last-child td{border-bottom:0}
td a{font-weight:600;text-decoration:none;white-space:nowrap}
.bar{height:10px;background:var(--gray-bg);border-radius:6px;overflow:hidden;margin:6px 0 4px}
.bar i{display:block;height:100%;background:var(--accent)}
.filters{display:flex;flex-wrap:wrap;gap:10px;margin:18px 0}
.filters select,.filters input{font:inherit;font-size:15px;padding:7px 10px;border:1px solid var(--line);border-radius:10px;background:var(--card);color:var(--ink)}
.meta{display:grid;grid-template-columns:repeat(auto-fit,minmax(180px,1fr));gap:12px;background:var(--card);border:1px solid var(--line);border-radius:14px;padding:18px;margin:20px 0}
.meta small{display:block;color:var(--muted);font-size:13px;text-transform:uppercase;letter-spacing:.05em}
pre{background:var(--card);border:1px solid var(--line);border-radius:12px;padding:14px 16px;overflow-x:auto;font-size:14.5px;line-height:1.5}
code{font-family:ui-monospace,SFMono-Regular,Menlo,monospace;font-size:.92em}
:not(pre)>code{background:var(--gray-bg);padding:1px 6px;border-radius:6px}
article{background:var(--card);border:1px solid var(--line);border-radius:14px;padding:6px 24px 12px;margin:14px 0}
.muted{color:var(--muted)}
article h1{font-size:22px;margin:18px 0 8px}
"""

FILTER_JS = """
const rows=[...document.querySelectorAll('tbody tr')];
const controls=[...document.querySelectorAll('[data-filter]')];
function apply(){
  const q=document.getElementById('q').value.toLowerCase();
  let shown=0;
  rows.forEach(r=>{
    const ok=controls.every(c=>!c.value||r.dataset[c.dataset.filter]===c.value)&&(!q||r.textContent.toLowerCase().includes(q));
    r.hidden=!ok;if(ok)shown++;
  });
  document.getElementById('count').textContent=shown+' of '+rows.length+' shown';
}
controls.forEach(c=>c.addEventListener('change',apply));
document.getElementById('q').addEventListener('input',apply);apply();
"""


def render_markdown(text: str) -> str:
    try:
        import markdown
    except ImportError:
        sys.exit("site needs the `markdown` package: uv run --with markdown python tools/gaps.py site")
    return markdown.markdown(text, extensions=["fenced_code", "tables", "sane_lists"])


def badge(value: str, kind: str = "") -> str:
    return f'<span class="badge {html.escape(kind or value)}">{html.escape(value)}</span>'


def page(title: str, body: str, active: str, root: str = "") -> str:
    nav = [("index.html", "Overview"), ("gaps.html", "Gaps"), ("plan.html", "Plan"), ("structure.html", "Structure"), ("journal.html", "Journal")]
    links = "".join(
        f'<a href="{root}{href}"{" class=on" if href == active else ""}>{label}</a>' for href, label in nav
    )
    return (
        f'<!doctype html><html lang="en"><head><meta charset="utf-8">'
        f'<meta name="viewport" content="width=device-width,initial-scale=1">'
        f"<title>{html.escape(title)}</title><style>{STYLE}</style></head><body>"
        f'<header><div><b>linkjac · neojac dogfooding</b>{links}</div></header><main>{body}</main></body></html>'
    )


def build_site(out: Path) -> None:
    gaps = sorted(load_gaps(), key=lambda g: g.id)
    refs, _ = scan_code()
    rows = read_plan()
    counts = open_counts(gaps)
    (out / "gaps").mkdir(parents=True, exist_ok=True)

    # overview
    done = sum(r["status"] in ("done", "skipped") for r in rows)
    pct = int(100 * done / len(rows)) if rows else 0
    now = current_milestone(rows)
    tiles = "".join(f'<div class="tile"><b>{n}</b><span>{s} not resolved</span></div>' for s, n in counts.items())
    latest = ""
    for path in journal_files()[:3]:
        latest += f"<article>{render_markdown(path.read_text(encoding='utf-8'))}</article>"
    top = [g for g in gaps if g.get("status") != "resolved" and g.get("severity") in ("blocker", "major")]
    top_rows = "".join(
        f'<tr><td><a href="gaps/{g.id}.html">{g.id}</a></td><td>{html.escape(g.get("title"))}</td>'
        f'<td>{badge(g.get("severity"))}</td><td>{badge(g.get("status"))}</td></tr>'
        for g in top[:8]
    )
    body = (
        "<h1>What neojac could not do (yet)</h1>"
        '<p class="lead">Rebuilding linkding in Jac with neojac, and recording every gap we hit on the way.</p>'
        f'<div class="tiles"><div class="tile"><b>{len(gaps)}</b><span>gaps recorded</span></div>{tiles}</div>'
        f'<h2>Progress</h2><div class="bar"><i style="width:{pct}%"></i></div>'
        f'<p class="muted">{done} of {len(rows)} milestones done'
        + (f" · now: {html.escape(now['id'] + ' ' + now['name'])}" if now else "") + "</p>"
        + ("<h2>Blockers and major gaps</h2><table><thead><tr><th>ID</th><th>Gap</th><th>Severity</th><th>Status</th></tr></thead>"
           f"<tbody>{top_rows}</tbody></table>" if top_rows else "")
        + ("<h2>Latest journal</h2>" + latest if latest else "")
    )
    (out / "index.html").write_text(page("Overview", body, "index.html"), encoding="utf-8")

    # gap list
    def options(values: list[str], label: str, key: str) -> str:
        opts = "".join(f'<option value="{v}">{v}</option>' for v in values)
        return f'<select data-filter="{key}"><option value="">{label}</option>{opts}</select>'

    table_rows = "".join(
        f'<tr data-severity="{g.get("severity")}" data-status="{g.get("status")}" data-kind="{g.get("kind")}" '
        f'data-area="{g.get("area")}"><td><a href="gaps/{g.id}.html">{g.id}</a></td>'
        f'<td>{html.escape(g.get("title"))}</td><td>{badge(g.get("severity"))}</td>'
        f'<td>{badge(g.get("status"))}</td><td>{html.escape(g.get("kind"))}</td>'
        f'<td>{html.escape(g.get("area"))}</td><td>{html.escape(g.get("milestone"))}</td></tr>'
        for g in gaps
    )
    body = (
        "<h1>Gaps</h1>"
        f'<div class="filters"><input id="q" placeholder="Search" aria-label="Search gaps">'
        f'{options(SEVERITIES, "Any severity", "severity")}{options(STATUSES, "Any status", "status")}'
        f'{options(KINDS, "Any kind", "kind")}{options(AREAS, "Any area", "area")}'
        '<span id="count" class="muted" style="align-self:center"></span></div>'
        "<table><thead><tr><th>ID</th><th>Gap</th><th>Severity</th><th>Status</th><th>Kind</th><th>Area</th><th>Step</th></tr></thead>"
        f"<tbody>{table_rows}</tbody></table><script>{FILTER_JS}</script>"
    )
    (out / "gaps.html").write_text(page("Gaps", body, "gaps.html"), encoding="utf-8")

    # gap pages
    for g in gaps:
        fields = [("Kind", g.get("kind")), ("Area", g.get("area")), ("Milestone", g.get("milestone")),
                  ("Found", g.get("found")), ("neojac", g.get("neojac")), ("Command", g.get("command")),
                  ("Diagnostic", g.get("code"))]
        meta = "".join(f"<div><small>{k}</small>{html.escape(v)}</div>" for k, v in fields if v)
        where = ""
        if refs.get(g.id):
            items = "".join(f"<li><code>{html.escape(p)}</code></li>" for p in refs[g.id])
            where = f"<h2>Workaround in code</h2><ul>{items}</ul>"
        body = (
            f'<p class="muted"><a href="../gaps.html">← All gaps</a></p>'
            f"<h1>{html.escape(g.get('title'))}</h1>"
            f"<p>{html.escape(g.id)} · {badge(g.get('severity'))} {badge(g.get('status'))}</p>"
            f'<div class="meta">{meta}</div>{render_markdown(g.body)}{where}'
        )
        (out / "gaps" / f"{g.id}.html").write_text(page(g.id, body, "gaps.html", "../"), encoding="utf-8")

    # plan
    plan_rows = "".join(
        f'<tr><td>{r["id"]}</td><td>{html.escape(r["name"])}</td><td>{badge(r["status"])}</td><td>{html.escape(r["done"])}</td></tr>'
        for r in rows
    )
    body = ("<h1>Plan</h1><table><thead><tr><th></th><th>Milestone</th><th>Status</th><th>Done when</th></tr></thead>"
            f"<tbody>{plan_rows}</tbody></table>")
    (out / "plan.html").write_text(page("Plan", body, "plan.html"), encoding="utf-8")

    # structure: module map and architecture picture
    modules = module_docs()
    mod_rows = "".join(
        f"<tr><td><code>{html.escape(p)}</code></td><td>{html.escape(d) if d else '<span class=muted>no docstring</span>'}</td></tr>"
        for p, d in modules
    )
    arch = ROOT / "arch.svg"
    picture = ""
    if arch.exists():
        (out / "arch.svg").write_text(arch.read_text(encoding="utf-8"), encoding="utf-8")
        picture = '<h2>Architecture</h2><p class="muted">Drawn by <code>neojac arch</code> from archwire.jac.</p><img src="arch.svg" alt="Layers and wires of the project" style="max-width:100%;background:#fff;border:1px solid var(--line);border-radius:14px;padding:12px">'
    body = (
        "<h1>Structure</h1>" + picture
        + "<h2>Modules</h2>"
        + ("<table><thead><tr><th>Module</th><th>What it is for</th></tr></thead>"
           f"<tbody>{mod_rows}</tbody></table>" if mod_rows else '<p class="muted">No modules yet.</p>')
    )
    (out / "structure.html").write_text(page("Structure", body, "structure.html"), encoding="utf-8")

    # journal
    entries = "".join(f"<article>{render_markdown(p.read_text(encoding='utf-8'))}</article>" for p in journal_files())
    body = "<h1>Journal</h1>" + (entries or '<p class="muted">No entries yet.</p>')
    (out / "journal.html").write_text(page("Journal", body, "journal.html"), encoding="utf-8")
    (out / ".nojekyll").write_text("", encoding="utf-8")


def cmd_site(args: argparse.Namespace) -> int:
    out = Path(args.out)
    build_site(out)
    print(f"site written to {out}/index.html")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)

    new = sub.add_parser("new", help="create the next gap file from the template")
    new.add_argument("title")
    new.add_argument("--kind", choices=KINDS, default="bug")
    new.add_argument("--severity", choices=SEVERITIES, default="minor")
    new.add_argument("--area", choices=AREAS, default="other")
    new.add_argument("--milestone", default="M0")
    new.set_defaults(func=cmd_new)

    check = sub.add_parser("check", help="validate gaps and WORKAROUND markers")
    check.add_argument("--quiet", action="store_true")
    check.add_argument("--hook-edit", action="store_true")
    check.add_argument("--hook-stop", action="store_true")
    check.set_defaults(func=cmd_check)

    status = sub.add_parser("status", help="short state of the project")
    status.add_argument("--brief", action="store_true")
    status.set_defaults(func=cmd_status)

    sub.add_parser("update", help="team update in markdown").set_defaults(func=cmd_update)
    sub.add_parser("map", help="one line per Jac module: path and purpose").set_defaults(func=cmd_map)

    site = sub.add_parser("site", help="build the static site")
    site.add_argument("--out", default="site")
    site.set_defaults(func=cmd_site)

    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
