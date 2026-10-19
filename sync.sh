#!/bin/bash
# Run by launchd (com.avaashh.zed-config-sync) whenever ~/.config/zed changes.
set -euo pipefail
cd "$(dirname "$0")"

# Let multi-file saves settle into one commit.
sleep 5

git add -A
changed=$(git diff --cached --name-only)
if [ -n "$changed" ]; then
  if [ "$(wc -l <<<"$changed")" -eq 1 ]; then
    git commit -qm "Update $changed"
  else
    git commit -qm "Update zed config"
  fi
fi

if [ -n "$(git log origin/main..main --oneline)" ]; then
  git push -q origin main
fi
