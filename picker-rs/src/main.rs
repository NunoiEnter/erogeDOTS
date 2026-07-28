use std::fs;
use std::io::{self};
use std::path::{Path, PathBuf};
use std::process::Command;

use crossterm::event::{self, Event, KeyCode, KeyEventKind};
use crossterm::terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen};
use crossterm::execute;
use ratatui::backend::CrosstermBackend;
use ratatui::layout::{Constraint, Direction, Layout, Rect};
use ratatui::style::{Color, Modifier, Style};
use ratatui::text::{Line, Span};
use ratatui::widgets::{Block, Borders, Padding, Paragraph};
use ratatui::Terminal;
use ratatui_image::picker::Picker;
use ratatui_image::protocol::Protocol;
use ratatui_image::Image;

#[derive(Debug, Clone)]
struct Theme {
    name: String,
    primary: String,
    primary_light: String,
    primary_dark: String,
    bg: String,
    fg: String,
    wallpaper: String,
}

impl Theme {
    fn empty(name: &str) -> Self {
        Self {
            name: name.to_string(),
            primary: String::new(),
            primary_light: String::new(),
            primary_dark: String::new(),
            bg: String::new(),
            fg: String::new(),
            wallpaper: String::new(),
        }
    }
}

fn expand_path(p: &str) -> PathBuf {
    if let Some(rest) = p.strip_prefix("~/") {
        if let Some(home) = dirs::home_dir() {
            return home.join(rest);
        }
    }
    PathBuf::from(p)
}

fn parse_theme_conf(path: &Path) -> Theme {
    let name = path.parent()
        .and_then(|p| p.file_name())
        .map(|n| n.to_string_lossy().to_string())
        .unwrap_or_default();

    let mut theme = Theme::empty(&name);

    let Ok(content) = fs::read_to_string(path) else {
        return theme;
    };

    for line in content.lines() {
        let line = line.trim();
        if line.is_empty() || line.starts_with('#') || line.starts_with('[') {
            continue;
        }

        let Some((key, value)) = line.split_once('=') else {
            continue;
        };

        let key = key.trim();
        let value = value.trim().trim_matches('"');

        match key {
            "primary" => theme.primary = value.to_string(),
            "primary_light" | "primary-light" => theme.primary_light = value.to_string(),
            "primary_dark" | "primary-dark" => theme.primary_dark = value.to_string(),
            "bg" => theme.bg = value.to_string(),
            "fg" => theme.fg = value.to_string(),
            "wallpaper" => theme.wallpaper = value.to_string(),
            _ => {}
        }
    }

    theme
}

fn discover_themes() -> Vec<Theme> {
    let Some(home) = dirs::home_dir() else {
        return vec![];
    };

    let themes_dir = home.join("erogeDOTS").join("themes");
    let Ok(entries) = fs::read_dir(&themes_dir) else {
        return vec![];
    };

    let mut themes: Vec<Theme> = entries
        .filter_map(|e| e.ok())
        .filter(|e| {
            e.file_type().map(|ft| ft.is_dir()).unwrap_or(false)
                && e.file_name() != "templates"
        })
        .filter_map(|e| {
            let conf = themes_dir.join(e.file_name()).join("theme.conf");
            if conf.exists() {
                Some(parse_theme_conf(&conf))
            } else {
                None
            }
        })
        .collect();

    themes.sort_by(|a, b| a.name.cmp(&b.name));
    themes
}

fn read_current_theme() -> String {
    let Some(home) = dirs::home_dir() else {
        return String::new();
    };
    fs::read_to_string(home.join(".config").join("theme").join("active"))
        .map(|s| s.trim().to_string())
        .unwrap_or_default()
}

fn hex_to_color(hex: &str) -> Color {
    let hex = hex.trim_start_matches('#');
    if hex.len() == 6 {
        if let (Ok(r), Ok(g), Ok(b)) = (
            u8::from_str_radix(&hex[0..2], 16),
            u8::from_str_radix(&hex[2..4], 16),
            u8::from_str_radix(&hex[4..6], 16),
        ) {
            return Color::Rgb(r, g, b);
        }
    }
    Color::Reset
}

struct App {
    themes: Vec<Theme>,
    cursor: usize,
    current: String,
    image_protocol: Option<Protocol>,
}

impl App {
    fn new() -> Self {
        let themes = discover_themes();
        let current = read_current_theme();

        Self {
            themes,
            cursor: 0,
            current,
            image_protocol: None,
        }
    }

    fn load_wallpaper(&mut self, picker: &mut Picker, wallpaper: &str) {
        let path = expand_path(wallpaper);
        if !path.exists() {
            self.image_protocol = None;
            return;
        }

        let img = match image::ImageReader::open(&path) {
            Ok(reader) => match reader.decode() {
                Ok(img) => img.to_rgb8(),
                Err(_) => {
                    self.image_protocol = None;
                    return;
                }
            },
            Err(_) => {
                self.image_protocol = None;
                return;
            }
        };

        let dyn_img = image::DynamicImage::ImageRgb8(img);
        let _font_size = picker.font_size();

        let target_cols: u32 = 36;
        let target_rows: u32 = 10;
        let size = ratatui::layout::Size::new(
            target_cols as u16,
            target_rows as u16,
        );

        match picker.new_protocol(dyn_img, size, ratatui_image::Resize::Fit(None)) {
            Ok(proto) => self.image_protocol = Some(proto),
            Err(_) => self.image_protocol = None,
        }
    }
}

fn main() -> io::Result<()> {
    let mut app = App::new();

    if app.themes.is_empty() {
        eprintln!("No themes found in ~/erogeDOTS/themes/");
        std::process::exit(1);
    }

    // Setup terminal
    enable_raw_mode()?;
    let mut stdout = io::stdout();
    execute!(stdout, EnterAlternateScreen)?;
    let backend = CrosstermBackend::new(stdout);
    let mut terminal = Terminal::new(backend)?;

    // Setup ratatui-image picker (auto-detects kitty protocol)
    let mut picker = Picker::from_query_stdio()
        .unwrap_or_else(|_| Picker::halfblocks());

    // Load initial wallpaper
    let first_wallpaper = app.themes.first()
        .map(|t| t.wallpaper.clone())
        .unwrap_or_default();
    if !first_wallpaper.is_empty() {
        app.load_wallpaper(&mut picker, &first_wallpaper);
    }

    let result = run_app(&mut terminal, &mut app, &mut picker);

    // Restore terminal
    disable_raw_mode()?;
    execute!(terminal.backend_mut(), LeaveAlternateScreen)?;
    terminal.show_cursor()?;

    if let Err(err) = result {
        eprintln!("Error: {}", err);
    }

    // Apply selected theme
    if app.cursor < app.themes.len() {
        let sel = &app.themes[app.cursor];
        if sel.name != app.current {
            let home = dirs::home_dir().unwrap_or_default();
            let script = home.join("erogeDOTS").join("scripts").join("theme-switch");
            let _ = Command::new(script).arg(&sel.name).status();
        } else {
            println!("Already on {}", sel.name);
        }
    }

    Ok(())
}

fn run_app(
    terminal: &mut Terminal<CrosstermBackend<io::Stdout>>,
    app: &mut App,
    picker: &mut Picker,
) -> io::Result<()> {
    loop {
        terminal.draw(|f| ui(f, app))?;

        if let Event::Key(key) = event::read()? {
            if key.kind != KeyEventKind::Press {
                continue;
            }

            match key.code {
                KeyCode::Char('c') if key.modifiers.contains(crossterm::event::KeyModifiers::CONTROL) => {
                    return Ok(());
                }
                KeyCode::Char('q') | KeyCode::Esc => return Ok(()),
                KeyCode::Up | KeyCode::Char('k') => {
                    if app.cursor > 0 {
                        app.cursor -= 1;
                        let theme = app.themes[app.cursor].clone();
                        if !theme.wallpaper.is_empty() {
                            app.load_wallpaper(picker, &theme.wallpaper);
                        } else {
                            app.image_protocol = None;
                        }
                    }
                }
                KeyCode::Down | KeyCode::Char('j') => {
                    if app.cursor < app.themes.len() - 1 {
                        app.cursor += 1;
                        let theme = app.themes[app.cursor].clone();
                        if !theme.wallpaper.is_empty() {
                            app.load_wallpaper(picker, &theme.wallpaper);
                        } else {
                            app.image_protocol = None;
                        }
                    }
                }
                KeyCode::Enter => return Ok(()),
                _ => {}
            }
        }
    }
}

fn ui(f: &mut ratatui::Frame, app: &App) {
    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length(3),  // header
            Constraint::Min(10),   // content
            Constraint::Length(2), // footer
        ])
        .split(f.area());

    // Header
    let header = Paragraph::new(Line::from(vec![
        Span::styled(
            "✿ erogeDOTS Theme Picker",
            Style::default().fg(Color::Rgb(255, 143, 177)).add_modifier(Modifier::BOLD),
        ),
    ]));
    f.render_widget(header, chunks[0]);

    // Content: list + preview
    let content_chunks = Layout::default()
        .direction(Direction::Horizontal)
        .constraints([
            Constraint::Length(24), // list
            Constraint::Min(30),   // preview
        ])
        .split(chunks[1]);

    render_list(f, app, content_chunks[0]);
    render_preview(f, app, content_chunks[1]);

    // Footer
    let footer = Paragraph::new(Line::from(vec![
        Span::styled(
            "[↑↓] Navigate   [Enter] Select   [q] Cancel",
            Style::default().fg(Color::Rgb(86, 95, 137)),
        ),
    ]));
    f.render_widget(footer, chunks[2]);
}

fn render_list(f: &mut ratatui::Frame, app: &App, area: Rect) {
    let block = Block::default()
        .borders(Borders::ALL)
        .border_style(Style::default().fg(Color::Rgb(86, 95, 137)))
        .padding(Padding::new(1, 1, 1, 1));

    let inner = block.inner(area);
    f.render_widget(block, area);

    for (i, theme) in app.themes.iter().enumerate() {
        if i as u16 >= inner.height {
            break;
        }

        let is_current = theme.name == app.current;
        let is_selected = i == app.cursor;

        let marker = if is_current { "●" } else { "○" };
        let marker_color = if is_current {
            Color::Rgb(158, 206, 106)
        } else {
            Color::Rgb(192, 202, 245)
        };

        let (fg, bg) = if is_selected {
            (Color::White, Color::Rgb(255, 143, 177))
        } else {
            (Color::Rgb(192, 202, 245), Color::Reset)
        };

        let line = Line::from(vec![
            Span::styled(format!(" {} ", marker), Style::default().fg(marker_color)),
            Span::styled(
                format!(" {} ", theme.name),
                Style::default().fg(fg).bg(bg),
            ),
        ]);

        let row = Rect {
            x: inner.x,
            y: inner.y + i as u16,
            width: inner.width,
            height: 1,
        };
        f.render_widget(Paragraph::new(line), row);
    }
}

fn render_preview(f: &mut ratatui::Frame, app: &App, area: Rect) {
    let block = Block::default()
        .borders(Borders::ALL)
        .border_style(Style::default().fg(Color::Rgb(86, 95, 137)))
        .padding(Padding::new(1, 1, 1, 1));

    let inner = block.inner(area);
    f.render_widget(block, area);

    let Some(theme) = app.themes.get(app.cursor) else {
        return;
    };

    let mut y = inner.y;

    // Theme name
    let name_line = Line::from(vec![Span::styled(
        &theme.name,
        Style::default()
            .fg(Color::Rgb(255, 143, 177))
            .add_modifier(Modifier::BOLD),
    )]);
    f.render_widget(Paragraph::new(name_line), Rect { x: inner.x, y, width: inner.width, height: 1 });
    y += 2;

    // Color blocks
    let colors = [
        ("Primary", &theme.primary),
        ("Primary Lt", &theme.primary_light),
        ("Primary Dk", &theme.primary_dark),
        ("Background", &theme.bg),
        ("Foreground", &theme.fg),
    ];

    for (label, hex) in &colors {
        if hex.is_empty() || y >= inner.y + inner.height {
            continue;
        }

        let color = hex_to_color(hex);
        let block_str = "      ";
        let line = Line::from(vec![
            Span::styled(block_str, Style::default().fg(color).bg(color)),
            Span::styled(
                format!("  {}", label),
                Style::default().fg(Color::Rgb(192, 202, 245)),
            ),
            Span::styled(
                format!("  {}", hex),
                Style::default().fg(Color::Rgb(86, 95, 137)),
            ),
        ]);
        f.render_widget(Paragraph::new(line), Rect { x: inner.x, y, width: inner.width, height: 1 });
        y += 1;
    }

    y += 1;

    // Wallpaper image (ratatui-image uses kitty graphics protocol natively)
    if let Some(ref protocol) = app.image_protocol {
        let img_area = Rect {
            x: inner.x,
            y,
            width: inner.width.min(36),
            height: 10.min(inner.y + inner.height.saturating_sub(y)),
        };
        let image_widget = Image::new(protocol);
        f.render_widget(image_widget, img_area);
        y += 10.min(inner.height.saturating_sub(y));
    }

    // Wallpaper path
    if !theme.wallpaper.is_empty() && y < inner.y + inner.height {
        let path_line = Line::from(vec![Span::styled(
            format!("✎ {}", theme.wallpaper),
            Style::default().fg(Color::Rgb(86, 95, 137)),
        )]);
        f.render_widget(Paragraph::new(path_line), Rect { x: inner.x, y, width: inner.width, height: 1 });
    }
}
