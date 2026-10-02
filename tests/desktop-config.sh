#!/usr/bin/env bash
# Integration checks use a disposable repository and never activate the desktop.
set -euo pipefail
root="$(cd -- "$(dirname -- "$0")/.." && pwd)"
bin="${EROGEDOTS_TEST_BIN:-$root/picker-rs/target/release}"
tmp="$(mktemp -d)"
trap 'rm -rf -- "$tmp"' EXIT
mkdir -p "$tmp/repo/home" "$tmp/repo/themes/templates/niri" "$tmp/repo/scripts" "$tmp/repo/wallpapers" "$tmp/config/theme"
cp "$root/configuration.nix" "$root/flake.lock" "$tmp/repo/"
cp "$root/home/"{moni.nix,desktop-packages.json} "$tmp/repo/home/"
cp "$root/themes/templates/niri/config.kdl" "$tmp/repo/themes/templates/niri/"
cp "$root/scripts/theme-switch" "$tmp/repo/scripts/"
cp -r "$root/themes/harumi" "$tmp/repo/themes/"
printf 'harumi\n' > "$tmp/config/theme/active"
export EROGEDOTS_ROOT="$tmp/repo" XDG_CONFIG_HOME="$tmp/config" XDG_STATE_HOME="$tmp/state"
request() { printf '%s\n' "$1" | "$bin/desktop-config"; }
previous="$(request '{"operation":"read","target":"home"}')"
jq -e '.ok and (.version | length == 64)' <<< "$previous" >/dev/null
save="$(jq -c '{operation:"save",target:"home",version:.version,text:(.text+"\n# integration edit\n")}' <<< "$previous")"
request "$save" | jq -e '.ok' >/dev/null
cmp "$tmp/state/erogedots/config-backups/"* "$root/home/moni.nix"
if request "$save" > "$tmp/stale"; then echo 'Stale write accepted' >&2; exit 1; fi
jq -e '(.ok | not) and (.error | contains("changed elsewhere"))' "$tmp/stale" >/dev/null
fresh="$(request '{"operation":"read","target":"home"}')"
invalid="$(jq -c '{operation:"save",target:"home",version:.version,text:"{ this is broken"}' <<< "$fresh")"
if request "$invalid" > "$tmp/invalid"; then echo 'Invalid Nix accepted' >&2; exit 1; fi
[[ "$(request '{"operation":"read","target":"home"}' | jq -r .version)" == "$(jq -r .version <<< "$fresh")" ]]
for name in 'hello; rm' '../file' 'hello + pkgs.vim'; do
    if request "$(jq -cn --arg name "$name" '{operation:"add",package:$name}')" > "$tmp/rejected"; then echo 'Invalid package accepted' >&2; exit 1; fi
done
before="$(rg -c 'Mod\+' "$tmp/repo/themes/templates/niri/config.kdl")"
request '{"operation":"niri-settings","gaps":12,"focusWidth":3,"columnWidth":60}' | jq -e '.ok and .status.niri == {gaps:12,focusWidth:3,columnWidth:60}' >/dev/null
[[ "$before" == "$(rg -c 'Mod\+' "$tmp/repo/themes/templates/niri/config.kdl")" ]]
# Complete graphical creator request, then a conflicting duplicate.
create="$(jq -cn --arg image "$root/wallpapers/harumi.jpg" '{operation:"create",id:"new-character",name:"A new character",displayName:"日本語",game:"Test",wallpaper:$image,palette:3}')"
printf '%s\n' "$create" | "$bin/theme-picker" theme-json | jq -e '.ok and .id == "new-character"' >/dev/null
[[ -f "$tmp/repo/themes/new-character/theme.conf" && -f "$tmp/repo/wallpapers/new-character.jpg" ]]
printf '%s\n' "$create" | "$bin/theme-picker" theme-json | jq -e '.ok | not' >/dev/null
cp -r "$root/themes/templates/quickshell" "$tmp/repo/themes/templates/"
for ui in light dark; do
    for system in light dark; do
        EROGEDOTS_APPEARANCE="$ui" EROGEDOTS_SYSTEM_APPEARANCE="$system" EROGEDOTS_NO_RESTART=1 EROGEDOTS_CONFIG_HOME="$tmp/rendered" "$root/scripts/theme-switch" new-character >/dev/null
        rg -q "string appearance: \"$ui\"" "$tmp/rendered/quickshell/Theme.qml"
        rg -q "string systemAppearance: \"$system\"" "$tmp/rendered/quickshell/Theme.qml"
        [[ "$(cat "$tmp/rendered/theme/appearance")" == "$ui" && "$(cat "$tmp/rendered/theme/system-appearance")" == "$system" ]]
    done
done
# Symlinked source is refused even when it points to a valid Nix file.
rm "$tmp/repo/home/moni.nix"
ln -s "$root/home/moni.nix" "$tmp/repo/home/moni.nix"
if request '{"operation":"read","target":"home"}' > "$tmp/symlink"; then echo 'Symlink accepted' >&2; exit 1; fi
printf 'PASS: config saves, backups, stale writes, invalid Nix, package boundaries, Niri validation, theme creation and all four appearance combinations\n'
