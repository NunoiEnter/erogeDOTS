#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "$0")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -r -- "$tmp"' EXIT
cp "$root/themes/templates/quickshell/"*.qml "$root/themes/templates/quickshell/"{qmldir,Keyboard.js} "$tmp/"
cp "${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/Theme.qml" "$tmp/"
cp "$root/tests/tool-pages.qml" "$tmp/shell.qml"
status=0
QT_QPA_PLATFORM=offscreen timeout 10 quickshell -p "$tmp/shell.qml" --no-color > "$tmp/log" 2>&1 || status=$?
if (( status != 0 )) || ! rg -q 'PASS: Extra Mode and System Config routes' "$tmp/log"; then
    sed -n '1,160p' "$tmp/log"
    exit 1
fi
printf 'PASS: Extra Mode and System Config routes\n'
