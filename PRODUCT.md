# erogeDOTS

<!-- impeccable:product-schema 1 -->

## Platform
Linux desktop: NixOS, Niri, and Quickshell (Qt Quick / QML).

## Purpose
A personal desktop that inhabits a romance visual novel title screen and its extras, with Windows 98 as an independent second style. Character palettes and wallpapers remain independent of the desktop style; terminals keep their character palettes.

## Existing capabilities
Five established character palettes, a Rust theme picker, generated application configs, quick settings, real MPRIS artwork and capability-aware controls, a system tray, calendar, notification counts, scroll controls, Niri keybindings, and a four-terminal larp workspace. Romance VN adds a full-screen title menu, a local character/wallpaper gallery, and a top hover drawer for dashboard, music, chapters, characters, connections and extras. Windows 98 retains its richer compact bar and framed control panel.

## Constraints
Keep the theme-switch workflow and existing desktop actions. Keep generated files out of Git. Preserve local changes to Home Manager's MPD configuration. Existing wallpapers and character names are the source assets; do not invent character artwork or quotes.

## Working assumptions
This is the user's daily desktop, so legibility, keyboard use and predictable controls govern motion. Hover previews must preserve desktop keyboard focus; pinned drawers and the title menu support keyboard use. The confirmed title-screen extension carries forward the original session direction rather than reopening the visual-world choice.

## Confirmed visual direction
The user chose early-2000s romance visual novels: cream panels, pastel accents, and delicate ornaments. Keep the five existing character identities and wallpaper assets. Windows 98 is a second durable style: grey surfaces, navy selection, square beveled controls and compact sans-serif text. The adjacent Character theme and Style controls choose these dimensions independently; the saved style lives in `~/.config/theme/style` (`vn` or `win98`, default `vn`) beside the saved character in `~/.config/theme/active`. The config location follows `XDG_CONFIG_HOME` or `EROGEDOTS_CONFIG_HOME` when set.


## Confirmed title-screen extension
The user explicitly rejected an ordinary Waybar appearance and requested a Senren Banka-like title menu with character/background selection and a Caelestia-like top hover dashboard. Romance VN presents the existing character art across the viewport, a logo and vertically stacked bilingual choices on the left, and the character name opposite. A quiet serif ribbon remains on the desktop.

The title choices keep their visual-novel names and explain their desktop action: New Game launches applications; Load selects real local character themes; Continue returns to the desktop; Flowchart opens workspaces and windows; Music Room controls the current player and sound; Extra Mode provides desktop tools and notifications; System Config provides connections, brightness, independent appearance choices and NixOS & Niri configuration; Exit opens session actions. The gallery derives from installed local theme directories and uses their actual wallpaper and metadata; it is not restricted to a hardcoded five-character list.

The title menu and top drawer share their page content. Hover opens after 160ms, leaving starts a 320ms grace period, and staying inside holds the drawer open. Clicking pins it; Escape closes it. The drawer slides over the desktop in 360ms without reserving desktop space. Character theme and Style remain adjacent in System Config. Selecting a character updates its wallpaper and palette while retaining the chosen Romance VN or Windows 98 style.


## Confirmed daily controls extension
The title choices support Up/Down focus traversal and activate once with Return or keypad Enter. The title footer's Terminal action and Super+Enter while the Romance VN title screen is open bring up a real floating Ghostty terminal over the character art on an empty chapter. The menu yields keyboard focus to the terminal; Menu focus returns it to the choices. Closing the terminal restores the original chapter when the terminal chapter is still focused. Super+Enter elsewhere retains ordinary terminal behavior.

Music Room includes a live CAVA spectrum from the audio sink monitor. One shared capture process runs only while a Romance VN music page is visible. Silence stays flat; invalid frames are discarded and capture failures show an unavailable state. The spectrum complements the existing player artwork and capability-aware transport controls.

System Config opens NixOS & Niri with Packages, Niri layout and Config files sections. Extra packages are validated against locked Nixpkgs and saved declaratively in `home/desktop-packages.json`, which Home Manager imports. Niri layout exposes window gaps, focus outline and default column width. Config files edits the bounded NixOS, Home Manager and Niri source files, checks syntax, saves backups, writes atomically and rejects stale edits. Check NixOS evaluates the complete system configuration. Saving and applying are separate actions: Apply Niri renders the current theme and reloads Niri; Apply NixOS runs the rebuild in the visible title terminal with normal password entry and progress output. Development verification did not initiate a privileged system rebuild.
