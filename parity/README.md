# Parity checks

Black-box checks that run the same requests against the original linkding and the Jac port, and compare the answers.

- Build them in M0, against the original only. They must pass there before any Jac exists.
- Written in Python with `pytest` and `httpx` (API) and Playwright (UI). They are our tooling, not part of the port.
- Run them through uv so nothing is installed globally: `uv run --with pytest --with httpx --with playwright pytest parity/` (Playwright also needs its browsers: `uv run --with playwright playwright install chromium`).
- The target is a base URL: `LINKDING_URL=http://127.0.0.1:8000 pytest parity/` for the original, another URL for the port.
- One command runs everything and writes `{"passed": n, "total": m}`: `parity/run.sh`. Against the original (default) it writes `parity/results.json`; `PARITY_TARGET=port parity/run.sh` builds `app/`, serves it on a fresh data directory, registers a `parity` user through `/__jac/auth/register` and writes `parity/results-port.json`. Report the two counts separately: the original's is the baseline, the port's is parity.
- Compare behaviour that a user or API client can see: status codes, JSON fields, filters, ordering, error bodies, redirects, rendered text. Ignore ids, timestamps and ordering the original does not promise.
- A check that cannot pass on the port is never deleted or skipped. Log the gap, and mark the check `expected_gap("GAP-nnn")` so it still runs.
