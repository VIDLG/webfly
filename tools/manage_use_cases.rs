#!/usr/bin/env -S rust-script --base-path . --clear-cache
//! ```cargo
//! [dependencies]
//! clap = { version = "4.5", features = ["derive"] }
//! anyhow = "1.0"
//! which = "7.0"
//! ```

use anyhow::{Context, Result};
use clap::{Parser, Subcommand};
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};

#[derive(Parser)]
#[command(name = "manage-use-cases")]
#[command(about = "Manage WebF use_cases build and deployment")]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// Build upstream use_cases project
    Build {
        /// Path to upstream use_cases directory
        #[arg(short, long)]
        src: PathBuf,
        
        /// Package manager to use (pnpm, npm, yarn, bun)
        #[arg(short = 'm', long, default_value = "pnpm")]
        package_manager: String,
    },
    /// Copy built assets to Flutter assets directory
    Copy {
        /// Path to upstream use_cases directory (looks for build/ inside)
        #[arg(short, long)]
        src: PathBuf,
        
        /// Destination path for copied assets
        #[arg(short, long)]
        dst: PathBuf,
    },
    /// Build upstream and copy assets (one-shot)
    Refresh {
        /// Path to upstream use_cases directory
        #[arg(short, long)]
        src: PathBuf,
        
        /// Destination path for copied assets
        #[arg(short, long)]
        dst: PathBuf,
        
        /// Package manager to use (pnpm, npm, yarn, bun)
        #[arg(short = 'm', long, default_value = "pnpm")]
        package_manager: String,
    },
}

fn build_upstream(src_dir: &Path, package_manager: &str) -> Result<()> {
    println!("Building upstream use_cases at: {}", src_dir.display());
    
    if !src_dir.exists() {
        anyhow::bail!("Source directory does not exist: {}", src_dir.display());
    }

    // Find package manager in PATH using which crate
    let pm_path = which::which(package_manager)
        .with_context(|| format!("{} not found in PATH. Please install {} or ensure it's in your PATH.", package_manager, package_manager))?;

    println!("Using package manager: {} ({})", package_manager, pm_path.display());

    // Run install
    let status = Command::new(&pm_path)
        .arg("install")
        .current_dir(src_dir)
        .stdout(Stdio::inherit())
        .stderr(Stdio::inherit())
        .status()
        .with_context(|| format!("Failed to run {} install", package_manager))?;

    if !status.success() {
        anyhow::bail!("{} install failed", package_manager);
    }

    // Run build
    let status = Command::new(&pm_path)
        .arg("build")
        .current_dir(src_dir)
        .stdout(Stdio::inherit())
        .stderr(Stdio::inherit())
        .status()
        .with_context(|| format!("Failed to run {} build", package_manager))?;

    if !status.success() {
        anyhow::bail!("{} build failed", package_manager);
    }

    println!("✓ Build completed successfully");
    Ok(())
}

fn copy_assets(src_dir: &Path, dst_dir: &Path) -> Result<()> {
    let build_dir = src_dir.join("build");
    
    if !build_dir.exists() {
        anyhow::bail!("Build output not found: {}", build_dir.display());
    }

    println!("Copying assets from {} to {}", build_dir.display(), dst_dir.display());

    // Remove destination if it exists
    if dst_dir.exists() {
        std::fs::remove_dir_all(dst_dir)
            .with_context(|| format!("Failed to remove destination: {}", dst_dir.display()))?;
    }

    // Create destination directory
    std::fs::create_dir_all(dst_dir)
        .with_context(|| format!("Failed to create destination: {}", dst_dir.display()))?;

    // Copy recursively
    copy_dir_all(&build_dir, dst_dir)
        .context("Failed to copy assets")?;

    println!("✓ Copied {} -> {}", build_dir.display(), dst_dir.display());
    Ok(())
}

fn copy_dir_all(src: &Path, dst: &Path) -> Result<()> {
    for entry in std::fs::read_dir(src)? {
        let entry = entry?;
        let ty = entry.file_type()?;
        let src_path = entry.path();
        let dst_path = dst.join(entry.file_name());

        if ty.is_dir() {
            std::fs::create_dir_all(&dst_path)?;
            copy_dir_all(&src_path, &dst_path)?;
        } else {
            std::fs::copy(&src_path, &dst_path)?;
        }
    }
    Ok(())
}

fn main() -> Result<()> {
    let cli = Cli::parse();

    match cli.command {
        Commands::Build { src, package_manager } => {
            build_upstream(&src, &package_manager)?;
        }
        Commands::Copy { src, dst } => {
            copy_assets(&src, &dst)?;
        }
        Commands::Refresh { src, dst, package_manager } => {
            build_upstream(&src, &package_manager)?;
            copy_assets(&src, &dst)?;
        }
    }

    Ok(())
}
