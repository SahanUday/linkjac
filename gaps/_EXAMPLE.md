---
id: GAP-000
title: neojac check accepts `impl` whose parameter names differ, then build fails
kind: bug
severity: major
status: worked-around
area: diagnostics
milestone: M1
found: 2026-11-24
neojac: 0.4.0
command: neojac check store.jac
code: W3010
---

<!-- An illustration of the level of detail wanted. Not a real finding. Not read by the tools. -->

## Symptom
`neojac check` passes, but `neojac build` stops with an error about the impl signature.

## Repro
Two files. Run the commands from the folder that holds both.

```sh
neojac --version
neojac check store.jac      # prints nothing
neojac build store.jac -o store
```

```jac
# store.jac
obj Shelf { def add(name: str, n: int = 1); }
# impl/store.impl.jac
impl Shelf.add(item: str, n: int = 1) { }
```

## Expected
`check` and `build` agree. `neojac docs W3010` says an impl that renames a parameter is reported by check.

## Workaround
Copied each declaration's signature into its impl. Marked in code with `WORKAROUND(GAP-000)`.

## Cause
Guess: `check` and `build` do not share one phase for impl signatures.
