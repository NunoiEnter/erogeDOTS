#!/usr/bin/env bash
# Cycles fcitx5 through EN -> JP -> TH -> EN ...
ORDER=(keyboard-us mozc keyboard-th)

CUR=$(fcitx5-remote -n 2>/dev/null)
IDX=0

for i in "${!ORDER[@]}"; do
    if [[ "${ORDER[$i]}" == "$CUR" ]]; then
        IDX=$i
        break
    fi
done

NEXT_IDX=$(( (IDX + 1) % ${#ORDER[@]} ))
fcitx5-remote -s "${ORDER[$NEXT_IDX]}"
