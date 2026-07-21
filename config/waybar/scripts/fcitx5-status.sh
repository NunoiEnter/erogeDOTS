#!/usr/bin/env bash
# Prints current fcitx5 input method as a short label for waybar.
CUR=$(fcitx5-remote -n 2>/dev/null)

case "$CUR" in
    keyboard-us) echo "  EN" ;;
    mozc)        echo "  JP" ;;
    keyboard-th) echo "  TH" ;;
    *)           echo "  ${CUR:-?}" ;;
esac
