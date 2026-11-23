#!/usr/bin/env bash
# One-time setup, run from the repo root. Safe to run again.
set -euo pipefail
cd "$(dirname "$0")/.."

need() { command -v "$1" >/dev/null || { echo "missing: $1 ($2)"; exit 1; }; }
need git "sudo apt install git"
need curl "sudo apt install curl"
need uv "https://docs.astral.sh/uv/getting-started/installation/"

# 1. neojac, latest release
if ! command -v neojac >/dev/null; then
  curl -fsSL https://github.com/jaseci-labs/neojac/releases/latest/download/install.sh | bash
  export PATH="$HOME/.local/bin:$PATH"
fi
neojac --version

# 2. neojac's playbooks, in .claude/skills
neojac skills install --to .claude/skills

# 3. the original app, read-only reference
if [ ! -d reference/linkding ]; then
  git clone https://github.com/sissbruecker/linkding reference/linkding
fi
pinned=$(sed -n 's/^Pinned commit: //p' reference/PINNED.md)
if [[ $pinned =~ ^[0-9a-f]{40}$ ]]; then
  git -C reference/linkding checkout -q "$pinned"
fi
commit=$(git -C reference/linkding rev-parse HEAD)
echo "linkding at $commit"
if grep -q "_not set_" reference/PINNED.md; then
  sed -i "s/^Pinned commit: .*/Pinned commit: $commit/; s/^Pinned on: .*/Pinned on: $(date +%F)/" reference/PINNED.md
fi

# 4. what the original needs to run in M0
if ! command -v node >/dev/null && command -v fnm >/dev/null; then eval "$(fnm env)"; fi
command -v node >/dev/null || echo "note: Node is missing. The original's frontend build needs it (try: curl -fsSL https://fnm.vercel.app/install | bash; fnm install --lts)"
echo "done. Next: commit."
