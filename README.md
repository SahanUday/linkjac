# linkjac

[linkding](https://github.com/sissbruecker/linkding) (a bookmark manager) rebuilt in Jac with neojac, as a dogfooding exercise. The point is the list of what neojac could not do, published at the project's GitHub Pages site.

## Setup (once)

Needs `git`, `curl`, `uv` and Python 3 on Linux or WSL2.

```sh
git clone <this repo> && cd linkjac
bash tools/setup.sh        # installs neojac, its skills, clones linkding at a pinned commit
git add -A && git commit -m "Pin linkding"
```

Then enable the site: GitHub, Settings, Pages, Source: GitHub Actions. The repo must be public on a free account.

## Working

Start Claude Code in this folder (`claude`, or the VS Code extension) and paste the first prompt from the kickoff guide. After that, each day:

1. Start a session. A status summary appears on its own.
2. Say what to do: "continue" works, or `/get-bearings` after a break.
3. At the end, Claude writes the journal and pushes. The site updates in about a minute.
4. `/daily-update` gives the text for the team.

## Layout

| Path | Holds |
|---|---|
| `CLAUDE.md` | Rules for Claude Code |
| `PLAN.md` | Milestones and status |
| `gaps/` | One file per gap; `_TEMPLATE.md` and `_EXAMPLE.md` show the form |
| `journal/` | One short file per working day |
| `parity/` | Checks that run against the original and the port |
| `app/` | The Jac project |
| `reference/` | The original app, read-only |
| `arch.svg` | Architecture picture from `neojac arch`, shown on the site |
| `tools/gaps.py` | `new`, `check`, `status`, `update`, `map`, `site` |
| `.claude/` | Settings, hooks, skills, subagents |

Preview the site: `uv run --with markdown python tools/gaps.py site` then open `site/index.html`.

linkding is MIT licensed, copyright Sascha Ißbrücker. Keep its notice with any code derived from it.
