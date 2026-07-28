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

# 2. Apply NixOS config (everything managed by Nix)
sudo nixos-rebuild switch --flake .#NixChan

# 3. Build Rust theme-picker (compiled once at install, not on every rebuild)
echo ""
echo "=== Building theme-picker ==="
if command -v cargo &>/dev/null; then
    cd "$TARGET/picker-rs"
    cargo build --release
    mkdir -p "$HOME/.local/bin"
    cp target/release/theme-picker "$HOME/.local/bin/"
    echo "theme-picker built: $HOME/.local/bin/theme-picker"
else
    echo "cargo not found — theme-picker will use fzf fallback"
fi

# 4. Apply Zen browser font config (after first launch creates profile)
ZEN_PROFILE=$(find "$HOME/.zen" -maxdepth 1 -name "*.default*" -type d 2>/dev/null | head -1)
if [[ -n "$ZEN_PROFILE" ]] && [[ -f "$TARGET/config/zen-browser/user.js" ]]; then
    cp "$TARGET/config/zen-browser/user.js" "$ZEN_PROFILE/user.js"
    echo "Zen browser font set to Kanit"
else
    echo "Launch Zen browser once, then re-run: cp ~/erogeDOTS/config/zen-browser/user.js ~/.zen/*.default*/user.js"
fi

echo ""
echo "=== Setup complete ==="
echo "Run: theme-switch   (or: theme-switch <name>)"
echo "Themes: harumi, nanami, natsume, nene"
