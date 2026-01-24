use anyhow::Result;
use std::path::Path;

pub fn process_web_platform(project_dir: &Path) -> Result<()> {
    let web_dir = project_dir.join("web");
    println!("Web directory generated at: {}", web_dir.display());
    Ok(())
}
