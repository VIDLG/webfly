use anyhow::{bail, Context, Result};
use std::fs;
use std::path::Path;
use std::process::Command;
use which::which;

use crate::config::FlutterCreateConfig;

pub fn resolve_cmd(command: &str) -> Result<std::path::PathBuf> {
    if command.contains(['/', '\\']) {
        let path = std::path::PathBuf::from(command);
        if path.exists() {
            return Ok(path);
        }
        bail!("command not found at: {}", path.display());
    }
    which(command).with_context(|| format!("command not found in PATH: {command}"))
}

pub fn run_flutter_create(
    path: &Path,
    flutter_cmd: &Path,
    project_name: &str,
    org: Option<&str>,
    description: Option<&str>,
    create: &FlutterCreateConfig,
) -> Result<()> {
    let mut command = Command::new(flutter_cmd);
    command
        .arg("create")
        .arg("--project-name")
        .arg(project_name);
    if let Some(platforms) = create.platforms.as_ref() {
        if !platforms.is_empty() {
            command.arg("--platforms").arg(platforms.join(","));
        }
    }
    if let Some(value) = create.android_language.as_deref() {
        command.arg("--android-language").arg(value);
    }
    if let Some(value) = org {
        command.arg("--org").arg(value);
    }
    if let Some(value) = description {
        command.arg("--description").arg(value);
    }
    let status = command
        .arg(path)
        .status()
        .context("Failed to run flutter create")?;
    if !status.success() {
        bail!("flutter create failed with status: {status}");
    }
    Ok(())
}

pub fn run_flutter_pub_get(path: &Path, flutter_cmd: &Path) -> Result<()> {
    let status = Command::new(flutter_cmd)
        .arg("pub")
        .arg("get")
        .current_dir(path)
        .status()
        .context("Failed to run flutter pub get")?;
    if !status.success() {
        bail!("flutter pub get failed with status: {status}");
    }
    Ok(())
}

pub fn run_flutter_pub_run(path: &Path, flutter_cmd: &Path, args: &[&str]) -> Result<()> {
    let mut command = Command::new(flutter_cmd);
    command.arg("pub").arg("run").current_dir(path);
    for arg in args {
        command.arg(arg);
    }
    let status = command
        .status()
        .context("Failed to run flutter pub run")?;
    if !status.success() {
        bail!("flutter pub run failed with status: {status}");
    }
    Ok(())
}

pub fn run_gen_logo(path: &Path, script_path: &str) -> Result<()> {
    let python_cmd = which("python")
        .or_else(|_| which("python3"))
        .context("Python not found in PATH")?;

    let status = Command::new(python_cmd)
        .arg(script_path)
        .arg("--pubspec")
        .arg("pubspec.yaml")
        .arg("--no-apply")
        .current_dir(path)
        .status()
        .context("Failed to run gen-logo script with python")?;

    if !status.success() {
        bail!("gen-logo script failed with status: {status}");
    }
    Ok(())
}

pub fn run_flutter_clean(path: &Path, flutter_cmd: &Path) -> Result<()> {
    let status = Command::new(flutter_cmd)
        .arg("clean")
        .current_dir(path)
        .status()
        .context("Failed to run flutter clean")?;
    if !status.success() {
        bail!("flutter clean failed with status: {status}");
    }
    Ok(())
}

pub fn remove_dir_all_with_retry(path: &Path) -> Result<()> {
    fs::remove_dir_all(path).with_context(|| {
        format!(
            "Failed to remove directory: {}. Use kill-file-handles tool if locked.",
            path.display()
        )
    })
}
