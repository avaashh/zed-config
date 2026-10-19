#!/bin/bash
# sync.sh push: run by launchd on changes to ~/.config/zed. Commits and pushes.
# sync.sh pull: run by launchd every morning. Rebases onto origin/main, then pushes.
set -euo pipefail
cd "$(dirname "$0")"

commit() {
  git add -A
  local changed
  changed=$(git diff --cached --name-only)
  [ -z "$changed" ] && return
  if [ "$(wc -l <<<"$changed")" -eq 1 ]; then
    git commit -qm "Update $changed"
  else
    git commit -qm "Update zed config"
  fi
}

push_if_ahead() {
  if [ -n "$(git log origin/main..main --oneline)" ]; then
    git push -q origin main
  fi
}

case "${1:-}" in
  push)
    # Let multi-file saves settle into one commit.
    sleep 5
    commit
    # Rejected when another Mac pushed since this morning; the next pull retries it.
    push_if_ahead || echo "$(date): push rejected, will retry after the morning pull" >&2
    ;;
  pull)
    commit
    git fetch -q origin
    if ! git rebase -q origin/main; then
      git rebase --abort
      echo "$(date): rebase onto origin/main conflicted, resolve by hand" >&2
      exit 1
    fi
    push_if_ahead
    ;;
  *)
    echo "usage: $0 push|pull" >&2
    exit 2
    ;;
esac
