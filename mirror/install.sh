#!/usr/bin/env bash
# Install the mirror on jackon.me: run from this repo on the Mac.
set -euo pipefail
host=${1:-jackon}
cd "$(dirname "$0")"
ssh "$host" mkdir -p bin
scp -q multica-ios-sync.sh "$host:bin/multica-ios-sync.sh"
ssh "$host" 'set -e
  sudo mkdir -p /mnt/data/blog-server/multica-ios
  sudo chown "$USER": /mnt/data/blog-server/multica-ios
  mkdir -p ~/logs && chmod +x ~/bin/multica-ios-sync.sh
  ~/bin/multica-ios-sync.sh
  # grep -v exits 1 on an empty crontab; under set -e that would install an empty one.
  (crontab -l 2>/dev/null | grep -v multica-ios-sync || true
   echo "*/30 * * * * $HOME/bin/multica-ios-sync.sh >> $HOME/logs/multica-ios-sync.log 2>&1") | crontab -
  crontab -l | grep multica-ios-sync'
