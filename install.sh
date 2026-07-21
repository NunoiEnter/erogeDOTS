#!/usr/bin/env bash
# erogeDOTS installer — fresh NixOS device
set -euo pipefail

REPO="https://github.com/NunoiEnter/erogeDOTS.git"
TARGET="$HOME/erogeDOTS"

echo "=== erogeDOTS installer ==="

# 1. Clone repo
if [[ ! -d "$TARGET" ]]; then
    git clone "$REPO" "$TARGET"
else
    echo "Repo exists at $TARGET, skipping clone"
fi

cd "$TARGET"

# 2. Apply NixOS config (includes home-manager + theme-picker)
echo "Applying NixOS config..."
sudo nixos-rebuild switch --flake .#NixChan

echo ""
echo "=== Setup complete ==="
echo "Run: theme-picker   (or: theme-switch <name>)"
echo "Themes: harumi, nanami, natsume, nene"
