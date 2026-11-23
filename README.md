# linkjac

[linkding](https://github.com/sissbruecker/linkding) (a bookmark manager) rebuilt in Jac with neojac, as a dogfooding exercise. The point is the list of what neojac could not do, published at the project's GitHub Pages site.

## Setup (once)

Needs `git`, `curl` and Python 3 on Linux or WSL2. To build the app, install neojac: `curl -fsSL https://github.com/jaseci-labs/neojac/releases/latest/download/install.sh | bash`. The original linkding is cloned into `reference/linkding` at the commit in `reference/PINNED.md`.

The parity test code and the scripts that run it are development tooling kept on the author's machine, not in this repository; `parity/README.md` describes them and `parity/results.json` and `parity/results-port.json` hold the latest counts.

To enable the site: GitHub, Settings, Pages, Source: GitHub Actions. The repo must be public on a free account.

## Working

Each day: do a slice of the current milestone in `PLAN.md`, log what neojac could not do in `gaps/`, add a short `journal/YYYY-MM-DD.md`, then commit and push. The site updates in about a minute. `python3 tools/gaps.py update` prints the text for the team; `python3 tools/gaps.py check` must pass.

## Layout

| Path | Holds |
|---|---|
| `PLAN.md` | Milestones and status |
| `gaps/` | One file per gap; `_TEMPLATE.md` and `_EXAMPLE.md` show the form |
| `journal/` | One short file per working day |
| `parity/` | Description of the parity checks and their latest counts (the test code is not published) |
| `app/` | The Jac project |
| `reference/` | The original app, read-only |
| `arch.svg` | Architecture picture from `neojac arch`, shown on the site |
| `tools/gaps.py` | `new`, `check`, `status`, `update`, `map`, `site` |

Preview the site: `uv run --with markdown python tools/gaps.py site` then open `site/index.html`.

linkding is MIT licensed, copyright Sascha Ißbrücker. Keep its notice with any code derived from it.
