# Theme schema

`themes/<name>/theme.conf` is INI-ish `key = "value"`. `theme-switch` uppercases
keys (`primary` -> `{{PRIMARY}}`) and substitutes into `themes/templates/<app>/`.

## Required (theme-switch refuses without these)

`primary`, `primary_light`, `primary_dark`, `bg`, `fg`, `wallpaper`

## Colors (consumed by templates)

`bg`, `bg_light`, `bg_surface`, `fg`, `fg_dim`,
`primary`, `primary_light`, `primary_dark`,
`niri_focus_active`, `niri_focus_inactive`, `niri_shadow`,
`bar_border`, `bar_workspace_active`, `bar_workspace_default`, `bar_clock_icon`,
`fetch_label`, `fetch_logo_outer`, `fetch_logo_inner`,
`catnap_primary`, `catnap_accent`,
`cava_colors`, `cmatrix_color`, `ghostty_opacity`

Old `waybar_*` names still work as fallback for one release
(`waybar_border` -> `bar_border`, etc.), then they go.

## Character meta (banner + picker only, not templates)

`char_name`, `char_full`, `char_game`, `char_quote`

## Static templates (no placeholders, copied as-is)

`swaync/config.json`, `cmatrix/config` — behavior only, colors come from
sibling files (`swaync/style.css`) or env (`CMATRIX_COLOR` in `~/.config/theme/env`).

## Fetch config

`themes/templates/fetch/config` lists the fields to show plus `label_color`,
`logo_outer`, `logo_inner` from `fetch_label`, `fetch_logo_outer`,
`fetch_logo_inner` (named colors only: red green yellow blue magenta cyan white).
Layout is fixed narrow fit (`size=0.5`, `box=1`, short fields only) so the
logo stays side-by-side at 81x41. Long rows (cpu/gpu/battery/display) are out —
they would stretch the box past 81 cols and stack the layout.
Fetch reads it on every run — no restart needed after `theme-switch`.

## Terminal base palette

`ghostty` / `kitty` / `alacritty` / `foot` templates keep a tokyonight base
for the 16 ANSI slots and override `background`, `foreground`, `cursor`,
`selection`, plus `{{PRIMARY}}` / `{{PRIMARY_LIGHT}}` accents.
`background-opacity` comes from `ghostty_opacity`. Full per-theme 16-color
palettes are out of scope until someone authors them.

## Incomplete themes

`themes/incomplete/*/` holds themes missing assets (wallpapers). `theme-switch
list` / `picker` skip it. Move a theme back to `themes/<name>/` once its
`wallpaper` file exists and `theme-switch <name>` generates zero `{{`.
