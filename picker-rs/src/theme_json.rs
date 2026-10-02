//! Shares the existing Rust creator with the graphical theme studio.
use super::*;
use serde_json::{json, Value};
use std::io::{BufRead, Read};
fn text<'a>(q: &'a Value, key: &str) -> io::Result<&'a str> {
    let value = q[key]
        .as_str()
        .ok_or_else(|| io::Error::other(format!("Missing {key}.")))?;
    if value.len() > 500 || value.contains(['\n', '\r', '\0']) {
        return Err(io::Error::other(
            "Keep each character field on one line, up to 500 characters.",
        ));
    }
    Ok(value)
}
fn dispatch(q: &Value) -> io::Result<Value> {
    match q["operation"].as_str() {
        Some("catalog") => Ok(
            json!({"palettes": PALETTES.iter().map(|p|json!({"name":p.name,"accent":p.primary,"background":p.bg,"text":p.fg})).collect::<Vec<_>>(),"roles":COLOR_ROLES.iter().map(|(key,label)|json!({"key":key,"label":label})).collect::<Vec<_>>(),"colors":PALETTES.iter().map(|p|colors_from_palette(*p)).collect::<Vec<_>>() }),
        ),
        Some("create") => {
            let slug = text(q, "id")?;
            if !valid_slug(slug) {
                return Err(io::Error::other(
                    "Use a lowercase theme ID with letters, numbers and hyphens.",
                ));
            }
            let name = text(q, "name")?;
            if name.trim().is_empty() {
                return Err(io::Error::other("Enter a character name."));
            }
            let image = PathBuf::from(text(q, "wallpaper")?);
            let image = if let Some(s) = image.to_str().and_then(|s| s.strip_prefix("~/")) {
                dirs::home_dir().unwrap_or_default().join(s)
            } else {
                image
            };
            if !image.is_absolute() {
                return Err(io::Error::other(
                    "Choose a full wallpaper path, or a path starting with ~/.",
                ));
            }
            let ext = image
                .extension()
                .and_then(|s| s.to_str())
                .unwrap_or("")
                .to_lowercase();
            if !["png", "jpg", "jpeg", "webp"].contains(&ext.as_str()) {
                return Err(io::Error::other("Choose a PNG, JPEG or WebP wallpaper."));
            }
            // Decode before writing anything. Bad files never produce a partial theme.
            let mut reader = image::ImageReader::open(&image)?.with_guessed_format()?;
            let mut limits = image::Limits::default();
            limits.max_alloc = Some(256 * 1024 * 1024);
            reader.limits(limits);
            reader.decode().map_err(|_| {
                io::Error::other("This wallpaper could not be decoded. Choose another image.")
            })?;
            let palette = q["palette"]
                .as_u64()
                .filter(|i| (*i as usize) < PALETTES.len())
                .ok_or_else(|| io::Error::other("Choose a color palette."))?
                as usize;
            let mut colors = colors_from_palette(PALETTES[palette]);
            if let Some(overrides) = q["colors"].as_array() {
                if overrides.len() != colors.len() {
                    return Err(io::Error::other("The color palette is incomplete."));
                }
                for (i, v) in overrides.iter().enumerate() {
                    let value = v.as_str().unwrap_or("");
                    let valid = value.starts_with('#')
                        && (value.len() == 7
                            || (COLOR_ROLES[i].0 == "niri_shadow" && value.len() == 9))
                        && value[1..].bytes().all(|b| b.is_ascii_hexdigit());
                    if !valid {
                        return Err(io::Error::other(format!(
                            "Enter a hex color for {}.",
                            COLOR_ROLES[i].1
                        )));
                    }
                    colors[i] = value.into();
                }
            }
            let new = NewTheme {
                slug: slug.into(),
                char_name: q["displayName"].as_str().unwrap_or(name).into(),
                char_full: name.into(),
                game: text(q, "game")?.into(),
                quote: String::new(),
                image,
                palette,
                colors,
            };
            create_theme(&new)?;
            Ok(
                json!({"id":slug,"message":"Theme created. Choose Apply theme to use your new character."}),
            )
        }
        _ => Err(io::Error::other("Unknown theme studio action.")),
    }
}
pub fn run() -> io::Result<()> {
    let mut line = String::new();
    io::stdin().lock().take(20000).read_line(&mut line)?;
    let result = serde_json::from_str::<Value>(&line)
        .map_err(io::Error::other)
        .and_then(|q| dispatch(&q));
    match result {
        Ok(mut value) => {
            value["ok"] = json!(true);
            println!("{value}");
        }
        Err(e) => println!("{}", json!({"ok":false,"error":e.to_string()})),
    }
    Ok(())
}
#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn catalog_and_invalid_input() {
        assert_eq!(
            dispatch(&json!({"operation":"catalog"})).unwrap()["colors"]
                .as_array()
                .unwrap()
                .len(),
            6
        );
        assert!(dispatch(&json!({"operation":"create","id":"../escape"})).is_err());
        assert!(dispatch(
            &json!({"operation":"create","id":"safe","name":"Name","wallpaper":"relative.jpg"})
        )
        .is_err());
    }
}
