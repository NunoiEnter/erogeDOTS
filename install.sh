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

# 3.5. Symlink tspick → theme-switch picker
ln -sf "$TARGET/scripts/tspick" "$HOME/.local/bin/tspick"
echo "tspick symlinked to ~/.local/bin/tspick"

# 4. Apply Zen browser user.js (fonts + GPU perf)
ZEN_PROFILE=$(find "$HOME/.config/zen" -maxdepth 2 -name "prefs.js" -type f 2>/dev/null | head -1 | xargs dirname 2>/dev/null)
if [[ -n "$ZEN_PROFILE" ]] && [[ -f "$TARGET/config/zen-browser/user.js" ]]; then
    cp "$TARGET/config/zen-browser/user.js" "$ZEN_PROFILE/user.js"
    echo "Zen browser user.js applied (fonts + GPU acceleration)"
else
    echo "Launch Zen browser once, then re-run: cp ~/erogeDOTS/config/zen-browser/user.js ~/.config/zen/*/user.js"
fi

# 5. PhotoGIMP — Photoshop-like UI for GIMP (after first GIMP launch)
if [[ -d "$HOME/.config/GIMP/3.0" ]] && [[ ! -f "$HOME/.config/GIMP/3.0/.photogimp-installed" ]]; then
    echo ""
    echo "=== Installing PhotoGIMP ==="
    "$TARGET/scripts/install-photogimp" || echo "PhotoGIMP skipped — run manually: $TARGET/scripts/install-photogimp"
fi

echo ""
echo "=== Setup complete ==="
echo "Run: theme-switch   (or: theme-switch <name>)"
echo "Themes: harumi, nanami, natsume, nene"
