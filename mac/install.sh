#!/usr/bin/env bash
# Load the Multica refresh job into launchd for the current user.
set -euo pipefail
cd "$(dirname "$0")"
chmod +x multica-refresh.sh
dst="$HOME/Library/LaunchAgents/com.jackon.multica-refresh.plist"
sed "s|__HOME__|$HOME|g" com.jackon.multica-refresh.plist > "$dst"
launchctl bootout "gui/$(id -u)" "$dst" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$dst"
launchctl print "gui/$(id -u)/com.jackon.multica-refresh" | grep -E 'state|run interval'
