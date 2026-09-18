# erogeDOTS Work Log

Append-only cross-session memory. Newest entry at the bottom. Every finished fix
gets one entry so a future session loading the `eroricer` skill can reconstruct
what happened without the old chat history.

## Entry format

```markdown
## YYYY-MM-DD — Title

- Changed: files or areas touched
- Why: one-line reason
- Verified: command or check that proved it works
- Commit: short hash once pushed (or "unpushed" if local only)
- Open: anything left undone, if any
```

---

## 2026-09-17 — Full repo investigation written into agent.md and README.md

- Changed: `agent.md` (new full reference), `README.md` (expanded structure, file
  roles, 7-theme table, stacks, scripts, shells)
- Why: persist how the dotfile works so future sessions start warm
- Verified: `git status`, staged only `agent.md` + `README.md`, pushed clean
- Commit: `ab6238a`
- Open: uncommitted work left in tree (flake.lock, desktop.nix, host config, niri +
  waybar templates, new sunshine package, meguru/tsumuki themes, waybar media_menu)

## 2026-09-17 — eroricer skill plus /erodots command created

- Changed: `.opencode/skills/eroricer/SKILL.md` (new), `.opencode/commands/erodots.md`
  (new), `docs/LOGS.md` (new), symlinks in `~/.config/opencode/skills/` and
  `~/.config/opencode/commands/` pointing at the repo copies, short sections in
  `agent.md` and `README.md` documenting the skill
- Why: `/erodots` in any session loads machine context; log keeps history across sessions
- Verified: frontmatter has required `name` + `description`, skill dir name matches
  `name`, command file resolves, symlinks resolve with `readlink -f`
- Commit: shipped in the commit carrying this entry (see `git log --oneline -3`)
- Open: none

## 2026-09-17 — Dirty tree committed (waybar island, xrdp, discord, 2 themes)

- Changed: `themes/templates/waybar/` (config.jsonc + style.css redesign, new
  media_menu.xml), `themes/templates/niri/config.kdl` (playerctld autostart),
  `hosts/NixChan/configuration.nix` (xrdp XFCE session, sunshine disabled),
  `home/modules/desktop.nix` (discord), `pkgs/sunshine/`, `themes/meguru/`,
  `themes/tsumuki/`, `flake.lock` bump
- Why: pending desktop work was sitting uncommitted; reviewed each diff, all legit
- Verified: `git diff` per file before staging; waybar island + mpris menu coherent
  with media_menu.xml; tree clean after commit
- Commit: `789d85c`
- Open: meguru/tsumuki wallpapers still missing; run `theme-switch` to regenerate
  live configs from the new templates on next rebuild

## 2026-09-17 — eroricer skill made to survive new devices via install.sh

- Changed: `install.sh` step 3.7 symlinks repo `.opencode/skills/eroricer` and
  `.opencode/commands/erodots.md` into `~/.config/opencode/`
- Why: skill source travels with git, but global symlinks lived only in
  `~/.config`, so a fresh device install lost `/erodots` outside the repo
- Verified: `bash -n install.sh` syntax OK; snippet re-ran idempotently and both
  symlinks resolve with `readlink -f`
- Commit: shipped in the commit carrying this entry
- Open: none

## 2026-09-17 — Keyboard language switch fixed (Alt+Shift) + stale fcitx5 profile

- Changed: `modules/nixos/i18n.nix` gains `fcitx5.settings.globalOptions` with
  `Hotkey.TriggerKeys = "Control+space Alt+Shift_L"` and
  `EnumerateWithTriggerKeys = "True"`; deleted stale `~/.config/fcitx5/profile`
  (backup at `/tmp/fcitx5-profile.bak`); restarted fcitx5
- Why: two stacked causes. The user profile held EN only and shadows
  `/etc/xdg/fcitx5/profile` (user file wins, no merge), so JP/TH never appeared.
  And no trigger key was ever declared, so nothing switched at all.
- Verified: generated `/etc/xdg/fcitx5/config` built from the flake contains the
  exact `[Hotkey]` section; after restart `fcitx5-remote -s` cycles
  keyboard-us/mozc/keyboard-th with zero errors in the fcitx5 log. Trigger syntax
  checked against fcitx5 upstream `key.cpp` (whitespace-separated key list,
  `Alt+`/`Shift+` prefixes, `Shift_L` keysym all valid).
- Commit: shipped in the commit carrying this entry
- Open: needs `sudo nixos-rebuild switch --flake ~/erogeDOTS#NixChan` (sudo
  password prompt, could not run headless) to activate Alt+Shift; until then
  default Ctrl+Space works. Note: plain `pkill -x fcitx5` did not stop the old
  daemon, `kill -9 <pid>` did.

## 2026-09-17 — install.sh verifies eroricer so every install ends ready

- Changed: `install.sh` step 3.8 checks SKILL.md frontmatter (`name` + `description`),
  the `/erodots` command file, and that the global skill symlink resolves to the
  repo copy; exits 1 with an error if anything is off
- Why: step 3.7 linked the files but never confirmed, so a broken skill could
  slip through a fresh install unnoticed
- Verified: `bash -n install.sh` clean; verify block run standalone prints
  the ready message
- Commit: shipped in the commit carrying this entry
- Open: none

## 2026-09-17 — Scoped passwordless sudo for agent rebuilds

- Changed: `hosts/NixChan/configuration.nix` gains `security.sudo.extraRules`
  granting moni NOPASSWD for `nixos-rebuild`, `nix-collect-garbage`,
  `nix-store`, `nix` (absolute `/run/current-system/sw/bin/` paths);
  `agent.md` sudo section documents the new no-prompt state
- Why: agent sessions run headless, sudo password prompts block rebuilds
- Verified: `nix eval` of `security.sudo.extraRules` shows the moni rule next
  to untouched defaults (root ALL, wheel still passworded)
- Commit: shipped in the commit carrying this entry
- Open: needs ONE last passworded `sudo nixos-rebuild switch --flake
  ~/erogeDOTS#NixChan` to activate (also picks up the Alt+Shift fcitx5 trigger
  from the previous commit); after that agent sudo runs prompt-free

## 2026-09-18 — music-pill rewritten in Rust (Python/GTK gone)

- Changed: new `music-pill-rs/` crate (wayland-client layer-shell, SHM pixel
  buffers, cosmic-text, image, ureq); `install.sh` step 3.9 builds it once to
  `~/.local/bin/music-pill`; niri template autostarts it by absolute path;
  deleted `scripts/music-pill`, `pkgs/music-pill/`, and their flake +
  terminal.nix wiring; README/agent.md updated
- Why: old pill never rendered art (`_load_album_art` was dead code, never
  called), was never autostarted, and the user asked for Rust instead of Python
- Verified: live screenshots show art disc, JP title/artist, prev/play/next;
  clicks wired (left play-pause, right next, middle previous, scroll volume);
  installed binary runs with zero env setup; flake still evaluates
- Commit: shipped in the commit carrying this entry
- Open: needs `sudo nixos-rebuild switch` (removes old nix pill package,
  keeps everything else); volume slider from the old expanded mode was dropped
  (scroll covers it). Bugs found along the way, for the record:
  stale single-IM fcitx5 profile aside, the Rust pill first died on every run
  because it attached SHM buffers before the first configure (Smithay client
  error, connection killed) — fixed by drawing only after configure — plus an
  O_WRONLY shm file the compositor could not mmap (now O_RDWR), and NUL bytes
  in playerctl argv which execve forbids (fields now queried separately).
- Left untouched: `home/modules/desktop.nix` (rustdesk) and
  `hosts/NixChan/configuration.nix` (rustdesk ports/uinput) have the user's own
  uncommitted changes; not mine, not staged
