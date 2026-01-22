#!/usr/bin/env rust-script
//! ```cargo
//! [dependencies]
//! image = "0.25"
//! anyhow = "1.0"
//! clap = { version = "4.5", features = ["derive"] }
//! serde = { version = "1.0", features = ["derive"] }
//! serde_yaml = "0.9"
//! which = "6.0"
//! env_logger = "0.11"
//! log = "0.4"
//! ```

use anyhow::{Context, Result};
use clap::Parser;
use image::{DynamicImage, GenericImageView, Rgba};
use log::{debug, info};
use serde::Deserialize;
use std::fs;
use std::path::PathBuf;

#[derive(Parser)]
#[command(name = "gen-logo")]
#[command(about = "Generate light and dark theme logo variants for Flutter apps", long_about = None)]
struct Args {
    /// Path to pubspec.yaml (reads webfly.logo config)
    #[arg(short, long, default_value = "pubspec.yaml")]
    pubspec: PathBuf,

    /// Input logo file path (overrides pubspec config)
    #[arg(short, long)]
    input: Option<PathBuf>,

    /// Output directory for generated variants (overrides pubspec config)
    #[arg(short, long)]
    output_dir: Option<PathBuf>,

    /// Light theme output filename
    #[arg(long)]
    light_name: Option<String>,

    /// Dark theme output filename
    #[arg(long)]
    dark_name: Option<String>,

    /// Only generate logo variants, skip running flutter commands
    #[arg(long)]
    no_apply: bool,

    /// Skip running flutter_launcher_icons
    #[arg(long)]
    skip_icons: bool,

    /// Skip running flutter_native_splash
    #[arg(long)]
    skip_splash: bool,
}

#[derive(Deserialize)]
struct Pubspec {
    webfly: Option<WebflyConfig>,
}

#[derive(Deserialize)]
struct WebflyConfig {
    logo: Option<LogoConfig>,
}

#[derive(Deserialize)]
struct LogoConfig {
    source: Option<String>,
    light_variant: Option<String>,
    dark_variant: Option<String>,
}

fn main() -> Result<()> {
    env_logger::Builder::from_env(env_logger::Env::default().default_filter_or("info")).init();

    let args = Args::parse();

    // Read pubspec.yaml for configuration
    let pubspec_content = fs::read_to_string(&args.pubspec)
        .with_context(|| format!("Failed to read {}", args.pubspec.display()))?;
    let pubspec: Pubspec = serde_yaml::from_str(&pubspec_content)
        .context("Failed to parse pubspec.yaml")?;

    // Get logo paths from pubspec or use defaults/overrides
    let logo_config = pubspec.webfly.and_then(|w| w.logo);

    let input_path = args.input
        .or_else(|| logo_config.as_ref().and_then(|c| c.source.as_ref().map(PathBuf::from)))
        .unwrap_or_else(|| PathBuf::from("assets/logo/webfly_logo.png"));

    let light_output = if let Some(ref dir) = args.output_dir {
        dir.join(args.light_name.as_deref().unwrap_or("webfly_logo_light.png"))
    } else if let Some(ref cfg) = logo_config {
        cfg.light_variant.as_ref()
            .map(PathBuf::from)
            .unwrap_or_else(|| PathBuf::from("assets/logo/webfly_logo_light.png"))
    } else {
        PathBuf::from("assets/logo/webfly_logo_light.png")
    };

    let dark_output = if let Some(ref dir) = args.output_dir {
        dir.join(args.dark_name.as_deref().unwrap_or("webfly_logo_dark.png"))
    } else if let Some(ref cfg) = logo_config {
        cfg.dark_variant.as_ref()
            .map(PathBuf::from)
            .unwrap_or_else(|| PathBuf::from("assets/logo/webfly_logo_dark.png"))
    } else {
        PathBuf::from("assets/logo/webfly_logo_dark.png")
    };

    debug!("Reading logo from: {}", input_path.display());
    let img = image::open(&input_path)
        .with_context(|| format!("Failed to open {}", input_path.display()))?;

    // Analyze logo brightness to determine appropriate variants
    let avg_brightness = calculate_average_brightness(&img);
    let is_dark_logo = avg_brightness < 128.0;

    debug!("Logo brightness: {:.1} ({})", avg_brightness,
        if is_dark_logo { "dark logo" } else { "light logo" });

    if is_dark_logo {
        img.save(&light_output).context("Failed to save light variant")?;
        let dark_img = invert_logo_colors(&img);
        dark_img.save(&dark_output).context("Failed to save dark variant")?;
    } else {
        let light_img = invert_logo_colors(&img);
        light_img.save(&light_output).context("Failed to save light variant")?;
        img.save(&dark_output).context("Failed to save dark variant")?;
    }

    info!("Generated logo variants: light and dark");

    if args.no_apply {
        debug!("Skipping flutter commands (--no-apply)");
        return Ok(());
    }

    // Find flutter command
    let flutter_cmd = which::which("flutter")
        .context("flutter command not found. Make sure Flutter is installed and in PATH")?;

    if !args.skip_icons {
        info!("Running flutter_launcher_icons...");
        let status = std::process::Command::new(&flutter_cmd)
            .args(&["pub", "run", "flutter_launcher_icons"])
            .status()
            .context("Failed to run flutter_launcher_icons")?;

        if !status.success() {
            anyhow::bail!("flutter_launcher_icons failed");
        }
    }

    if !args.skip_splash {
        info!("Running flutter_native_splash...");
        let status = std::process::Command::new(&flutter_cmd)
            .args(&["pub", "run", "flutter_native_splash:create"])
            .status()
            .context("Failed to run flutter_native_splash")?;

        if !status.success() {
            anyhow::bail!("flutter_native_splash failed");
        }
    }

    info!("Done");
    Ok(())
}

fn calculate_average_brightness(img: &DynamicImage) -> f32 {
    let mut total_brightness = 0u64;
    let mut pixel_count = 0u64;

    for pixel in img.pixels() {
        // Only consider non-transparent pixels
        if pixel.2[3] > 0 {
            let rgba = pixel.2;
            // Calculate perceived brightness (Rec. 709 coefficients)
            let brightness = (0.2126 * rgba[0] as f32
                            + 0.7152 * rgba[1] as f32
                            + 0.0722 * rgba[2] as f32) as u64;
            total_brightness += brightness;
            pixel_count += 1;
        }
    }

    if pixel_count > 0 {
        (total_brightness as f32) / (pixel_count as f32)
    } else {
        128.0 // Default to mid-brightness if no non-transparent pixels
    }
}

fn invert_logo_colors(img: &DynamicImage) -> DynamicImage {
    let mut inverted = img.to_rgba8();

    for pixel in inverted.pixels_mut() {
        pixel[0] = 255 - pixel[0]; // Invert R
        pixel[1] = 255 - pixel[1]; // Invert G
        pixel[2] = 255 - pixel[2]; // Invert B
        // pixel[3] stays the same (alpha/transparency)
    }

    DynamicImage::ImageRgba8(inverted)
}
