---
id: GAP-038
title: neojac test says 'the test runner failed to build' for modules that build and pass in the next run, with no diagnostic
kind: bug
severity: minor
status: open
area: test
milestone: M3
found: 2026-11-23
neojac: 0.4.0
command: capped --mem 4G -- neojac test (run in app/)
code:
---

## Symptom
Twice, `neojac test` in `app/` (under `capped --mem 4G`) reported modules as not built, with no diagnostic, and the very next run of the same sources passed.
1. After the refactor edits: `32 passed; 8 of 10 modules passed`, `FAILED rest.jac (did not build)`, `FAILED rest_forms.jac (did not build)`. Only the last six lines of output were read, so any message above them is unknown.
2. After adding the Netscape modules and tests, with the full output read: for `netscape_import.jac`, `netscape_parse.jac` and `search.jac` the only text was `<module>.jac: the test runner failed to build`. No error code, file or line. The same run also had two real test failures (`clock.jac`, `netscape_export.jac`), which were printed with a traceback.
Both times the next `neojac test` (and `neojac test netscape_parse.test.jac` alone) passed all those modules, with no source change in between.
3. M4, 2026-11-23: the first `capped --mem 4G -- neojac test` after adding `web_tags.jac`, `impl/web_tags.impl.jac`, `rename_tag` (in `tags.jac`) and a test in `tags.test.jac` (and the `ui/` and `pages/` modules around them) ended with `FAILED netscape_export.jac (did not build)`, `FAILED netscape_parse.jac (did not build)`, `FAILED rest.jac (did not build)`. Only the last three lines were read (the command tailed its output), so any message above is unknown: the "capture full output" step of the note below was not followed in this run. The next run, with the full output kept in `~/.claude-scratch/linkjac/gap-038-run2.log` and no server or neojac process running (`pgrep` and `ss` showed none), was `59 passed; 13 of 13 modules passed in 11.3s`, with no source change in between. The modules named are not the ones edited. What ran just before the first test run: `neojac check` (clean) and `neojac fmt` on several files.

Not reproduced in three later tries (after occurrence 2): a full run after `touch` of every `.jac` and removal of `.jac/cache`, at `--mem 4G` and at `--mem 8G` (13 of 13 modules passed each time).

4. M4 S5, 2026-11-23, `neojac test web_actions.test.jac`: `web_actions.jac: the test runner failed to build`, `0 passed; 0 of 1 module passed`. This time the full output was read: above that line the run had printed the real diagnostics (`W2001 unknown name 'create_bookmark'` four times, with file, line and caret). So a "failed to build" line can follow ordinary diagnostics, and occurrences 1 and 3 (read through `tail` only) may have had diagnostics above the lines that were read. It does not explain occurrence 2 (full output read, no diagnostic) or the reruns that passed with no source change.

## Repro
```sh
neojac --version                      # neojac 0.4.0 (linux-x86_64, bdb6b2746f64)
cd app
capped --mem 4G -- neojac test        # first run after editing several modules and tests, at least one test failing
```
Could not be made to fail on demand; the repro above is the circumstance, not a recipe.

## Expected
`neojac docs apps/stdjac` and `neojac help test` were not found to say what "failed to build" means for a module. A diagnostic of the kind `neojac check` prints (code, file, line) was expected, or no failure.

## Next time
Capture the full output (`... 2>&1 | tee ~/.claude-scratch/linkjac/gap-038-run.log`) and note whether any server or other `neojac` process was running at the time (`pgrep -a 'neojac|api-linux|cli-linux'`). The two runs above were made without either: the first was read from its last six lines only, and for the second it was not noted whether a served binary was still up from a parity run.

## Workaround
Rerun `neojac test`. Nothing in the code.

## Cause
Unknown.

## Runs since 2026-11-23 (full output kept in `~/.claude-scratch/linkjac/test-2026-11-23.log`)
Each run is made through `~/.claude-scratch/linkjac/ntest.sh`, which appends `neojac test`'s whole output to the day's log, and first records `pgrep` for neojac, `api-linux`, `cli-linux`, `manage.py`, `vite` and `bun`, and how many sockets listen on 8000, 8010 and 5173. The served binaries are named `api` and `cli` inside `dist/`, so the `api-linux` pattern does not match them; the listener count is the signal for a server. From the log:
- Run 1 (before the script existed; 60 passed, 13 of 13 modules): whether anything was running before it was not recorded; `pgrep` after it showed nothing.
- Run 2 (20:07, repeat, 60 passed, 13 of 13): no processes, 0 listeners.
- Run 3 (20:20, 60 passed, 13 of 13): no processes, 1 listener (the port server of a mutation run, on 8010).
- Runs 4 and 5 (`neojac test web_actions.test.jac`, failed to build, with diagnostics above the line: see 4): a `neojac build` of another project copy was running (the mutation run's), 0 listeners.
- Run 6 (same file, 2 passed): no processes, 1 listener.
- Run 7 (full, 62 passed, 14 of 14 modules): two `neojac build` processes of the mutation run were running.
No spurious "did not build" in these seven runs (the two "did not build" were real errors). A running server (run 3, 6) and a running `neojac build` of another directory (run 7) did not stop a run passing.
- Runs 8 and 9 (full, 62 passed, 14 of 14 modules; both answered from the cache in 0.09 s after comment-only edits): no processes, 0 listeners for run 9; run 8 had 1 listener (a mutation run's server). Still no spurious "did not build".
- Runs 10 and 11 (2026-11-23, M5 session, `neojac test -k tag` in `app/`, made by hand, not through `ntest.sh`, so no `pgrep` record; the original (port 8000) and the port's served binary (port 8010) were both up, and a `neojac build` had finished some minutes before; the sources of `ui/impl/*` and `impl/tags.impl.jac` had just been edited): run 10 printed `FAILED` with `(did not build)` for `bookmarks.jac`, `rest_forms.jac`, `search.jac`, `search_expression.jac` (only the last four lines were read); run 11, the same command, `rest_forms.jac: the test runner failed to build` with no diagnostic, the other 7 modules of 8 passed (18 passed). A full run through `ntest.sh` right after: 62 passed, 14 of 14 modules. So 2 spurious failures in a row, then none; both servers were running during the failures (earlier runs with one server up passed).
- Run 12 (2026-11-23 22:09, M5 slice S1, full run through `ntest.sh`, 16 modules, none of them cached after edits to `archwire.jac`, 3 new modules and 2 new test files; no neojac, server or listener running before it): 58 passed, 15 of 16 modules, `rest.jac: the test runner failed to build` with no diagnostic in the whole log. The same module alone right after (`neojac test rest.test.jac`): 7 passed in 20.6 s. The run took 55 s (the earlier cached runs 9 s). Guess, not checked: it happens on a run that builds many modules at once, the first run after sources change; runs 10 and 11 were also the first after edits.
