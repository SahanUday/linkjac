# Parity checks

Black-box checks that run the same requests against the original linkding and the Jac port, and compare the answers.

- Build them in M0, against the original only. They must pass there before any Jac exists.
- Written in Python with `pytest` and `httpx` (API) and Playwright (UI). They are our tooling, not part of the port.
- The target is a base URL: `LINKDING_URL=http://127.0.0.1:8000 pytest parity/` for the original, another URL for the port.
- One command runs everything and writes `parity/results.json` as `{"passed": n, "total": m}`: `parity/run.sh`.
- Compare behaviour that a user or API client can see: status codes, JSON fields, filters, ordering, error bodies, redirects, rendered text. Ignore ids, timestamps and ordering the original does not promise.
- A check that cannot pass on the port is never deleted or skipped. Log the gap, and mark the check `expected_gap("GAP-nnn")` so it still runs.
