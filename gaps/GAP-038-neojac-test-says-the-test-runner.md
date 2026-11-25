---
id: GAP-038
title: neojac test builds one module per core whatever the memory allows; a build the kernel kills is reported only as 'the test runner failed to build'
kind: bug
severity: major
status: worked-around
area: test
milestone: M3
found: 2026-11-23
neojac: 0.4.0
command: capped --mem 4G -- neojac test (run in app/)
code:
---

## Symptom
`neojac test` reports modules as `<module>.jac: the test runner failed to build` and `FAILED <module>.jac (did not build)` with no diagnostic, no signal and no word about memory, and a later run of the same sources passes. Reproduced on purpose on 2026-11-26: when the run has a memory limit, the kernel kills build processes for running out of memory (`dmesg`: `neojac invoked oom-killer`, `Memory cgroup out of memory: Killed process ... (neojac)`), and each such module is reported that way. By default the runner builds one module for each core (12 here); one cold build of a trivial module peaked at about 1.5 GB. A rerun passes more often because the modules already built are cached, so fewer are built at once.

## Repro
Minimal: 12 modules that each hold one function and one test, on a 12-core machine, in a 2 GB memory cgroup (`capped` is a `systemd-run --user --scope -p MemoryMax=...` wrapper).

```sh
neojac --version                      # neojac 0.4.0 (linux-x86_64, bdb6b2746f64)
mkdir gap038 && cd gap038
printf '[project]\nname = "gap038"\narchwire = false\n\n[check.lint]\nignore = ["strip-comments", "strip-docstrings"]\n\n[test]\ndirectories = ["."]\n' > jac.toml
for i in $(seq 12); do printf '"""Module %s."""\n\nimport json;\nimport re;\n\ndef f%s(n: int) -> str {\n    return json.dumps({"n": re.sub("a", "b", str(n))});\n}\n\ntest "f%s" {\n    assert f%s(1);\n}\n' $i $i $i $i > m$i.jac; done
NEOJAC_CACHE_DIR=$(mktemp -d) systemd-run --user --scope -p MemoryMax=2G -p MemorySwapMax=0 -- neojac test        # 0 of 12 modules passed, 12 "did not build"; cgroup memory.events oom_kill 12
rm -rf .jac
NEOJAC_CACHE_DIR=$(mktemp -d) systemd-run --user --scope -p MemoryMax=2G -p MemorySwapMax=0 -- neojac test -j 1   # 12 of 12 passed, peak 1534 MiB, oom_kill 0
```

Measured 2026-11-26 (`oom_kill` and `memory.peak` of the run's cgroup):

| Project | Cap, jobs | Runs | Modules reported "did not build" | oom_kill |
|---|---|---|---|---|
| 12 trivial modules, cold | 2G, default (12) | 1 | 12 of 12 | 12 |
| 12 trivial modules, cold | 2G, `-j 1` | 1 | 0 | 0 (peak 1534 MiB) |
| 12 trivial modules, cold | 1G, `-j 1` | 1 | 12 of 12 | 16 (one build does not fit) |
| `app/`, after an edit to `clock.jac` (13 to build) | 4G, default | 3 | 7, 5, 6 of 19 | 7, 5, 6 |
| same | 8G, default | 3 | 1, 1, 2 of 19 | 1, 1, 2 |
| same | 4G, `-j 4` | 3 | 0, 0, 0 | 0 (peaks 3522, 3880, 4029 MiB) |

The three runs of the 4G default row are the "edit a file, run the full test, three times" trials: logs `~/.claude-scratch/linkjac/gap038-edit{1,2,3}-4g.log`, made by `~/.claude-scratch/linkjac/gap038-trial.sh`. The same day a natural occurrence came first (5 modules, then 1 on the rerun, after an edit to `archwire.jac`; kernel log: 5 kills at 01:24, 1 at 01:25).

The earlier occurrences (below) against the user journal's "killed by the OOM killer" lines: kills at 15:47, 16:24, 19:49, 21:35 to 21:36, 22:09, 22:49 and 23:01 to 23:02 on 2026-11-23, the times of the spurious failures. Counts match for occurrences 1 to 3 and runs 12 and 13; the runs at 23:01 and 23:02 reported more modules (11 and 3) than there are kill lines (4 and 2), which is not explained.

Without a memory limit the 12 builds were not run; on a machine with little free memory the same is expected (guess).

## Expected
`neojac help test` and `neojac docs toolchain/test` give `-j` its default, one per core, and say nothing about memory. A runner whose build process is killed should say so (the signal, or "out of memory"), as a diagnostic or a line naming it, and the default job count could take available memory (the cgroup's limit) into account.

## Workaround
`neojac test -j 3` under the 4 GB cap (`WORKAROUND(GAP-038)` in `app/jac.toml`; the working rule is in PLAN.md). `-j 4` passed three times but peaked at the cap, so 3 is used.

## Cause
Guess: the build processes are killed by the kernel (shown by the kernel log and `memory.events`), and the runner turns any build process that dies into "failed to build" without looking at how it died. The second half was not checked in neojac.

## History before the cause was found (2026-11-23)
Twice, `neojac test` in `app/` (under `capped --mem 4G`) reported modules as not built, with no diagnostic, and the very next run of the same sources passed.
1. After the refactor edits: `32 passed; 8 of 10 modules passed`, `FAILED rest.jac (did not build)`, `FAILED rest_forms.jac (did not build)`. Only the last six lines of output were read, so any message above them is unknown.
2. After adding the Netscape modules and tests, with the full output read: for `netscape_import.jac`, `netscape_parse.jac` and `search.jac` the only text was `<module>.jac: the test runner failed to build`. No error code, file or line. The same run also had two real test failures (`clock.jac`, `netscape_export.jac`), which were printed with a traceback.
Both times the next `neojac test` (and `neojac test netscape_parse.test.jac` alone) passed all those modules, with no source change in between.
3. M4, 2026-11-23: the first `capped --mem 4G -- neojac test` after adding `web_tags.jac`, `impl/web_tags.impl.jac`, `rename_tag` (in `tags.jac`) and a test in `tags.test.jac` (and the `ui/` and `pages/` modules around them) ended with `FAILED netscape_export.jac (did not build)`, `FAILED netscape_parse.jac (did not build)`, `FAILED rest.jac (did not build)`. Only the last three lines were read (the command tailed its output), so any message above is unknown: the "capture full output" step of the note below was not followed in this run. The next run, with the full output kept in `~/.claude-scratch/linkjac/gap-038-run2.log` and no server or neojac process running (`pgrep` and `ss` showed none), was `59 passed; 13 of 13 modules passed in 11.3s`, with no source change in between. The modules named are not the ones edited. What ran just before the first test run: `neojac check` (clean) and `neojac fmt` on several files.

Not reproduced in three later tries (after occurrence 2): a full run after `touch` of every `.jac` and removal of `.jac/cache`, at `--mem 4G` and at `--mem 8G` (13 of 13 modules passed each time).

4. M4 S5, 2026-11-23, `neojac test web_actions.test.jac`: `web_actions.jac: the test runner failed to build`, `0 passed; 0 of 1 module passed`. This time the full output was read: above that line the run had printed the real diagnostics (`W2001 unknown name 'create_bookmark'` four times, with file, line and caret). So a "failed to build" line can follow ordinary diagnostics, and occurrences 1 and 3 (read through `tail` only) may have had diagnostics above the lines that were read. It does not explain occurrence 2 (full output read, no diagnostic) or the reruns that passed with no source change.

### Runs since 2026-11-23 (full output kept in `~/.claude-scratch/linkjac/test-2026-11-23.log`)
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
- Run 12 (2026-11-23 22:09, M5 slice S1, full run through `ntest.sh`, 16 modules, none of them cached after edits to `archwire.jac`, 3 new modules and 2 new test files; no neojac, server or listener running before it): 58 passed, 15 of 16 modules, `rest.jac: the test runner failed to build` with no diagnostic in the whole log. The same module alone right after (`neojac test rest.test.jac`): 7 passed in 20.6 s. The run took 55 s (the earlier cached runs 9 s). Guess at the time: it happens on a run that builds many modules at once, the first run after sources change; runs 10 and 11 were also the first after edits.
- Run 13 (22:49, M5 slice S3, through `ntest.sh`, 17 modules; nothing running before; sources had just changed: new `Bookmark.favicon_file`, 7 new modules, an edited `archwire.jac`): 38 passed, 12 of 17 modules, `the test runner failed to build` for `bookmarks`, `netscape_export`, `netscape_import`, `rest`, `search`, with no diagnostic. `neojac test bookmarks.test.jac` alone right after: 6 passed. A second full run (cached): 68 passed, 17 of 17. A third, with `NEOJAC_CACHE_DIR` pointed at an empty directory (that run took 1 m 37 s, so it was a cold build, all modules in parallel under the 4 GB cap, 12 cores): 68 passed, 17 of 17, no failure. So a cold full build does not by itself fail; 3 of the 4 failures of this session (runs 10, 12, 13) came on the first full run after an edit to `archwire.jac` or to a module several others import. Guess: a stale cache entry for a module whose dependency changed. Not checked.
