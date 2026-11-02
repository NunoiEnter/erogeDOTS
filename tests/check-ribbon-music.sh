#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "$0")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -r -- "$tmp"' EXIT
cp "$root/themes/templates/quickshell/"*.qml "$root/themes/templates/quickshell/"{qmldir,Keyboard.js} "$tmp/"
cp "${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/Theme.qml" "$tmp/"
cp "$root/tests/ribbon-music.qml" "$tmp/shell.qml"
status=0
QT_QPA_PLATFORM=offscreen timeout 30 quickshell -p "$tmp/shell.qml" --no-color > "$tmp/log" 2>&1 || status=$?
if (( status != 0 )) || ! rg -q 'PASS: Top-bar music widget' "$tmp/log"; then
    sed -n '1,200p' "$tmp/log"
    exit 1
fi
rg -i 'error|warning|loop' "$tmp/log" || true
printf 'PASS: Top-bar music widget\n'
