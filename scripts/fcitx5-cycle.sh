#!/usr/bin/env bash
set -euo pipefail

order=(keyboard-us mozc keyboard-th)
current="$(fcitx5-remote -n 2>/dev/null || true)"
index=0

for i in "${!order[@]}"; do
    if [[ "${order[$i]}" == "$current" ]]; then
        index=$i
        break
    fi
done

next=$(( (index + 1) % ${#order[@]} ))
fcitx5-remote -s "${order[$next]}"
