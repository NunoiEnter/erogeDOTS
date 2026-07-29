// erogeDOTS — Zen browser performance & font config
// Copy to ~/.config/zen/<profile>/user.js after first launch

// ── GPU Acceleration (Wayland + AMD) ─────────────────────────
user_pref("gfx.webrender.all", true);
user_pref("gfx.webrender.enabled", true);
user_pref("gfx.webrender.compositor.force-enabled", true);
user_pref("layers.acceleration.force-enabled", true);
user_pref("media.hardware-video-decoding.force-enabled", true);
user_pref("widget.wayland-dmabuf-vaapi.enabled", true);

// ── Fonts ────────────────────────────────────────────────────
user_pref("font.name.sans-serif.x-western", "Kanit");
user_pref("font.name.serif.x-western", "Kanit");
user_pref("font.name.monospace.x-western", "JetBrains Mono");
user_pref("font.size.variable.x-western", 16);
user_pref("font.size.fixed.x-western", 14);

// Disable about:config warning
user_pref("browser.aboutConfig.showWarning", false);
