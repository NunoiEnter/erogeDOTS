//! VN presentation over the existing installer; installation remains in install.sh.
use crate::{key, repo_root, select, terminal, vn_paper, vn_style, Term};
use crossterm::event::{self, KeyCode};
use ratatui::{
    layout::{Constraint, Layout},
    style::{Color, Modifier, Style},
    text::{Line, Span},
    widgets::{Block, Borders, Gauge, Paragraph, Wrap},
};
use std::{
    collections::VecDeque,
    io::{self, BufRead, BufReader},
    process::{Command, Stdio},
    sync::mpsc,
    thread,
    time::Duration,
};

const STAGES: &[&str] = &[
    "Authenticate sudo once",
    "Prepare source",
    "Check flake",
    "Build",
    "Activate",
    "Generate active theme",
    "Verify",
];
const CHAPTERS: &[&str] = &[
    "Authenticate",
    "Prepare source",
    "Check flake",
    "Build NixOS",
    "Activate NixOS",
    "Restore theme",
    "Verify",
];

struct Progress {
    stage: usize,
    logs: VecDeque<String>,
    result: Option<bool>,
    preview: bool,
}

impl Progress {
    fn receive(&mut self, line: String) {
        if let Some(step) = line.strip_prefix("==> ") {
            if let Some(index) = STAGES.iter().position(|stage| step.starts_with(stage)) {
                self.stage = index;
            }
        }
        if self.logs.len() == 160 {
            self.logs.pop_front();
        }
        self.logs.push_back(line);
    }
}

fn render(frame: &mut ratatui::Frame, progress: &Progress) {
    let canvas = vn_paper(frame);
    let page = Layout::vertical([
        Constraint::Length(3),
        Constraint::Min(8),
        Constraint::Length(3),
        Constraint::Length(2),
    ])
    .split(canvas);
    let accent = Color::Rgb(137, 75, 110);
    let muted = Color::Rgb(109, 83, 104);
    let title = if progress.preview {
        "erogeDOTS / Installation preview"
    } else {
        "erogeDOTS / A new beginning"
    };
    frame.render_widget(
        Paragraph::new(vec![
            Line::styled(
                title,
                Style::default().fg(accent).add_modifier(Modifier::BOLD),
            ),
            Line::from("Alpha 2.0 · NixOS + Niri · Romance VN desktop"),
        ]),
        page[0],
    );
    let columns = if canvas.width >= 70 {
        Layout::horizontal([Constraint::Length(26), Constraint::Min(24)]).split(page[1])
    } else {
        Layout::vertical([Constraint::Length(9), Constraint::Min(2)]).split(page[1])
    };
    let chapters: Vec<Line> = CHAPTERS
        .iter()
        .enumerate()
        .map(|(index, stage)| {
            let marker = if progress.preview {
                "next"
            } else if progress.result == Some(true) || index < progress.stage {
                "complete"
            } else if index == progress.stage {
                "now"
            } else {
                "next"
            };
            Line::from(vec![
                Span::styled(
                    format!("{marker:8}"),
                    Style::default().fg(if index == progress.stage {
                        accent
                    } else {
                        muted
                    }),
                ),
                Span::raw(*stage),
            ])
        })
        .collect();
    frame.render_widget(
        Paragraph::new(chapters).block(
            Block::default()
                .title(" Chapters ")
                .borders(Borders::ALL)
                .border_style(Style::default().fg(accent)),
        ),
        columns[0],
    );
    let log_block = Block::default()
        .title(" Scene log ")
        .borders(Borders::ALL)
        .border_style(Style::default().fg(accent));
    let log_area = log_block.inner(columns[1]);
    let keep = usize::from(log_area.height);
    let start = progress.logs.len().saturating_sub(keep);
    let logs: Vec<Line> = progress
        .logs
        .iter()
        .skip(start)
        .map(|line| Line::from(line.as_str()))
        .collect();
    frame.render_widget(
        Paragraph::new(logs)
            .block(log_block)
            .wrap(Wrap { trim: false }),
        columns[1],
    );
    let label = if progress.preview {
        "Your installation follows these chapters."
    } else {
        match progress.result {
            Some(true) => "Your next chapter is ready.",
            Some(false) => "Installation stopped. The scene log explains why.",
            None => "Preparing your desktop — actual stage progress",
        }
    };
    let ratio = if progress.result == Some(true) {
        1.0
    } else {
        progress.stage as f64 / STAGES.len() as f64
    };
    frame.render_widget(
        Gauge::default()
            .block(Block::default().borders(Borders::TOP))
            .gauge_style(Style::default().fg(accent).bg(Color::Rgb(239, 221, 233)))
            .ratio(ratio)
            .label(label),
        page[2],
    );
    let help = if progress.preview {
        "Preview only · no changes made · Enter / Esc return"
    } else if progress.result.is_some() {
        "Enter / Esc return · Full log: ~/.local/state/erogedots/install.log"
    } else {
        "Installation is working · build and activation may take several minutes"
    };
    frame.render_widget(
        Paragraph::new(help)
            .style(Style::default().fg(muted))
            .wrap(Wrap { trim: true }),
        page[3],
    );
}

fn preview(term: &mut Term) -> io::Result<()> {
    let mut progress = Progress {
        stage: 0,
        logs: VecDeque::new(),
        result: None,
        preview: true,
    };
    progress.receive("Welcome. This is a preview of the installation guide.".into());
    progress.receive("No authentication, package build or system activation is performed.".into());
    progress.receive("Begin installation from the welcome menu when you are ready.".into());
    loop {
        term.draw(|frame| render(frame, &progress))?;
        match key()? {
            KeyCode::Enter | KeyCode::Esc | KeyCode::Char('q') => return Ok(()),
            _ => {}
        }
    }
}

fn welcome(term: &mut Term) -> io::Result<bool> {
    loop {
        match select(
            term,
            "erogeDOTS / A new beginning",
            "NixOS · user moni · ~/erogeDOTS\n↑ ↓ choose · Enter select · Esc return",
            &[
                "Begin installation — check, build and activate NixOS".into(),
                "Read the installation guide".into(),
                "Return without changes".into(),
            ],
        )? {
            Some(0) => return Ok(true),
            Some(1) => loop {
                term.draw(|frame| {
                        let area = vn_paper(frame);
                        frame.render_widget(Paragraph::new("Before your first scene\n\nThis personal configuration requires NixOS, user moni and ~/erogeDOTS.\n\nInstallation discovers your hardware, checks the flake, builds and activates the system, then restores your character theme.\n\nYou will enter your sudo password in the normal terminal before installation begins. The complete log is saved in ~/.local/state/erogedots/install.log.\n\nTheme changes later do not need a NixOS rebuild.\n\nEnter / Esc: return to the welcome menu").style(vn_style()).wrap(Wrap { trim: false }), area);
                    })?;
                if matches!(key()?, KeyCode::Enter | KeyCode::Esc) {
                    break;
                }
            },
            _ => return Ok(false),
        }
    }
}

pub fn run(is_preview: bool) -> io::Result<()> {
    if is_preview {
        return terminal(preview);
    }
    if !terminal(welcome)? {
        return Ok(());
    }
    if !Command::new("sudo").arg("-v").status()?.success() {
        return Err(io::Error::other(
            "Authentication failed. Installation did not start.",
        ));
    }
    let mut child = Command::new(repo_root().join("install.sh"))
        .arg("--plain")
        .env("EROGEDOTS_SUDO_READY", "1")
        .stdin(Stdio::null())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()?;
    let (sender, receiver) = mpsc::channel();
    let output = child.stdout.take().expect("piped installer stdout");
    let errors = child.stderr.take().expect("piped installer stderr");
    let error_sender = sender.clone();
    let out_reader = thread::spawn(move || {
        for line in BufReader::new(output).lines().map_while(Result::ok) {
            if sender.send(line).is_err() {
                break;
            }
        }
    });
    let err_reader = thread::spawn(move || {
        for line in BufReader::new(errors).lines().map_while(Result::ok) {
            if error_sender.send(line).is_err() {
                break;
            }
        }
    });
    let result = terminal(|term| {
        let mut progress = Progress {
            stage: 0,
            logs: VecDeque::new(),
            result: None,
            preview: false,
        };
        loop {
            for line in receiver.try_iter() {
                progress.receive(line);
            }
            if progress.result.is_none() {
                if let Some(status) = child.try_wait()? {
                    progress.result = Some(status.success());
                    // Drain both streams before showing the final result.
                    for line in receiver.iter() {
                        progress.receive(line);
                    }
                }
            }
            term.draw(|frame| render(frame, &progress))?;
            if event::poll(Duration::from_millis(75))? {
                if let event::Event::Key(pressed) = event::read()? {
                    if progress.result.is_some()
                        && matches!(
                            pressed.code,
                            KeyCode::Enter | KeyCode::Esc | KeyCode::Char('q')
                        )
                    {
                        return Ok(progress.result == Some(true));
                    }
                }
            }
        }
    });
    if result.is_err() {
        let _ = child.kill();
    }
    let _ = child.wait();
    let _ = out_reader.join();
    let _ = err_reader.join();
    match result? {
        true => Ok(()),
        false => Err(io::Error::other(
            "Installation failed. See ~/.local/state/erogedots/install.log.",
        )),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use ratatui::{backend::TestBackend, Terminal};
    #[test]
    fn progress_uses_real_stage_markers_and_bounds_logs() {
        let mut progress = Progress {
            stage: 0,
            logs: VecDeque::new(),
            result: None,
            preview: false,
        };
        progress.receive("==> Build NixChan".into());
        assert_eq!(progress.stage, 3);
        for _ in 0..200 {
            progress.receive("build output".into());
        }
        assert_eq!(progress.logs.len(), 160);
        progress.receive("==> Activate NixChan".into());
        assert_eq!(progress.stage, 4);
    }
    #[test]
    fn preview_renders_at_small_and_wide_terminal_sizes() {
        for (width, height) in [(80, 24), (120, 36)] {
            let mut terminal = Terminal::new(TestBackend::new(width, height)).unwrap();
            let progress = Progress {
                stage: 0,
                logs: VecDeque::new(),
                result: None,
                preview: true,
            };
            terminal.draw(|frame| render(frame, &progress)).unwrap();
            let buffer = terminal.backend().buffer();
            let text: String = buffer.content().iter().map(|cell| cell.symbol()).collect();
            assert!(text.contains("Installation preview"));
            assert!(text.contains("Preview only"));
        }
    }
}
