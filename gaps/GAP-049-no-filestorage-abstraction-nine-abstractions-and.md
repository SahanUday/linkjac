---
id: GAP-049
title: No file-storage abstraction: nine abstractions and none keeps files, so assets and favicons are base64 text in node fields
kind: limitation
severity: major
status: worked-around
area: store
milestone: M5
found: 2026-11-26
neojac: 0.4.0
command: neojac docs search "file storage"
code:
---

## Symptom
linkding keeps page snapshots, uploaded assets, favicons and preview images as files in folders (`LD_ASSET_FOLDER`, `LD_FAVICON_FOLDER`). neojac 0.4.0 has no abstraction for that: `neojac docs apps/plugins`, "The abstractions", lists `store`, `auth`, `transport`, `llm`, `jobs`, `schedule`, `limits`, `ui` and `bundler`, and none keeps files or blobs for an app. The searches `neojac docs search "file storage"`, `"files abstraction"`, `"store a file"`, `"large file"`, `"blob"`, `"object storage"` and `"upload"` (run 2026-11-26) found no page on an app keeping files through the platform: the hits are the native file libraries (`library/files`), `sqlite3` blobs, `neojac browse upload` and memory pages. A program can write files itself with the native libraries, and `neojac docs apps/data` "Where it is kept" names an app data directory, but no page read says how app code (not a plugin: `Host.data_dir()` is a plugin's, `apps/plugins`) asks for that directory.

## Repro
```sh
neojac --version                      # neojac 0.4.0 (linux-x86_64, bdb6b2746f64)
neojac docs apps/plugins              # section "The abstractions": nine rows, no files
neojac docs search "file storage"
neojac docs search "blob"
neojac docs search "object storage"
```

## Expected
Not promised by the docs, so a limitation: a way for an app to keep bytes outside the graph (a `files` abstraction with a plugin, or a documented app data directory), as linkding does.

## Workaround
Bytes are kept as base64 text in a `str` field of a node, through `root` (`Asset.data`, `Favicon.data`), marked `WORKAROUND(GAP-049)`. A `bytes` field also persisted in a spike (PLAN.md, M5), but base64 `str` is what crosses from a job and to the transport. Not tested: how large an asset can be (nothing over a small fixture page was stored), memory use with many assets (`apps/data` "What of the graph is in memory": a node comes with its fields), or the cost of rewriting the graph.

## Cause
Unknown.
