use anyhow::{Context, Result};
use std::path::Path;

/// Process Windows platform directory
pub fn process_windows_platform(project_dir: &Path) -> Result<()> {
    let windows_dir = project_dir.join("windows");

    if !windows_dir.exists() {
        anyhow::bail!(
            "Windows directory not found. Run 'flutter create --platforms=windows .' first."
        );
    }

    println!("✓ Windows platform directory confirmed");

    Ok(())
}
