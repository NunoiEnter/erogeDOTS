//! erogeDOTS music-pill-rs — floating Wayland layer-shell media pill.
//!
//! Native Rust replacement for the old Python/GTK pill. No GTK, no Python:
//! raw wayland-client + layer-shell, pixel-pushed SHM buffers, cosmic-text
//! shaping (JP/TH safe), MPRIS polled through the `playerctl` CLI, synced
//! lyrics from LRCLIB.
//!
//! Layout: full-width top strip, album art disc, title + artist/lyric lines,
//! prev/play/next pixel buttons on the right.
//! Clicks: left = play/pause, right = next, middle = previous,
//! vertical scroll = volume. Auto-hides (transparent, no input, no zone)
//! when nothing is playing.

use std::collections::hash_map::DefaultHasher;
use std::fs::OpenOptions;
use std::hash::{Hash, Hasher};
use std::io::{Read, Write};
use std::os::unix::io::AsFd;
use std::path::PathBuf;
use std::process::Command;
use std::time::Duration;

use cosmic_text::{
    Attrs, Buffer, Family, FontSystem, Metrics, Shaping, SwashCache, SwashContent, Weight,
};
use wayland_client::{
    Connection, Dispatch, QueueHandle, WEnum,
    delegate_noop,
    protocol::{
        wl_buffer::WlBuffer, wl_callback::WlCallback, wl_compositor::WlCompositor,
        wl_display::WlDisplay, wl_output::WlOutput, wl_pointer::WlPointer,
        wl_registry::WlRegistry, wl_region::WlRegion, wl_seat::WlSeat, wl_shm::WlShm,
        wl_shm_pool::WlShmPool, wl_surface::WlSurface,
        wl_pointer, wl_registry, wl_seat, wl_shm, wl_display,
    },
};
use wayland_protocols_wlr::layer_shell::v1::client::{
    zwlr_layer_shell_v1::{self, ZwlrLayerShellV1},
    zwlr_layer_surface_v1::{self, ZwlrLayerSurfaceV1},
};

// ── Look ────────────────────────────────────────────────────────────────

const BAR_H: u32 = 64;
const PAD: i32 = 10;
const ART: i32 = 44;
const BG: (u8, u8, u8, u8) = (32, 22, 22, 217); // rgba(22,22,32,0.85)
const TITLE_C: (u8, u8, u8) = (0xe8, 0xa0, 0xbf);
const SUB_C: (u8, u8, u8) = (0xb4, 0x8e, 0xad);
const ACCENT: (u8, u8, u8) = (0xc8, 0xa0, 0xe8);
const BTN_W: i32 = 36;

// ── Small helpers ───────────────────────────────────────────────────────

fn run(cmd: &str, args: &[&str]) -> String {
    Command::new(cmd)
        .args(args)
        .output()
        .map(|o| String::from_utf8_lossy(&o.stdout).trim().to_string())
        .unwrap_or_default()
}

fn cache_dir() -> PathBuf {
    let d = dirs_fallback();
    std::fs::create_dir_all(&d).ok();
    d
}

fn dirs_fallback() -> PathBuf {
    if let Ok(h) = std::env::var("HOME") {
        PathBuf::from(h).join(".cache").join("eroge-music-pill")
    } else {
        PathBuf::from("/tmp/eroge-music-pill")
    }
}

// ── MPRIS through playerctl ─────────────────────────────────────────────

struct Track {
    title: String,
    artist: String,
    album: String,
    art_url: String,
    length: f64,
    id: String,
}

fn metadata() -> Track {
    // NOTE: fields are queried one by one. An earlier version passed a
    // single -f template with NUL separators, but NUL bytes are illegal in
    // execve argv (Rust Command rejects them), so that silently returned "".
    let q = |var: &str| run("playerctl", &["metadata", "--format", var]);
    let length = q("{{mpris:length}}").trim().parse::<i64>().map(|v| v as f64 / 1_000_000.0).unwrap_or(0.0);
    Track {
        title: q("{{title}}"),
        artist: q("{{artist}}"),
        album: q("{{album}}"),
        art_url: q("{{mpris:artUrl}}"),
        length,
        id: q("{{mpris:trackid}}"),
    }
}

fn status() -> String {
    run("playerctl", &["status"])
}

fn position() -> f64 {
    run("playerctl", &["position"]).parse::<f64>().unwrap_or(0.0)
}

// ── LRCLIB synced lyrics ────────────────────────────────────────────────

fn fetch_lyrics(t: &Track) -> Vec<(f64, String)> {
    if t.title.is_empty() {
        return vec![];
    }
    let mut req = ureq::get("https://lrclib.net/api/get")
        .query("track_name", &t.title)
        .query("artist_name", &t.artist);
    if !t.album.is_empty() {
        req = req.query("album_name", &t.album);
    }
    if t.length > 0.0 {
        req = req.query("duration", &format!("{}", t.length as i64));
    }
    let body = match req.call() {
        Ok(r) => match r.into_string() {
            Ok(b) => b,
            Err(_) => return vec![],
        },
        Err(_) => return vec![],
    };
    let synced = serde_json::from_str::<serde_json::Value>(&body)
        .ok()
        .and_then(|v| v.get("syncedLyrics")?.as_str().map(|s| s.to_string()))
        .unwrap_or_default();
    let mut out = vec![];
    for line in synced.lines() {
        if !line.starts_with('[') {
            continue;
        }
        let Some(end) = line.find(']') else { continue };
        let ts = &line[1..end];
        let Some((m, s)) = ts.split_once(':') else { continue };
        let (Ok(mm), Ok(ss)) = (m.parse::<f64>(), s.parse::<f64>()) else { continue };
        out.push((mm * 60.0 + ss, line[end + 1..].trim().to_string()));
    }
    out
}

fn lyric_at(lyrics: &[(f64, String)], pos: f64) -> String {
    let mut cur = "";
    for (start, text) in lyrics {
        if pos >= *start {
            cur = text;
        } else {
            break;
        }
    }
    cur.to_string()
}

// ── Album art ───────────────────────────────────────────────────────────

fn art_cache_path(url: &str) -> PathBuf {
    let mut h = DefaultHasher::new();
    url.hash(&mut h);
    let ext = url.rsplit('?').next().unwrap_or(url);
    let ext = ext.rsplit('.').next().unwrap_or("img");
    let ext: String = ext.chars().filter(|c| c.is_ascii_alphanumeric()).take(4).collect();
    cache_dir().join(format!("{:x}.{}", h.finish(), ext))
}

fn load_art(url: &str) -> Option<image::RgbaImage> {
    if url.is_empty() {
        return None;
    }
    let img = if let Some(path) = url.strip_prefix("file://") {
        image::open(path).ok()?
    } else if url.starts_with("http://") || url.starts_with("https://") {
        let dest = art_cache_path(url);
        let bytes = if dest.exists() {
            std::fs::read(&dest).ok()?
        } else {
            let mut data = vec![];
            ureq::get(url)
                .timeout(Duration::from_secs(10))
                .call()
                .ok()?
                .into_reader()
                .read_to_end(&mut data)
                .ok()?;
            std::fs::write(&dest, &data).ok()?;
            data
        };
        let fmt = image::guess_format(&bytes).ok()?;
        image::load_from_memory_with_format(&bytes, fmt).ok()?
    } else {
        return None;
    };
    Some(img.resize_exact(96, 96, image::imageops::FilterType::Triangle).to_rgba8())
}

// ── Pixel buffer ────────────────────────────────────────────────────────

struct Canvas {
    w: u32,
    h: u32,
    px: Vec<u8>, // ARGB8888 bytes: B,G,R,A on little-endian
}

impl Canvas {
    fn new(w: u32, h: u32) -> Self {
        Self { w, h, px: vec![0; (w * h * 4) as usize] }
    }
    fn blend(&mut self, x: i32, y: i32, r: u8, g: u8, b: u8, a: u8) {
        if x < 0 || y < 0 || x >= self.w as i32 || y >= self.h as i32 || a == 0 {
            return;
        }
        let i = ((y as u32 * self.w + x as u32) * 4) as usize;
        let af = a as f32 / 255.0;
        let (dr, dg, db) = (self.px[i + 2] as f32, self.px[i + 1] as f32, self.px[i] as f32);
        self.px[i] = (b as f32 * af + db * (1.0 - af)) as u8;
        self.px[i + 1] = (g as f32 * af + dg * (1.0 - af)) as u8;
        self.px[i + 2] = (r as f32 * af + dr * (1.0 - af)) as u8;
        let da = self.px[i + 3] as f32 / 255.0;
        self.px[i + 3] = ((af + da * (1.0 - af)) * 255.0) as u8;
    }
    /// Blend one color channel with its own coverage (for SubpixelMask
    /// glyphs, whose image data is R,G,B coverage triplets per pixel).
    fn blend_ch(&mut self, x: i32, y: i32, ch: usize, v: u8, cov: u8) {
        if x < 0 || y < 0 || x >= self.w as i32 || y >= self.h as i32 || cov == 0 {
            return;
        }
        let i = ((y as u32 * self.w + x as u32) * 4) as usize;
        let cf = cov as f32 / 255.0;
        let d = self.px[i + ch] as f32;
        self.px[i + ch] = (v as f32 * cf + d * (1.0 - cf)) as u8;
        let da = self.px[i + 3] as f32 / 255.0;
        self.px[i + 3] = ((cf + da * (1.0 - cf)) * 255.0) as u8;
    }
    fn rect(&mut self, x: i32, y: i32, w: i32, h: i32, r: u8, g: u8, b: u8, a: u8) {
        for yy in y..y + h {
            for xx in x..x + w {
                self.blend(xx, yy, r, g, b, a);
            }
        }
    }
    fn rounded(&mut self, x: i32, y: i32, w: i32, h: i32, rad: i32, c: (u8, u8, u8, u8)) {
        for yy in y..y + h {
            for xx in x..x + w {
                let dx = (xx - x).min(x + w - 1 - xx).min(rad);
                let dy = (yy - y).min(y + h - 1 - yy).min(rad);
                if dx * dx + dy * dy >= rad * rad {
                    continue;
                }
                self.blend(xx, yy, c.0, c.1, c.2, c.3);
            }
        }
    }
    fn disc(&mut self, cx: i32, cy: i32, rad: i32, c: (u8, u8, u8, u8)) {
        for yy in cy - rad..=cy + rad {
            for xx in cx - rad..=cx + rad {
                let (dx, dy) = (xx - cx, yy - cy);
                if dx * dx + dy * dy <= rad * rad {
                    self.blend(xx, yy, c.0, c.1, c.2, c.3);
                }
            }
        }
    }
    fn blit_circle(&mut self, img: &image::RgbaImage, cx: i32, cy: i32, rad: i32) {
        let (iw, ih) = (img.width() as i32, img.height() as i32);
        for yy in cy - rad..=cy + rad {
            for xx in cx - rad..=cx + rad {
                let (dx, dy) = (xx - cx, yy - cy);
                if dx * dx + dy * dy > rad * rad {
                    continue;
                }
                let sx = ((xx - (cx - rad)) as f32 / (rad * 2) as f32 * iw as f32) as u32;
                let sy = ((yy - (cy - rad)) as f32 / (rad * 2) as f32 * ih as f32) as u32;
                let p = img.get_pixel(sx.min(iw as u32 - 1), sy.min(ih as u32 - 1));
                self.blend(xx, yy, p[0], p[1], p[2], p[3]);
            }
        }
    }
    fn tri(&mut self, cx: i32, cy: i32, s: i32, dir: i32, c: (u8, u8, u8)) {
        // dir > 0 points right, dir < 0 points left
        for yy in -s..=s {
            let a = yy.abs();
            let (x0, x1) = if dir > 0 {
                (cx - s + 2 * a, cx + s)
            } else {
                (cx - s, cx + s - 2 * a)
            };
            self.rect(x0, cy + yy, x1 - x0, 1, c.0, c.1, c.2, 255);
        }
    }
}

fn draw_text(
    cv: &mut Canvas,
    fs: &mut FontSystem,
    swash: &mut SwashCache,
    text: &str,
    x: i32,
    y: i32,
    max_w: u32,
    size: f32,
    bold: bool,
    color: (u8, u8, u8),
) {
    if text.is_empty() || max_w == 0 {
        return;
    }
    let mut attrs = Attrs::new().family(Family::SansSerif);
    if bold {
        attrs = attrs.weight(Weight::SEMIBOLD);
    }
    let metrics = Metrics::new(size, size + 6.0);
    let mut buf = Buffer::new(fs, metrics);
    buf.set_size(fs, Some(max_w as f32), Some(size + 8.0));
    buf.set_text(fs, text, attrs, Shaping::Advanced);
    buf.shape_until_scroll(fs, false);
    for run in buf.layout_runs() {
        for glyph in run.glyphs {
            let physical = glyph.physical((x as f32, y as f32), 1.0);
            let Some(img) = swash.get_image(fs, physical.cache_key) else { continue };
            let (gw, gh) = (img.placement.width as i32, img.placement.height as i32);
            let (gx, gy) = (physical.x + img.placement.left, physical.y + img.placement.top);
            match img.content {
                SwashContent::Mask => {
                    for row in 0..gh {
                        for col in 0..gw {
                            let a = img.data[(row * gw + col) as usize];
                            cv.blend(gx + col, gy + row, color.0, color.1, color.2, a);
                        }
                    }
                }
                SwashContent::SubpixelMask => {
                    // 3 coverage bytes per pixel (R,G,B subpixels)
                    for row in 0..gh {
                        for col in 0..gw {
                            let o = ((row * gw + col) * 3) as usize;
                            cv.blend_ch(gx + col, gy + row, 2, color.0, img.data[o]);
                            cv.blend_ch(gx + col, gy + row, 1, color.1, img.data[o + 1]);
                            cv.blend_ch(gx + col, gy + row, 0, color.2, img.data[o + 2]);
                        }
                    }
                }
                SwashContent::Color => {
                    for row in 0..gh {
                        for col in 0..gw {
                            let o = ((row * gw + col) * 4) as usize;
                            let (b, g, r, a) =
                                (img.data[o], img.data[o + 1], img.data[o + 2], img.data[o + 3]);
                            cv.blend(gx + col, gy + row, r, g, b, a);
                        }
                    }
                }
            }
        }
    }
}

// ── Wayland state ───────────────────────────────────────────────────────

struct Media {
    track_id: String,
    title: String,
    artist: String,
    art_url: String,
    art: Option<image::RgbaImage>,
    lyrics: Vec<(f64, String)>,
    lyric_line: String,
    playing: bool,
    visible: bool,
}

struct State {
    compositor: Option<WlCompositor>,
    shm: Option<WlShm>,
    shell: Option<ZwlrLayerShellV1>,
    seat: Option<WlSeat>,
    output: Option<WlOutput>,
    surface: Option<WlSurface>,
    layer: Option<ZwlrLayerSurfaceV1>,
    buffer: Option<WlBuffer>,
    width: u32,
    configured: bool,
    pointer_x: f64,
    pointer_y: f64,
    exit: bool,
    media: Media,
    font_system: Option<FontSystem>,
    swash: Option<SwashCache>,
}

impl State {
    fn buttons(&self) -> (i32, i32, i32) {
        let x0 = self.width as i32 - PAD - BTN_W * 3 - 8;
        (x0, x0 + BTN_W, x0 + BTN_W * 2)
    }
}

delegate_noop!(State: ignore WlCompositor);
delegate_noop!(State: ignore WlSurface);
delegate_noop!(State: ignore WlBuffer);
delegate_noop!(State: ignore WlShmPool);
delegate_noop!(State: ignore WlShm);
delegate_noop!(State: ignore WlOutput);
delegate_noop!(State: ignore WlRegion);
delegate_noop!(State: ignore WlCallback);
delegate_noop!(State: ignore ZwlrLayerShellV1);

impl Dispatch<WlDisplay, ()> for State {
    fn event(
        _: &mut Self,
        _: &WlDisplay,
        event: wl_display::Event,
        _: &(),
        _: &Connection,
        _: &QueueHandle<Self>,
    ) {
        if let wl_display::Event::Error { object_id, code, message } = event {
            eprintln!("WAYLAND ERROR obj={} code={} msg={}", object_id, code, message);
        }
    }
}

impl Dispatch<WlRegistry, ()> for State {
    fn event(
        st: &mut Self,
        proxy: &WlRegistry,
        event: wl_registry::Event,
        _: &(),
        _: &Connection,
        qh: &QueueHandle<Self>,
    ) {
        if let wl_registry::Event::Global { name, interface, version } = event {
            match interface.as_str() {
                "wl_compositor" => {
                    st.compositor = Some(proxy.bind::<WlCompositor, _, _>(name, version.min(6), qh, ()));
                }
                "wl_shm" => {
                    st.shm = Some(proxy.bind::<WlShm, _, _>(name, version.min(1), qh, ()));
                }
                "zwlr_layer_shell_v1" => {
                    st.shell =
                        Some(proxy.bind::<ZwlrLayerShellV1, _, _>(name, version.min(4), qh, ()));
                }
                "wl_seat" => {
                    st.seat = Some(proxy.bind::<WlSeat, _, _>(name, version.min(7), qh, ()));
                }
                "wl_output" => {
                    if st.output.is_none() {
                        st.output = Some(proxy.bind::<WlOutput, _, _>(name, version.min(4), qh, ()));
                    }
                }
                _ => {}
            }
        }
    }
}

impl Dispatch<WlSeat, ()> for State {
    fn event(
        _st: &mut Self,
        seat: &WlSeat,
        event: wl_seat::Event,
        _: &(),
        _: &Connection,
        qh: &QueueHandle<Self>,
    ) {
        if let wl_seat::Event::Capabilities { capabilities: WEnum::Value(caps) } = event {
            if caps.contains(wl_seat::Capability::Pointer) {
                seat.get_pointer(qh, ());
            }
        }
    }
}

impl Dispatch<WlPointer, ()> for State {
    fn event(
        st: &mut Self,
        _: &WlPointer,
        event: wl_pointer::Event,
        _: &(),
        _: &Connection,
        _: &QueueHandle<Self>,
    ) {
        use wl_pointer::{ButtonState, Event::*};
        match event {
            Enter { surface_x, surface_y, .. } => {
                st.pointer_x = surface_x;
                st.pointer_y = surface_y;
            }
            Motion { surface_x, surface_y, .. } => {
                st.pointer_x = surface_x;
                st.pointer_y = surface_y;
            }
            Button { button, state: WEnum::Value(ButtonState::Pressed), .. } => {
                let x = st.pointer_x as i32;
                let (prev, play, next) = st.buttons();
                let in_btn = |x0: i32| x >= x0 && x < x0 + BTN_W;
                match button {
                    0x110 => {
                        // left: play/pause, or button-local action
                        if in_btn(play) || !(in_btn(prev) || in_btn(next)) {
                            run("playerctl", &["play-pause"]);
                        } else if in_btn(prev) {
                            run("playerctl", &["previous"]);
                        } else if in_btn(next) {
                            run("playerctl", &["next"]);
                        }
                    }
                    0x111 => {
                        run("playerctl", &["next"]);
                    }
                    0x112 => {
                        run("playerctl", &["previous"]);
                    }
                    _ => {}
                }
            }
            Axis { axis, value, .. } => {
                if axis == WEnum::Value(wl_pointer::Axis::VerticalScroll) {
                    if value < 0.0 {
                        run("playerctl", &["volume", "0.05+"]);
                    } else if value > 0.0 {
                        run("playerctl", &["volume", "0.05-"]);
                    }
                }
            }
            _ => {}
        }
    }
}

impl Dispatch<ZwlrLayerSurfaceV1, ()> for State {
    fn event(
        st: &mut Self,
        layer: &ZwlrLayerSurfaceV1,
        event: zwlr_layer_surface_v1::Event,
        _: &(),
        _: &Connection,
        _: &QueueHandle<Self>,
    ) {
        match event {
            zwlr_layer_surface_v1::Event::Configure { serial, width, height } => {
                layer.ack_configure(serial);
                if width > 0 && height > 0 {
                    st.width = width;
                    st.configured = true;
                    draw(st);
                }
            }
            zwlr_layer_surface_v1::Event::Closed => {
                st.exit = true;
            }
            _ => {}
        }
    }
}

// ── Fonts: resolve a few families through fontconfig, load the files ────

fn load_fonts(fs: &mut FontSystem) {
    let mut seen = std::collections::HashSet::new();
    // Explicit CJK/Thai families first: bare "sans-serif:lang=xx" queries
    // can resolve to Kanit (no CJK coverage), which turns JP titles to tofu.
    for pat in [
        "sans-serif",
        "Noto Sans Thai",
        "Noto Sans CJK JP",
        "sans-serif:lang=th",
        "sans-serif:lang=ja",
    ] {
        let file = run("fc-match", &["-f", "%{file}\n", pat]);
        let file = file.lines().next().unwrap_or("").trim().to_string();
        if file.is_empty() || !seen.insert(file.clone()) {
            continue;
        }
        match std::fs::read(&file) {
            Ok(data) => {
                fs.db_mut().load_font_data(data);
                eprintln!("pill: font {} <- {}", pat, file);
            }
            Err(e) => eprintln!("pill: cannot read {}: {}", file, e),
        }
    }
}

// ── Draw ────────────────────────────────────────────────────────────────

fn draw(st: &mut State) {
    // Never attach a buffer before the first configure: committing two
    // buffers pre-configure trips a Smithay/niri client error and the
    // connection gets killed. The empty setup commit asks for configure.
    if !st.configured {
        return;
    }
    let (Some(surface), Some(layer), Some(shm), Some(fs), Some(swash)) = (
        st.surface.as_ref(),
        st.layer.as_ref(),
        st.shm.as_ref(),
        st.font_system.as_mut(),
        st.swash.as_mut(),
    ) else {
        return;
    };
    let w = st.width.max(320);
    let h = BAR_H;
    let m = &st.media;

    let mut cv = Canvas::new(w, h);
    if m.visible {
        cv.rounded(0, 0, w as i32, h as i32, 20, BG);
        // art disc or accent fallback disc
        let (cx, cy, rad) = (PAD + ART / 2, h as i32 / 2, ART / 2);
        match &m.art {
            Some(img) => cv.blit_circle(img, cx, cy, rad),
            None => cv.disc(cx, cy, rad, (ACCENT.0, ACCENT.1, ACCENT.2, 90)),
        }
        // texts
        let tx = PAD + ART + 10;
        let text_w = (w as i32 - tx - (BTN_W * 3 + PAD + 16)).max(50) as u32;
        draw_text(&mut cv, fs, swash, &m.title, tx, 6, text_w, 19.0, true, TITLE_C);
        draw_text(&mut cv, fs, swash, &m.lyric_line, tx, 34, text_w, 14.0, false, SUB_C);
        // buttons
        let (prev, play, next) = st.buttons();
        let cyb = h as i32 / 2;
        // prev: bar + left triangle
        cv.rect(prev + 8, cyb - 7, 3, 14, ACCENT.0, ACCENT.1, ACCENT.2, 255);
        cv.tri(prev + 22, cyb, 8, -1, ACCENT);
        // play / pause
        if m.playing {
            cv.rect(play + 12, cyb - 7, 4, 14, ACCENT.0, ACCENT.1, ACCENT.2, 255);
            cv.rect(play + 20, cyb - 7, 4, 14, ACCENT.0, ACCENT.1, ACCENT.2, 255);
        } else {
            cv.tri(play + 19, cyb, 9, 1, ACCENT);
        }
        // next: right triangle + bar
        cv.tri(next + 14, cyb, 8, 1, ACCENT);
        cv.rect(next + 25, cyb - 7, 3, 14, ACCENT.0, ACCENT.1, ACCENT.2, 255);
    }

    // ship pixels through SHM
    let stride = w * 4;
    let rtd = std::env::var("XDG_RUNTIME_DIR").unwrap_or_else(|_| "/tmp".into());
    let path = format!("{}/pill-{}-{}.buf", rtd, std::process::id(), w);
    // O_RDWR: the compositor mmaps the pool PROT_READ|PROT_WRITE, which
    // fails on O_WRONLY fds ("Failed to mmap fd" protocol error).
    let mut f = OpenOptions::new()
        .read(true)
        .write(true)
        .create(true)
        .truncate(true)
        .open(&path)
        .expect("shm tmp");
    f.set_len((stride * h) as u64).expect("shm size");
    f.write_all(&cv.px).expect("shm write");
    let pool = shm.create_pool(f.as_fd(), (stride * h) as i32, &qh_of(st), ());
    let buf = pool.create_buffer(
        0,
        w as i32,
        h as i32,
        stride as i32,
        wl_shm::Format::Argb8888,
        &qh_of(st),
        (),
    );
    pool.destroy();
    std::fs::remove_file(&path).ok();

    if m.visible {
        layer.set_exclusive_zone(h as i32);
        if let Some(comp) = st.compositor.as_ref() {
            let reg = comp.create_region(&qh_of(st), ());
            reg.add(0, 0, w as i32, h as i32);
            surface.set_input_region(Some(&reg));
            reg.destroy();
        }
    } else {
        layer.set_exclusive_zone(0);
        if let Some(comp) = st.compositor.as_ref() {
            let reg = comp.create_region(&qh_of(st), ());
            surface.set_input_region(Some(&reg));
            reg.destroy();
        }
    }
    surface.attach(Some(&buf), 0, 0);
    surface.damage_buffer(0, 0, w as i32, h as i32);
    surface.commit();
    if let Some(old) = st.buffer.replace(buf) {
        old.destroy();
    }
}

// QueueHandle plumbing: draw() only has &mut State, so stash a clone-able
// handle. wayland-client QueueHandle is Clone; we keep one in a thread-local
// set once at startup.
use std::cell::RefCell;
thread_local! {
    static QH: RefCell<Option<QueueHandle<State>>> = const { RefCell::new(None) };
}
fn qh_of(_st: &State) -> QueueHandle<State> {
    QH.with(|q| q.borrow().clone().expect("queue handle"))
}

// ── Media polling ───────────────────────────────────────────────────────

fn poll_media(st: &mut State) -> bool {
    let status = status();
    let t = metadata();
    let playing = status == "Playing";
    let visible = !(status == "Stopped" && t.title.is_empty());
    let m = &mut st.media;
    let mut dirty = m.playing != playing || m.visible != visible;

    if t.id != m.track_id {
        m.track_id = t.id.clone();
        m.title = if t.artist.is_empty() { t.title.clone() } else { format!("{} — {}", t.title, t.artist) };
        m.artist = t.artist.clone();
        m.art_url = t.art_url.clone();
        m.art = load_art(&t.art_url);
        m.lyrics = fetch_lyrics(&t);
        m.lyric_line.clear();
        dirty = true;
    }
    m.playing = playing;
    m.visible = visible;

    if visible {
        let line = if m.lyrics.is_empty() {
            if m.artist.is_empty() { String::new() } else { m.artist.clone() }
        } else {
            let l = lyric_at(&m.lyrics, position());
            if l.is_empty() { "♪ ♫ ♪".into() } else { l }
        };
        if line != m.lyric_line {
            m.lyric_line = line;
            dirty = true;
        }
    }
    dirty
}

// ── Main ────────────────────────────────────────────────────────────────

fn main() {
    let conn = Connection::connect_to_env().expect("wayland connect");
    let display = conn.display();
    let mut event_queue = conn.new_event_queue();
    let qh = event_queue.handle();
    QH.with(|q| *q.borrow_mut() = Some(qh.clone()));

    let _registry = display.get_registry(&qh, ());

    let mut font_system = FontSystem::new();
    load_fonts(&mut font_system);

    let mut st = State {
        compositor: None,
        shm: None,
        shell: None,
        seat: None,
        output: None,
        surface: None,
        layer: None,
        buffer: None,
        width: 600,
        configured: false,
        pointer_x: 0.0,
        pointer_y: 0.0,
        exit: false,
        media: Media {
            track_id: String::new(),
            title: String::new(),
            artist: String::new(),
            art_url: String::new(),
            art: None,
            lyrics: vec![],
            lyric_line: String::new(),
            playing: false,
            visible: false,
        },
        font_system: Some(font_system),
        swash: Some(SwashCache::new()),
    };

    event_queue.roundtrip(&mut st).expect("roundtrip globals");

    let surface = st.compositor.as_ref().expect("compositor").create_surface(&qh, ());
    let layer = st
        .shell
        .as_ref()
        .expect("layer shell")
        .get_layer_surface(
            &surface,
            st.output.as_ref(),
            zwlr_layer_shell_v1::Layer::Top,
            "eroge-music-pill".into(),
            &qh,
            (),
        );
    layer.set_size(0, BAR_H);
    layer.set_anchor(
        zwlr_layer_surface_v1::Anchor::Top
            | zwlr_layer_surface_v1::Anchor::Left
            | zwlr_layer_surface_v1::Anchor::Right,
    );
    layer.set_exclusive_zone(BAR_H as i32);
    layer.set_margin(8, 0, 0, 0);
    surface.commit();
    st.surface = Some(surface);
    st.layer = Some(layer);

    // prime: request configure with an empty commit. The first real draw
    // happens in the Configure handler (see draw(): no buffers pre-config).
    draw(&mut st);

    // calloop: wayland socket source wakes us for configure/pointer/seat
    // events, timer source drives the 1s MPRIS poll. No sleep-polling.
    let mut ev: calloop::EventLoop<State> =
        calloop::EventLoop::try_new().expect("event loop");
    calloop_wayland_source::WaylandSource::new(conn, event_queue)
        .insert(ev.handle())
        .expect("wayland source");
    ev.handle()
        .insert_source(calloop::timer::Timer::immediate(), |_, _, st: &mut State| {
            if poll_media(st) {
                draw(st);
            }
            calloop::timer::TimeoutAction::ToDuration(Duration::from_secs(1))
        })
        .expect("timer source");
    ev.run(None, &mut st, |_| {}).expect("event loop run");
}
