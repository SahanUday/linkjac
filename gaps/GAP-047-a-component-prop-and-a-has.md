---
id: GAP-047
title: A component prop and a has of the same name pass neojac check, then neojac build fails in the bundle: The symbol already been declared
kind: bug
severity: minor
status: worked-around
area: ui
milestone: M4
found: 2026-11-23
neojac: 0.4.0
command: neojac build
code:
---

## Symptom
`BookmarkForm(url: str = "")` with `has url: str = url;` in its body passes `neojac check` with no diagnostic. `neojac build` then fails in the bundler (about 190 ms in) with `[vite:esbuild] Transform failed with 1 error: ...src/ui/bookmark_form.jsx:23:11: ERROR: The symbol "url" has already been declared`. The generated line it points at is `const [url, setUrl] = $state(url);`, next to `let unread0 = $props["unread0"];` for another prop. Found by a gap audit's question, then tried in a scratch copy of `app/` (`~/.claude-scratch/`), changing only the `url` prop and its one caller. The other props keep a `0` suffix in `app/` for this reason: that was the earlier choice, made without a gap file (found now).

## Repro
```sh
neojac --version                      # neojac 0.4.0 (linux-x86_64, bdb6b2746f64)
# in a browser-space component: def:pub C(url: str = "") -> JsxElement; impl C(url: str = "") -> JsxElement { has url: str = url; return <input value={url} />; }
neojac check                          # clean
neojac build                          # Build failed ... The symbol "url" has already been declared
```
Only this one component was tried; the exact generated text was read from the build output.

## Expected
`neojac check` to refuse it, or the build to work. `neojac docs apps/components` ("Props") was read for a rule on a `has` with a prop's name; this was not looked for in every page.

## Workaround
Props are named `url0`, `tags0`, ... and copied into `has url = url0` (`WORKAROUND(GAP-047)` in `app/ui/bookmark_form.jac` and `app/ui/impl/bookmark_form.impl.jac`).

## Cause
Unknown. Guess: the generated code declares the state with the prop's name in the same scope.
