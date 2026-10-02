use serde_json::{json, Value};
use std::{
    env,
    io::{self, Write},
    path::PathBuf,
    process::Command,
};
type Result<T> = std::result::Result<T, Box<dyn std::error::Error>>;
fn niri(args: &[&str]) -> Result<String> {
    let o = Command::new("niri").arg("msg").args(args).output()?;
    if !o.status.success() {
        return Err(String::from_utf8_lossy(&o.stderr).into_owned().into());
    }
    Ok(String::from_utf8(o.stdout)?)
}
fn workspaces() -> Result<Vec<Value>> {
    Ok(serde_json::from_str(&niri(&["-j", "workspaces"])?)?)
}
fn focus(w: &Value) -> Result<()> {
    niri(&["action", "focus-workspace", &w["idx"].to_string()])?;
    Ok(())
}
fn run() -> Result<i32> {
    let root = env::var_os("EROGEDOTS_ROOT")
        .map(PathBuf::from)
        .unwrap_or_else(|| {
            PathBuf::from(env::var_os("HOME").unwrap_or_default()).join("erogeDOTS")
        });
    let spaces = workspaces()?;
    let origin = spaces
        .iter()
        .find(|w| w["is_focused"] == true)
        .ok_or("No focused workspace.")?;
    let windows: Vec<Value> = serde_json::from_str(&niri(&["-j", "windows"])?)?;
    let empty = spaces
        .iter()
        .find(|w| {
            w["output"] == origin["output"] && !windows.iter().any(|v| v["workspace_id"] == w["id"])
        })
        .ok_or("No empty chapter is available for the title terminal.")?;
    println!("{}", json!({"origin":origin["id"]}));
    io::stdout().flush()?;
    focus(empty)?;
    let mut command = Command::new("ghostty");
    command
        .args([
            "--gtk-single-instance=false",
            "--class=org.erogedots.TitleTerminal",
            "--title=Title Terminal",
        ])
        .arg(format!("--working-directory={}", root.display()))
        .env("GDK_BACKEND", "wayland");
    let args: Vec<String> = env::args().skip(1).collect();
    if !args.is_empty() {
        command.args(["-e","bash","-c","\"$@\"; result=$?; printf '\\nTask finished (exit %s). Press Enter to return.\\n' \"$result\"; read -r; exit \"$result\"","title-task"]).args(args);
    }
    let status = command.status();
    if let Ok(current) = workspaces() {
        if current
            .iter()
            .any(|w| w["id"] == empty["id"] && w["is_focused"] == true)
        {
            if let Some(previous) = current.iter().find(|w| w["id"] == origin["id"]) {
                focus(previous)?;
            }
        }
    }
    Ok(status?.code().unwrap_or(1))
}
fn main() {
    match run() {
        Ok(code) => std::process::exit(code),
        Err(e) => {
            println!("{}", json!({"error":e.to_string()}));
            std::process::exit(1);
        }
    }
}
