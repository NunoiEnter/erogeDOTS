---
name: erogeDOTS
description: An early-2000s romance visual novel desktop.
colors:
  paper: "#fff9f0"
  ink: "#43394b"
  muted: "#776477"
  accent: "#995b78"
  tint: "#f3dce4"
  line: "#cbb4bf"
typography:
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
  frame: "5px"
  control: "3px"
  inset: "2px"
spacing:
  tight: "6px"
  related: "8px"
  group: "12px"
  panel: "24px"
components:
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
---

# Design System: erogeDOTS

## Overview

**Creative North Star: "Romance VN Stationery"**

A daily desktop framed like an early-2000s romance visual novel: cream stationery, pastel character colors, floral corners and serif names. The five existing character identities and wallpapers supply the imagery.

Compact controls keep everyday actions readable and predictable. This document records the Quickshell templates; Harumi is the concrete reference palette below, while each character theme supplies the same semantic roles. Terminal palettes remain separately dark.

**Key Characteristics:**

- Cream dialogue frames with fine double borders.
- Pastel character accents and geometric floral ornaments.
- Serif titles paired with compact sans-serif controls.
- Visible keyboard focus and restrained, immediate state changes.

## Colors

The Harumi palette places warm paper behind plum ink and muted rose accents. Exact reference values live in the frontmatter; other character palettes replace these roles together.

- **Primary — accent:** selected buttons, frame outlines, focus and floral centers.
- **Secondary — tint:** hover and pressed fills, nameplates, slider tracks and petals.
- **Neutral — paper / ink:** panel surfaces and primary readable text.
- **Neutral — muted / line:** supporting text and fine separators or inset borders.

**The Character Palette Rule.** Read panel colors through Theme roles so the same components follow the selected character.

## Typography

Noto Serif JP gives character names and recurring section titles their printed quality. Noto Sans carries body text and controls. The reused title/body/label roles are recorded above; the system-menu heading additionally uses bold serif at 25px, and the clock uses bold sans-serif at 15px. These are local roles, not a generated type scale.

Text defaults to plain text and right elision; longer game names and error messages explicitly wrap.

**The Two Voices Rule.** Use the serif for names and section titles; use the sans-serif for controls, status and supporting text.

## Layout

The chapter bar reserves 52px at the top of each screen. Its frame is inset horizontally by 12px; contents use 14px horizontal padding. Workspaces are compact numbered controls with 4px gaps, while related bar controls generally use 8px gaps.

The menu sits near the bottom center, capped at 800px wide and 540px tall, with 24px content margins and a scrollable controls column. Its wallpaper column disappears below 680px card width, keeping theme selection in the controls column. The bar progressively hides sound at 760px, window title at 860px and date at 1050px. These are desktop width adaptations, not a separate mobile layout.

## Elevation & Depth

Frames use opaque paper, a one-pixel accent outline and a secondary line inset by 5px. The menu dims the wallpaper with a translucent backdrop. Quickshell components define no drop shadows or decorative animation; state changes are immediate.

**The Stationery Frame Rule.** Separate surfaces with paper, fine outlines and an inset border; keep ornaments at frame corners.

## Shapes

Small radii preserve a lightly softened stationery silhouette. Frames use the frame radius, buttons and nameplates the control radius, and inset borders and slider parts the inset radius. Four small rounded petals and a center dot form each 26px corner ornament; they are drawn geometry, independent of icon fonts.

## Components

- **Buttons:** paper and ink at rest; tint on hover or press; accent and bold paper text when selected. Horizontal padding is 12px, or 6px for compact controls. Compact height is 30px. Keyboard focus thickens the accent border to 2px. Disabled labels use muted text at reduced opacity.
- **Quiet buttons:** suppress their border and inset at rest, then reveal them on hover. Preserve the focus border even when quiet.
- **Dialogue frames:** double outlines with opposite floral corners. The menu adds a tinted character nameplate and an existing wallpaper crop; neither is a new raster asset.
- **Workspace navigation:** two-digit labels in compact buttons; active workspace uses the selected treatment. An accent marker indicates urgency.
- **Sliders:** labeled percentage above a tinted 8px track, accent progress and a paper thumb measuring 13px by 20px. Focus thickens the thumb border; unavailable controls dim and show “Unavailable”.

The sidecar contains self-contained HTML/CSS visual translations for the preview panel. QML remains the source for desktop behavior; these snippets do not connect to system actions.

## Do's and Don'ts

- Do reuse the existing character names and wallpaper assets.
- Do show selected controls with accent fill and paper text.
- Do retain visible keyboard focus and readable unavailable states.
- Don't invent character artwork or quotations.
- Don't replace the cream panel roles with the terminal background palette.
- Don't use decorative motion at the expense of predictable daily controls.
