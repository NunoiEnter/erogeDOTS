# ⚠️ erogeDOTS — VER.1.2

> **⚠️ WARNING: MY PERSONAL DOTFILES — NOT FOR YOU ⚠️**
>
> This is **my** personal NixOS setup. Runs on **my** machine (`NixChan`), uses **my**
> themes, **my** keybinds, **my** little quirks. This isn't a template or a distro —
> it's just my home.
>
> **STATUS: STILL BUILDING.** I break things, fix them, and move on. Don't expect
> stability. Don't expect support. If you copy this and something explodes —
> that's on you, not me. ⚠️

---

## 🎮 What even is this

My NixOS dotfiles with a visual-novel look (waifu themes), one theme-switcher that
re-colors everything, and a lightweight desktop stack on **niri**.

Why "lightweight"? I tried Noctalia (a whole desktop shell). It looked amazing but
ate resources. So I dropped it and rebuilt the same look with small tools: waybar,
swaync, fuzzel — way lighter, still pretty.

## 🧠 How it works

Three layers, in order:

1. **NixOS system** (`hosts/NixChan/configuration.nix`): bootloader, networking,
   sound, Bluetooth, display manager, desktops, fonts, Nix settings.
2. **Home-Manager user** (`home/moni.nix`, `home/modules/`): user packages, zsh,
   MIME apps, symlinks. Static configs such as nvim come from the Nix store.
3. **Theme runtime** (`scripts/theme-switch`, `themes/`): parses
   `themes/<name>/theme.conf`, substitutes `{{VARIABLES}}` into
   `themes/templates/<app>/*`, caches the result in
   `~/.config/theme/cache/<name>/`, then copies live files into `~/.config/<app>/`
   and records `~/.config/theme/{active,env}`. Wallpaper goes through `awww`.
   No rebuild is needed to change colors.

Flow:

```text
flake.nix
  -> sudo nixos-rebuild switch --flake .#NixChan
    -> system + Home-Manager symlinks
      -> home.activation.restoreTheme runs theme-switch <active> if cache missing
        -> ~/.config/<app>/ + wallpaper
```

Config rule: symlinks for static content, regular generated files for anything
theme-switch owns. Do not edit `~/.config/niri/config.kdl` directly; edit
`themes/templates/niri/config.kdl` and re-run
`theme-switch $(cat ~/.config/theme/active)`.

## 🧱 Where stuff lives

```text
erogeDOTS/
├── flake.nix                  # inputs: nixpkgs, home-manager, qylock, rust-overlay
├── flake.lock                 # locked inputs
├── install.sh                 # fresh-machine installer
├── agent.md                   # agent identity + full repo reference
├── hosts/NixChan/             # machine-specific system config
│   ├── configuration.nix      # system services, desktops, fonts, Nix settings
│   └── hardware-configuration.nix # MY hardware only, not portable
├── home/
│   ├── moni.nix               # user entry: imports, nvim symlink, theme restore hook
│   └── modules/
│       ├── terminal.nix       # terminal tools, MPD, zsh, aliases
│       └── desktop.nix        # desktop apps, mimeapps, launchers
├── modules/nixos/
│   └── i18n.nix               # fcitx5 EN/JP/TH input, env vars, CJK fonts
├── themes/                    # theme definitions + templates
│   ├── sana/ harumi/ nanami/ natsume/ nene/ meguru/ tsumuki/
│   └── templates/             # 11 apps with {{color}} placeholders
│       ├── niri/ waybar/ swaync/ fuzzel/
│       ├── ghostty/ alacritty/ foot/ kitty/
│       └── catnap/ cava/ cmatrix/
├── scripts/
│   ├── theme-switch           # parses theme.conf -> generates -> applies -> restarts
│   ├── tspick                 # wrapper: theme-switch picker
│   ├── cliphist-pick          # image-aware clipboard picker
│   ├── dropterm               # quake dropdown terminal (Mod+grave)
│   ├── music-pill             # GTK4 floating music + lyrics pill
│   ├── vnload / vnsave        # Heroic/Wine save snapshot sync helpers
│   └── bench                  # illustrative build-speed comparison output
├── picker-rs/                 # Rust TUI theme picker (src/main.rs)
├── pkgs/
│   ├── catnap/                # prebuilt catnap binary package
│   ├── chatgpt/               # official ChatGPT RPM as FHSEnv
│   ├── music-pill/            # wrapper for scripts/music-pill
│   └── sunshine/              # Sunshine RPM as FHSEnv (currently disabled)
├── config/                    # static configs
│   ├── nvim/                  # LazyVim config, symlinked by Home-Manager
│   ├── firefox/user.js        # fonts + GPU perf, applied after first launch
│   ├── waybar/scripts/        # waybar helper scripts
│   ├── openvpn/               # VPN profiles
│   └── ytfzf/                 # ytfzf config (currently dead upstream)
├── shells/                    # nix develop environments
├── wallpapers/                # theme wallpapers (5 present, see themes table)
├── docs/                      # notes: DEVELOPMENT, INSTALL, larper, vpn
└── README.md                  # this file
```

### File roles in detail

| Path | What it does |
|---|---|
| `flake.nix` | Declares `nixosConfigurations.NixChan`, 9 devShells, and `catnap`/`chatgpt`/`music-pill` packages. Uses `rust-overlay` for dev shells. |
| `install.sh` | Clone -> `nixos-rebuild switch` -> `cargo build --release` picker-rs -> copy to `~/.local/bin/theme-picker` -> symlink `tspick`/`cliphist-pick` -> apply Firefox `user.js`. Uses fzf fallback when cargo is absent. |
| `hosts/NixChan/configuration.nix` | systemd-boot limit 2, NetworkManager + openvpn, Tailscale + SSH 22, xrdp XFCE session, PipeWire, Bluetooth, SDDM Wayland, niri + XFCE + GNOME, patched qylock shim, Kanit/Noto/JetBrainsMono fonts, flakes, allowUnfree. |
| `home/moni.nix` | Imports terminal + desktop modules, symlinks `config/nvim`, restores theme on activation. |
| `home/modules/terminal.nix` | User MPD on PipeWire, 4 terminals, zsh aliases (`ts`, `yt`, `cmx`, `cave`, `pkmn`, etc.), catnap on shell open, dev CLIs, screenshot/clipboard/session utilities. |
| `home/modules/desktop.nix` | Daily apps, ChatGPT package, Firefox defaults, dual-location mimeapps, figma handler, Claude webapp, Dolphin dark theme, nvim-terminal entry. |
| `modules/nixos/i18n.nix` | fcitx5 + mozc with `keyboard-us`/`mozc`/`keyboard-th` cycle and required env vars. |
| `themes/<name>/theme.conf` | Colors, gradients, focus rings, terminal colors, nvim scheme, cava/cmatrix/catnap values, wallpaper path, character metadata. |
| `themes/templates/<app>/` | Source templates with `{{PLACEHOLDERS}}` for all 11 themed apps. |
| `scripts/theme-switch` | Full switcher: `list`, `current`, `preview`, `picker`, and direct `<theme>` apply with wallpaper + app reload. |
| `picker-rs/src/main.rs` | Ratatui picker with wallpaper image preview; Enter calls `theme-switch`. |
| `pkgs/*` | Local Nix packages for binaries not cleanly in nixpkgs. |
| `shells/*` | Reproducible `nix develop .#<name>` toolsets. |
| `config/nvim` | Editor config, store-symlinked, not theme-generated. |
| `wallpapers/` | Active wallpaper assets. |

## 🥞 My stacks

### Desktop shell (lightweight — no Qt6 bloat)

| Piece | What it does for me |
|---|---|
| **niri** | my tiling compositor — scrollable columns, tabbed, overview |
| **waybar** | Noctalia-style bar — full width, capsule widgets, launcher/notif/clipboard/session |
| **swaync** | my notifications |
| **fuzzel** | launcher + dmenu |
| **wlogout** | session menu (power off, reboot, logout) |
| **qylock** | my lock screen (patched so mouse clicks work) — swaylock as backup |
| **wlsunset** | night light, manual toggle (`Mod+Ctrl+W`) |
| **cliphist** | clipboard history (`Mod+Ctrl+V`) |
| **grim + slurp + swappy** | screenshots + region annotate (`Print` family) |
| **music-pill** | floating MPRIS pill with LRCLIB synced lyrics, auto-hides when stopped |
| **awww** | wallpaper daemon with fade transitions |

### Theming

- **theme-switch** — one command, re-colors 11 apps: niri, waybar, swaync, fuzzel,
  ghostty, alacritty, foot, kitty, catnap, cava, cmatrix
- **picker-rs** — Rust picker with live wallpaper previews; fzf fallback included
- **Cache** — generated configs live in `~/.config/theme/cache/<name>/`; active theme
  in `~/.config/theme/active`; shell env in `~/.config/theme/env`

| Theme | Character / source | Accent | Wallpaper here? |
|---|---|---|---|
| `sana` | Sana Inui / Mashiro-iro Symphony | `#e05050` red | yes |
| `harumi` | Harumi | pink | yes |
| `nanami` | Nanami | dark purple | yes |
| `natsume` | Natsume | warm pastel | yes |
| `nene` | Nene | lavender | yes |
| `meguru` | Inaba Meguru / Sanoba Witch | `#f09a4c` orange | missing |
| `tsumuki` | Shiiba Tsumugi / Sanoba Witch | `#e6c055` gold | missing |

### Terminal and editor

- ghostty (default), kitty, alacritty, foot — all themed
- zsh with completion, autosuggestions, syntax highlighting, theme env sourcing
- catnap fetch on shell open with cache + `clear` redraw; `mini` alias for small view
- nvim (LazyVim), vscodium, zed-editor
- yazi, fzf, ripgrep, fd, btop/htop, fun fetch toys (`pkmn`, `cmx`, `cave`, etc.)

### Apps, gaming, media

- Firefox default + librewolf + chrome, vesktop/discord, obs-studio
- dolphin/ark, qimgv, vlc/mpv/yt-dlp/ytfzf, qbittorrent
- wine, steam, steam-run, heroic + `vnload`/`vnsave` save snapshots
- MPD user service + rmpc + playerctl, foliate, figma-linux

### AI tools

- **claude-code** — Anthropic CLI (`claude`), from nixpkgs
- **codex** — OpenAI CLI (`codex`), from nixpkgs
- **ChatGPT** — official Linux desktop app, packaged from OpenAI's RPM
- **Claude launcher** — Firefox web-app entry (`claude.ai`) in the app menu

### Dev shells

```bash
nix develop              # full shell (all languages combined)
nix develop .#rust       # Rust + rust-analyzer/clippy/cargo tools
nix develop .#python     # Python + ruff/pyright/uv
nix develop .#go         # Go + gopls/gofumpt/linter
nix develop .#tester     # QA: pytest/k6/playwright/httpie
nix develop .#docker     # containers + scan/lint tools
nix develop .#security   # authorized-targets-only security toolkit
nix develop .#common     # shared CLI tools only
nix develop .#webapp     # webapp workflow
```

Full details: `docs/DEVELOPMENT.md`.

### Scripts

| Script | Purpose |
|---|---|
| `theme-switch <theme>\|list\|current\|preview\|picker` | Generate + apply theme, restart affected apps |
| `tspick` | Shortcut to the interactive picker |
| `dropterm` | Toggle quake terminal under waybar |
| `cliphist-pick` | Clipboard history with correct image/text paste |
| `music-pill` | Floating music overlay with three modes |
| `vnload [game]` / `vnsave [game]` | Restore/snapshot Heroic save folders |
| `bench` | Illustrative rebuild-speed comparison |

### Keybinds I actually use

| Key | Action |
|---|---|
| `Mod+Return` | terminal (ghostty) |
| `Mod+Shift+Return` | mini terminal |
| `Mod+grave` | dropdown terminal (quake-style under waybar) |
| `Mod+D` | app launcher (fuzzel) |
| `Mod+Ctrl+V` | clipboard history |
| `Mod+Shift+W` | session menu (wlogout) |
| `Mod+Ctrl+W` | night light toggle |
| `Super+Alt+L` | lock (qylock) |
| `Print` / `Ctrl+Print` / `Alt+Print` / `Shift+Print` | screenshot / screen / window / annotate |
| `Mod+Shift+/` | hotkey overlay (all binds listed) |
| `Mod+O` | overview |

Full list: press `Mod+Shift+/` anytime.

## 🚀 Installing (if you're me)

### Fresh machine

```bash
bash <(curl -s https://raw.githubusercontent.com/NunoiEnter/erogeDOTS/main/install.sh)
```

That clones the repo, runs `sudo nixos-rebuild switch --flake .#NixChan`, then
compiles the Rust theme-picker once into `~/.local/bin/theme-picker`.

### How the picker build actually works

The **install.sh script does the compiling** — you don't touch cargo yourself:

1. `git clone` the repo → `~/erogeDOTS`
2. `sudo nixos-rebuild switch` — installs EVERYTHING including `cargo` (it's in
   my `home/modules/terminal.nix` packages). This order matters: cargo must exist
   *before* the build step.
3. `cd picker-rs && cargo build --release` — compiles the Rust picker from source
   (`picker-rs/src/main.rs`)
4. `cp target/release/theme-picker ~/.local/bin/` — drops the binary into PATH

**When does it build?** Only **once, during install.sh**. Nixos-rebuild NEVER
recompiles it — that's the point: picker is Rust, not a Nix package, so rebuilds
stay fast. The binary just sits in `~/.local/bin/theme-picker` and keeps working.

**When would I rebuild it manually?** Only if you edit the picker source
(`picker-rs/src/main.rs`, e.g. add a theme option) — then:

```bash
cd ~/erogeDOTS/picker-rs
cargo build --release
cp target/release/theme-picker ~/.local/bin/
```

**No cargo?** install.sh falls back to fzf-based picker (no Rust build). Only
matters on a machine without the toolchain.

### Already cloned — just rebuild

```bash
cd ~/erogeDOTS
sudo nixos-rebuild switch --flake .#NixChan
```

### Theme/config tweaks (no rebuild needed)

```bash
theme-switch sana          # or: harumi nanami natsume nene meguru tsumuki
niri msg action load-config-file
pkill waybar; waybar &
```

Edit colors in `themes/<name>/theme.conf`; edit layout/behavior in
`themes/templates/<app>/`; add an app by creating
`themes/templates/<new-app>/` and adding its name to the `apps` arrays in
`scripts/theme-switch`.

## ⚠️ Read this before you copy me

- Hostname is **`NixChan`** — hardware-configuration is for MY hardware only.
- My aliases, my colors, my keybinds. Yours will (and should) differ.
- `allowUnfree` overlap deliberately left alone.
- `meguru` and `tsumuki` theme.conf files exist but their wallpapers are not in
  `wallpapers/` yet.
- `docs/INSTALL.md` still mentions old `battery-alert` and `pkgs/theme-picker`
  paths; the current picker is `picker-rs` built once by `install.sh`.
- **Still building.** Expect churn.

## 📚 My notes

- `agent.md` — agent identity plus full working reference for this repo
- `docs/DEVELOPMENT.md`, `docs/INSTALL.md`
- `docs/larper.md`, `docs/vpn-instructions.md`

---

**VER.1.2** — personal, WIP, waifu-powered. えへへ 💕
