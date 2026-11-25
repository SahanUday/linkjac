---
id: GAP-052
title: App code cannot read who the caller is: only a page's signed_in_as() names them
kind: limitation
severity: major
status: open
area: auth
milestone: M6
found: 2026-11-26
neojac: 0.4.0
command: neojac docs search "caller username"
code:
---

## Symptom
Inside an endpoint the app has the caller's `root` and nothing that names them: no function returns the user id that the auth plugin's `caller()` answered. A page has `await signed_in_as()` (`neojac docs apps/pages`, "Signing in"), which a server function can only be told by its caller, unverified. linkding's API needs the name on the server (`?user=<name>` on the shared list, the owner of a shared bookmark), and its admin commands name a user (GAP-040).

## Repro
```sh
neojac --version                      # neojac 0.4.0 (linux-x86_64, bdb6b2746f64)
neojac docs apps/data                 # "Whose root": root, root.shared, allroots(); no name
neojac docs apps/pages                # "Signing in": signed_in_as() is a page's function
neojac docs search "caller username"
neojac docs search "who is the caller"
```

## Expected
A server-side function giving the current caller's user id (and one giving the root of a user id). No page read has either.

## Workaround
None. `?user=` on `/api/bookmarks/shared/` stays unported. Not tried: the transport asking `GET /__jac/auth/me` with the caller's header and passing the answer to the app as an argument (it would put identity in the transport, and the endpoint it calls can be reached by other callers).

## Cause
Unknown.
