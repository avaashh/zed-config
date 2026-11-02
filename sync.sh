#!/bin/bash
# sync.sh push: run by launchd on changes to Zed or T3 config. Commits and pushes.
# sync.sh pull: run by launchd every morning. Rebases onto origin/main, applies T3 config, then pushes.
set -euo pipefail
cd "$(dirname "$0")"

t3_userdata="$HOME/.t3/userdata"

t3_files() {
  {
    printf '%s\n' settings.json keybindings.json client-settings.json
    (cd "$t3_userdata" && ls themes/*.json 2>/dev/null) || true
    ls t3/themes/*.json 2>/dev/null | sed 's|^t3/||' || true
  } | sort -u
}
# Last version this Mac synced, per file. Lets copy_in tell a local edit from a stale copy.
synced=.git/t3-synced
mkdir -p t3/themes "$synced/themes" "$t3_userdata/themes"

t3_running() {
  pgrep -qf 'T3 Code \(Beta\)\.app/Contents/MacOS/'
}

copy_in() {
  local f
  for f in $(t3_files); do
    [ -f "$t3_userdata/$f" ] || continue
    if [ -f "$synced/$f" ]; then
      cmp -s "$t3_userdata/$f" "$synced/$f" && continue
    elif [ -f "t3/$f" ]; then
      # First run on a Mac that pulled the repo's copy: the repo wins on the next pull.
      continue
    fi
    cp "$t3_userdata/$f" "t3/$f"
    cp "$t3_userdata/$f" "$synced/$f"
  done
}

copy_out() {
  local f
  for f in $(t3_files); do
    [ -f "t3/$f" ] || continue
    if ! cmp -s "t3/$f" "$t3_userdata/$f"; then
      # The desktop app holds client settings in memory and would overwrite the file.
      if [ "$f" = client-settings.json ] && t3_running; then
        echo "$(date): T3 is running, client-settings.json applies on a pull after quitting it" >&2
        continue
      fi
      cp "t3/$f" "$t3_userdata/$f.sync-tmp"
      mv "$t3_userdata/$f.sync-tmp" "$t3_userdata/$f"
    fi
    cp "t3/$f" "$synced/$f"
  done
}

commit() {
  git add -A
  local changed
  changed=$(git diff --cached --name-only)
  [ -z "$changed" ] && return
  if [ "$(wc -l <<<"$changed")" -eq 1 ]; then
    git commit -qm "Update $changed"
  else
    git commit -qm "Update config"
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
    copy_in
    commit
    # Rejected when another Mac pushed since this morning; the next pull retries it.
    push_if_ahead || echo "$(date): push rejected, will retry after the morning pull" >&2
    ;;
  pull)
    copy_in
    commit
    git fetch -q origin
    if ! git rebase -q origin/main; then
      git rebase --abort
      echo "$(date): rebase onto origin/main conflicted, resolve by hand" >&2
      exit 1
    fi
    copy_out
    push_if_ahead
    ;;
  *)
    echo "usage: $0 push|pull" >&2
    exit 2
    ;;
esac
