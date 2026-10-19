#!/bin/bash
# Installs the launchd agents that run sync.sh. Safe to re-run.
set -euo pipefail
dir="$(cd "$(dirname "$0")" && pwd)"
agents="$HOME/Library/LaunchAgents"
domain="gui/$(id -u)"

git -C "$dir" config user.email 84456448+avaashh@users.noreply.github.com

# Replaced by the push/pull pair below.
launchctl bootout "$domain/com.avaashh.zed-config-sync" 2>/dev/null || true
rm -f "$agents/com.avaashh.zed-config-sync.plist"

install_agent() {
  local mode=$1 trigger=$2
  local label=com.avaashh.zed-config-$mode
  cat > "$agents/$label.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$label</string>
  <key>ProgramArguments</key>
  <array>
    <string>$dir/sync.sh</string>
    <string>$mode</string>
  </array>
$trigger
  <key>StandardOutPath</key>
  <string>$HOME/Library/Logs/zed-config-sync.log</string>
  <key>StandardErrorPath</key>
  <string>$HOME/Library/Logs/zed-config-sync.log</string>
</dict>
</plist>
EOF
  launchctl bootout "$domain/$label" 2>/dev/null || true
  launchctl bootstrap "$domain" "$agents/$label.plist"
}

install_agent push "  <key>WatchPaths</key>
  <array>
    <string>$dir</string>
    <string>$dir/settings.json</string>
    <string>$dir/keymap.json</string>
    <string>$dir/themes</string>
  </array>"

# launchd rather than cron: a run missed while the Mac sleeps fires on wake.
install_agent pull "  <key>StartCalendarInterval</key>
  <dict>
    <key>Hour</key>
    <integer>8</integer>
    <key>Minute</key>
    <integer>0</integer>
  </dict>"
