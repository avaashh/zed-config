#!/bin/bash
# Run by launchd (com.avaashh.zed-config-sync) on changes to ~/.config/zed and hourly.
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

git fetch -q origin
if ! git rebase -q origin/main; then
  git rebase --abort
  echo "$(date): rebase onto origin/main conflicted, resolve by hand" >&2
  exit 1
fi

if [ -n "$(git log origin/main..main --oneline)" ]; then
  git push -q origin main
fi
