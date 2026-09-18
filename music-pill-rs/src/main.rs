//! erogeDOTS music-pill-rs — hover/hotkey square media widget.
//!
//! Native Rust layer-shell widget, no GTK, no Python. Hidden by default;
//! a small art tab sits top-right. Hovering (or clicking) the tab, or the
//! `Mod+Shift+M` hotkey (`music-pill toggle`), opens a square card: big
//! album art, title, artist/synced-lyric line, progress bar, prev/play/next.
//! Moving off the card closes it (unless pinned open with toggle).
//! Left = play/pause, right = next, middle = previous, scroll = volume.
//! Auto-hides entirely when nothing is playing.

use std::collections::hash_map::DefaultHasher;
use std::hash::{Hash, Hasher};
use std::io::{Read, Write};
use std::os::unix::io::AsFd;
use std::os::unix::net::{UnixListener, UnixStream};
use std::path::PathBuf;
use std::process::Command;
use std::time::{Duration, Instant};

use calloop::generic::Generic;
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
        wl_display, wl_pointer, wl_registry, wl_seat, wl_shm,
    },
};
use wayland_protocols_wlr::layer_shell::v1::client::{
    zwlr_layer_shell_v1::{self, ZwlrLayerShellV1},
    zwlr_layer_surface_v1::{self, ZwlrLayerSurfaceV1},
};

// ── Look ────────────────────────────────────────────────────────────────

const COLLAPSED_H: u32 = 64;
const EXPANDED_H: u32 = 440;
const CARD_W: i32 = 360;
const BG: (u8, u8, u8, u8) = (32, 22, 22, 217); // rgba(22,22,32,0.85)
const SUB_C: (u8, u8, u8) = (0xb4, 0x8e, 0xad);
const BRIGHT: (u8, u8, u8) = (0xf5, 0xee, 0xf5);
const DIM: (u8, u8, u8) = (0x7a, 0x7a, 0x9a);
const ACCENT: (u8, u8, u8) = (0xc8, 0xa0, 0xe8);

// ── Small helpers ──

// ── Small helpers ───────────────────────────────────────────────────────

fn run(cmd: &str, args: &[&str]) -> String {
    Command::new(cmd)
        .args(args)
        .output()
        .map(|o| String::from_utf8_lossy(&o.stdout).trim().to_string())
        .unwrap_or_default()
}

fn runtime_dir() -> PathBuf {
    std::env::var("XDG_RUNTIME_DIR").map(PathBuf::from).unwrap_or_else(|_| PathBuf::from("/tmp"))
}

fn cache_dir() -> PathBuf {
    let d = std::env::var("HOME")
        .map(|h| PathBuf::from(h).join(".cache").join("eroge-music-pill"))
        .unwrap_or_else(|_| PathBuf::from("/tmp/eroge-music-pill"));
    std::fs::create_dir_all(&d).ok();
    d
}

fn sock_path() -> PathBuf {
    runtime_dir().join("eroge-music-pill.sock")
}

fn fmt_time(sec: f64) -> String {
    let s = sec.max(0.0) as i64;
    format!("{}:{:02}", s / 60, s % 60)
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
    // Fields queried one by one: NUL bytes are illegal in execve argv, so a
    // single -f template with NUL separators can never work.
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
    if let Some(path) = url.strip_prefix("file://") {
        let path: String = url::percent_decode(path);
        return image::open(&path).ok().map(|i| {
            i.resize_exact(320, 320, image::imageops::FilterType::Triangle).to_rgba8()
        });
    }
    if url.starts_with("http://") || url.starts_with("https://") {
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
        return image::load_from_memory_with_format(&bytes, fmt)
            .ok()
            .map(|i| i.resize_exact(320, 320, image::imageops::FilterType::Triangle).to_rgba8());
    }
    None
}

mod url {
    //! Tiny percent-decoder so file:// art paths with spaces/UTF-8 resolve.
    pub fn percent_decode(s: &str) -> String {
        let mut out = Vec::with_capacity(s.len());
        let b = s.as_bytes();
        let mut i = 0;
        while i < b.len() {
            if b[i] == b'%' && i + 2 < b.len() {
                if let (Some(h), Some(l)) = (hex(b[i + 1]), hex(b[i + 2])) {
                    out.push(h << 4 | l);
                    i += 3;
                    continue;
                }
            }
            out.push(b[i]);
            i += 1;
        }
        String::from_utf8_lossy(&out).into_owned()
    }
    fn hex(c: u8) -> Option<u8> {
        match c {
            b'0'..=b'9' => Some(c - b'0'),
            b'a'..=b'f' => Some(c - b'a' + 10),
            b'A'..=b'F' => Some(c - b'A' + 10),
            _ => None,
        }
    }
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
    /// Blend one color channel with its own coverage (SubpixelMask glyphs
    /// carry R,G,B coverage triplets per pixel).
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
    fn rounded_inside(xx: i32, yy: i32, x: i32, y: i32, w: i32, h: i32, rad: i32) -> bool {
        // inside iff within rad of the shrunk inner rect
        let nx = xx.clamp(x + rad, x + w - 1 - rad);
        let ny = yy.clamp(y + rad, y + h - 1 - rad);
        let (dx, dy) = (xx - nx, yy - ny);
        dx * dx + dy * dy <= rad * rad
    }
    fn rounded(&mut self, x: i32, y: i32, w: i32, h: i32, rad: i32, c: (u8, u8, u8, u8)) {
        for yy in y..y + h {
            for xx in x..x + w {
                if !Self::rounded_inside(xx, yy, x, y, w, h, rad) {
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
    fn ring(&mut self, cx: i32, cy: i32, rad: i32, th: i32, c: (u8, u8, u8)) {
        for yy in cy - rad - th..=cy + rad + th {
            for xx in cx - rad - th..=cx + rad + th {
                let d2 = (xx - cx) * (xx - cx) + (yy - cy) * (yy - cy);
                if d2 <= (rad + th) * (rad + th) && d2 >= (rad - th) * (rad - th) {
                    self.blend(xx, yy, c.0, c.1, c.2, 255);
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
    fn blit_rounded(&mut self, img: &image::RgbaImage, dx: i32, dy: i32, dw: i32, dh: i32, rad: i32) {
        let (iw, ih) = (img.width() as i32, img.height() as i32);
        for yy in dy..dy + dh {
            for xx in dx..dx + dw {
                if !Self::rounded_inside(xx, yy, dx, dy, dw, dh, rad) {
                    continue;
                }
                let sx = ((xx - dx) as f32 / dw as f32 * iw as f32) as u32;
                let sy = ((yy - dy) as f32 / dh as f32 * ih as f32) as u32;
                let p = img.get_pixel(sx.min(iw as u32 - 1), sy.min(ih as u32 - 1));
                self.blend(xx, yy, p[0], p[1], p[2], p[3]);
            }
        }
    }
    fn vscrim(&mut self, x: i32, y: i32, w: i32, h: i32, max_a: u8) {
        for row in 0..h {
            let a = (max_a as f32 * row as f32 / h as f32) as u8;
            self.rect(x, y + row, w, 1, 0, 0, 0, a);
        }
    }
    fn line(&mut self, x0: i32, y0: i32, x1: i32, y1: i32, c: (u8, u8, u8)) {
        let steps = (x1 - x0).abs().max((y1 - y0).abs()).max(1);
        for i in 0..=steps {
            let x = x0 + (x1 - x0) * i / steps;
            let y = y0 + (y1 - y0) * i / steps;
            self.disc(x, y, 1, (c.0, c.1, c.2, 255));
        }
    }
    fn tri(&mut self, cx: i32, cy: i32, s: i32, dir: i32, c: (u8, u8, u8)) {
        // dir > 0 points right, dir < 0 points left
        for yy in -s..=s {
            let a = yy.abs();
            let (x0, x1) = if dir > 0 { (cx - s + 2 * a, cx + s) } else { (cx - s, cx + s - 2 * a) };
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
    pos: f64,
    len: f64,
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
    cur_h: u32,
    pointer_x: f64,
    pointer_y: f64,
    in_widget: bool,
    open: bool,
    pinned: bool,
    close_at: Option<Instant>,
    exit: bool,
    media: Media,
    font_system: Option<FontSystem>,
    swash: Option<SwashCache>,
}

impl State {
    fn target_h(&self) -> u32 {
        if self.open { EXPANDED_H } else { COLLAPSED_H }
    }
    fn tab_rect(&self) -> (i32, i32, i32, i32) {
        let w = self.width as i32;
        (w - 64, 4, w - 8, 60)
    }
    fn card_rect(&self) -> (i32, i32, i32, i32) {
        let w = self.width as i32;
        (w - 16 - CARD_W, 8, w - 16, 432)
    }
    /// Card button zones: returns "prev" | "play" | "next" | "close" | "".
    fn card_hit(&self, x: i32, y: i32) -> &'static str {
        let (x0, y0, x1, y1) = self.card_rect();
        if x < x0 || x >= x1 || y < y0 || y >= y1 {
            return "";
        }
        // X button, top-right of card
        if x >= x1 - 40 && y < y0 + 40 {
            return "close";
        }
        let cx = x0 + CARD_W / 2;
        let cy = y0 + 388;
        if y >= cy - 22 && y < cy + 22 {
            if x >= cx - 72 && x < cx - 32 {
                return "prev";
            }
            if x >= cx - 20 && x < cx + 20 {
                return "play";
            }
            if x >= cx + 32 && x < cx + 72 {
                return "next";
            }
        }
        ""
    }
}

delegate_noop!(State: ignore WlCompositor);
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
delegate_noop!(State: ignore WlSurface);
delegate_noop!(State: ignore WlBuffer);
delegate_noop!(State: ignore WlShmPool);
delegate_noop!(State: ignore WlShm);
delegate_noop!(State: ignore WlOutput);
delegate_noop!(State: ignore WlRegion);
delegate_noop!(State: ignore WlCallback);
delegate_noop!(State: ignore ZwlrLayerShellV1);

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
                st.in_widget = true;
                st.close_at = None;
                if !st.open && st.media.visible {
                    let (x0, y0, x1, y1) = st.tab_rect();
                    let (x, y) = (surface_x as i32, surface_y as i32);
                    if x >= x0 && x < x1 && y >= y0 && y < y1 {
                        set_open(st, true);
                    }
                }
            }
            Motion { surface_x, surface_y, .. } => {
                st.pointer_x = surface_x;
                st.pointer_y = surface_y;
            }
            Leave { .. } => {
                st.in_widget = false;
                if st.open && !st.pinned {
                    st.close_at = Some(Instant::now() + Duration::from_millis(800));
                }
            }
            Button { button, state: WEnum::Value(ButtonState::Pressed), .. } => {
                let (x, y) = (st.pointer_x as i32, st.pointer_y as i32);
                if !st.open {
                    let (x0, y0, x1, y1) = st.tab_rect();
                    if x >= x0 && x < x1 && y >= y0 && y < y1 {
                        toggle(st);
                    }
                    return;
                }
                match button {
                    0x110 => match st.card_hit(x, y) {
                        "close" => set_open_pinned(st, false),
                        "prev" => {
                            run("playerctl", &["previous"]);
                        }
                        "next" => {
                            run("playerctl", &["next"]);
                        }
                        _ => {
                            run("playerctl", &["play-pause"]);
                        }
                    },
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

// ── Open / close / toggle ───────────────────────────────────────────────

fn apply_size(st: &mut State) {
    let h = st.target_h();
    if h == st.cur_h {
        draw(st);
        return;
    }
    st.cur_h = h;
    if let (Some(layer), Some(surface)) = (st.layer.as_ref(), st.surface.as_ref()) {
        layer.set_size(0, h);
        layer.set_exclusive_zone(if st.media.visible { h as i32 } else { 0 });
        surface.commit();
    }
    draw(st);
}

/// Open or close the card (hover-driven: unpinned).
fn set_open(st: &mut State, open: bool) {
    if st.open == open {
        return;
    }
    st.open = open;
    apply_size(st);
}

/// Toggle from hotkey/click/X: pin follows the new state.
fn toggle(st: &mut State) {
    st.pinned = !st.open;
    set_open(st, !st.open);
}

fn set_open_pinned(st: &mut State, open: bool) {
    st.pinned = open;
    set_open(st, open);
}

// ── Fonts ───────────────────────────────────────────────────────────────

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
    // Never attach a buffer before the first configure: committing buffers
    // pre-configure trips a Smithay/niri client error and kills us.
    if !st.configured {
        return;
    }
    let w = st.width.max(320);
    let h = st.cur_h.max(COLLAPSED_H);
    let open = st.open;
    let tab = st.tab_rect();
    let card = st.card_rect();
    let (Some(surface), Some(layer), Some(shm), Some(fs), Some(swash)) = (
        st.surface.as_ref(),
        st.layer.as_ref(),
        st.shm.as_ref(),
        st.font_system.as_mut(),
        st.swash.as_mut(),
    ) else {
        return;
    };
    let m = &st.media;

    let mut cv = Canvas::new(w, h);
    if m.visible {
        if open {
            draw_card(&mut cv, card, m, fs, swash);
        } else {
            // trigger tab, top-right
            let (x0, y0, _x1, _y1) = tab;
            cv.rounded(x0, y0, 56, 56, 16, BG);
            cv.ring(x0 + 28, y0 + 28, 23, 2, ACCENT);
            match &m.art {
                Some(img) => cv.blit_circle(img, x0 + 28, y0 + 28, 20),
                None => {
                    cv.disc(x0 + 28, y0 + 28, 20, (ACCENT.0, ACCENT.1, ACCENT.2, 90));
                    draw_text(&mut cv, fs, swash, "♪", x0 + 19, y0 + 14, 20, 20.0, false, BRIGHT);
                }
            }
            if m.playing {
                cv.tri(x0 + 28, y0 + 28, 8, 1, BRIGHT);
            }
        }
    }

    // ship pixels through SHM (O_RDWR: the compositor mmaps PROT_READ|WRITE)
    let stride = w * 4;
    let path = format!("{}/pill-{}-{}.buf", runtime_dir().display(), std::process::id(), w);
    let mut f = std::fs::OpenOptions::new()
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
            if st.open {
                let (x0, y0, x1, y1) = st.card_rect();
                reg.add(x0, y0, x1 - x0, y1 - y0);
            } else {
                let (x0, y0, x1, y1) = st.tab_rect();
                reg.add(x0, y0, x1 - x0, y1 - y0);
            }
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

fn draw_card(cv: &mut Canvas, card: (i32, i32, i32, i32), m: &Media, fs: &mut FontSystem, swash: &mut SwashCache) {
    let (x0, y0, _x1, _y1) = card;
    cv.rounded(x0, y0, CARD_W, 424, 24, BG);
    cv.ring(x0 + CARD_W - 24, y0 + 24, 11, 0, ACCENT); // X button halo base
    // X glyph
    let (xc, yc) = (x0 + CARD_W - 24, y0 + 24);
    cv.line(xc - 6, yc - 6, xc + 6, yc + 6, DIM);
    cv.line(xc + 6, yc - 6, xc - 6, yc + 6, DIM);

    // art square with scrim
    let (ax, ay, asz) = (x0 + 16, y0 + 16, 328);
    match &m.art {
        Some(img) => {
            cv.blit_rounded(img, ax, ay, asz, asz, 20);
            cv.vscrim(ax, ay + asz - 150, asz, 150, 200);
            // title + sub over the scrim
            draw_text(cv, fs, swash, &m.title, ax + 12, ay + asz - 66, (asz - 24) as u32, 20.0, true, BRIGHT);
            draw_text(cv, fs, swash, &m.lyric_line, ax + 12, ay + asz - 38, (asz - 24) as u32, 14.0, false, SUB_C);
        }
        None => {
            cv.rounded(ax, ay, asz, asz, 20, (ACCENT.0, ACCENT.1, ACCENT.2, 45));
            cv.disc(ax + asz / 2, ay + asz / 2 - 20, 44, (ACCENT.0, ACCENT.1, ACCENT.2, 120));
            draw_text(cv, fs, swash, &m.title, ax + 12, ay + asz - 66, (asz - 24) as u32, 20.0, true, BRIGHT);
            draw_text(cv, fs, swash, &m.lyric_line, ax + 12, ay + asz - 38, (asz - 24) as u32, 14.0, false, SUB_C);
        }
    }

    // progress
    let pos = m.pos.min(m.len);
    let frac = if m.len > 0.0 { (pos / m.len).clamp(0.0, 1.0) } else { 0.0 };
    let (px, py, pw) = (ax, ay + asz + 14, asz);
    cv.rounded(px, py, pw, 5, 2, (DIM.0, DIM.1, DIM.2, 90));
    cv.rounded(px, py, (pw as f64 * frac) as i32, 5, 2, (ACCENT.0, ACCENT.1, ACCENT.2, 255));
    draw_text(cv, fs, swash, &fmt_time(pos), px, py + 8, 60, 11.0, false, DIM);
    let total = fmt_time(m.len);
    draw_text(cv, fs, swash, &total, px + pw - 60, py + 8, 60, 11.0, false, DIM);

    // controls
    let cx = x0 + CARD_W / 2;
    let cy = y0 + 388;
    cv.tri(cx - 52, cy, 9, -1, ACCENT);
    cv.rect(cx - 66, cy - 8, 3, 16, ACCENT.0, ACCENT.1, ACCENT.2, 255);
    if m.playing {
        cv.rect(cx - 8, cy - 9, 5, 18, ACCENT.0, ACCENT.1, ACCENT.2, 255);
        cv.rect(cx + 3, cy - 9, 5, 18, ACCENT.0, ACCENT.1, ACCENT.2, 255);
    } else {
        cv.tri(cx + 2, cy, 11, 1, ACCENT);
    }
    cv.tri(cx + 52, cy, 9, 1, ACCENT);
    cv.rect(cx + 63, cy - 8, 3, 16, ACCENT.0, ACCENT.1, ACCENT.2, 255);
}

// QueueHandle plumbing for draw() (which only has &mut State).
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
    let pos = position();
    let m = &mut st.media;
    let mut dirty = m.playing != playing || m.visible != visible;

    if t.id != m.track_id {
        m.track_id = t.id.clone();
        m.title = t.title.clone();
        m.artist = t.artist.clone();
        m.art_url = t.art_url.clone();
        m.art = load_art(&t.art_url);
        m.lyrics = fetch_lyrics(&t);
        m.lyric_line.clear();
        dirty = true;
    }
    m.playing = playing;
    if m.visible != visible {
        m.visible = visible;
        if !visible {
            st.open = false;
            st.pinned = false;
            st.close_at = None;
            apply_size(st);
            return true;
        }
        dirty = true;
    }
    m.pos = pos;
    m.len = t.length;

    if visible {
        let line = if m.lyrics.is_empty() {
            if m.artist.is_empty() { String::new() } else { m.artist.clone() }
        } else {
            let l = lyric_at(&m.lyrics, pos);
            if l.is_empty() { "♪ ♫ ♪".into() } else { l }
        };
        if line != m.lyric_line {
            m.lyric_line = line;
            dirty = true;
        }
        // progress bar moves while open and playing
        if st.open && playing {
            dirty = true;
        }
    }
    dirty
}

// ── Socket IPC (toggle / show / hide from hotkey) ───────────────────────

fn handle_cmd(st: &mut State, cmd: &str) {
    match cmd {
        "toggle" => toggle(st),
        "show" => set_open_pinned(st, true),
        "hide" => set_open_pinned(st, false),
        "next" => {
            run("playerctl", &["next"]);
        }
        "prev" => {
            run("playerctl", &["previous"]);
        }
        "play-pause" => {
            run("playerctl", &["play-pause"]);
        }
        _ => {}
    }
}

fn send_cmd(cmd: &str) -> bool {
    let Ok(mut s) = UnixStream::connect(sock_path()) else { return false };
    s.write_all(cmd.as_bytes()).is_ok()
}

// ── Main ────────────────────────────────────────────────────────────────

fn main() {
    // CLI mode: forward to the running instance, or start opened if none.
    let arg = std::env::args().nth(1).unwrap_or_default();
    let want_open = matches!(arg.as_str(), "toggle" | "show");
    if matches!(arg.as_str(), "toggle" | "show" | "hide" | "next" | "prev" | "play-pause") {
        if send_cmd(&arg) {
            return;
        }
    } else if !arg.is_empty() {
        eprintln!("usage: music-pill [toggle|show|hide|next|prev|play-pause]");
        std::process::exit(2);
    }

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
        cur_h: COLLAPSED_H,
        pointer_x: 0.0,
        pointer_y: 0.0,
        in_widget: false,
        open: false,
        pinned: false,
        close_at: None,
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
            pos: 0.0,
            len: 0.0,
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
    layer.set_size(0, COLLAPSED_H);
    layer.set_anchor(
        zwlr_layer_surface_v1::Anchor::Top
            | zwlr_layer_surface_v1::Anchor::Left
            | zwlr_layer_surface_v1::Anchor::Right,
    );
    layer.set_margin(8, 0, 0, 0);
    surface.commit();
    st.surface = Some(surface);
    st.layer = Some(layer);

    if want_open {
        st.pinned = true;
        st.open = true;
    }
    apply_size(&mut st);

    // command socket: hotkey / clicks from other processes
    let sock = sock_path();
    std::fs::remove_file(&sock).ok();
    let listener = UnixListener::bind(&sock).expect("bind command socket");
    listener.set_nonblocking(true).expect("nonblocking socket");

    // calloop: wayland socket wakes us for configure/pointer/seat,
    // timers drive the MPRIS poll and the hover-close delay.
    let mut ev: calloop::EventLoop<State> =
        calloop::EventLoop::try_new().expect("event loop");
    calloop_wayland_source::WaylandSource::new(conn, event_queue)
        .insert(ev.handle())
        .expect("wayland source");
    let sock_src = Generic::new(listener, calloop::Interest::READ, calloop::Mode::Level);
    ev.handle()
        .insert_source(sock_src, |_, file: &mut calloop::generic::NoIoDrop<UnixListener>, st: &mut State| {
            while let Ok((mut s, _)) = file.as_ref().accept() {
                let mut cmd = String::new();
                if s.read_to_string(&mut cmd).is_ok() {
                    handle_cmd(st, cmd.trim());
                }
            }
            Ok(calloop::PostAction::Continue)
        })
        .expect("socket source");
    ev.handle()
        .insert_source(calloop::timer::Timer::immediate(), |_, _, st: &mut State| {
            if poll_media(st) {
                draw(st);
            }
            calloop::timer::TimeoutAction::ToDuration(Duration::from_secs(1))
        })
        .expect("timer source");
    ev.handle()
        .insert_source(calloop::timer::Timer::immediate(), |_, _, st: &mut State| {
            if st.exit {
                std::process::exit(0);
            }
            if let Some(t) = st.close_at {
                if Instant::now() >= t && !st.in_widget && !st.pinned {
                    st.close_at = None;
                    set_open(st, false);
                } else if st.in_widget || st.pinned {
                    st.close_at = None;
                }
            }
            calloop::timer::TimeoutAction::ToDuration(Duration::from_millis(150))
        })
        .expect("hover timer source");
    let _ = ev.run(None, &mut st, |_| {});
    std::fs::remove_file(&sock).ok();
}
