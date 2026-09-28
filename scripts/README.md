# scripts/

| Script | Purpose |
|---|---|
| `theme-switch <theme>\|list\|current\|preview\|picker` | Generate + apply theme, restart apps |
| `tspick` | Shortcut to the interactive picker |
| `dropterm` | Quake terminal under the bar (`Mod+grave`) |
| `larp [open\|kill]` | 2x2 hacker wall: fetch + tty-clock + cmatrix + cava (`Mod+G`) |
| `cliphist-pick` | Clipboard history, image-aware paste (`Mod+Ctrl+V`) |
| `fcitx5-cycle.sh` | Cycle EN/JP/TH input (called from niri keys) |
| `ram show\|diet\|watch` | RAM breakdown + safe user-process diet |
| `unzzz start\|stop` | Stay awake with lid closed (user inhibit service) |
| `zzz` | Hibernate now (needs swap; fails without it) |
| `mk-boot-partition` | LIVE-USB ONLY: shrink p5, create 1G XBOOTLDR p6 |

Shared bits live in `lib/common.sh` (`DOTFILES` autodetect, `APPS` list,
`should_skip`, `sed_escape`). Source it, don't duplicate it.

Retired scripts are documented in `docs/RETIRED.md`, not here.
