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

## 2026-09-18 — music-pill is now a hover/hotkey square card

- Changed: `music-pill-rs` rewritten around open/close state. Collapsed = 56px
  art tab top-right (input region limited to the tab so the rest passes
  through). Hover or click on the tab opens a 360px square card: big art with
  scrim, title, artist/synced-lyric line, progress bar with times, prev/play/X
  controls. Pointer leave closes after 800ms unless pinned. `music-pill
  toggle|show|hide` talks to the running instance over a unix socket;
  `Mod+Shift+M` bound in the niri template. Rounded corners fixed (proper
  corner-center test), per-channel subpixel text blending.
- Why: pill strip always visible was noise; user wants on-demand square widget
- Verified: screenshots of collapsed tab, expanded card (art, times 2:35/4:59,
  buttons), and toggle-close back to tab; socket IPC both directions;
  theme-switch regen applied the hotkey live
- Commit: shipped in the commit carrying this entry
- Open: hover-open path itself could not be exercised headless (no mouse), only
  code-reviewed; user to confirm by hovering the tab

## 2026-09-18 — Music widget experiments removed for now

- Changed: deleted `music-pill-rs/`, `themes/templates/eww/`, `scripts/eww-start`;
  reverted theme-switch eww integration, niri autostart/hotkey, install.sh 3.9
  build block; killed eww daemon, removed live `~/.config/eww`, regenerated
  theme so live niri is widget-free. Media controls remain in waybar mpris.
- Why: user call — custom pill felt unsmooth, eww card prototype ate hours on
  yuck layout fights (empty image path kills the window, fixed window heights
  clip content, scale widgets break measurement). Parked, not abandoned: full
  history in git (`ce69578`, `d022c2f`) and prior log entries.
- Verified: live niri config has no widget lines, no eww dir, daemon dead,
  `bash -n install.sh` clean, tree holds only the user's own rustdesk edits
- Commit: shipped in the commit carrying this entry
- Open: desktop.nix eww package line rides with the user's uncommitted rustdesk
  work (theirs to commit); revisit widget when there's a calm window

## 2026-09-20 — Boot 1G fix: ESP at /efi, /boot on root via GRUB, keep 10 gens

- Changed: `hosts/NixChan/hardware-configuration.nix` (`/boot` vfat 86AC-1287 -> `/efi` vfat), `hosts/NixChan/configuration.nix` (systemd-boot limit 2 -> GRUB enable true efiSupport nodev useOSProber limit 10 efiSysMountPoint /efi, nix.gc 7d -> 30d + nix.optimise.automatic true), `scripts/mk-boot-partition` (new 1G XBOOTLDR helper for live USB), plus rustdesk ports/uinput/firewall and nix settings from prior dirty tree
- Why: 96M ESP (Windows default `nvme0n1p1`) overflowed `100%` `OSError 28 No space left` on `systemd-boot` `copyfileobj` each gen `~40M` `limit 2` still overflow
- Verified: `df -h /boot` `321G ext4` `48G->62G free` after `nix-collect-garbage -d` `13.1G 11762 paths` + `/efi 96M 72% 28M free`, `ls /boot/grub` `grub.cfg`, `ls /efi/EFI/NixOS-efi/grubx64.efi` active `0x0005`, `bootctl status` GRUB first, `nix eval` `grub.configurationLimit 10` `gc 30d`, `sudo -n nixos-rebuild switch` `Done` `d076...`, `efivarfs` GRUB boot-order
- Commit: `eb5e1d5` (boot 1G GRUB) + `e8664bd` (keep 10 GC 30d) + this log entry
- Open: real `1G vfat p6 XBOOTLDR` at `/boot` needs live USB `bash scripts/mk-boot-partition` (shrink `p5 326G->325G`, mkpart 1G) to get physical separate `vfat` if want; old `/efi/EFI/systemd` + `/efi/EFI/nixos` still on ESP `~20M` can `sudo rm -rf` after stable GRUB boot

## 2026-09-21 — Install Arduino IDE 2.x

- Changed: `home/modules/desktop.nix` (`arduino-ide` 2.3.10 + `arduino-cli` 1.5.1), `hosts/NixChan/configuration.nix` (`extraGroups` add `dialout`)
- Why: user requested Arduino IDE for board upload
- Verified: `sudo nixos-rebuild switch --flake ~/erogeDOTS#NixChan` generation 150 `2026-09-21 11:05:29` `Done` `i7gwfxn1`, `which arduino-ide` `/etc/profiles/per-user/moni/bin/arduino-ide`, `which arduino-cli` same, `id moni` shows `dialout`, `nix eval` version `2.3.10`, 37 derivations built, 29 paths fetched 402 MiB
- Commit: unpushed (this batch)
- Open: needs re-login (logout/login or reboot) for new `dialout` group to apply to current shell; after that serial `ttyACM0/ttyUSB0` works without sudo per NixOS wiki `users.users.<name>.extraGroups = [ "dialout" ]`

## 2026-09-21 — System-apply now user-terminal-only

- Changed: `agent.md` (`## Sudo Authorization` -> `## Sudo / System Apply Policy`, agent never runs `nixos-rebuild`/`nix-collect-garbage` headless, must print command for user terminal), `.opencode/skills/eroricer/SKILL.md` (`Sudo scope` -> `Sudo / apply scope — user-terminal-only`)
- Why: user requested rebuild/GC/etc must be done in user terminal, agent must always send command instead of auto-running
- Verified: `git diff` shows new policy in both files, `grep -n "user-terminal-only" agent.md` and `SKILL.md` present, no functional Nix change
- Commit: unpushed (this batch)
- Open: none — future `nixos-rebuild switch|test|boot` and `nix-collect-garbage` will be presented as `sudo nixos-rebuild switch --flake ~/erogeDOTS#NixChan` for user to paste; `security.sudo.extraRules` NOPASSWD remains for paste convenience only

## 2026-09-23 — Update ChatGPT to 26.917.61114

- Changed: `pkgs/chatgpt/default.nix` (version `26.903.61454` -> `26.917.61114`, hash bump to `sha256-VyOu35iASa3ROwNdUB68wVh6PMncLwUrV+9N8Cx4U1Q=`)
- Why: upstream `latest` RPM moved (installed `26.903.61454` stale, header strings show `chatgpt-26.917.61114-1`)
- Verified: `bsdtar -tf` on fresh RPM still has `usr/lib/chatgpt/ChatGPT` + `usr/share/pixmaps/chatgpt.png`; `nix eval .#chatgpt.version` prints `26.917.61114`; `nix build .#chatgpt --no-link --dry-run` resolves 6 derivations clean
- Commit: unpushed
- Open: needs `sudo nixos-rebuild switch --flake ~/erogeDOTS#NixChan` in user terminal to activate

## 2026-09-23 — Disable sleep on lid close

- Changed: `hosts/NixChan/configuration.nix` gains `services.logind.settings.Login` with `HandleLidSwitch`, `HandleLidSwitchExternalPower`, `HandleLidSwitchDocked` all `ignore`
- Why: logind default suspends on lid close; user wants stay awake
- Verified: `nix eval .#nixosConfigurations.NixChan.config.services.logind.settings.Login` shows all three `ignore`
- Commit: unpushed
- Open: needs `sudo nixos-rebuild switch --flake ~/erogeDOTS#NixChan` in user terminal to activate

## 2026-09-23 — Lid-close via on-demand inhibit, default reverted

- Changed: reverted `services.logind.settings.Login` ignore block in `hosts/NixChan/configuration.nix` (tree no longer touches that file); no rebuild needed
- Why: user wants command-only, not permanent default
- Verified: `nix eval` shows Login back to `{ KillUserProcesses = false; }`; live `systemd-inhibit --list` proves UID 1000 block lock on `handle-lid-switch` works with no sudo
- Commit: unpushed
- Open: none

## 2026-09-23 — zzz hibernate + unzzz stay-awake commands

- Changed: new `scripts/zzz` (`systemctl hibernate`), new `scripts/unzzz` (`systemd-inhibit --what=handle-lid-switch --mode=block ... sleep infinity`); both executable, on PATH via `home.sessionPath`, no rebuild needed
- Why: user wants `zzz` to hibernate, `unzzz` to stay awake with lid closed
- Verified: `bash -n` clean on both; `unzzz` run in background registers `handle-lid-switch block` lock in `systemd-inhibit --list`, killed cleanly; `zzz` syntax only (executing hibernates the machine)
- Commit: unpushed
- Open: `zzz` fails until swap exists — `swapDevices = [ ]`, 30Gi RAM needs ~30G swapfile + `boot.resumeDevice` + resume_offset; say go and it gets set up (needs rebuild)

## 2026-09-24 — Quickshell quick-settings popover (Caelestia-style)

- Changed: new `themes/templates/quickshell/shell.qml` (ShellRoot + `quick-settings` IpcHandler + top-center card: Wi-Fi/BT pills, Pipewire volume + brightnessctl sliders, Mpris media row, UPower battery, lock/leave/night/alerts + settings shortcuts); `scripts/theme-switch` gains `quickshell` in both apps arrays + kill/respawn block; niri template gains `quickshell -n -p` spawn + `Mod+S` toggle bind; waybar network/pulseaudio/battery `on-click` now toggles popover (right-clicks keep old actions); `home/modules/desktop.nix` gains `quickshell`; README + agent.md updated (12 themed apps, Mod+S)
- Why: compact control-center dropdown per user pick, Harumi-themed via existing placeholders
- Verified: `bash -n` clean; `theme-switch harumi` regen leaves zero `{{` in live shell.qml; store quickshell 0.3.1 loads config with no QML errors and `ipc call quick-settings toggle/open/close` all clean; `nix eval` shows `quickshell-0.3.1` in home packages; `nix build --dry-run` toplevel resolves clean
- Commit: unpushed
- Open: needs `sudo nixos-rebuild switch --flake ~/erogeDOTS#NixChan` in user terminal so `quickshell` lands on PATH and niri spawn works after login; widget currently running from store path as stopgap

## 2026-09-24 — Eww bar migration with media cover and dropdown

- Changed: new `themes/templates/eww/{eww.yuck,eww.css,media-placeholder.svg}`; new executable `scripts/eww-start`, `scripts/eww-media`, `scripts/eww-status`, and `scripts/fcitx5-cycle.sh`; `theme-switch` now owns `eww`, removes stale `eww.scss`, restarts Eww, and uses `niri msg action load-config-file`; niri startup replaces Waybar with `eww-start`; Waybar removed from Home Manager packages; Eww status buttons open the existing Quickshell popover via newest-instance IPC; docs updated
- Why: user requested Waybar migration to Eww with mandatory quick-settings access and live media thumbnail
- Verified: `bash -n` on all new/changed scripts; `niri msg action load-config-file` succeeds; Eww 0.6 parses config with `eww debug` and live layer surface; `theme-switch harumi` resolves every Eww placeholder and removes stale SCSS; `quickshell ipc -n call quick-settings open/close` shows/hides `eroge-quick-settings`; live Firefox MPRIS cover appears in Eww bar; `nix eval` shows `eww` and `quickshell` but no `waybar`; `nix build --dry-run`, `nix flake check --no-build`, and `git diff --check` pass
- Commit: unpushed
- Open: user must run `sudo nixos-rebuild switch --flake ~/erogeDOTS#NixChan` to persist package/startup changes; legacy Waybar templates remain for rollback

## 2026-09-24 — Match Waybar scale and redesign quick-settings

- Changed: Eww bar now mirrors pre-migration Waybar metrics (13px base type, 38px window, 4×10px island padding, 28px controls, 15px glyphs, 26px media art) and uses a 1150px centered geometry; Quickshell dropdown rebuilt as a 400px Harumi control-center card with character subtitle, connectivity state dots, section labels, compact sliders, media block, session actions, and settings links
- Why: user requested Waybar-identical scale and a clearer redesigned dropdown
- Verified: live screenshot shows compact bar and redesigned dropdown on workspace 2; Eww parser/debug clean; Quickshell newest-instance IPC opens/closes `eroge-quick-settings`; all generated Eww placeholders resolve; shell syntax, `nix flake check --no-build`, toplevel dry-run, and `git diff --check` pass
- Commit: unpushed
- Open: none beyond the existing user-terminal rebuild requirement

## 2026-09-24 — Thin Eww bar and clear tab overlap

- Changed: Eww bar reduced to 30px logical height at 6px top margin, 12px base type, 24px controls, 22px workspace buttons, and 22px media art; Quickshell dropdown top offset increased to 68px so card clears browser tab bars
- Why: user reported bar too thick and dropdown covering top tabs
- Verified: live workspace-2 screenshot shows thin bar and dropdown below top tabs; Eww debug/ping clean; Quickshell IPC clean; generated placeholders resolve; shell syntax, `nix flake check --no-build`, toplevel dry-run, and `git diff --check` pass
- Commit: unpushed
- Open: none beyond the existing user-terminal rebuild requirement

## 2026-09-25 — Keep Eww bar and quick-settings clear of browser tabs

- Changed: `themes/templates/eww/eww.yuck` now reserves its top layer with `exclusive true`; `themes/templates/quickshell/shell.qml` uses a `Region` input mask and moves the card to `topMargin: 120`
- Why: the floating Eww bar and dropdown were covering browser tab rows
- Verified: live Harumi screenshot shows the bar above the browser tabs and the dropdown below them; clicking a browser tab while the dropdown remained open switched tabs; `eww ping`, Eww debug, Quickshell IPC, shell syntax, and `git diff --check` pass
- Commit: unpushed
- Open: user must run `sudo nixos-rebuild switch --flake ~/erogeDOTS#NixChan` to persist package/startup changes

## 2026-09-25 — TLP battery policy and lower Eww wakeups

- Changed: `hosts/NixChan/configuration.nix` replaces `power-profiles-daemon` with TLP 1.10.2 and `tlp-pd`, enables automatic performance on AC and power-saver on battery, and preserves the 75/80 charge thresholds; `themes/templates/eww/eww.yuck` reduces status, workspace, and media polling intervals
- Why: live BAT0 measured 27.51/50.5 Wh (54.5% capacity), 1,456 cycles, 28–30 W under active load, 100% screen brightness, balanced PPD, and no automatic battery policy
- Verified: `upower --dump`, sysfs power readings, `nix eval` of TLP/pd settings, `nix flake check --no-build`, `nix build .#nixosConfigurations.NixChan.config.system.build.toplevel --no-link`, and `git diff --check`; current session set to PPD power-saver and brightness 40%
- Commit: unpushed
- Open: user must run `sudo nixos-rebuild switch --flake ~/erogeDOTS#NixChan`; run `theme-switch harumi` afterward to regenerate live Eww config and restart terminals; replace worn battery, then measure idle draw with heavy apps closed

## 2026-09-25 — Allow full 100% battery charge

- Changed: `hosts/NixChan/configuration.nix` sets TLP `START_CHARGE_THRESH_BAT0 = 0` and `STOP_CHARGE_THRESH_BAT0 = 100`
- Why: user explicitly requested charging fully to 100%
- Verified: targeted TLP settings evaluate to 0/100; current live firmware threshold remains 75/80 until rebuild; full flake validation is currently blocked by unrelated untracked `pkgs/discord-opencode` and `home/modules/discord-opencode.nix`
- Commit: unpushed
- Open: user must run `sudo nixos-rebuild switch --flake ~/erogeDOTS#NixChan`, then `sudo tlp setcharge 0 100 BAT0` if firmware does not apply immediately; note full charging accelerates battery wear

## 2026-09-25 — Wake niri display after lid opens

- Changed: `themes/templates/niri/config.kdl` adds a `lid-open` switch event that runs `niri msg action power-on-monitors`
- Why: `unzzz` correctly blocks logind suspension, but niri can leave the internal panel asleep after reopening; niri normally disables the panel on lid close
- Verified: live `systemd-inhibit --list` shows active `unzzz` block; latest lid close produced no suspend; `niri msg action power-on-monitors` succeeds; isolated Niri config validation passes
- Commit: unpushed
- Open: run `theme-switch harumi` to regenerate and reload live niri config; it restarts terminals, so run after closing this session if needed

## 2026-09-25 — Make unzzz survive terminal closure

- Changed: `scripts/unzzz` now runs the inhibitor as detached `systemd --user` transient service `unzzz.service`; supports `unzzz start` and `unzzz stop`
- Why: direct `systemd-inhibit ... sleep infinity` died when its terminal closed, so later lid closures could suspend again
- Verified: `bash -n scripts/unzzz`; `unzzz start`; `systemctl --user status unzzz.service` active; `systemd-inhibit --list` shows `unzzz` blocking `handle-lid-switch`
- Commit: unpushed
- Open: run `theme-switch harumi` to activate the niri lid-open wake event; use `unzzz stop` to release the block

## 2026-09-25 — Keep niri internal panel enabled across lid events

- Changed: `themes/templates/niri/config.kdl` enables `keep-laptop-panel-on-when-lid-is-closed` and explicitly enables `eDP-1` plus DPMS on `lid-open`
- Why: niri can leave its internal connector disabled after lid transitions; `power-on-monitors` alone only wakes DPMS
- Verified: generated live config contains both settings; `niri validate --config /home/moni/.config/niri/config.kdl` passes; `niri msg outputs` reports active `eDP-1`; `unzzz.service` remains active
- Commit: unpushed
- Open: physical lid close/open test still required

## 2026-09-25 — Restore panel brightness after display-wake change

- Changed: live `amdgpu_bl1` brightness restored from 80% to 40%; no color or niri output-mode change made
- Why: user reported a brighter-looking display after lid-wake troubleshooting
- Verified: `brightnessctl get` reports 40%; `niri msg outputs` remains 1920x1080 at 60 Hz; AC is online and TLP is in performance profile
- Commit: unpushed
- Open: if color still differs on battery, AMDGPU adaptive backlight is the next suspect; disabling it trades battery savings for unchanged panel color

## 2026-09-25 — Oko-chan v2 Discord conversations and controls

- Changed: `pkgs/discord-opencode/` Rust bridge, `settings.rs`, V1 OpenCode client, task persistence, message intents, persona/project commands, `/oc` controls, and safer lexical permission checks
- Why: add owner-only natural Discord conversations, forum-post follow-ups, durable session mapping, customizable persona, and discoverable OpenCode controls without widening project or host privileges
- Verified: `cargo fmt --all`, `cargo check --all-targets`, `cargo clippy --all-targets -- -D warnings`, `cargo test --all-targets` (22 tests), `nix flake check`, `nix build .#discord-opencode-bot --no-link`, full NixOS `toplevel` build, disposable OpenCode V1 API probes, and `git diff --check`
- Commit: unpushed
- Open: enable Discord Message Content Intent, rotate the previously exposed bot token, and explicitly authorize `sudo nixos-rebuild switch` before activating v2; current service remains old `0.1.0`

## 2026-09-25 — Eww bar speed fix, sorted workspaces, music moved to dropdown

- Changed: `scripts/eww-status` (new `workspaces` sorted by idx + `workspaces-listen` on niri event-stream), `scripts/eww-media` (new `json` combined poll, background art fetch), `themes/templates/eww/eww.yuck` (event-driven workspaces, single media poll, slower clock/network/battery intervals, compact auto-size bar, music card moved to `media-dropdown` window below bar), `themes/templates/eww/eww.css` (dropdown styles, fixed-size bar music button), `scripts/eww-start` (also opens `media-dropdown`)
- Why: bar felt slow (13 polls spawning playerctl/wpctl/upower/nmcli every 2-3s, workspace highlight lagged up to 2s, cover download blocked up to 10s); workspace tabs showed in niri id order (2 4 3 1); fixed 1150px width left a long empty pill; inline title text stretched the bar while music played
- Verified: `bash -n` on all touched scripts; `eww-status workspaces` returns idx order 1 2 3 4; `eww-media json` returns one valid JSON line; `theme-switch harumi` applied, `eww list-windows` shows `bar` + `media-dropdown`, `eww state` parses media JSON with no config errors; focus-workspace 1 reflected in `eww state` within 1s; fake Playing state renders truncated dropdown below a constant-width bar in screenshot, then live config restored and reloaded clean
- Commit: unpushed (eww scripts/templates are untracked files; not staged, no push requested)
- Open: dropdown x-position reads slightly left of bar center on 1920x1080 — confirm on real music playback; consider `playerctl previous/next` on bar button right-click

## 2026-09-25 — Short centered Eww pill, duplicate-bar cleanup

- Changed: `themes/templates/eww/eww.yuck` (status buttons icon-only with values in tooltips, fixed 600px bar geometry), `themes/templates/eww/eww.css` (tighter paddings, symmetric `margin: 0 640px` on `.bar-shell` because the layer-shell window spans full output width and ignores `:width`/halign centering), `scripts/eww-start` (correct `pkill -x .eww-wrapped`, kill orphaned `workspaces-listen` scripts, `close-all` before open, `timeout 10` on IPC calls)
- Why: bar still stretched edge to edge; probes (minimal content, exclusive toggle, height removal, 400px scratch window) showed eww windows size from content but the bar window always spans full width, so margins carve the 640px centered pill; repeated `open` calls stacked duplicate bars because the old pkill pattern missed the `.eww-wrapped` nix wrapper name
- Verified: `bash -n`; `theme-switch harumi`; screenshot shows single 640px pill centered at 960 with all modules fitting; fake Playing state shows pill width unchanged plus truncated dropdown card below; restored live config, `active-windows` shows one `bar` + one `media-dropdown`, `git diff --check` clean
- Commit: unpushed (eww scripts/templates untracked; not staged, no push requested)
- Open: dropdown card sits slightly left of bar center while playing — cosmetic only; margins assume 1920-wide output, revisit if external monitor used

## 2026-09-26 — Eww bar rebuilt waybar-style, SIGKILL duplicate fix

- Changed: `themes/templates/eww/eww.yuck` (centerbox 3-section layout: launcher + ◆/◇ workspaces + focused-window title left, clock + music button center, brightness/volume/network/battery + settings/notifications/clipboard/power right; music card stays in `media-dropdown`), `themes/templates/eww/eww.css` (10px side margins, workspace diamonds pink active/dim inactive, no forced min-width), `scripts/eww-status` (new `focused-title`, `fcitx5` modes), `scripts/eww-start` (SIGKILL old daemon, kill orphaned listeners, close-all + IPC timeouts)
- Why: user wanted old waybar look (full strip, left/center/right, ◆ active ◇ default, focused title) in eww instead of the centered pill; numbers dropped per waybar format-icons
- Verified: `bash -n`; `theme-switch harumi`; single `bar` + `media-dropdown` in active-windows; screenshot shows all modules with clock centered-ish and bar width constant while fake Playing state shows truncated dropdown below; `git diff --check` clean
- Commit: unpushed (eww scripts/templates untracked; not staged, no push requested)
- Open: forcing shell min-width past natural content clips right modules off-screen, so bar is content-width (~1380px) not edge-to-edge; duplicate bars were old daemons surviving SIGTERM — `eww kill` also fails, only SIGKILL works; fcitx5 shows `?` until an input method activates (same as legacy waybar script)

## 2026-09-26 — Drop eww music dropdown, text pill back in bar

- Changed: `themes/templates/eww/eww.yuck` (removed `media-dropdown` window and `media-drop-card`; `media-button` now shows play/pause glyph plus title truncated to 22 chars), `themes/templates/eww/eww.css` (removed dropdown styles, pill-style `.media-button-text`), `scripts/eww-start` (only opens `bar`)
- Why: Super+S quick-settings popover overlapped the image dropdown; user prefers the text player pill in the bar
- Verified: `theme-switch harumi`; only `bar` in active-windows; fake Playing state shows truncated title pill next to clock with bar width stable; live config restored, `git diff --check` clean
- Commit: unpushed (eww scripts/templates untracked; not staged, no push requested)
- Open: none

## 2026-09-26 — TTY default boot plus RAM trims for sub-1G idle

- Changed: `hosts/NixChan/configuration.nix` (`systemd.defaultUnit` mkForce `multi-user.target`, `services.xrdp.enable` false, `hardware.bluetooth.enable`/`powerOnBoot` false, `services.blueman.enable` false), `home/modules/terminal.nix` (`services.mpd.enable` false), `home/modules/discord-opencode.nix` (`Install.WantedBy` mkForce [] but manual start kept)
- Why: user wants TTY as default boot and idle RAM under 1G from ~1.1G; SDDM greeter stack alone costs ~250M (weston 85M + greeter 176M)
- Verified: `nix eval` defaultUnit `multi-user.target`, xrdp/bluetooth/blueman/mpd false, discord WantedBy `[]`; `nix build toplevel --dry-run` resolves clean; `git diff --check` clean
- Commit: unpushed
- Open: user must run `sudo nixos-rebuild switch --flake ~/erogeDOTS#NixChan` in own terminal; GUI on-demand via `sudo systemctl isolate graphical.target`; re-enable xrdp/BT/mpd/discord when needed; note opencode serve itself holds ~1.1G RSS so true idle reading needs agent stopped

## 2026-09-26 — Quickshell-only Senren Banka bar, Eww + Waybar removed

- Changed: deleted `themes/templates/eww/` + `scripts/eww-start|eww-media|eww-status`, `git rm` `themes/templates/waybar/` + `config/waybar/scripts/`, cleared live `~/.config/eww` + `~/.config/waybar`; new `themes/templates/quickshell/shell.qml` Senren Banka bar (torii launcher, hanko workspace seals via niri JSON poll, scenario title, VN clock + ❀ media, ema status) + dialogue-box popover; `scripts/theme-switch` drops eww (11 apps, kills orphan eww daemon, cleans live dirs); niri template spawns quickshell only; `home/modules/desktop.nix` drops eww package; `scripts/ram` + `dropterm` de-eww; README/agent.md/INSTALL/DEVELOPMENT reworded to quickshell-only
- Why: user asked remove all Eww, replace with Waybar + Quickshell, then narrowed to Quickshell-only in Senren Banka visual-novel style, plus full sweep clean
- Verified: `bash -n` switch/ram/dropterm clean; harumi placeholder substitution resolves to none; `nix eval` home packages has quickshell and no eww; live `~/.config/quickshell/shell.qml` regenerated placeholder-free; `git diff --check` clean
- Commit: unpushed (quickshell template + fcitx5/ram/unzzz/zzz scripts still untracked; no push requested)
- Open: user must run `sudo nixos-rebuild switch --flake ~/erogeDOTS#NixChan` then `theme-switch harumi` in own terminal to activate (restarts quickshell + terminals); kill any lingering `.eww-wrapped` daemon manually; remaining sweep candidates untouched: `config/ytfzf` (dead upstream), `vnload/vnsave` symlinks (check Heroic-Saves target), missing meguru/tsumuki wallpapers, `docs/larper.md` + `vpn-instructions.md` review

## 2026-09-26 — Revert TTY boot to normal graphical login

- Changed: `hosts/NixChan/configuration.nix` removes `systemd.defaultUnit = lib.mkForce "multi-user.target"` so default returns to `graphical.target` with SDDM Wayland login
- Why: latest build booted to blank dark TTY, user asked revert to normal login
- Verified: `nix eval` defaultUnit `graphical.target`, sddm.enable `true`; toplevel `--dry-run` resolves clean; `git diff --check` clean
- Commit: unpushed
- Open: user must run `sudo nixos-rebuild switch --flake ~/erogeDOTS#NixChan` in own terminal; RAM trims from same TTY commit left disabled (xrdp, bluetooth/blueman, mpd, discord WantedBy) — say go to re-enable any

## 2026-09-27 — GRUB fast boot timeout 1

- Changed: `hosts/NixChan/configuration.nix` (`boot.loader.timeout` 5 -> 1)
- Why: loader measured 13.5s of 32s total; 5s menu wait + GRUB ext4 read on 95% full root
- Verified: `nix eval` timeout `1`, toplevel `--dry-run` resolves clean, `git diff --check` clean
- Commit: unpushed
- Open: user must run `sudo nixos-rebuild switch --flake ~/erogeDOTS#NixChan` in own terminal; full 1-2s loader needs XBOOTLDR `p6` + systemd-boot via `scripts/mk-boot-partition` if still slow

## 2026-09-27 — GRUB zero timeout

- Changed: `hosts/NixChan/configuration.nix` (`boot.loader.timeout` 1 -> 0)
- Why: user wants no menu wait
- Verified: `nix eval` timeout `0`, `git diff --check` clean
- Commit: unpushed
- Open: user must run `sudo nixos-rebuild switch --flake ~/erogeDOTS#NixChan` in own terminal; hold `Shift`/`Esc` at boot for menu

## 2026-09-27 — Full restructure: split monolith, clean themes, retire dead code

- Changed: `hosts/NixChan/configuration.nix` now imports-only + 12 files in `hosts/NixChan/modules/` (boot/network/desktop/audio/power/fonts/i18n/gaming/bluetooth/remote/nix-settings/users); old `modules/nixos/` deleted. `home/modules/` split from terminal/desktop into shell/dev/fun/desktop/apps/gaming/media/mime (+ discord-opencode); `flake.nix` passes catnap/chatgpt/bot via `extraSpecialArgs` (no double `callPackage`); `shells/full.nix` composes rust+python+go+common; `tester.nix` double jq gone; `webapp.nix` uses `nativeBuildInputs`. `scripts/lib/common.sh` (DOTFILES autodetect, single APPS, safe sed) + `scripts/README.md`; `theme-switch` deduped, dead `config/$app` copy + eww shims removed, `waybar_*` fallback maps to `bar_*`. `themes/SCHEMA.md` new; 5 theme.conf cleaned (dead keys out, cava/cmatrix added, natsume focus + sana icon fixed, opacity wired into 4 terminal templates, quickshell uses `{{BAR_BORDER}}`); meguru/tsumuki parked in `themes/incomplete/`. Retired to `docs/RETIRED.md` + deleted: `scripts/bench`, `scripts/vnload/vnsave` symlinks, `config/ytfzf`, `config/openvpn/`, sunshine toggle, blueman/bluez user pkgs. Docs regen: README/agent/DEVELOPMENT/INSTALL/SKILL/install.sh
- Why: user asked full-access clean — less folders, clear names, unused backed up then deleted, easy to read
- Verified: `nix flake check --no-build` all checks passed; toplevel `--dry-run` resolves (steam udev rules present); `bash -n` all scripts + install.sh clean; `git diff --check` clean; placeholder check: all 17 `{{VARS}}` resolve in all 5 live themes; `theme-switch list` shows 5 live (incomplete skipped); `preview harumi` shows bar border
- Commit: unpushed
- Open: user must run `sudo nixos-rebuild switch --flake ~/erogeDOTS#NixChan` in own terminal, then `theme-switch harumi` to regen live configs (restarts quickshell + terminals)

## 2026-09-27 — Replaced catnap with areofyl/fetch

- Changed: `flake.nix` drops local `catnap` package (nixpkgs `pkgs.fetch` 2.3.0 instead), deleted `pkgs/catnap/`; `home/modules/shell.nix` installs `fetch`, hook runs it on open (interactive, any key passes to shell; `MINI=1` gets `--frames 60`), dropped cache + `clear` override, `mini` alias now `fetch --frames 60`; niri mini spawn just sets `MINI=1`; `themes/templates/catnap/` replaced by `themes/templates/fetch/config` (field list + `label_color`/`logo_outer`/`logo_inner`); 7 theme.conf swap `catnap_primary`/`accent` for `fetch_label`/`logo_outer`/`logo_inner`; `scripts/lib/common.sh` APPS `catnap` -> `fetch`; `theme-switch` apply cleans `~/.config/catnap` + cache once; removed stale `~/.local/bin/catnap`; docs updated (agent/README/DEVELOPMENT/INSTALL/SCHEMA/RETIRED)
- Why: new shells had no fetch at all (home split dropped `catnap` from packages — that was the "broke" part); prebuilt 2.1.1 also stale. areofyl/fetch spins the NixOS logo in 3D with live info, themed per theme-switch
- Verified: `fetch --frames 2` in pty shows NixOS logo + labels in config color; field filtering works; `nix flake check --no-build` pass; toplevel `--dry-run` clean; `fetch-2.3.0` in home packages eval; all 18 `{{VARS}}` resolve in 5 live themes; zero `catnap` hits left in code; `bash -n` + `git diff --check` clean
- Commit: unpushed
- Open: user must run `sudo nixos-rebuild switch --flake ~/erogeDOTS#NixChan` in own terminal, then `theme-switch harumi` (writes `~/.config/fetch/config`, clears catnap leftovers); new terminals show spinning logo until any key

## 2026-09-27 — Scaled fetch down to compact larp layout

- Changed: `themes/templates/fetch/config` now `size=0.6` + `box=1` with 11 fields (os/kernel/uptime/packages/shell/wm/cpu/memory/disk/battery/colors); dropped host/display/terminal/gpu/locale rows
- Why: full-size logo + 17-field dump ate the terminal; boxed compact panel reads hacker, not dashboard
- Verified: pty render with harumi colors — 17 rows, magenta labels, NixOS logo two-tone, box intact; theme keys unchanged; `git diff --check` clean
- Commit: unpushed
- Open: same rebuild + `theme-switch harumi` from previous entry applies it

## 2026-09-27 — Fetch narrowed to fit 81x41

- Changed: `themes/templates/fetch/config` now `size=0.5` with 8 short fields (os/kernel/uptime/packages/shell/wm/memory/disk/colors); dropped cpu/gpu/battery/display/terminal/host/locale
- Why: at 81x41 the box stretched past 81 cols, fetch stacked logo over info and overflowed 41 rows. Narrow fields keep it side-by-side like old catnap
- Verified: pty at `stty cols 81 rows 41` — logo + 49-wide box side-by-side, 15 rows total; `git diff --check` clean
- Commit: unpushed
- Open: same rebuild + `theme-switch harumi`; dropped rows restorable by adding field names back to the template

## 2026-09-27 — Restored catnap as default fetch + new larp wall

- Changed: restored `pkgs/catnap/` + `themes/templates/catnap/` from HEAD, re-added `catnap_primary`/`accent` keys to all 7 theme.conf, flake passes `catnap` again, shell hook back to catnap-on-open with cache + `clear` redraw, `mini` alias + niri mini spawn use catnap mini config. New `scripts/larp` (`open|kill`): TL `fetch --infinite` loop, TR `tty-clock` in `${CMATRIX_COLOR}`, BL `cmatrix`, BR `cava`; 4 floating quadrant rules + `Mod+G` bind in niri template (1920x1080 geometry). `APPS` now 12 (catnap + fetch). Docs updated (agent/README/DEVELOPMENT/INSTALL/SCHEMA/scripts-README/larper.md); RETIRED catnap section removed (no longer retired)
- Why: catnap is the original shell fetch; areofyl keeps its place as the larp centerpiece instead
- Verified: `niri validate` on substituted template passes (4 rules + bind); `nix flake check --no-build` pass; toplevel `--dry-run` 0 errors; both `catnap-2.1.1` and `fetch-2.3.0` in home packages eval; all 20 `{{VARS}}` resolve in 5 live themes; `bash -n` + `git diff --check` clean
- Commit: unpushed
- Open: user must run `sudo nixos-rebuild switch --flake ~/erogeDOTS#NixChan` in own terminal, then `theme-switch harumi`; open terminals show catnap again; `larp` or `Mod+G` opens the wall
