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
# nixos-rebuild put cargo in the user profile — make sure it's on PATH even
# if the current shell was started before this install
export PATH="/etc/profiles/per-user/$USER/bin:$PATH"
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

# 3.6. Symlink cliphist-pick (image-aware clipboard picker)
ln -sf "$TARGET/scripts/cliphist-pick" "$HOME/.local/bin/cliphist-pick"
echo "cliphist-pick symlinked to ~/.local/bin/cliphist-pick"

# 4. Apply Firefox user.js (fonts + GPU perf)
FIREFOX_PROFILE=$(find "$HOME/.config/mozilla/firefox" -maxdepth 2 -name "prefs.js" -type f 2>/dev/null | head -1 | xargs dirname 2>/dev/null)
if [[ -n "$FIREFOX_PROFILE" ]] && [[ -f "$TARGET/config/firefox/user.js" ]]; then
    cp "$TARGET/config/firefox/user.js" "$FIREFOX_PROFILE/user.js"
    echo "Firefox user.js applied (fonts + GPU acceleration)"
else
    echo "Launch Firefox once, then re-run: cp ~/erogeDOTS/config/firefox/user.js ~/.config/mozilla/firefox/*/user.js"
fi

echo ""
echo "=== Setup complete ==="
echo "Run: theme-switch   (or: theme-switch <name>)"
echo "Themes: sana (Sana Inui), harumi, nanami, natsume, nene"
