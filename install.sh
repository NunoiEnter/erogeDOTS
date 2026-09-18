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

# 3.7. Link eroricer skill + /erodots command into opencode config
# The repo copies under .opencode/ are the source of truth (they travel with
# git). These symlinks make the skill and command available in every session,
# from any directory — including fresh devices where ~/.config is empty.
mkdir -p "$HOME/.config/opencode/skills" "$HOME/.config/opencode/commands"
ln -sfn "$TARGET/.opencode/skills/eroricer" "$HOME/.config/opencode/skills/eroricer"
ln -sfn "$TARGET/.opencode/commands/erodots.md" "$HOME/.config/opencode/commands/erodots.md"
echo "eroricer skill + /erodots linked into ~/.config/opencode"

# 3.8. Verify eroricer is loadable (fail loudly, install is the only chance)
SKILL_FILE="$TARGET/.opencode/skills/eroricer/SKILL.md"
if [[ -f "$SKILL_FILE" ]] \
    && grep -q "^name: eroricer$" "$SKILL_FILE" \
    && grep -q "^description: " "$SKILL_FILE" \
    && [[ -f "$HOME/.config/opencode/commands/erodots.md" ]] \
    && [[ "$(readlink -f "$HOME/.config/opencode/skills/eroricer")" == "$TARGET/.opencode/skills/eroricer" ]]; then
    echo "eroricer verified — type /erodots in any opencode session"
else
    echo "ERROR: eroricer skill verification failed (see step 3.7)" >&2
    exit 1
fi

# 3.9. (retired) Music widget experiments (Python pill, Rust pill, eww card)
# were removed; media controls live in waybar's mpris module for now.
cd "$TARGET"

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
