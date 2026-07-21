# erogeDOTS Session Summary

## Goal
Build and maintain a NixOS dotfiles system (`~/erogeDOTS`) with:
- Instant desktop theme switching via `theme-switch` script
- Themed notifications, terminals, bar, and fetch tool
- Visual novel aesthetic (TUI picker, catnap art, themed CSS)

---

## What We Built This Session

### 1. Terminal Migration: foot → ghostty → all terminals
**Problem:** Niri transparency bug (#1823) broke kitty/foot opacity on focused windows.

**Solution:**
- Switched primary terminal to **ghostty** (handles niri transparency correctly)
- Added `draw-border-with-background false` to niri config (fixes AMD GPU transparency)
- Added backup terminals: **alacritty**, **foot**, **kitty** (all themed, transparent, no title bar)
- Created config templates for each in `themes/templates/{alacritty,foot,kitty}/`

### 2. Fetch Tool: fastfetch → catnap
**Problem:** fastfetch slow modules, image loading timing issues.

**Solution:**
- Swapped to **catnap** v2.1.1 (Nim, ~10ms, NixOS art included)
- Binary installed to `~/.local/bin/catnap`
- Created themed `config.cat` template with magenta border, minimal stats
- Catnap runs on shell open, output cached for `clear` redraw

### 3. Notification Daemon: swaync
**Solution:**
- Installed **swaynotificationcenter** (GTK4, full notification center)
- Created `config.json` and `style.css` templates
- CSS themed with primary/bg/fg colors per theme
- Added to niri `spawn-at-startup`
- `swaync-client --reload-config` on theme switch

### 4. Other Fixes
- **niri transparency fix:** `draw-border-with-background false` in both template and active config
- **Waybar logs:** Redirected to `/dev/null` so prompt returns immediately
- **ASCII art banner:** Replaced fastfetch-on-switch with themed erogeDOTS banner
- **Theme.conf updates:** Renamed `kitty_*` vars to `ghostty_*` across all 4 themes

---

## Key Decisions

| Decision | Reason |
|----------|--------|
| ghostty as primary terminal | Avoids niri #1823 focus ring bug, supports kitty graphics protocol |
| `draw-border-with-background false` | Required for AMD GPU transparency in niri |
| catnap over fastfetch | 10ms speed, NixOS art built-in, simple `.cat` DSL |
| swaync over mako/dunst | Full notification center with CSS theming, history panel, DND |
| Backup terminals kept | Safety net if ghostty breaks |

---

## Git Commits (this session)

| Hash | Message |
|------|---------|
| `a83e940` | feat: swaync notification daemon with themed CSS |
| `bd9780b` | feat: swap fastfetch → catnap (10ms Rust fetch, NixOS art) |
| `c3344d4` | perf: faster fastfetch on open, remove slow modules |
| `9c6d28a` | fix: fastfetch image load delay, remove color bar, clear preserves output |
| `bc43add` | fix: fastfetch logo loading, updated config |
| `6f21b2f` | feat: ghostty terminal, backup terminals, fastfetch on open, niri transparency fix |

---

## Current Architecture

```
erogeDOTS/
├── themes/
│   ├── templates/
│   │   ├── niri/config.kdl        # spawns: ghostty, waybar, swaync, awww, fcitx5
│   │   ├── ghostty/config         # opacity 0.8, no decoration
│   │   ├── alacritty/alacritty.toml
│   │   ├── foot/foot.ini
│   │   ├── kitty/kitty.conf
│   │   ├── waybar/{config.jsonc,style.css}
│   │   ├── catnap/config.cat      # themed NixOS art, magenta border
│   │   ├── swaync/{config.json,style.css}
│   │   ├── fuzzel/config.ini
│   │   └── kitty/kitty.conf
│   ├── harumi/                    # default theme (pink)
│   ├── nene/                      # lavender
│   ├── natsume/                   # brown
│   └── nanami/                    # yellow/red
├── scripts/
│   ├── theme-switch               # main switcher (414 lines)
│   └── tspick                     # wrapper
├── picker-rs/                     # Rust TUI picker (ratatui-image)
├── config/                        # base configs + active niri config
├── home/modules/terminal.nix      # all packages + zsh config
└── home/moni.nix                  # restoreTheme activation
```

---

## Pending: `sudo nixos-rebuild switch`

Required to install new packages:
- `ghostty` (primary terminal)
- `kitty`, `alacritty`, `foot` (backup terminals)
- `vscodium`, `foliate` (apps)
- `swaynotificationcenter` (notification daemon)

Remove old packages:
- `fastfetch` (replaced by catnap)

---

## Next Steps

### Immediate
1. **Run `sudo nixos-rebuild switch`** — activate all new packages
2. **Test ghostty transparency** — open ghostty, verify 0.8 opacity works
3. **Test swaync** — run `notify-send "test" "hello"`, verify themed popup
4. **Test catnap** — open new terminal, verify catnap loads instantly

### Short-term
5. **Theme swaync with notification rules** — per-app colors, timeout, sound
6. **Add waybar module for swaync** — notification count badge
7. **Clean up picker-rs** — remove Go picker remnants if any
8. **Add more themes** — user may want additional color palettes

### Long-term
9. **Niri opacity fix** — monitor niri #1823 for upstream fix
10. **Fetch tool evolution** — catnap is young (287 stars), may want to revisit fetchx/raifetch when they mature
11. **Lock screen** — not yet configured (swaync has DND but no lock screen)
12. **Waybar refinements** — currently minimal, could add modules (weather, media, etc.)
