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

# 2. Apply NixOS config (includes home-manager)
echo "Applying NixOS config..."
sudo nixos-rebuild switch --flake .#NixChan

# 3. Ensure local bins exist
mkdir -p "$HOME/.local/bin"

# 4. Build Rust picker if not present
if [[ ! -f "$HOME/.local/bin/theme-picker" ]]; then
    echo "Building theme picker..."
    cd picker-rs
    cargo build --release
    cp target/release/theme-picker "$HOME/.local/bin/"
    cd ..
fi

# 5. Pick theme (first run)
echo ""
echo "=== Setup complete ==="
echo "Run: theme-picker   (or: theme-switch <name>)"
echo "Themes: harumi, nanami, natsume, nene"
