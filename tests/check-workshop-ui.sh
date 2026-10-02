#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "$0")/.." && pwd)"
rendered="${EROGEDOTS_TEST_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}}"
tmp="$(mktemp -d)"
trap 'rm -rf -- "$tmp"' EXIT
cp "$rendered/quickshell/"* "$tmp/"
cp "$root/tests/workshop-ui.qml" "$tmp/shell.qml"
export PATH="${EROGEDOTS_TEST_BIN:-$root/picker-rs/target/release}:$PATH"
status=0
QT_QPA_PLATFORM=offscreen timeout 200 quickshell -p "$tmp/shell.qml" --no-color > "$tmp/log" 2>&1 || status=$?
cat "$tmp/log"
[[ "$status" == 0 ]] && rg -q 'PASS: workshop UI' "$tmp/log"
! rg -q 'ReferenceError|TypeError|Error:|Unable to assign|Binding loop' "$tmp/log"
