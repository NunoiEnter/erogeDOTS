#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
cp "$root/themes/templates/quickshell/DrawerState.qml" "$tmp/"
cp "$root/tests/drawer-events.qml" "$tmp/shell.qml"
status=0
QT_QPA_PLATFORM=offscreen timeout 10 quickshell -p "$tmp/shell.qml" --no-color > "$tmp/log" 2>&1 || status=$?
if (( status != 0 )) || ! grep -q 'PASS: drawer hover state' "$tmp/log"; then
    cat "$tmp/log"
    exit 1
fi
printf 'PASS: drawer hover state\n'
