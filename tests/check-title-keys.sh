#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
runner="${QMLTESTRUNNER:-$(command -v qmltestrunner || true)}"
[[ -n "$runner" ]] || { echo 'Set QMLTESTRUNNER to the Qt 6 qmltestrunner path.' >&2; exit 1; }
qml_path="$(dirname "$(dirname "$(realpath "$runner")")")/lib/qt-6/qml"
if [[ -d "$qml_path" ]]; then export QML_IMPORT_PATH="${QML_IMPORT_PATH:-$qml_path}"; fi
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
cp "$root/themes/templates/quickshell/"{TitleChoice,VnButton,VnText,RetroBevel}.qml "$tmp/"
# Use the rendered singleton: no desktop processes or hardware state are started.
cp "${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/Theme.qml" "$tmp/"
printf 'singleton Theme 1.0 Theme.qml\n' > "$tmp/qmldir"
cp "$root/tests/title-keys.qml" "$tmp/tst_title.qml"
QT_QPA_PLATFORM=offscreen "$runner" -input "$tmp" -platform offscreen
