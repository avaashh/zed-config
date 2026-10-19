#!/bin/bash
# Installs the launchd agent that runs sync.sh. Safe to re-run.
set -euo pipefail
dir="$(cd "$(dirname "$0")" && pwd)"
label=com.avaashh.zed-config-sync
plist="$HOME/Library/LaunchAgents/$label.plist"

git -C "$dir" config user.email 84456448+avaashh@users.noreply.github.com

cat > "$plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$label</string>
  <key>ProgramArguments</key>
  <array>
    <string>$dir/sync.sh</string>
  </array>
  <key>WatchPaths</key>
  <array>
    <string>$dir</string>
    <string>$dir/settings.json</string>
    <string>$dir/keymap.json</string>
    <string>$dir/themes</string>
  </array>
  <key>StartInterval</key>
  <integer>3600</integer>
  <key>StandardOutPath</key>
  <string>$HOME/Library/Logs/zed-config-sync.log</string>
  <key>StandardErrorPath</key>
  <string>$HOME/Library/Logs/zed-config-sync.log</string>
</dict>
</plist>
EOF

launchctl bootout "gui/$(id -u)/$label" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$plist"
