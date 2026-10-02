//! JSON boundary for the desktop workshop. No persistent service or interpreter.
use fs2::FileExt;
use regex::Regex;
use serde_json::{json, Value};
use sha2::{Digest, Sha256};
use std::{
    env, fs,
    io::{self, BufRead, Read, Write},
    path::{Path, PathBuf},
    process::{Command, Stdio},
    time::{Duration, Instant, SystemTime, UNIX_EPOCH},
};
use tempfile::{NamedTempFile, TempDir};

type Result<T> = std::result::Result<T, Box<dyn std::error::Error>>;
fn fail<T>(s: &str) -> Result<T> {
    Err(s.into())
}
fn home() -> PathBuf {
    PathBuf::from(env::var_os("HOME").unwrap_or_default())
}
fn directory(key: &str, fallback: PathBuf) -> PathBuf {
    env::var_os(key).map(PathBuf::from).unwrap_or(fallback)
}
struct Config {
    root: PathBuf,
    config: PathBuf,
    state: PathBuf,
}
impl Config {
    fn new() -> Result<Self> {
        Ok(Self {
            root: directory("EROGEDOTS_ROOT", home().join("erogeDOTS")).canonicalize()?,
            config: directory("XDG_CONFIG_HOME", home().join(".config")),
            state: directory("XDG_STATE_HOME", home().join(".local/state")).join("erogedots"),
        })
    }
    fn target(&self, name: &str) -> Result<PathBuf> {
        let path = self.root.join(match name {
            "nixos" => "configuration.nix",
            "home" => "home/moni.nix",
            "niri" => "themes/templates/niri/config.kdl",
            "packages" => "home/desktop-packages.json",
            _ => return fail("Choose NixOS, Home Manager or Niri."),
        });
        if path.is_symlink() || !path.canonicalize()?.starts_with(&self.root) {
            return fail("The editor cannot replace a file outside this repository.");
        }
        Ok(path)
    }
    fn write(&self, path: &Path, text: &str) -> Result<()> {
        if path.is_symlink() || !path.canonicalize()?.starts_with(&self.root) {
            return fail("Cannot replace a file outside the repository.");
        }
        let backups = self.state.join("config-backups");
        fs::create_dir_all(&backups)?;
        let stamp = SystemTime::now().duration_since(UNIX_EPOCH)?.as_nanos();
        fs::copy(
            path,
            backups.join(format!(
                "{stamp}-{}",
                path.file_name().unwrap().to_string_lossy()
            )),
        )?;
        let mut temp = NamedTempFile::new_in(path.parent().unwrap())?;
        temp.as_file()
            .set_permissions(fs::metadata(path)?.permissions())?;
        temp.write_all(text.as_bytes())?;
        temp.as_file().sync_all()?;
        temp.persist(path)?;
        Ok(())
    }
    fn packages(&self) -> Result<Vec<String>> {
        let values: Vec<String> =
            serde_json::from_str(&fs::read_to_string(self.target("packages")?)?)?;
        if values.iter().any(|v| !attribute(v)) {
            return fail("The package list must contain Nix package names.");
        }
        Ok(values)
    }
    fn status(&self) -> Result<Value> {
        let host = hostname()?;
        Ok(
            json!({"packages": self.packages()?, "hostname": host, "hostAvailable": self.root.join("hosts").join(&host).join("hardware-configuration.nix").is_file(), "niri": niri_settings(&fs::read_to_string(self.target("niri")?)?).ok(), "revision": self.locked()?["rev"]}),
        )
    }
    fn locked(&self) -> Result<Value> {
        let lock: Value = serde_json::from_str(&fs::read_to_string(self.root.join("flake.lock"))?)?;
        Ok(lock["nodes"]["nixpkgs"]["locked"].clone())
    }
    fn url(&self) -> Result<String> {
        let p = self.locked()?;
        Ok(format!(
            "github:{}/{}/{}",
            field(&p, "owner")?,
            field(&p, "repo")?,
            field(&p, "rev")?
        ))
    }
    fn validate(&self, name: &str, text: &str) -> Result<()> {
        if text.len() > 512000 {
            return fail("This editor accepts files up to 500 KB.");
        }
        if name != "niri" {
            let mut file = tempfile::Builder::new().suffix(".nix").tempfile()?;
            file.write_all(text.as_bytes())?;
            run(Command::new("nix-instantiate")
                .arg("--parse")
                .arg(file.path()))?;
        } else {
            let dir = TempDir::new()?;
            let root = dir.path();
            fs::create_dir_all(root.join("themes/templates/niri"))?;
            fs::write(root.join("themes/templates/niri/config.kdl"), text)?;
            for entry in fs::read_dir(self.root.join("themes"))? {
                let entry = entry?;
                if entry.path().join("theme.conf").is_file() {
                    std::os::unix::fs::symlink(
                        entry.path(),
                        root.join("themes").join(entry.file_name()),
                    )?;
                }
            }
            let active =
                fs::read_to_string(self.config.join("theme/active")).unwrap_or("harumi".into());
            let style = fs::read_to_string(self.config.join("theme/style")).unwrap_or("vn".into());
            let appearance =
                fs::read_to_string(self.config.join("theme/appearance")).unwrap_or("light".into());
            run(Command::new(self.root.join("scripts/theme-switch"))
                .arg(active.trim())
                .env("EROGEDOTS_ROOT", root)
                .env("EROGEDOTS_CONFIG_HOME", root.join("config"))
                .env("EROGEDOTS_NO_RESTART", "1")
                .env("EROGEDOTS_STYLE", style.trim())
                .env("EROGEDOTS_APPEARANCE", appearance.trim()))?;
            run(Command::new("niri")
                .args(["validate", "--config"])
                .arg(root.join("config/niri/config.kdl")))?;
        }
        Ok(())
    }
    fn dispatch(&self, q: &Value) -> Result<Value> {
        match field(q, "operation")? {
            "status" => Ok(json!({"status":self.status()?})),
            "read" => {
                let name = field(q, "target")?;
                let path = self.target(name)?;
                let text = fs::read_to_string(&path)?;
                Ok(json!({"text":text,"version":digest(&text),"target":name,"path":path}))
            }
            "save" => {
                let name = field(q, "target")?;
                let path = self.target(name)?;
                let version = field(q, "version")?;
                let text = field(q, "text")?;
                if digest(&fs::read_to_string(&path)?) != version {
                    return fail("This file changed elsewhere. Reload it before saving.");
                }
                self.validate(name, text)?;
                if digest(&fs::read_to_string(&path)?) != version {
                    return fail("This file changed during validation. Reload it before saving.");
                }
                self.write(&path, text)?;
                Ok(
                    json!({"version":digest(text),"status":self.status()?,"message":"Saved and validated. Apply your changes when ready."}),
                )
            }
            "search" => self.search(field(q, "query")?),
            "add" | "remove" => {
                let name = field(q, "package")?;
                if !attribute(name) {
                    return fail("Use a package name such as ripgrep or kdePackages.kate.");
                }
                let mut values = self.packages()?;
                if q["operation"] == "add" {
                    let expression=format!("let p = import (builtins.getFlake {}).outPath {{ system = builtins.currentSystem; config.allowUnfree = true; }}; in if (p.{name}.type or \"\") == \"derivation\" then (p.{name}.pname or p.{name}.name) else throw \"Choose an installable package\"",serde_json::to_string(&self.url()?)?);
                    run(Command::new("nix").args([
                        "eval",
                        "--raw",
                        "--impure",
                        "--expr",
                        &expression,
                    ]))?;
                    values.push(name.into());
                    values.sort();
                    values.dedup();
                } else {
                    values.retain(|v| v != name);
                }
                self.write(
                    &self.target("packages")?,
                    &(serde_json::to_string_pretty(&values)? + "\n"),
                )?;
                Ok(
                    json!({"status":self.status()?,"message":"Package list saved. Apply NixOS to install or remove these packages."}),
                )
            }
            "niri-settings" => {
                let path = self.target("niri")?;
                let original = fs::read_to_string(&path)?;
                niri_settings(&original)?;
                let mut text = original.clone();
                for (key, lo, hi, pattern) in [
                    ("gaps", 0, 64, r"(\bgaps\s+)\d+"),
                    ("focusWidth", 0, 12, r"(focus-ring\s*\{\s*width\s+)\d+"),
                    (
                        "columnWidth",
                        20,
                        100,
                        r"(default-column-width\s*\{\s*proportion\s+)[\d.]+",
                    ),
                ] {
                    let value = q[key]
                        .as_i64()
                        .ok_or("Enter a whole number for the layout.")?;
                    if !(lo..=hi).contains(&value) {
                        return fail("Layout value is outside its allowed range.");
                    }
                    let replacement = if key == "columnWidth" {
                        (value as f64 / 100.0).to_string()
                    } else {
                        value.to_string()
                    };
                    text = Regex::new(pattern)?
                        .replacen(&text, 1, |c: &regex::Captures| {
                            format!("{}{replacement}", &c[1])
                        })
                        .into_owned();
                }
                self.validate("niri", &text)?;
                if fs::read_to_string(&path)? != original {
                    return fail("The Niri file changed during validation. Reload before saving.");
                }
                self.write(&path, &text)?;
                Ok(
                    json!({"status":self.status()?,"message":"Layout saved and validated. Apply Niri to use it."}),
                )
            }
            _ => fail("Unknown desktop configuration action."),
        }
    }
    fn search(&self, query: &str) -> Result<Value> {
        let query = query.trim();
        if query.len() < 2 || query.len() > 80 {
            return fail("Search with 2–80 characters, such as Firefox or video player.");
        }
        let rev = field(&self.locked()?, "rev")?.to_owned();
        let cache = directory("XDG_CACHE_HOME", home().join(".cache"))
            .join("erogedots/packages")
            .join(&rev);
        fs::create_dir_all(&cache)?;
        let path = cache.join(format!("{}.json", digest(query)));
        let data = if path.is_file() {
            fs::read_to_string(&path)?
        } else {
            let terms: Vec<String> = query.split_whitespace().map(regex::escape).collect();
            let output = run(Command::new("nix")
                .args(["search", "--json", "--no-write-lock-file"])
                .arg(self.url()?)
                .args(terms))?;
            let _: Value = serde_json::from_str(&output)?;
            let mut temp = NamedTempFile::new_in(&cache)?;
            temp.write_all(output.as_bytes())?;
            temp.persist(&path)?;
            output
        };
        let raw: Value = serde_json::from_str(&data)?;
        let mut results = Vec::new();
        for (key, value) in raw
            .as_object()
            .ok_or("Nix returned an invalid package list.")?
        {
            let name = key.splitn(3, '.').nth(2).unwrap_or(key);
            if !attribute(name) {
                continue;
            }
            let pname = value["pname"].as_str().unwrap_or(name);
            results.push(json!({"attribute":name,"name":pname,"version":value["version"],"description":value["description"],"icon":local_icon(pname,name)}));
        }
        results.sort_by_key(|v| {
            (
                v["attribute"].as_str() != Some(query),
                v["attribute"].as_str().unwrap_or("").to_owned(),
            )
        });
        let total = results.len();
        results.truncate(60);
        Ok(
            json!({"results":results,"total":total,"revision":rev,"message":if total==0 {"No packages matched. Try a shorter app name."} else {""}}),
        )
    }
    fn terminal(&self, action: &str) -> Result<i32> {
        if action == "apply-niri" {
            use std::os::unix::process::CommandExt;
            let active = fs::read_to_string(self.config.join("theme/active"))?;
            return Err(Command::new(self.root.join("scripts/theme-switch"))
                .arg(active.trim())
                .args(["--show-menu", "workshop"])
                .exec()
                .into());
        }
        if action != "check" && action != "rebuild" {
            return fail("Unknown terminal action.");
        }
        let host = hostname()?;
        if !self
            .root
            .join("hosts")
            .join(&host)
            .join("hardware-configuration.nix")
            .is_file()
        {
            return fail("This computer has no matching host configuration in hosts/.");
        }
        let stage = TempDir::new()?;
        let paths = run(Command::new("git").arg("-C").arg(&self.root).args([
            "ls-files",
            "--cached",
            "--others",
            "--exclude-standard",
            "-z",
        ]))?;
        for name in paths.split('\0').filter(|s| !s.is_empty()) {
            let source = self.root.join(name);
            if !source.is_file() {
                continue;
            }
            let target = stage.path().join(name);
            fs::create_dir_all(target.parent().unwrap())?;
            fs::copy(source, target)?;
        }
        let path = format!("path:{}", stage.path().display());
        let status = if action == "check" {
            Command::new("nix")
                .args([
                    "flake",
                    "check",
                    &path,
                    "--no-build",
                    "--no-write-lock-file",
                ])
                .status()?
        } else {
            Command::new("sudo")
                .args([
                    "nixos-rebuild",
                    "switch",
                    "--flake",
                    &format!("{path}#{host}"),
                    "--no-write-lock-file",
                ])
                .status()?
        };
        Ok(status.code().unwrap_or(1))
    }
}
fn field<'a>(v: &'a Value, k: &str) -> Result<&'a str> {
    v[k].as_str().ok_or_else(|| format!("Missing {k}.").into())
}
fn attribute(s: &str) -> bool {
    Regex::new(r"^[A-Za-z_][A-Za-z0-9_-]*(?:\.[A-Za-z_][A-Za-z0-9_-]*)*$")
        .unwrap()
        .is_match(s)
}
fn digest(s: &str) -> String {
    format!("{:x}", Sha256::digest(s.as_bytes()))
}
fn hostname() -> Result<String> {
    Ok(run(&mut Command::new("hostname"))?.trim().to_owned())
}
fn niri_settings(text: &str) -> Result<Value> {
    let mut numbers = Vec::new();
    for pattern in [
        r"\bgaps\s+(\d+)",
        r"focus-ring\s*\{\s*width\s+(\d+)",
        r"default-column-width\s*\{\s*proportion\s+([\d.]+)",
    ] {
        let re = Regex::new(pattern)?;
        let c = re
            .captures(text)
            .ok_or("This custom Niri layout needs the source editor.")?;
        numbers.push(c[1].parse::<f64>()?);
    }
    Ok(json!({"gaps":numbers[0],"focusWidth":numbers[1],"columnWidth":(numbers[2]*100.0).round()}))
}
fn run(cmd: &mut Command) -> Result<String> {
    // Files avoid pipe backpressure on large Nix search output. Bound hung evaluations.
    let out = NamedTempFile::new()?;
    let err = NamedTempFile::new()?;
    let mut child = cmd
        .stdout(Stdio::from(out.reopen()?))
        .stderr(Stdio::from(err.reopen()?))
        .spawn()?;
    let start = Instant::now();
    loop {
        if let Some(status) = child.try_wait()? {
            let output = fs::read_to_string(out.path())?;
            if status.success() {
                return Ok(output);
            }
            let error = fs::read_to_string(err.path())?;
            let error = if error.trim().is_empty() {
                output
            } else {
                error
            };
            return Err(error
                .chars()
                .rev()
                .take(2000)
                .collect::<String>()
                .chars()
                .rev()
                .collect::<String>()
                .into());
        }
        if start.elapsed() > Duration::from_secs(180) {
            child.kill()?;
            child.wait()?;
            return fail(
                "The command timed out. Try again; Nix downloads already completed are cached.",
            );
        }
        std::thread::sleep(Duration::from_millis(50));
    }
}
fn local_icon(pname: &str, attribute: &str) -> String {
    let dirs = [
        home().join(".local/share/applications"),
        home().join(".nix-profile/share/applications"),
        PathBuf::from(format!(
            "/etc/profiles/per-user/{}/share/applications",
            env::var("USER").unwrap_or_default()
        )),
        PathBuf::from("/run/current-system/sw/share/applications"),
    ];
    let leaf = attribute
        .rsplit('.')
        .next()
        .unwrap_or(attribute)
        .to_lowercase();
    for dir in dirs {
        if let Ok(entries) = fs::read_dir(dir) {
            for entry in entries.flatten() {
                let stem = entry
                    .path()
                    .file_stem()
                    .unwrap_or_default()
                    .to_string_lossy()
                    .to_lowercase();
                if stem != pname.to_lowercase()
                    && stem != leaf
                    && !stem.ends_with(&format!(".{leaf}"))
                {
                    continue;
                }
                if let Ok(text) = fs::read_to_string(entry.path()) {
                    let mut main = false;
                    for line in text.lines() {
                        if line.starts_with('[') {
                            main = line == "[Desktop Entry]";
                        } else if main {
                            if let Some(icon) = line.strip_prefix("Icon=") {
                                return resolve_icon(icon, &entry.path());
                            }
                        }
                    }
                }
            }
        }
    }
    String::new()
}
fn resolve_icon(icon: &str, desktop: &Path) -> String {
    if icon.starts_with('/') {
        return icon.into();
    }
    // Nix desktop files often point into the same store package as their icons.
    if let Ok(file) = desktop.canonicalize() {
        if let Some(share) = file.parent().and_then(Path::parent) {
            for size in ["128x128", "64x64", "48x48", "32x32", "scalable", "256x256"] {
                for extension in ["png", "svg", "xpm"] {
                    let path = share
                        .join("icons/hicolor")
                        .join(size)
                        .join("apps")
                        .join(format!("{icon}.{extension}"));
                    if path.is_file() {
                        return path.to_string_lossy().into_owned();
                    }
                }
            }
            for extension in ["png", "svg", "xpm"] {
                let path = share.join("pixmaps").join(format!("{icon}.{extension}"));
                if path.is_file() {
                    return path.to_string_lossy().into_owned();
                }
            }
        }
    }
    icon.into()
}

fn main() {
    let result = (|| -> Result<i32> {
        let c = Config::new()?;
        if let Some(action) = env::args().nth(1) {
            return c.terminal(&action);
        }
        fs::create_dir_all(&c.state)?;
        let lock = fs::OpenOptions::new()
            .create(true)
            .truncate(false)
            .write(true)
            .open(c.state.join("desktop-config.lock"))?;
        lock.lock_exclusive()?;
        let mut line = String::new();
        io::stdin()
            .lock()
            .take(4 * 1024 * 1024)
            .read_line(&mut line)?;
        let q: Value = serde_json::from_str(&line)?;
        let mut response = c.dispatch(&q)?;
        response["ok"] = json!(true);
        println!("{response}");
        Ok(0)
    })();
    match result {
        Ok(code) => std::process::exit(code),
        Err(error) => {
            println!("{}", json!({"ok":false,"error":error.to_string()}));
            std::process::exit(1);
        }
    }
}
#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn rejects_expression_injection() {
        for s in ["hello; rm", "hello\"", "../file", "hello + pkgs.vim", ""] {
            assert!(!attribute(s));
        }
        assert!(attribute("kdePackages.kate"));
    }
    #[test]
    fn layout_keeps_other_content() {
        let s =
            "layout { gaps 10\n focus-ring { width 2 }\n default-column-width { proportion 0.5 } }";
        assert!(niri_settings(s).is_ok());
        assert!(niri_settings("layout { gaps 8 }").is_err());
    }
    #[test]
    fn atomic_save_and_boundary() {
        let dir = TempDir::new().unwrap();
        fs::create_dir_all(dir.path().join("home")).unwrap();
        let path = dir.path().join("home/moni.nix");
        fs::write(&path, "original").unwrap();
        let c = Config {
            root: dir.path().to_owned(),
            config: dir.path().join("config"),
            state: dir.path().join("state"),
        };
        c.write(&path, "edited").unwrap();
        assert_eq!(fs::read_to_string(&path).unwrap(), "edited");
        let backup = fs::read_dir(c.state.join("config-backups"))
            .unwrap()
            .next()
            .unwrap()
            .unwrap()
            .path();
        assert_eq!(fs::read_to_string(backup).unwrap(), "original");
        fs::remove_file(&path).unwrap();
        std::os::unix::fs::symlink("/etc/passwd", &path).unwrap();
        assert!(c.target("home").is_err());
        assert!(c.target("../../etc/passwd").is_err());
    }
}
