mod android;
mod config;
mod utils;
mod web;
mod windows;

use anyhow::{bail, Result};
use clap::Parser;
use std::path::{Path, PathBuf};

use config::{expand_config, load_config};
use utils::{
    remove_dir_all_with_retry, resolve_cmd, run_flutter_create,
};

#[derive(Parser, Debug)]
#[command(name = "flutter-gen-platform", about = "Generate Flutter platform directories")]
struct Args {
    #[arg(long, value_name = "FILE", default_value = "flutter/app.pkl")]
    config: PathBuf,

    #[arg(long, value_name = "CMD", default_value = "flutter")]
    flutter_cmd: String,

    #[arg(long, value_name = "DIR")]
    project_dir: Option<PathBuf>,

    #[arg(long, help = "Preview changes without writing files")]
    dry_run: bool,
}

fn main() -> Result<()> {
    let args = Args::parse();
    let config_path = args.config;
    let flutter_cmd = args.flutter_cmd;
    let project_dir = args.project_dir;
    let dry_run = args.dry_run;

    if dry_run {
        println!("[DRY RUN] Preview mode - no files will be modified\n");
    }

    let mut cfg = load_config(&config_path)?;

    let project_dir = project_dir.unwrap_or_else(|| {
        config_path
            .parent()
            .unwrap_or_else(|| Path::new("."))
            .to_path_buf()
    });

    // Use version from app.pkl's pubspec config
    if cfg.version.is_none() {
        if let Some(pubspec_config) = &cfg.pubspec {
            cfg.version = pubspec_config.version.clone();
            if let Some(version) = &cfg.version {
                println!("Using version from config: {}", version);
            }
        }
    }

    // Set output_file_name if version is available
    if cfg.android.app.build.output_file_name.is_none() {
        if let Some(version) = &cfg.version {
            let pattern = cfg
                .output_file_name_pattern
                .as_deref()
                .unwrap_or("{project_name}-v{version}-${name}.apk");

            let output_pattern = pattern
                .replace("{version}", version)
                .replace("{project_name}", &cfg.project_name);

            cfg.android.app.build.output_file_name = Some(output_pattern);
        }
    }

    expand_config(&mut cfg)?;

    // Determine which platforms to process based on config
    let platforms = cfg
        .create
        .platforms
        .as_ref()
        .map(|p| p.as_slice())
        .unwrap_or(&[]);
    let process_android = platforms.is_empty() || platforms.contains(&"android".to_string());
    let process_web = platforms.contains(&"web".to_string());
    let process_windows = platforms.contains(&"windows".to_string());

    // Remove existing platform directories
    if process_android {
        let android_dir = project_dir.join("android");
        if android_dir.exists() {
            if dry_run {
                println!("[DRY RUN] Would remove directory: {}", android_dir.display());
            } else {
                remove_dir_all_with_retry(&android_dir)?;
            }
        }
    }

    if process_web {
        let web_dir = project_dir.join("web");
        if web_dir.exists() {
            if dry_run {
                println!("[DRY RUN] Would remove directory: {}", web_dir.display());
            } else {
                remove_dir_all_with_retry(&web_dir)?;
            }
        }
    }

    if process_windows {
        let windows_dir = project_dir.join("windows");
        if windows_dir.exists() {
            if dry_run {
                println!("[DRY RUN] Would remove directory: {}", windows_dir.display());
            } else {
                remove_dir_all_with_retry(&windows_dir)?;
            }
        }
    }

    let flutter_cmd = resolve_cmd(&flutter_cmd)?;
    if !dry_run {
        run_flutter_create(
            &project_dir,
            &flutter_cmd,
            &cfg.project_name,
            cfg.org.as_deref(),
            cfg.description.as_deref(),
            &cfg.create,
        )?;
    } else {
        println!("[DRY RUN] Would run flutter create with:");
        println!("  project_name: {}", cfg.project_name);
        if let Some(org) = &cfg.org {
            println!("  org: {}", org);
        }
        if let Some(desc) = &cfg.description {
            println!("  description: {}", desc);
        }
        println!("  platforms: {:?}", cfg.create.platforms);
        println!("  android_language: {:?}\n", cfg.create.android_language);
        return Ok(());
    }

    // Process Android platform
    if process_android {
        let android_dir = project_dir.join("android");
        if !android_dir.exists() {
            bail!(
                "Generated android directory not found at: {}",
                android_dir.display()
            );
        }
        android::process_android_platform(&project_dir, &cfg.android)?;
    }

    // Process Web platform
    if process_web {
        let web_dir = project_dir.join("web");
        if !web_dir.exists() {
            bail!("Generated web directory not found at: {}", web_dir.display());
        }
        web::process_web_platform(&project_dir)?;
    }

    // Process Windows platform
    if process_windows {
        let windows_dir = project_dir.join("windows");
        if !windows_dir.exists() {
            bail!("Generated windows directory not found at: {}", windows_dir.display());
        }
        windows::process_windows_platform(&project_dir)?;
    }

    println!("Platform directories generated successfully!");
    Ok(())
}
