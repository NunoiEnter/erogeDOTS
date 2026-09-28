#!/usr/bin/env bash
# scripts/lib/common.sh — single source for theme-switch paths + app list.
# Sourced by theme-switch. No side effects when sourced.
# shellcheck disable=SC2034

# DOTFILES autodetect: git repo root if inside erogeDOTS, else $HOME/erogeDOTS.
if _root="$(git rev-parse --show-toplevel 2>/dev/null)"; then
  DOTFILES="$_root"
else
  DOTFILES="$HOME/erogeDOTS"
fi
THEMES_DIR="$DOTFILES/themes"
STATE_DIR="$HOME/.config/theme"
STATE_FILE="$STATE_DIR/active"
TEMPLATES_DIR="$THEMES_DIR/templates"

# Single app list. Edit here only — theme-switch reads this array twice
# (generate + apply) from the same source.
APPS=(niri quickshell catnap fetch fuzzel swaync ghostty alacritty foot kitty cava cmatrix)

# Directories theme-switch never treats as themes.
SKIP_DIRS=(templates incomplete)

should_skip() {
  local name="$1" skip
  for skip in "${SKIP_DIRS[@]}"; do
    [[ "$name" == "$skip" ]] && return 0
  done
  return 1
}

# Escape sed replacement chars (& | \) in theme values.
sed_escape() {
  printf '%s' "$1" | sed -e 's/[&|\\]/\\&/g'
}
