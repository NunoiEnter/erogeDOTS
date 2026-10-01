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
  win98-paper: "#c0c0c0"
  win98-ink: "#000000"
  win98-muted: "#404040"
  win98-accent: "#000080"
  win98-tint: "#d6d6d6"
  win98-line: "#808080"
  win98-highlight: "#ffffff"
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

**Key Characteristics:**

- Full character imagery balanced by cream paper and fine rules.
- Pastel character accents and geometric floral ornaments.
- Serif bilingual choices and titles paired with compact sans-serif details.
- Hover previews with gentle sliding motion and deliberate keyboard focus.
- Independent Windows 98 grey panels, navy selection and square bevels.

## Colors

The Harumi palette places warm paper behind plum ink and muted rose accents. Exact reference values live in the frontmatter; other character palettes replace these roles together.

### Primary

- **Accent:** selected buttons, title-choice emphasis, frame outlines, focus and floral centers.

### Secondary

- **Tint:** hover and pressed fills, nameplates, slider tracks and petals.

### Neutral

- **Paper / ink:** panel surfaces and primary readable text.
- **Muted / line:** supporting text and fine separators or inset borders.

Windows 98 maps the same roles to its fixed grey, black and navy palette. White highlights and dark bevel edges supply its tactile contrast; character wallpaper still provides the imagery. The title screen blends paper over the wallpaper horizontally, making the menu readable while preserving character art on the opposite side.

**The Character Palette Rule.** Read panel colors through Theme roles so components follow the character palette in Romance VN and the fixed interface palette in Windows 98.

## Typography

Noto Serif JP gives bilingual title choices, character names, page headings and ribbon tabs their printed quality. Noto Sans carries descriptions, body text and ordinary controls. Windows 98 uses Noto Sans throughout. The frontmatter records reused roles rather than a fabricated modular scale: headline for title choices and page headings; section for compact music titles and chapter sections; title for smaller headings; ribbon for navigation; body and label for everyday controls and supporting information. Headline weight becomes bold for selected/hovered title choices and page headings. The title logo and dashboard clock use local larger sizes rather than a global display token.

Text defaults to plain text and right elision; longer game names, expanded music metadata and error messages explicitly wrap. Bilingual choice labels accompany concrete desktop subtitles. Configuration source editing uses a monospace face within the same paper-and-ink field treatment; this specialist text role does not replace ordinary control typography.

**The Two Voices Rule.** In Romance VN, use the serif for names, title choices, navigation and section titles; use the sans-serif for ordinary controls, status and supporting text. Windows 98 uses the sans-serif throughout.

## Layout

Romance VN reserves only its 40px top ribbon. Its row uses 20px left and 16px right margins with 10px gaps. Above 960px it uses the longer navigation labels; sound is added above 1120px and the tray above 1180px. Dashboard, Music Room, Chapters and Characters remain the central navigation.

The title menu occupies the viewport with cropped character wallpaper. A paper gradient supports the left menu; the character name sits opposite when no page is open. Left/right margins scale with the viewport with a 32px minimum. The choice column is 320px above 1000px viewport width and 260px otherwise; its choices scroll when needed. A selected page occupies the remaining area in a stationery frame with 24px inner margins. This describes the title surface, not a required composition for every new screen.

The top drawer starts below the ribbon and overlays the desktop without adding an exclusive zone. It centers beneath the triggering tab and stays at least 16px from each screen edge. Page widths are 480–820px, capped by available screen width; heights are capped by screen height. Drawer page content uses 24px margins and scrolling. Character choices use three columns above 660px content width and two otherwise, with 12px gaps. Chapter lists and tool actions follow the available page width.

Windows 98 retains a 52px bar with 6px horizontal padding, 6px row gaps and 3px workspace gaps. Its Super+S control panel sits above bottom center, capped at 800px wide and 610px tall, with height limited to screen height minus 110px. Its bottom margin is 14% of screen height, clamped to 36–120px. Content margins are 24px with 44px above content beneath the title bar. The 220px wallpaper column disappears below 680px card width. Character theme and Style remain adjacent below the scrollable content.

The Windows 98 bar progressively adds tray (above 720px), volume (760px), battery (840px), session (900px), Wi-Fi (940px), media (1100px), window title (1180px), brightness (1280px) and date (1440px). Hardware and player availability also govern visibility. These are desktop width adaptations, not a separate mobile layout.

## Elevation & Depth

Romance VN frames use opaque paper, a one-pixel accent outline and a secondary line inset by 5px. The title screen's paper gradient, thin rules and restrained translucent hover fills carry depth without drop shadows. The clipped drawer slides from above its frame; its input region follows the visible height so unrevealed content does not intercept the desktop.

Windows 98 replaces the inset line and ornaments with square bevels: 2px white top/left edges and dark bottom/right edges, reversed on pressed or selected controls. Generated GTK surfaces use the renderer's 1px inset bevel. The framed control panel dims the wallpaper with a translucent backdrop. Bevels are structural edges native to this style, not ambient shadows.

**The Stationery Frame Rule.** In Romance VN, separate surfaces with paper, fine outlines and an inset border; keep ornaments at frame corners.

**The Beveled Control Rule.** In Windows 98, square frames and raised controls use light top/left and dark bottom/right edges; reverse the edges for pressed or selected controls.

## Shapes

Romance VN's small radii preserve a lightly softened stationery silhouette. Frames use the frame radius, buttons and nameplates the control radius, and inset borders and slider parts the inset radius. Four small rounded petals and a center dot form each 26px corner ornament; they are drawn geometry, independent of icon fonts. Title choices and ribbon highlights are rectangular with fine rules; a small geometric diamond marks highlighted title choices. Windows 98 uses square frames, buttons, calendar cells and slider parts, with no floral ornaments or floating nameplate. Its menu adds a navy title bar.

## Components

- **Title choices:** 58px stacked bilingual rows with a serif English choice, smaller Japanese label and sans-serif desktop subtitle. Hover, selection and keyboard focus use accent text, a translucent tint fill and a geometric diamond; the English label moves right over 180ms with OutCubic easing. The highlight fades over 150ms. Keyboard focus is strong and the accessible name includes the action description. Up/Down traverse the focus chain; Return and keypad Enter activate once. The character-gallery choice is Load / ロード.
- **Ribbon navigation:** serif tabs with transparent resting backgrounds and a fine bottom accent rule for hover, keyboard focus or the open page. The hover fill fades over 140ms and the underline changes over 180ms with OutCubic easing. Keyboard focus thickens the underline. The logo opens the title menu; navigation tabs preview their shared pages.
- **Top drawer:** hover intent waits 160ms; pointer exit gives 320ms grace; entering the content holds it open. An already open preview changes pages as the pointer crosses tabs. Click pins the page, a second click on the same pinned tab closes it, and Escape closes it. Pinned drawers receive keyboard focus; hover previews do not. The drawer closes when the title menu or calendar takes over. Sliding uses 360ms OutExpo easing; panel width and horizontal position adapt over 220ms OutCubic.
- **Shared pages:** dashboard, music, characters, workspaces, connections and extras use the same DesktopPages content in title-menu frames and drawer frames. Each has a serif page title, fine divider, scrollable body and Return action. System Config keeps Character theme and Style adjacent and opens the NixOS & Niri configuration page. Its Packages, Niri layout and Config files sections reuse the existing paper fields, buttons, fine dividers and wrapped status text.
- **Character choices:** real local theme metadata and wallpaper crops form selectable gallery buttons. Active selection uses accent fill and paper text. Character selection changes wallpaper and palette, retains the independent style, and reopens the Characters page. Existing theme add/picker actions remain available.
- **Buttons:** paper and ink at rest; tint on hover or press; accent and bold paper text when selected. Horizontal padding is 12px, or 6px for compact controls. Compact height is 30px. Keyboard focus thickens the accent border to 2px. Disabled labels use muted text at reduced opacity.
- **Fields and configuration:** text fields use paper, ink and muted placeholder text; accent selection keeps paper-colored selected text. Focus changes the fine line border to a stronger accent outline. The source editor keeps this treatment with plain monospace text, horizontal scrolling and mouse selection. Editable native numeric controls inherit the theme palette. Busy actions disable their controls; validation and errors remain readable wrapped text. Saving is distinct from applying, and the full-system check and apply actions show output in the terminal.
- **Windows 98 buttons:** the same dimensions and focus behavior, using the fixed grey/navy palette, square corners and raised or sunken bevels. Quiet buttons retain the bevel; Romance VN quiet buttons reveal border and inset on hover while preserving the focus border.
- **Frames:** double outlines with opposite floral corners in Romance VN; square bevels and a navy title bar in the Windows 98 control panel. Existing wallpaper crops remain source imagery rather than new raster assets.
- **Workspace navigation:** Romance VN calls workspaces Chapters and lists their actual windows; active chapters use the selected treatment. Clicking focuses a workspace or window and returns to the desktop. Windows 98 retains compact two-digit workspace buttons with urgency markers. Scrolling the Chapters tab or old workspace controls switches workspaces on that display.
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
- Don't invent character artwork or quotations.
- Don't replace interface surface roles with the terminal background palette.
- Don't turn Romance VN navigation back into an ordinary status-card strip.
- Don't use decorative motion at the expense of predictable daily controls.
