---
name: erogeDOTS
description: A romance VN title-screen desktop with an independent Windows 98 style.
colors:
  paper: "#fff9f0"
  ink: "#43394b"
  muted: "#776477"
  accent: "#995b78"
  tint: "#f3dce4"
  line: "#cbb4bf"
  dark-paper: "#211d29"
  dark-ink: "#f7eef5"
  dark-muted: "#c4b0c2"
  dark-tint: "#393044"
  dark-line: "#76617a"
  win98-paper: "#c0c0c0"
  win98-ink: "#000000"
  win98-muted: "#404040"
  win98-accent: "#000080"
  win98-tint: "#d6d6d6"
  win98-line: "#808080"
  win98-highlight: "#ffffff"
  session-paper: "#171619"
  session-ink: "#fff8fa"
  session-highlight: "#ff9de1"
  session-line: "#5b555e"
typography:
  headline:
    fontFamily: "Noto Serif JP"
    fontSize: "25px"
  section:
    fontFamily: "Noto Serif JP"
    fontSize: "18px"
  ribbon:
    fontFamily: "Noto Serif JP"
    fontSize: "14px"
  win98-title:
    fontFamily: "Noto Sans"
    fontSize: "16px"
    fontWeight: 700
  title:
    fontFamily: "Noto Serif JP"
    fontSize: "16px"
    fontWeight: 700
  body:
    fontFamily: "Noto Sans"
    fontSize: "12px"
  label:
    fontFamily: "Noto Sans"
    fontSize: "11px"
rounded:
  square: "0px"
  frame: "5px"
  control: "3px"
  inset: "2px"
spacing:
  tight: "6px"
  related: "8px"
  group: "12px"
  panel: "24px"
components:
  win98-button:
    backgroundColor: "{colors.win98-paper}"
    textColor: "{colors.win98-ink}"
    typography: "{typography.body}"
    rounded: "{rounded.square}"
    height: "38px"
  win98-button-selected:
    backgroundColor: "{colors.win98-accent}"
    textColor: "{colors.win98-paper}"
    rounded: "{rounded.square}"
    height: "38px"
  win98-frame:
    backgroundColor: "{colors.win98-paper}"
    rounded: "{rounded.square}"
  button:
    backgroundColor: "{colors.paper}"
    textColor: "{colors.ink}"
    typography: "{typography.body}"
    rounded: "{rounded.control}"
    height: "38px"
  button-selected:
    backgroundColor: "{colors.accent}"
    textColor: "{colors.paper}"
    rounded: "{rounded.control}"
    height: "38px"
  button-quiet:
    backgroundColor: "{colors.paper}"
    textColor: "{colors.ink}"
    rounded: "{rounded.control}"
    height: "30px"
  dialogue-frame:
    backgroundColor: "{colors.paper}"
    rounded: "{rounded.frame}"
  workspace:
    backgroundColor: "{colors.paper}"
    textColor: "{colors.ink}"
    typography: "{typography.label}"
    rounded: "{rounded.control}"
    height: "30px"
  title-choice:
    textColor: "{colors.ink}"
    typography: "{typography.headline}"
    height: "58px"
  session-choice:
    backgroundColor: "{colors.session-paper}"
    textColor: "{colors.session-ink}"
    height: "88px"
  ribbon-tab:
    textColor: "{colors.ink}"
    typography: "{typography.ribbon}"
    height: "40px"
---

# Design System: erogeDOTS

## Overview

**Creative North Star: "Romance VN Title Screen & Stationery"**

A daily desktop inhabits an early-2000s romance visual novel title screen and its extras: existing character art, cream stationery, pastel character colors, floral corners and bilingual serif choices. The established character identities and wallpapers supply the imagery. A quiet serif ribbon leads into the same paper-framed pages as the title menu.

Compact controls keep everyday actions readable and predictable. Windows 98 remains a second world of grey control panels, navy title bars and square bevels, with its richer status bar and framed settings menu. Character names, wallpapers and desktop actions remain available in both styles; the title screen and sliding drawer belong to Romance VN.

This document records the shipped Quickshell templates and theme renderer; Harumi is the concrete Romance VN reference palette in the frontmatter. Character palettes supply the Romance VN semantic roles; Windows 98 overrides the interface roles independently. Terminal palettes remain separately dark. Style is saved separately from the character in `~/.config/theme/style` (`vn` or `win98`, default `vn`), following the configured config directory.

Panel brightness and the system app preference are independent of the character and desktop style. Load now includes separate Light/Dark choices for VN panels and System apps, followed by the character gallery and a graphical Add a theme form. The NixOS & Niri workshop combines real package search from the locked Nixpkgs source, a live miniature layout preview and an advanced source editor. All of these surfaces retain the existing stationery controls, serif headings and fine rules.

**Key Characteristics:**

- Full character imagery balanced by cream paper and fine rules.
- Pastel character accents and geometric floral ornaments.
- Serif bilingual choices and titles paired with compact sans-serif details.
- Hover previews with gentle sliding motion and deliberate keyboard focus.
- Independent Windows 98 grey panels, navy selection and square bevels.

## Colors

The Harumi palette places warm paper behind plum ink and muted rose accents. Exact reference values live in the frontmatter; other character palettes replace these roles together.

Light Romance VN uses the character's paper palette. Dark Romance VN uses the `dark-paper`, `dark-ink`, `dark-muted`, `dark-tint` and `dark-line` defaults in the frontmatter while retaining the same frame geometry and type. Dark accent inherits the character's `PRIMARY_LIGHT`; an explicit `VN_DARK_*` value can override each dark role. These are panel roles, independent of the terminal palette and system app preference.

### Primary

- **Accent:** selected buttons, title-choice emphasis, frame outlines, focus and floral centers.

### Secondary

- **Tint:** hover and pressed fills, nameplates, slider tracks and petals.

### Neutral

- **Paper / ink:** panel surfaces and primary readable text.
- **Muted / line:** supporting text and fine separators or inset borders.

Windows 98 maps the same roles to its fixed grey, black and navy palette. White highlights and dark bevel edges supply its tactile contrast; character wallpaper still provides the imagery. The title screen blends paper over the wallpaper horizontally, making the menu readable while preserving character art on the opposite side.

**The Character Palette Rule.** Read panel colors through Theme roles so components follow the character palette in Romance VN and the fixed interface palette in Windows 98. The screenshot-referenced Exit choices retain their black washi and pink highlight across Romance VN character palettes.

## Typography

Noto Serif JP gives bilingual title choices, character names, page headings and ribbon tabs their printed quality. Noto Sans carries descriptions, body text and ordinary controls. Windows 98 uses Noto Sans throughout. The frontmatter records reused roles rather than a fabricated modular scale: headline for title choices and page headings; section for compact music titles and chapter sections; title for smaller headings; ribbon for navigation; body and label for everyday controls and supporting information. Headline weight becomes bold for selected/hovered title choices and page headings. The title logo and dashboard clock use local larger sizes rather than a global display token.

Text defaults to plain text and right elision; longer game names, expanded music metadata and error messages explicitly wrap. Bilingual choice labels accompany concrete desktop subtitles. Configuration source editing uses a monospace face within the same paper-and-ink field treatment; this specialist text role does not replace ordinary control typography.

**The Two Voices Rule.** In Romance VN, use the serif for names, title choices, navigation and section titles; use the sans-serif for ordinary controls, status and supporting text. Windows 98 uses the sans-serif throughout.

## Layout

Romance VN reserves only its 40px top ribbon. Its row uses 20px left and 16px right margins with 10px gaps. Above 960px it uses the longer navigation labels; sound is added above 1120px and the tray above 1180px. Dashboard, Music Room, Chapters and Characters remain the central navigation.

The title menu occupies the viewport with cropped character wallpaper. A paper gradient supports the left menu; the character name sits opposite when no page is open. Left/right margins scale with the viewport with a 32px minimum. The choice column is 320px above 1000px viewport width and 260px otherwise; its choices scroll when needed. A selected page occupies the remaining area in a stationery frame with 24px inner margins. This describes the title surface, not a required composition for every new screen.

The top drawer starts below the ribbon and overlays the desktop without adding an exclusive zone. It centers beneath the triggering tab and stays at least 16px from each screen edge. Page widths are 480–820px, capped by available screen width; heights are capped by screen height. Drawer page content uses 24px margins and scrolling. Character choices use three columns above 660px content width and two otherwise, with 12px gaps. Flowchart has a vertical workspace spine and arrowed branches to live windows: 60px nodes, 76px branch pitch and 28px inter-chapter space. Workspace width is capped at 180px or 42% of the page; the window branch uses the remaining width. Empty chapters stay legible without inventing windows.

Windows 98 retains a 52px bar with 6px horizontal padding, 6px row gaps and 3px workspace gaps. Its Super+S control panel sits above bottom center, capped at 800px wide and 610px tall, with height limited to screen height minus 110px. Its bottom margin is 14% of screen height, clamped to 36–120px. Content margins are 24px with 44px above content beneath the title bar. The 220px wallpaper column disappears below 680px card width. Character theme and Style remain adjacent below the scrollable content.

The Windows 98 bar progressively adds tray (above 720px), volume (760px), battery (840px), session (900px), Wi-Fi (940px), media (1100px), window title (1180px), brightness (1280px) and date (1440px). Hardware and player availability also govern visibility. These are desktop width adaptations, not a separate mobile layout.

The Add a theme form stacks labeled fields with 12px spacing, a 170px cropped wallpaper preview with a 52px paper-backed caption, wrapping palette choices and a 22px swatch strip. The workshop results occupy a clipped scroll area capped at 360px; at most the first 60 matches are shown with the total count. Its Niri miniature is 140px tall; numeric labels and controls collapse from two columns to one below 410px. Advanced files use a 280px source editor.

## Elevation & Depth

Romance VN frames use opaque paper, a one-pixel accent outline and a secondary line inset by 5px. The title screen's paper gradient, thin rules and restrained translucent hover fills carry depth without drop shadows. The clipped drawer slides from above its frame; its input region follows the visible height so unrevealed content does not intercept the desktop.

Windows 98 replaces the inset line and ornaments with square bevels: 2px white top/left edges and dark bottom/right edges, reversed on pressed or selected controls. Generated GTK surfaces use the renderer's 1px inset bevel. The framed control panel dims the wallpaper with a translucent backdrop. Bevels are structural edges native to this style, not ambient shadows.

**The Stationery Frame Rule.** In Romance VN, separate surfaces with paper, fine outlines and an inset border; keep ornaments at frame corners.

**The Beveled Control Rule.** In Windows 98, square frames and raised controls use light top/left and dark bottom/right edges; reverse the edges for pressed or selected controls.

## Shapes

Romance VN's small radii preserve a lightly softened stationery silhouette. Frames use the frame radius, buttons and nameplates the control radius, and inset borders and slider parts the inset radius. Four small rounded petals and a center dot form each 26px corner ornament; they are drawn geometry, independent of icon fonts. Title choices and ribbon highlights are rectangular with fine rules; a small geometric diamond marks highlighted title choices. Exit choices alone follow the user's reference with capsule ends and two inset rims. Windows 98 uses square frames, buttons, calendar cells and slider parts, with no floral ornaments or floating nameplate. Its menu adds a navy title bar.

## Components

- **Title choices:** 58px stacked bilingual rows with a serif English choice, smaller Japanese label and sans-serif desktop subtitle. Hover, selection and keyboard focus use accent text, a translucent tint fill and a geometric diamond; the English label moves right over 180ms with OutCubic easing. The highlight fades over 150ms. Keyboard focus is strong and the accessible name includes the action description. Up/Down traverse the focus chain; Return and keypad Enter activate once. The character-gallery choice is Load / ロード.
- **Exit choices:** the selected wallpaper fills the scene with a modest dark veil and no enclosing panel. Sleep, Lock, Restart and Shutdown use 88px black washi bars, capsule ends, double rims and sparse cream/gold flecks. Confirmation uses two vertically stacked bilingual bars, defaulting to No. A centered 28px English label sits above 22px Japanese; warm-white text turns pink on hover, selection or keyboard focus over 120ms. Keyboard focus also colors the outer rim. Texture repaints only on size or label changes. Action descriptions remain readable above confirmation, in tooltips and in accessible names. Short screens scroll and reveal focused choices. Up/Down and Left/Right traverse; Enter activates once and Escape cancels. Windows 98 retains grey/navy square beveled choice surfaces. The title-screen choices retain their existing style.
- **Ribbon navigation:** serif tabs with transparent resting backgrounds and a fine bottom accent rule for hover, keyboard focus or the open page. The hover fill fades over 140ms and the underline changes over 180ms with OutCubic easing. Keyboard focus thickens the underline. The logo opens the title menu; navigation tabs preview their shared pages.
- **Top drawer:** hover intent waits 160ms; pointer exit gives 320ms grace; entering the content holds it open. An already open preview changes pages as the pointer crosses tabs. Click pins the page, a second click on the same pinned tab closes it, and Escape closes it. Pinned drawers receive keyboard focus; hover previews do not. The drawer closes when the title menu or calendar takes over. Sliding uses 360ms OutExpo easing; panel width and horizontal position adapt over 220ms OutCubic.
- **Shared pages:** dashboard, music, characters, workspaces, connections and extras use the same DesktopPages content in title-menu frames and drawer frames. Each has a serif page title, fine divider, scrollable body and Return action. System Config keeps Character theme and Style adjacent and opens the NixOS & Niri configuration page. Its Packages, Niri layout and Config files sections reuse the existing paper fields, buttons, fine dividers and wrapped status text.
- **Appearance choices:** on Load, VN panels and System apps each have independent Light/Dark selected buttons. Settings are persisted in `~/.config/theme/appearance` (default `light`) and `~/.config/theme/system-appearance` (default `dark`), following the configured config directory. System apps sets the GNOME `color-scheme` preference to `prefer-light` or `prefer-dark`; application support determines how that preference is presented. Dark panels with System apps set to Light is a valid combination. Windows 98 keeps its fixed grey palette and disables the VN panel choices while retaining the saved VN preference; System apps remains selectable. Busy theme changes disable the controls.
- **Add a theme:** Add a character opens an in-page graphical form for a lowercase theme ID, character name, optional display name and optional game/source. Browse uses a native image picker for PNG, JPEG and WebP; a path field also accepts local files and `~/` paths. The wallpaper crop previews with the entered name and source; a failed image displays a readable error. Six starter palettes (Sakura Pink, Honey Gold, Forest, Lavender, Crimson and Ocean) populate a swatch strip; Edit individual colors exposes all 15 labeled color fields. The preview remains framed by the active desktop theme. Create theme saves the new theme through the existing picker backend, freezes the created form and exposes a separate Apply theme action; creating a theme does not automatically switch the desktop.
- **Package search:** the workshop searches the actual locked Nixpkgs source and shows its revision when available, a wrapped progress/error message, total matches and an explicit first-60 limit. Each result shows a local application icon when available, otherwise the bundled official Nix SVG, plus name/version, attribute, description and Add/Added state. Fine dividers separate the scrolling results. Your extra packages lists saved additions with Remove, while Add exact package name remains available. Adding or removing saves the package list; Check NixOS and Apply NixOS are separate terminal actions. Existing Home Manager packages remain in Advanced files.
- **Niri layout and advanced files:** numeric controls update a two-window miniature immediately: tinted desktop, paper windows, accent outline around the focused left window and a live width percentage. Gap, outline and default width edits remain local until Save layout; Apply Niri is a separate action. Unsupported custom layouts direct users to Advanced files. That editor has NixOS, Home Manager and Niri targets, a monospace field, Save & validate and Reload. Saving backs up and checks syntax; switching targets with unsaved edits reports a message. Check NixOS validates the full system before an explicit Apply NixOS. Applying uses the existing backend; the miniature itself does not rearrange live windows.
- **Tool actions:** Extra Mode and System Config reuse one quiet VnAction row with a 26px authored line icon, serif 16px action name and wrapped 11px explanation. A 14px outgoing icon distinguishes external tools from in-page navigation or confirmation. Live status moves below the label below 360px row width. Connections/sound and appearance/configuration use existing fine rules and headings, not nested cards. Disabled hardware remains muted and noninteractive; all six Extra tools and the existing configuration workshop retain their original routes. Only Extra Mode and System Config gain small title-description icons; other title choices remain unchanged. NetworkManager owns local Wi-Fi/VPN credential entry; no repository API-secret editor is introduced without a real consumer.
- **Character choices:** real local theme metadata and wallpaper crops form selectable gallery buttons. Active selection uses accent fill and paper text. Character selection changes wallpaper and palette, retains the independent style, and reveals the ready main title after the black curtain. Existing theme add/picker actions remain available.
- **Buttons:** paper and ink at rest; tint on hover or press; accent and bold paper text when selected. Horizontal padding is 12px, or 6px for compact controls. Compact height is 30px. Keyboard focus thickens the accent border to 2px. Disabled labels use muted text at reduced opacity.
- **Fields and configuration:** text fields use paper, ink and muted placeholder text; accent selection keeps paper-colored selected text. Focus changes the fine line border to a stronger accent outline. The source editor keeps this treatment with plain monospace text, horizontal scrolling and mouse selection. Editable native numeric controls inherit the theme palette. Busy actions disable their controls; validation and errors remain readable wrapped text. Saving is distinct from applying, and the full-system check and apply actions show output in the terminal.
- **Windows 98 buttons:** the same dimensions and focus behavior, using the fixed grey/navy palette, square corners and raised or sunken bevels. Quiet buttons retain the bevel; Romance VN quiet buttons reveal border and inset on hover while preserving the focus border.
- **Frames:** double outlines with opposite floral corners in Romance VN; square bevels and a navy title bar in the Windows 98 control panel. Existing wallpaper crops remain source imagery rather than new raster assets.
- **Workspace navigation:** Romance VN calls workspaces Chapters. Flowchart links them down a spine and branches to their actual windows; active chapters and the focused window use the selected treatment. Clicking focuses a workspace or window and returns to the desktop. Windows 98 retains compact two-digit workspace buttons with urgency markers. Scrolling the Chapters tab or old workspace controls switches workspaces on that display.
- **Scene continuity:** character/style changes fade to black in 280ms, render and restart behind an independent all-display curtain, wait for decoded title artwork, then unveil the ready main title in 450ms. The arriving title stays below the curtain until its fade completes; no gallery or preparation label flashes between scenes. A failed switch releases the curtain, with a 30-second watchdog as a final recovery path. Normal title openings retain the original 420ms entrance and unchanged choice styling. A short generic synthetic female “eroDOTS” title voice plays once per opening; local replacements and a persistent mute file keep sound under the user's control.
- **Sliders:** labeled percentage above a tinted 8px track, accent progress and a paper thumb measuring 13px by 20px. Focus thickens the thumb border; unavailable controls dim and show “Unavailable”.
- **Music:** artwork comes from the current MPRIS player; a geometric disc fills missing, loading or failed artwork. The compact shared view uses a 76px cover, the full Music Room a 140px cover. Track, artist and album/player identity accompany transport controls. Prev, Play/Pause and Next reflect actual player capabilities. Progress appears only with position/length support and seeking reflects canSeek. The retained Windows 98 menu/bar artwork is 64px/24px. Romance VN Music Room adds an accent-colored live spectrum from one shared CAVA sink-monitor process, active only for a visible music page. Bars ease between measured levels; silence rests at the baseline and unavailable capture shows a muted message. The spectrum follows audio rather than a decorative time loop.
- **Title terminal:** the footer Terminal button and Super+Enter from the title screen open native floating Ghostty over the wallpaper on an empty chapter. The title layer lowers behind it and releases keyboard focus; Menu focus returns focus to the choices. When the terminal closes, the helper restores the original chapter if the terminal chapter is still focused. Terminal colors retain the character terminal palette.
- **Daily actions:** notifications and Do Not Disturb, calendar, sound scrolling/right-click mute, connections, brightness and session tools preserve established actions. Availability is shown through enabled states and service-dependent visibility.

**The Preview Focus Rule.** Hover may reveal desktop pages without taking keyboard focus; pinning makes the drawer an intentional keyboard surface.

The sidecar contains self-contained HTML/CSS visual translations for the preview panel. QML remains the source for desktop behavior; these snippets do not connect to system actions.

## Do's and Don'ts

- Do reuse the existing character names and wallpaper assets.
- Do show selected controls with accent fill and paper text.
- Do retain visible keyboard focus and readable unavailable states.
- Do preserve independent character and style choices.
- Do use square bevels and sans-serif titles for Windows 98.
- Do preserve desktop focus during hover previews and provide Escape for pinned drawers.
- Do explain visual-novel menu names with their real desktop actions.
- Do show live audio levels and honest idle or unavailable states.
- Do keep configuration edits, validation and apply actions explicit, with terminal output for system checks and rebuilds.
- Do keep VN panel brightness and the system app preference independent, including dark panels with light system apps.
- Do preview theme imagery and palette choices before creation, then keep Apply theme as a separate action.
- Do use real locked-Nixpkgs results, local icons or the official Nix fallback, and visible search limits.
- Don't invent character artwork or quotations.
- Don't replace interface surface roles with the terminal background palette.
- Don't turn Romance VN navigation back into an ordinary status-card strip.
- Don't use decorative motion at the expense of predictable daily controls.
