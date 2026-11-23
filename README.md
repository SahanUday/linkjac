# linkjac

[linkding](https://github.com/sissbruecker/linkding) (a bookmark manager) rebuilt in Jac with neojac, as a dogfooding exercise. The point is the list of what neojac could not do, published at the project's GitHub Pages site.

## Setup (once)

Needs `git`, `curl`, `uv` and Python 3 on Linux or WSL2. linkding's frontend build also needs Node (`fnm install --lts`).

```sh
git clone <this repo> && cd linkjac
bash tools/setup.sh        # installs neojac, clones linkding at the pinned commit
git add -A && git commit -m "Pin linkding"
```

Then enable the site: GitHub, Settings, Pages, Source: GitHub Actions. The repo must be public on a free account.

## Working

Each day: do a slice of the current milestone in `PLAN.md`, log what neojac could not do in `gaps/`, add a short `journal/YYYY-MM-DD.md`, then commit and push. The site updates in about a minute. `python3 tools/gaps.py update` prints the text for the team; `python3 tools/gaps.py check` must pass.

## Layout

| Path | Holds |
|---|---|
| `PLAN.md` | Milestones and status |
| `gaps/` | One file per gap; `_TEMPLATE.md` and `_EXAMPLE.md` show the form |
| `journal/` | One short file per working day |
| `parity/` | Checks that run against the original and the port |
| `app/` | The Jac project |
| `reference/` | The original app, read-only |
| `arch.svg` | Architecture picture from `neojac arch`, shown on the site |
| `tools/gaps.py` | `new`, `check`, `status`, `update`, `map`, `site` |

GitHub's language bar leaves out the test harness (`parity/`) and the site tooling (`tools/gaps.py`, via `.gitattributes`), so it shows the port's own code.

Bytes of source by language (2026-11-23, `.jac` and `.py` files only, no generated or dependency folders):

| Folder | Jac | Python |
|---|---|---|
| `app/` | 128,259 | 0 |
| `plugins/` | 9,784 | 0 |
| `parity/` | 0 | 62,964 |
| `tools/` | 0 | 27,910 |

Preview the site: `uv run --with markdown python tools/gaps.py site` then open `site/index.html`.

linkding is MIT licensed, copyright Sascha Ißbrücker. Keep its notice with any code derived from it.
