---
id: GAP-024
title: neojac port --check says nothing about Django HTML templates and stylesheets
kind: limitation
severity: minor
status: open
area: port
milestone: M0
found: 2026-11-23
neojac: 0.4.0
command: neojac port --check bookmarks/templates
code: 
---

## Symptom
linkding's UI is 44 Django `.html` templates plus CSS. `neojac port --check bookmarks/templates` reports only the 2 `.js` files in that folder (`settings/bookmarklet.js`, `settings/bookmarklet_clientside.js`) as refused and does not mention the 44 `.html` files: neither ported nor refused. The language table in `neojac docs toolchain/port` lists no template or CSS language.

## Repro
```sh
neojac --version
cd ~/.claude-scratch/linkjac/linkding-m0
find bookmarks/templates -name '*.html' | wc -l   # 44
neojac port --check bookmarks/templates 2>&1 | tail -2   # 2 sources refused
```

## Expected
Documented by the path rules. `neojac docs toolchain/port`, section "What a path names": "A directory is every source under it that port translates" and "A file is known by its extension, and one port does not translate is E4004". An `.html` or `.css` file is no source port translates, so a directory run leaves it out without a line. The page does not name templates or stylesheets or say `--check` stays silent about them. The web UI is rebuilt by hand with the `ui` plugin in M4.

## Workaround
None. The UI is designed by hand in M4.

## Cause
Unknown.
