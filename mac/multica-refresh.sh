#!/usr/bin/env bash
# Re-sign and install the latest Multica IPA over Wi-Fi with xtool; free-account signatures last 7 days.
set -euo pipefail
export PATH=/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin

repo=JackonYang/multica-ios-build
state="$HOME/Library/Application Support/multica-refresh"
mkdir -p "$state"
refresh_after=$((3 * 86400))  # re-sign well inside the 7-day window
warn_after=$((5 * 86400))

notify() { terminal-notifier -title "Multica 续签" -message "$1" -group multica-refresh >/dev/null 2>&1 || true; }
log() { echo "$(date '+%F %T') $*"; }
# Release assets through the API with gh's token, so this keeps working once the repo is private.
# curl does the transfer, not gh: gh is a Go binary and ignores the SIGALRM a timeout would send.
asset() {  # $1 = asset name, $2 = curl -m seconds, rest = curl args
  local id
  id=$(jq -r --arg n "$1" '.assets[] | select(.name == $n) | .id' <<<"$release")
  curl -fsSL -m "$2" --retry 2 -H "Authorization: Bearer $token" -H 'Accept: application/octet-stream' \
    "${@:3}" "https://api.github.com/repos/$repo/releases/assets/$id"
}

now=$(date +%s)
last_ok=$(cat "$state/last-success" 2>/dev/null || echo 0)
last_ver=$(cat "$state/last-version" 2>/dev/null || echo none)

token=$(gh auth token) || { log "gh not logged in; run gh auth login"; notify "gh 未登录，无法续签"; exit 0; }
release=$(curl -fsS -m 30 --retry 2 -H "Authorization: Bearer $token" "https://api.github.com/repos/$repo/releases/latest") \
  && src=$(asset source.json 30) || { log "source fetch failed"; exit 0; }
ver=$(jq -r '.apps[0].versions[0].version' <<<"$src")

if (( now - last_ok < refresh_after )) && [ "$ver" = "$last_ver" ]; then
  exit 0
fi

udid=$(cat "$state/udid" 2>/dev/null || true)
dev_args=(--network)
[ -n "$udid" ] && dev_args+=(-u "$udid")

ipa="$state/Multica-$ver.ipa"
if [ ! -s "$ipa" ]; then
  asset "Multica-$ver.ipa" 900 -o "$ipa.part" && mv -f "$ipa.part" "$ipa" \
    || { log "ipa download failed"; exit 0; }
fi

log "installing $ver"
# A locked phone drops off Wi-Fi for minutes at a time, so let xtool wait for it; alarm bounds the wait.
rc=0
# Exec the app binary directly: the brew wrapper forks it, so alarm would orphan the real process.
XTL_CLI=1 perl -e 'alarm shift; exec @ARGV' 600 /Applications/xtool.app/Contents/MacOS/xtool \
  install "${dev_args[@]}" "$ipa" </dev/null || rc=$?
if (( rc == 0 )); then
  echo "$now" > "$state/last-success"
  echo "$ver" > "$state/last-version"
  find "$state" -name 'Multica-*.ipa' ! -name "Multica-$ver.ipa" -delete
  [ "$ver" != "$last_ver" ] && notify "已安装 Multica $ver"
  log "ok"
elif (( rc == 142 )); then  # SIGALRM: phone never showed up
  log "phone not on this network"
  if (( now - last_ok > warn_after )) && [ ! -e "$state/warned-$last_ok" ]; then
    notify "已超过 5 天没续签。让手机和 Mac 连同一个 Wi-Fi。"
    touch "$state/warned-$last_ok"
  fi
else
  notify "续签失败，看 ~/Library/Logs/multica-refresh.log"
  log "install failed rc=$rc"
fi
