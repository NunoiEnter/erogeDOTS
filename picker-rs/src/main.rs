use std::collections::HashSet;
use std::fs;
use std::io::{self};
use std::path::{Path, PathBuf};
use std::process::Command;

use crossterm::event::{self, Event, KeyCode, KeyEventKind, KeyModifiers};
use crossterm::execute;
use crossterm::terminal::{
    disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen,
};
use ratatui::backend::CrosstermBackend;
use ratatui::layout::{Constraint, Direction, Layout, Rect};
use ratatui::style::{Color, Modifier, Style};
use ratatui::text::{Line, Span};
use ratatui::widgets::{Block, Borders, List, ListItem, ListState, Paragraph};
use ratatui::Terminal;
use ratatui_image::picker::Picker;
use ratatui_image::protocol::Protocol;
use ratatui_image::Image;

type Term = Terminal<CrosstermBackend<io::Stdout>>;

#[derive(Clone, Debug)]
struct Theme {
    name: String,
    primary: String,
    primary_light: String,
    primary_dark: String,
    bg: String,
    fg: String,
    wallpaper: String,
    character: String,
    game: String,
}

#[derive(Clone, Copy)]
struct Palette {
    name: &'static str,
    primary: &'static str,
    light: &'static str,
    dark: &'static str,
    bg: &'static str,
    bg_light: &'static str,
    surface: &'static str,
    fg: &'static str,
    fg_dim: &'static str,
    icon: &'static str,
}

const PALETTES: [Palette; 6] = [
    Palette {
        name: "Sakura Pink",
        primary: "#ff8fb1",
        light: "#ffc4dd",
        dark: "#d67a99",
        bg: "#1a1b26",
        bg_light: "#24283b",
        surface: "#2f3347",
        fg: "#c0caf5",
        fg_dim: "#a9b1d6",
        icon: "🌸",
    },
    Palette {
        name: "Honey Gold",
        primary: "#e0af68",
        light: "#f6d89b",
        dark: "#b88945",
        bg: "#1f1b16",
        bg_light: "#2a241c",
        surface: "#393024",
        fg: "#f3e6cf",
        fg_dim: "#c8b99e",
        icon: "◆",
    },
    Palette {
        name: "Forest",
        primary: "#9ece6a",
        light: "#c3e88d",
        dark: "#73a84e",
        bg: "#161b18",
        bg_light: "#202822",
        surface: "#2b352e",
        fg: "#d5e8d8",
        fg_dim: "#9fb8a4",
        icon: "🌿",
    },
    Palette {
        name: "Lavender",
        primary: "#bb9af7",
        light: "#d7c2ff",
        dark: "#8f6fca",
        bg: "#191724",
        bg_light: "#26233a",
        surface: "#34304a",
        fg: "#e0def4",
        fg_dim: "#aaa6c3",
        icon: "✿",
    },
    Palette {
        name: "Crimson",
        primary: "#f7768e",
        light: "#ff9eaa",
        dark: "#c44f68",
        bg: "#1d171a",
        bg_light: "#291f23",
        surface: "#39292f",
        fg: "#f4dfe4",
        fg_dim: "#bea5ab",
        icon: "♥",
    },
    Palette {
        name: "Ocean",
        primary: "#7dcfff",
        light: "#b4e7ff",
        dark: "#4a9cc7",
        bg: "#151c26",
        bg_light: "#1f2937",
        surface: "#2a3748",
        fg: "#d7e8f5",
        fg_dim: "#9fb7ca",
        icon: "◇",
    },
];

// Every hex color consumed by the theme templates. The same order is used by
// the editor and by theme_config, so new themes cannot omit a template color.
const COLOR_ROLES: [(&str, &str); 15] = [
    ("primary", "Primary accent"),
    ("primary_light", "Light accent"),
    ("primary_dark", "Dark accent"),
    ("bg", "Background"),
    ("bg_light", "Raised background"),
    ("bg_surface", "Surface"),
    ("fg", "Text"),
    ("fg_dim", "Muted text"),
    ("bar_border", "Bar border"),
    ("niri_focus_active", "Active focus ring"),
    ("niri_focus_inactive", "Inactive focus ring"),
    ("niri_shadow", "Window shadow RGBA"),
    ("btm_header", "Bottom header"),
    ("btm_sel_bg", "Bottom selection"),
    ("btm_teal", "Bottom teal"),
];

type ThemeColors = [String; COLOR_ROLES.len()];

fn colors_from_palette(palette: Palette) -> ThemeColors {
    [
        palette.primary.into(),
        palette.light.into(),
        palette.dark.into(),
        palette.bg.into(),
        palette.bg_light.into(),
        palette.surface.into(),
        palette.fg.into(),
        palette.fg_dim.into(),
        palette.light.into(),
        palette.primary.into(),
        "#505050".into(),
        "#00000077".into(),
        "#7aa2f7".into(),
        "#34548a".into(),
        "#7dcfff".into(),
    ]
}

fn theme_color<'a>(colors: &'a ThemeColors, key: &str) -> &'a str {
    let index = COLOR_ROLES
        .iter()
        .position(|(role, _)| *role == key)
        .expect("known theme color");
    &colors[index]
}

const DEV_SHELLS: [(&str, &str); 11] = [
    ("default", "Rust + Python + Go + common tools"),
    ("rust", "Rust toolchain, clippy, rustfmt, audit"),
    ("python", "Python, uv, ruff, pyright, test tools"),
    ("go", "Go, gopls, linters, debugger helpers"),
    ("java", "JDK 21, Maven, Gradle, IntelliJ IDEA"),
    ("common", "Git, Neovim, Nix, formatters, shellcheck"),
    ("tester", "pytest, Playwright, k6, HTTP tools"),
    ("docker", "Docker, Podman, image scanners"),
    ("security", "Authorized security-lab toolkit"),
    ("webapp", "Bun, Node.js, GitHub CLI"),
    ("pg-computer", "Python desktop-control development"),
];

fn repo_root() -> PathBuf {
    std::env::var_os("EROGEDOTS_ROOT")
        .map(PathBuf::from)
        .or_else(|| dirs::home_dir().map(|p| p.join("erogeDOTS")))
        .unwrap_or_default()
}

fn wallpaper_path(value: &str) -> PathBuf {
    if let Some(relative) = value.strip_prefix("~/") {
        return dirs::home_dir().unwrap_or_default().join(relative);
    }
    let path = PathBuf::from(value);
    if path.is_absolute() {
        path
    } else {
        repo_root().join(path)
    }
}

fn hex_color(value: &str) -> Color {
    let hex = value.trim_start_matches('#');
    if hex.len() == 6 || hex.len() == 8 {
        if let (Ok(mut red), Ok(mut green), Ok(mut blue)) = (
            u8::from_str_radix(&hex[0..2], 16),
            u8::from_str_radix(&hex[2..4], 16),
            u8::from_str_radix(&hex[4..6], 16),
        ) {
            if hex.len() == 8 {
                if let Ok(alpha) = u8::from_str_radix(&hex[6..8], 16) {
                    // RGBA has no single visible color; preview it over dark gray.
                    let blend = |channel: u8| {
                        ((channel as u16 * alpha as u16 + 32 * (255 - alpha as u16)) / 255) as u8
                    };
                    red = blend(red);
                    green = blend(green);
                    blue = blend(blue);
                }
            }
            return Color::Rgb(red, green, blue);
        }
    }
    Color::Reset
}

fn rgba(value: &str) -> [u8; 4] {
    let hex = value.trim_start_matches('#');
    let channel = |start| u8::from_str_radix(&hex[start..start + 2], 16).unwrap_or(0);
    if hex.len() != 6 && hex.len() != 8 {
        return [0, 0, 0, 255];
    }
    [
        channel(0),
        channel(2),
        channel(4),
        if hex.len() == 8 { channel(6) } else { 255 },
    ]
}

fn color_hex(value: [u8; 4], alpha: bool) -> String {
    if alpha {
        format!(
            "#{:02x}{:02x}{:02x}{:02x}",
            value[0], value[1], value[2], value[3]
        )
    } else {
        format!("#{:02x}{:02x}{:02x}", value[0], value[1], value[2])
    }
}

fn color_line(label: &str, value: &str) -> Line<'static> {
    Line::from(vec![
        Span::styled("    ", Style::default().bg(hex_color(value))),
        Span::raw(format!("  {value}  {label}")),
    ])
}

fn load_preview_image(path: &Path, picker: &mut Picker) -> Option<Protocol> {
    let image = image::ImageReader::open(path).ok()?.decode().ok()?;
    picker
        .new_protocol(
            image,
            ratatui::layout::Size::new(48, 16),
            ratatui_image::Resize::Fit(None),
        )
        .ok()
}

fn parse_theme(path: &Path) -> Theme {
    let mut theme = Theme {
        name: path
            .parent()
            .and_then(Path::file_name)
            .unwrap_or_default()
            .to_string_lossy()
            .into(),
        primary: String::new(),
        primary_light: String::new(),
        primary_dark: String::new(),
        bg: String::new(),
        fg: String::new(),
        wallpaper: String::new(),
        character: String::new(),
        game: String::new(),
    };
    if let Ok(text) = fs::read_to_string(path) {
        for line in text.lines().map(str::trim) {
            let Some((key, value)) = line.split_once('=') else {
                continue;
            };
            let value = value.trim().trim_matches('"').to_string();
            match key.trim() {
                "primary" => theme.primary = value,
                "primary_light" => theme.primary_light = value,
                "primary_dark" => theme.primary_dark = value,
                "bg" => theme.bg = value,
                "fg" => theme.fg = value,
                "wallpaper" => theme.wallpaper = value,
                "char_full" => theme.character = value,
                "char_game" => theme.game = value,
                _ => {}
            }
        }
    }
    theme
}

fn themes() -> Vec<Theme> {
    let mut out = vec![];
    if let Ok(entries) = fs::read_dir(repo_root().join("themes")) {
        for entry in entries.flatten() {
            let conf = entry.path().join("theme.conf");
            if conf.is_file() {
                out.push(parse_theme(&conf));
            }
        }
    }
    out.sort_by(|a, b| a.name.cmp(&b.name));
    out
}

fn current_theme() -> String {
    dirs::home_dir()
        .and_then(|p| fs::read_to_string(p.join(".config/theme/active")).ok())
        .unwrap_or_default()
        .trim()
        .into()
}

fn terminal<T>(run: impl FnOnce(&mut Term) -> io::Result<T>) -> io::Result<T> {
    enable_raw_mode()?;
    let mut stdout = io::stdout();
    execute!(stdout, EnterAlternateScreen)?;
    let mut terminal = Terminal::new(CrosstermBackend::new(stdout))?;
    let result = run(&mut terminal);
    disable_raw_mode()?;
    execute!(terminal.backend_mut(), LeaveAlternateScreen)?;
    terminal.show_cursor()?;
    result
}

fn key() -> io::Result<KeyCode> {
    loop {
        if let Event::Key(k) = event::read()? {
            if k.kind != KeyEventKind::Press {
                continue;
            }
            if k.code == KeyCode::Char('c') && k.modifiers.contains(KeyModifiers::CONTROL) {
                return Ok(KeyCode::Esc);
            }
            return Ok(k.code);
        }
    }
}

fn select(term: &mut Term, title: &str, help: &str, rows: &[String]) -> io::Result<Option<usize>> {
    if rows.is_empty() {
        return Ok(None);
    }
    let mut cursor = 0;
    loop {
        term.draw(|f| {
            let areas = Layout::default()
                .direction(Direction::Vertical)
                .constraints([
                    Constraint::Length(3),
                    Constraint::Min(4),
                    Constraint::Length(2),
                ])
                .split(f.area());
            f.render_widget(
                Paragraph::new(title).style(
                    Style::default()
                        .fg(Color::Magenta)
                        .add_modifier(Modifier::BOLD),
                ),
                areas[0],
            );
            let items: Vec<ListItem> = rows.iter().map(|row| ListItem::new(row.as_str())).collect();
            let mut state = ListState::default().with_selected(Some(cursor));
            let list = List::new(items)
                .block(Block::default().borders(Borders::ALL))
                .highlight_symbol("› ")
                .highlight_style(
                    Style::default()
                        .fg(Color::Black)
                        .bg(Color::LightMagenta)
                        .add_modifier(Modifier::BOLD),
                );
            f.render_stateful_widget(list, areas[1], &mut state);
            f.render_widget(
                Paragraph::new(help).style(Style::default().fg(Color::DarkGray)),
                areas[2],
            );
        })?;
        match key()? {
            KeyCode::Up | KeyCode::Char('k') => cursor = cursor.saturating_sub(1),
            KeyCode::Down | KeyCode::Char('j') => cursor = (cursor + 1).min(rows.len() - 1),
            KeyCode::Enter => return Ok(Some(cursor)),
            KeyCode::Esc | KeyCode::Char('q') => return Ok(None),
            _ => {}
        }
    }
}

fn input(term: &mut Term, title: &str, hint: &str) -> io::Result<Option<String>> {
    let mut value = String::new();
    loop {
        term.draw(|f| {
            let area = centered(f.area(), 70, 7);
            let block = Block::default()
                .title(title)
                .borders(Borders::ALL)
                .border_style(Style::default().fg(Color::Magenta));
            let inner = block.inner(area);
            f.render_widget(block, area);
            f.render_widget(
                Paragraph::new(format!("{value}▌\n{hint}"))
                    .style(Style::default().fg(Color::White)),
                inner,
            );
        })?;
        match key()? {
            KeyCode::Char(c) => value.push(c),
            KeyCode::Backspace => {
                value.pop();
            }
            KeyCode::Enter if !value.trim().is_empty() => return Ok(Some(value.trim().into())),
            KeyCode::Esc => return Ok(None),
            _ => {}
        }
    }
}

fn centered(area: Rect, percent_x: u16, height: u16) -> Rect {
    let vertical = Layout::vertical([
        Constraint::Length(area.height.saturating_sub(height) / 2),
        Constraint::Length(height),
        Constraint::Min(0),
    ])
    .split(area);
    Layout::horizontal([
        Constraint::Percentage((100 - percent_x) / 2),
        Constraint::Percentage(percent_x),
        Constraint::Min(0),
    ])
    .split(vertical[1])[1]
}

fn valid_slug(value: &str) -> bool {
    !value.is_empty()
        && value.len() <= 48
        && value
            .bytes()
            .all(|b| b.is_ascii_lowercase() || b.is_ascii_digit() || b == b'-')
        && !value.starts_with('-')
        && !value.ends_with('-')
}

fn image_file(path: &Path) -> bool {
    path.extension().and_then(|x| x.to_str()).is_some_and(|x| {
        matches!(
            x.to_ascii_lowercase().as_str(),
            "jpg" | "jpeg" | "png" | "webp"
        )
    })
}

fn collect_images(dir: &Path, depth: u8, out: &mut Vec<PathBuf>) {
    if depth == 0 || out.len() >= 500 {
        return;
    }
    let Ok(entries) = fs::read_dir(dir) else {
        return;
    };
    for entry in entries.flatten() {
        if out.len() >= 500 {
            break;
        }
        let path = entry.path();
        if path.is_dir() && !entry.file_name().to_string_lossy().starts_with('.') {
            collect_images(&path, depth - 1, out);
        } else if path.is_file() && image_file(&path) {
            out.push(path);
        }
    }
}

fn discover_images() -> Vec<PathBuf> {
    let mut images = vec![];
    let wallpapers = repo_root().join("wallpapers");
    let home = dirs::home_dir();
    collect_images(&wallpapers, 2, &mut images);
    if let Some(home) = &home {
        collect_images(&home.join("Pictures"), 4, &mut images);
        collect_images(&home.join("Downloads"), 2, &mut images);
    }
    let mut seen = HashSet::new();
    images.retain(|p| seen.insert(p.clone()));
    let pictures = home.map(|path| path.join("Pictures"));
    let rank = |path: &Path| {
        if path.starts_with(&wallpapers) {
            0
        } else if pictures.as_ref().is_some_and(|dir| path.starts_with(dir)) {
            1
        } else {
            2
        }
    };
    images.sort_by(|a, b| rank(a).cmp(&rank(b)).then_with(|| a.cmp(b)));
    images
}

fn select_image(term: &mut Term, images: &[PathBuf]) -> io::Result<Option<usize>> {
    if images.is_empty() {
        return Ok(None);
    }
    let mut picker = Picker::from_query_stdio().unwrap_or_else(|_| Picker::halfblocks());
    let mut cursor = 0;
    let mut preview = load_preview_image(&images[cursor], &mut picker);
    loop {
        term.draw(|frame| {
            let page = Layout::vertical([
                Constraint::Length(2),
                Constraint::Min(10),
                Constraint::Length(2),
            ])
            .split(frame.area());
            frame.render_widget(
                Paragraph::new("6/9 Choose wallpaper · live preview").style(
                    Style::default()
                        .fg(Color::Magenta)
                        .add_modifier(Modifier::BOLD),
                ),
                page[0],
            );
            let body = Layout::horizontal([Constraint::Percentage(40), Constraint::Percentage(60)])
                .split(page[1]);
            let rows: Vec<ListItem> = images
                .iter()
                .map(|path| ListItem::new(path.file_name().unwrap_or_default().to_string_lossy()))
                .collect();
            let mut state = ListState::default().with_selected(Some(cursor));
            frame.render_stateful_widget(
                List::new(rows)
                    .block(Block::default().title("Images").borders(Borders::ALL))
                    .highlight_symbol("› ")
                    .highlight_style(Style::default().fg(Color::Black).bg(Color::LightMagenta)),
                body[0],
                &mut state,
            );
            let block = Block::default()
                .title("Wallpaper preview")
                .borders(Borders::ALL);
            let inner = block.inner(body[1]);
            frame.render_widget(block, body[1]);
            let detail = Layout::vertical([Constraint::Length(2), Constraint::Min(1)]).split(inner);
            frame.render_widget(
                Paragraph::new(images[cursor].display().to_string())
                    .style(Style::default().fg(Color::Gray)),
                detail[0],
            );
            if let Some(protocol) = &preview {
                frame.render_widget(Image::new(protocol), detail[1]);
            } else {
                frame.render_widget(
                    Paragraph::new("Image could not be loaded")
                        .style(Style::default().fg(Color::DarkGray)),
                    detail[1],
                );
            }
            frame.render_widget(
                Paragraph::new("[↑↓/jk] preview another image  [Enter] choose  [Esc] cancel")
                    .style(Style::default().fg(Color::DarkGray)),
                page[2],
            );
        })?;
        let next = match key()? {
            KeyCode::Up | KeyCode::Char('k') => cursor.saturating_sub(1),
            KeyCode::Down | KeyCode::Char('j') => (cursor + 1).min(images.len() - 1),
            KeyCode::Enter if preview.is_some() => return Ok(Some(cursor)),
            KeyCode::Esc => return Ok(None),
            _ => cursor,
        };
        if next != cursor {
            cursor = next;
            preview = load_preview_image(&images[cursor], &mut picker);
        }
    }
}

fn select_palette(term: &mut Term) -> io::Result<Option<usize>> {
    let mut cursor = 0;
    loop {
        term.draw(|frame| {
            let page = Layout::vertical([
                Constraint::Length(2),
                Constraint::Min(10),
                Constraint::Length(2),
            ])
            .split(frame.area());
            frame.render_widget(
                Paragraph::new("7/9 Choose starting color scheme").style(
                    Style::default()
                        .fg(Color::Magenta)
                        .add_modifier(Modifier::BOLD),
                ),
                page[0],
            );
            let body = Layout::horizontal([Constraint::Percentage(36), Constraint::Percentage(64)])
                .split(page[1]);
            let rows: Vec<ListItem> = PALETTES
                .iter()
                .map(|p| ListItem::new(color_line(p.name, p.primary)))
                .collect();
            let mut state = ListState::default().with_selected(Some(cursor));
            frame.render_stateful_widget(
                List::new(rows)
                    .block(Block::default().title("Schemes").borders(Borders::ALL))
                    .highlight_symbol("› ")
                    .highlight_style(Style::default().fg(Color::Black).bg(Color::LightMagenta)),
                body[0],
                &mut state,
            );
            let block = Block::default()
                .title("Exact scheme colors")
                .borders(Borders::ALL);
            let inner = block.inner(body[1]);
            frame.render_widget(block, body[1]);
            let colors = colors_from_palette(PALETTES[cursor]);
            let lines: Vec<Line> = COLOR_ROLES[..8]
                .iter()
                .enumerate()
                .map(|(i, (_, label))| color_line(label, &colors[i]))
                .collect();
            frame.render_widget(Paragraph::new(lines), inner);
            frame.render_widget(
                Paragraph::new("[↑↓/jk] preview scheme  [Enter] choose  [Esc] cancel")
                    .style(Style::default().fg(Color::DarkGray)),
                page[2],
            );
        })?;
        match key()? {
            KeyCode::Up | KeyCode::Char('k') => cursor = cursor.saturating_sub(1),
            KeyCode::Down | KeyCode::Char('j') => cursor = (cursor + 1).min(PALETTES.len() - 1),
            KeyCode::Enter => return Ok(Some(cursor)),
            KeyCode::Esc => return Ok(None),
            _ => {}
        }
    }
}

fn sample_colors() -> Vec<(String, String)> {
    let mut samples = Vec::new();
    let mut seen = HashSet::new();
    for palette in PALETTES {
        for (label, hex) in [
            ("Primary", palette.primary),
            ("Light", palette.light),
            ("Dark", palette.dark),
            ("Background", palette.bg),
            ("Raised", palette.bg_light),
            ("Surface", palette.surface),
            ("Text", palette.fg),
            ("Muted", palette.fg_dim),
        ] {
            if seen.insert(hex) {
                samples.push((format!("{} · {label}", palette.name), hex.into()));
            }
        }
    }
    for (label, hex) in [
        ("Bottom header", "#7aa2f7"),
        ("Bottom selection", "#34548a"),
        ("Bottom teal", "#7dcfff"),
        ("Niri inactive", "#505050"),
        ("Black", "#000000"),
        ("White", "#ffffff"),
    ] {
        if seen.insert(hex) {
            samples.push((label.into(), hex.into()));
        }
    }
    samples
}

fn pick_color(
    term: &mut Term,
    label: &str,
    current: &str,
    alpha: bool,
) -> io::Result<Option<String>> {
    let samples = sample_colors();
    let mut cursor = samples
        .iter()
        .position(|(_, hex)| hex == current)
        .unwrap_or(0);
    let mut value = rgba(current);
    let mut channel = 0;
    let channel_count = if alpha { 4 } else { 3 };
    loop {
        let hex = color_hex(value, alpha);
        term.draw(|frame| {
            let page = Layout::vertical([
                Constraint::Length(2),
                Constraint::Min(10),
                Constraint::Length(3),
            ])
            .split(frame.area());
            frame.render_widget(
                Paragraph::new(format!("Choose {label} · {hex}"))
                    .style(Style::default().fg(Color::Magenta).add_modifier(Modifier::BOLD)),
                page[0],
            );
            let body = Layout::horizontal([Constraint::Percentage(48), Constraint::Percentage(52)])
                .split(page[1]);
            let rows: Vec<ListItem> = samples
                .iter()
                .map(|(name, hex)| ListItem::new(color_line(name, hex)))
                .collect();
            let mut state = ListState::default().with_selected(Some(cursor));
            frame.render_stateful_widget(
                List::new(rows)
                    .block(Block::default().title("Color palette").borders(Borders::ALL))
                    .highlight_symbol("› ")
                    .highlight_style(Style::default().fg(Color::Black).bg(Color::LightMagenta)),
                body[0],
                &mut state,
            );
            let block = Block::default().title("Exact color").borders(Borders::ALL);
            let inner = block.inner(body[1]);
            frame.render_widget(block, body[1]);
            let detail = Layout::vertical([
                Constraint::Length(2),
                Constraint::Min(3),
                Constraint::Length(2),
            ])
            .split(inner);
            frame.render_widget(Paragraph::new(format!("{label}\n{hex}")), detail[0]);
            frame.render_widget(
                Block::default().style(Style::default().bg(hex_color(&hex))),
                detail[1],
            );
            let channels = ["R", "G", "B", "A"];
            let values: Vec<Span> = (0..channel_count)
                .map(|i| {
                    Span::styled(
                        format!(" {} {:03} ", channels[i], value[i]),
                        if i == channel {
                            Style::default().fg(Color::Black).bg(Color::LightMagenta)
                        } else {
                            Style::default()
                        },
                    )
                })
                .collect();
            frame.render_widget(Paragraph::new(Line::from(values)), detail[2]);
            let help = if alpha {
                "[↑↓/jk] swatch  [Tab] R/G/B/A  [←→] ±1  [ and ] ±16\n[Enter] use hex  [Esc] back · shadow shown on dark gray"
            } else {
                "[↑↓/jk] swatch  [Tab] R/G/B  [←→] ±1  [ and ] ±16\n[Enter] use exact hex  [Esc] keep previous color"
            };
            frame.render_widget(
                Paragraph::new(help).style(Style::default().fg(Color::DarkGray)),
                page[2],
            );
        })?;
        match key()? {
            KeyCode::Up | KeyCode::Char('k') => {
                cursor = cursor.saturating_sub(1);
                value[..3].copy_from_slice(&rgba(&samples[cursor].1)[..3]);
            }
            KeyCode::Down | KeyCode::Char('j') => {
                cursor = (cursor + 1).min(samples.len() - 1);
                value[..3].copy_from_slice(&rgba(&samples[cursor].1)[..3]);
            }
            KeyCode::Tab => channel = (channel + 1) % channel_count,
            KeyCode::Left => value[channel] = value[channel].saturating_sub(1),
            KeyCode::Right => value[channel] = value[channel].saturating_add(1),
            KeyCode::Char('[') => value[channel] = value[channel].saturating_sub(16),
            KeyCode::Char(']') => value[channel] = value[channel].saturating_add(16),
            KeyCode::Enter => return Ok(Some(color_hex(value, alpha))),
            KeyCode::Esc => return Ok(None),
            _ => {}
        }
    }
}

fn edit_colors(term: &mut Term, mut colors: ThemeColors) -> io::Result<Option<ThemeColors>> {
    let mut cursor = 0;
    loop {
        term.draw(|frame| {
            let page = Layout::vertical([
                Constraint::Length(2),
                Constraint::Min(10),
                Constraint::Length(2),
            ])
            .split(frame.area());
            frame.render_widget(
                Paragraph::new("8/9 Fine-tune every theme color").style(
                    Style::default()
                        .fg(Color::Magenta)
                        .add_modifier(Modifier::BOLD),
                ),
                page[0],
            );
            let body = Layout::horizontal([Constraint::Percentage(62), Constraint::Percentage(38)])
                .split(page[1]);
            let rows: Vec<ListItem> = COLOR_ROLES
                .iter()
                .enumerate()
                .map(|(i, (_, label))| ListItem::new(color_line(label, &colors[i])))
                .collect();
            let mut state = ListState::default().with_selected(Some(cursor));
            frame.render_stateful_widget(
                List::new(rows)
                    .block(
                        Block::default()
                            .title("All color roles")
                            .borders(Borders::ALL),
                    )
                    .highlight_symbol("› ")
                    .highlight_style(Style::default().fg(Color::Black).bg(Color::LightMagenta)),
                body[0],
                &mut state,
            );
            let block = Block::default()
                .title("Selected color")
                .borders(Borders::ALL);
            let inner = block.inner(body[1]);
            frame.render_widget(block, body[1]);
            let detail = Layout::vertical([Constraint::Length(3), Constraint::Min(1)]).split(inner);
            frame.render_widget(
                Paragraph::new(format!("{}\n{}", COLOR_ROLES[cursor].1, colors[cursor])),
                detail[0],
            );
            frame.render_widget(
                Block::default().style(Style::default().bg(hex_color(&colors[cursor]))),
                detail[1],
            );
            frame.render_widget(
                Paragraph::new("[↑↓/jk] role  [Enter] choose/edit color  [s] next  [Esc] cancel")
                    .style(Style::default().fg(Color::DarkGray)),
                page[2],
            );
        })?;
        match key()? {
            KeyCode::Up | KeyCode::Char('k') => cursor = cursor.saturating_sub(1),
            KeyCode::Down | KeyCode::Char('j') => cursor = (cursor + 1).min(COLOR_ROLES.len() - 1),
            KeyCode::Enter => {
                if let Some(hex) = pick_color(
                    term,
                    COLOR_ROLES[cursor].1,
                    &colors[cursor],
                    COLOR_ROLES[cursor].0 == "niri_shadow",
                )? {
                    colors[cursor] = hex;
                }
            }
            KeyCode::Char('s') => return Ok(Some(colors)),
            KeyCode::Esc => return Ok(None),
            _ => {}
        }
    }
}

#[derive(Debug)]
struct NewTheme {
    slug: String,
    char_name: String,
    char_full: String,
    game: String,
    quote: String,
    image: PathBuf,
    palette: usize,
    colors: ThemeColors,
}

fn add_flow(term: &mut Term) -> io::Result<Option<NewTheme>> {
    let slug = loop {
        let Some(value) = input(
            term,
            "1/9 Theme ID",
            "lowercase letters, numbers and hyphens; Enter = next, Esc = cancel",
        )?
        else {
            return Ok(None);
        };
        if valid_slug(&value) && !repo_root().join("themes").join(&value).exists() {
            break value;
        }
    };
    let Some(char_name) = input(term, "2/9 Character", "display name (any language)")? else {
        return Ok(None);
    };
    let Some(char_full) = input(term, "3/9 Full name", "romanized/full character name")? else {
        return Ok(None);
    };
    let Some(game) = input(term, "4/9 Game", "source title")? else {
        return Ok(None);
    };
    let Some(quote) = input(term, "5/9 Quote", "short quote")? else {
        return Ok(None);
    };

    let images = discover_images();
    let Some(image) = select_image(term, &images)? else {
        return Ok(None);
    };
    let Some(palette) = select_palette(term)? else {
        return Ok(None);
    };
    let Some(colors) = edit_colors(term, colors_from_palette(PALETTES[palette]))? else {
        return Ok(None);
    };
    let confirm = vec![
        format!("Create {slug} with {}", PALETTES[palette].name),
        "Cancel".into(),
    ];
    if select(term, "9/9 Confirm", "[Enter] confirm", &confirm)? != Some(0) {
        return Ok(None);
    }
    Ok(Some(NewTheme {
        slug,
        char_name,
        char_full,
        game,
        quote,
        image: images[image].clone(),
        palette,
        colors,
    }))
}

fn quoted(value: &str) -> String {
    value
        .replace('\\', "\\\\")
        .replace('"', "\\\"")
        .replace(['\n', '\r'], " ")
}

fn closest_named_color(value: &str) -> &'static str {
    let Color::Rgb(red, green, blue) = hex_color(value) else {
        return "magenta";
    };
    const COLORS: [(&str, [u8; 3]); 7] = [
        ("red", [240, 90, 100]),
        ("green", [130, 210, 110]),
        ("yellow", [235, 200, 90]),
        ("blue", [110, 150, 245]),
        ("magenta", [225, 125, 210]),
        ("cyan", [100, 210, 230]),
        ("white", [230, 230, 230]),
    ];
    COLORS
        .iter()
        .min_by_key(|(_, candidate)| {
            [red, green, blue]
                .iter()
                .zip(candidate)
                .map(|(actual, expected)| (*actual as i32 - *expected as i32).pow(2))
                .sum::<i32>()
        })
        .map(|(name, _)| *name)
        .unwrap_or("magenta")
}

fn theme_config(new: &NewTheme, wallpaper: &str) -> String {
    let p = PALETTES[new.palette];
    let color_values = COLOR_ROLES
        .iter()
        .enumerate()
        .map(|(index, (key, _))| format!("{key} = \"{}\"\n", new.colors[index]))
        .collect::<String>();
    let primary = theme_color(&new.colors, "primary");
    let cli_color = closest_named_color(primary);
    format!(
        r##"# Generated by theme-picker

[colors]
{color_values}

[desktop]
bar_workspace_active = "◆"
bar_workspace_default = "◇"
bar_clock_icon = "{icon}"
ghostty_opacity = "0.55"
wallpaper = "{wallpaper}"

[terminal]
cava_colors = "{primary}:{dark}:{light}"
cmatrix_color = "{cli_color}"
fetch_label = "{cli_color}"
fetch_logo_outer = "{cli_color}"
fetch_logo_inner = "white"

[character]
char_name = "{char_name}"
char_full = "{char_full}"
char_game = "{game}"
char_quote = "{quote}"
"##,
        icon = p.icon,
        wallpaper = quoted(wallpaper),
        dark = theme_color(&new.colors, "primary_dark"),
        light = theme_color(&new.colors, "primary_light"),
        char_name = quoted(&new.char_name),
        char_full = quoted(&new.char_full),
        game = quoted(&new.game),
        quote = quoted(&new.quote),
    )
}

fn create_theme(new: &NewTheme) -> io::Result<()> {
    let ext = new
        .image
        .extension()
        .and_then(|x| x.to_str())
        .unwrap_or("jpg")
        .to_ascii_lowercase();
    let wallpaper = format!("wallpapers/{}.{}", new.slug, ext);
    let target_image = repo_root().join(&wallpaper);
    let target_theme = repo_root().join("themes").join(&new.slug);
    if target_theme.exists() || target_image.exists() {
        return Err(io::Error::new(
            io::ErrorKind::AlreadyExists,
            "theme or wallpaper already exists",
        ));
    }
    fs::create_dir_all(&target_theme)?;
    if fs::copy(&new.image, &target_image).is_err() {
        let _ = fs::remove_dir(&target_theme);
        return Err(io::Error::other("could not copy wallpaper"));
    }
    if let Err(err) = fs::write(
        target_theme.join("theme.conf"),
        theme_config(new, &wallpaper),
    ) {
        let _ = fs::remove_file(&target_image);
        let _ = fs::remove_dir(&target_theme);
        return Err(err);
    }
    println!("Created theme: {}", new.slug);
    println!("Apply it with: theme-switch {}", new.slug);
    Ok(())
}

struct ThemeChooser {
    values: Vec<Theme>,
    current: String,
    cursor: usize,
    image: Option<Protocol>,
}

impl ThemeChooser {
    fn new() -> Self {
        Self {
            values: themes(),
            current: current_theme(),
            cursor: 0,
            image: None,
        }
    }

    fn load_image(&mut self, picker: &mut Picker) {
        let Some(theme) = self.values.get(self.cursor) else {
            self.image = None;
            return;
        };
        let path = wallpaper_path(&theme.wallpaper);
        self.image = load_preview_image(&path, picker);
    }
}

fn render_theme_chooser(frame: &mut ratatui::Frame, app: &ThemeChooser) {
    let page = Layout::vertical([
        Constraint::Length(2),
        Constraint::Min(12),
        Constraint::Length(2),
    ])
    .split(frame.area());
    frame.render_widget(
        Paragraph::new("erogeDOTS · Theme").style(
            Style::default()
                .fg(Color::Magenta)
                .add_modifier(Modifier::BOLD),
        ),
        page[0],
    );

    let body =
        Layout::horizontal([Constraint::Percentage(32), Constraint::Percentage(68)]).split(page[1]);
    let rows: Vec<ListItem> = app
        .values
        .iter()
        .map(|theme| {
            let mark = if theme.name == app.current {
                "●"
            } else {
                "○"
            };
            ListItem::new(format!("{mark} {}", theme.name))
        })
        .collect();
    let mut state = ListState::default().with_selected(Some(app.cursor));
    frame.render_stateful_widget(
        List::new(rows)
            .block(Block::default().title("Themes").borders(Borders::ALL))
            .highlight_symbol("› ")
            .highlight_style(
                Style::default()
                    .fg(Color::Black)
                    .bg(Color::LightMagenta)
                    .add_modifier(Modifier::BOLD),
            ),
        body[0],
        &mut state,
    );

    let preview = Block::default()
        .title("Wallpaper preview")
        .borders(Borders::ALL);
    let inner = preview.inner(body[1]);
    frame.render_widget(preview, body[1]);
    if let Some(theme) = app.values.get(app.cursor) {
        let swatch = "      ";
        let details = vec![
            ratatui::text::Line::from(vec![
                ratatui::text::Span::styled(
                    swatch,
                    Style::default()
                        .fg(hex_color(&theme.primary))
                        .bg(hex_color(&theme.primary)),
                ),
                ratatui::text::Span::raw(format!("  {}", theme.name)),
            ]),
            ratatui::text::Line::from(format!("{} · {}", theme.character, theme.game)),
            ratatui::text::Line::from(theme.wallpaper.as_str()),
        ];
        let parts = Layout::vertical([Constraint::Length(4), Constraint::Min(1)]).split(inner);
        frame.render_widget(Paragraph::new(details), parts[0]);
        if let Some(protocol) = &app.image {
            frame.render_widget(Image::new(protocol), parts[1]);
        } else {
            frame.render_widget(
                Paragraph::new("Wallpaper could not be loaded")
                    .style(Style::default().fg(Color::DarkGray)),
                parts[1],
            );
        }
    }

    frame.render_widget(
        Paragraph::new("[↑↓/jk] move  [Enter] apply  [q/Esc] cancel")
            .style(Style::default().fg(Color::DarkGray)),
        page[2],
    );
}

fn choose_theme(term: &mut Term) -> io::Result<Option<String>> {
    let mut app = ThemeChooser::new();
    if app.values.is_empty() {
        return Ok(None);
    }
    let mut picker = Picker::from_query_stdio().unwrap_or_else(|_| Picker::halfblocks());
    app.load_image(&mut picker);

    loop {
        term.draw(|frame| render_theme_chooser(frame, &app))?;
        match key()? {
            KeyCode::Up | KeyCode::Char('k') => {
                app.cursor = app.cursor.saturating_sub(1);
                app.load_image(&mut picker);
            }
            KeyCode::Down | KeyCode::Char('j') => {
                app.cursor = (app.cursor + 1).min(app.values.len() - 1);
                app.load_image(&mut picker);
            }
            KeyCode::Enter => return Ok(Some(app.values[app.cursor].name.clone())),
            KeyCode::Esc | KeyCode::Char('q') => return Ok(None),
            _ => {}
        }
    }
}

fn choose_dev(term: &mut Term) -> io::Result<Option<String>> {
    let rows: Vec<String> = DEV_SHELLS
        .iter()
        .map(|(name, desc)| format!("{name:12} {desc}"))
        .collect();
    select(
        term,
        "erogeDOTS · Development shell",
        "[↑↓/jk] move  [Enter] open  [q/Esc] cancel",
        &rows,
    )
    .map(|picked| picked.map(|i| DEV_SHELLS[i].0.into()))
}

fn usage() {
    println!("theme-picker [themes|add|dev]\n\n  themes  choose and apply a theme (default)\n  add     create a theme with guided choices\n  dev     choose and enter a Nix development shell");
}

fn main() -> io::Result<()> {
    match std::env::args().nth(1).as_deref() {
        None | Some("themes") => {
            if let Some(name) = terminal(choose_theme)? {
                Command::new(repo_root().join("scripts/theme-switch"))
                    .arg(name)
                    .status()?;
            }
        }
        Some("add") => {
            if let Some(new) = terminal(add_flow)? {
                create_theme(&new)?;
            }
        }
        Some("dev") => {
            if let Some(shell) = terminal(choose_dev)? {
                Command::new("nix")
                    .args([
                        "develop",
                        &format!("path:{}#{shell}", repo_root().display()),
                    ])
                    .status()?;
            }
        }
        Some("help" | "-h" | "--help") => usage(),
        Some(other) => {
            eprintln!("unknown command: {other}");
            usage();
            std::process::exit(2);
        }
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn slug_rejects_paths_and_bad_edges() {
        assert!(valid_slug("new-theme2"));
        for bad in ["../x", "Upper", "has space", "-start", "end-", ""] {
            assert!(!valid_slug(bad), "accepted {bad:?}");
        }
    }

    #[test]
    fn image_extensions_are_case_insensitive() {
        assert!(image_file(Path::new("wallpaper.PNG")));
        assert!(image_file(Path::new("wallpaper.webp")));
        assert!(!image_file(Path::new("secret.txt")));
    }

    #[test]
    fn generated_config_has_required_values_and_escapes() {
        let new = NewTheme {
            slug: "test".into(),
            char_name: "A".into(),
            char_full: "A \"B\"".into(),
            game: "G".into(),
            quote: "Q".into(),
            image: "a.jpg".into(),
            palette: 0,
            colors: colors_from_palette(PALETTES[0]),
        };
        let mut new = new;
        new.colors[0] = "#123456".into();
        let text = theme_config(&new, "wallpapers/test.jpg");
        for (role, _) in COLOR_ROLES {
            assert!(text.contains(&format!("{role} =")), "missing {role}");
        }
        assert!(text.contains("primary = \"#123456\""));
        assert!(text.contains("ghostty_opacity = \"0.55\""));
        assert!(text.contains("wallpaper = \"wallpapers/test.jpg\""));
        assert!(text.contains("A \\\"B\\\""));
    }
}
