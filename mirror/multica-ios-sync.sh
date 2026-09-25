#!/usr/bin/env bash
# Mirror the latest release to jackon.me so the phone never has to reach GitHub.
set -euo pipefail
repo=JackonYang/multica-ios-build
dest=/mnt/data/blog-server/multica-ios
base=https://jackon.me/multica-ios
tmp=$(mktemp -d "$dest/.tmp.XXXXXX"); trap 'rm -rf "$tmp"' EXIT

curl -fsSL -m 60 --retry 3 -o "$tmp/source.json" "https://github.com/$repo/releases/latest/download/source.json"
ver=$(jq -r '.apps[0].versions[0].version' "$tmp/source.json")
ipa="Multica-$ver.ipa"
if [ ! -s "$dest/$ipa" ]; then
  curl -fsSL -m 900 --retry 3 -o "$tmp/$ipa" "$(jq -r '.apps[0].versions[0].downloadURL' "$tmp/source.json")"
  [ "$(stat -c%s "$tmp/$ipa")" = "$(jq -r '.apps[0].versions[0].size' "$tmp/source.json")" ] \
    || { echo "size mismatch for $ipa" >&2; exit 1; }
  mv "$tmp/$ipa" "$dest/$ipa"
  echo "$(date -Is) mirrored $ipa"
fi
[ -s "$dest/icon.png" ] || curl -fsSL -m 60 --retry 3 -o "$dest/icon.png" "$(jq -r '.apps[0].iconURL' "$tmp/source.json")"

jq --arg ipa "$base/$ipa" --arg icon "$base/icon.png" \
  '.apps[0].versions[0].downloadURL = $ipa | .apps[0].iconURL = $icon' "$tmp/source.json" > "$tmp/out.json"
cmp -s "$tmp/out.json" "$dest/source.json" || mv "$tmp/out.json" "$dest/source.json"
# SideStore only needs the current version; keep one older IPA for rollback.
ls -1t "$dest"/Multica-*.ipa | tail -n +3 | xargs -r rm -f
