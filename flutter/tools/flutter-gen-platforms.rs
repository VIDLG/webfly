//! ```cargo
//! [dependencies]
//! anyhow = "1.0"
//! android-manifest = "0.3"
//! clap = { version = "4.5", features = ["derive"] }
//! java-properties = "1.4"
//! serde_json = "1.0"
//! serde = { version = "1.0", features = ["derive"] }
//! toml = "0.8"
//! xmltree = "0.10"
//! walkdir = "2.5"
//! which = "6.0"
//! windows = { version = "0.59", features = ["Win32_Foundation", "Win32_System_RestartManager"] }
//! ```

use android_manifest::{AndroidManifest, StringResourceOrString, UsesPermission, VarOrBool};
use anyhow::{bail, Context, Result};
use clap::Parser;
use serde::Deserialize;
use std::collections::HashMap;
use std::env;
use std::fs;
use std::path::{Path, PathBuf};
use std::process::Command;
use std::time::Duration;
use which::which;
use xmltree::{Element, EmitterConfig};


#[derive(Debug, Deserialize)]
#[allow(dead_code)]
struct Config {
    project_name: String,
    #[serde(default)]
    org: Option<String>,
    #[serde(default)]
    description: Option<String>,
    #[serde(default)]
    create: FlutterCreateConfig,
    android: AndroidConfig,
    ios: Option<IosConfig>,
}

#[derive(Debug, Deserialize, Default)]
struct FlutterCreateConfig {
    #[serde(default)]
    platforms: Option<Vec<String>>,
    #[serde(default)]
    android_language: Option<String>,
}


#[derive(Debug, Deserialize)]
struct AndroidConfig {
    #[serde(default)]
    gradle_wrapper: AndroidGradleWrapperConfig,
    #[serde(default)]
    app: AndroidAppConfig,
    build: AndroidBuildConfig,
    #[serde(default)]
    settings: AndroidSettingsConfig,
}

#[derive(Debug, Deserialize, Default)]
struct AndroidBuildConfig {
    allprojects: RepositoryList,
}

#[derive(Debug, Deserialize, Default)]
struct AndroidSettingsConfig {
    plugin_management: RepositoryList,
}

#[derive(Debug, Deserialize, Default)]
struct AndroidGradleWrapperConfig {
    distribution_url: Option<String>,
}

#[derive(Debug, Deserialize, Default)]
struct AndroidAppConfig {
    #[serde(default)]
    build: AndroidAppBuildConfig,
    #[serde(default)]
    manifest: AndroidAppManifestConfig,
}

#[derive(Debug, Deserialize, Default)]
struct AndroidAppBuildConfig {
    #[serde(default)]
    namespace: String,
    #[serde(default)]
    application_id: String,
}

#[derive(Debug, Deserialize, Default)]
struct AndroidManifestConfig {
    #[serde(default)]
    application_label: Option<String>,
    #[serde(default)]
    uses_cleartext_traffic: Option<bool>,
    #[serde(default)]
    enable_on_back_invoked_callback: Option<bool>,
    #[serde(default)]
    permissions: Option<Vec<AndroidUsesPermission>>,
}

#[derive(Debug, Deserialize, Clone)]
struct AndroidUsesPermission {
    name: String,
    #[serde(default)]
    max_sdk_version: Option<u32>,
    #[serde(default)]
    uses_permission_flags: Option<String>,
    #[serde(default)]
    target_api: Option<String>,
}

#[derive(Debug, Deserialize, Default)]
struct AndroidAppManifestConfig {
    #[serde(default)]
    main: AndroidManifestConfig,
    debug: Option<AndroidManifestConfig>,
    profile: Option<AndroidManifestConfig>,
}

#[derive(Debug, Deserialize)]
#[allow(dead_code)]
struct IosConfig {}

#[derive(Debug, Deserialize, Default)]
struct RepositoryList {
    repositories: Vec<String>,
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
    expand_config(&mut cfg)?;

    let project_dir = project_dir.unwrap_or_else(|| {
        config_path
            .parent()
            .unwrap_or_else(|| Path::new("."))
            .to_path_buf()
    });
    let output_dir = project_dir.join("android");

    if output_dir.exists() {
        if dry_run {
            println!("[DRY RUN] Would remove directory: {}", output_dir.display());
        } else {
            remove_dir_all_with_retry(&output_dir, 10)?;
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
        return Ok(()); // Exit early in dry run since we can't preview without actual files
    }

    if !output_dir.exists() {
        bail!("Generated android directory not found at: {}", output_dir.display());
    }

    apply_repositories(
        &output_dir.join("build.gradle.kts"),
        &cfg.android.build.allprojects.repositories,
    )?;
    apply_plugin_repositories(
        &output_dir.join("settings.gradle.kts"),
        &cfg.android.settings.plugin_management.repositories,
    )?;
    apply_app_gradle(
        &output_dir.join("app/build.gradle.kts"),
        &cfg.android.app.build.namespace,
        &cfg.android.app.build.application_id,
    )?;
    apply_manifest(
        &output_dir.join("app/src/main/AndroidManifest.xml"),
        &cfg.android.app.manifest.main,
    )?;
    if let Some(debug) = cfg.android.app.manifest.debug.as_ref() {
        apply_manifest(&output_dir.join("app/src/debug/AndroidManifest.xml"), debug)?;
    }
    if let Some(profile) = cfg.android.app.manifest.profile.as_ref() {
        apply_manifest(&output_dir.join("app/src/profile/AndroidManifest.xml"), profile)?;
    }
    if let Some(distribution_url) = &cfg.android.gradle_wrapper.distribution_url {
        apply_gradle_wrapper_properties(
            &output_dir.join("gradle/wrapper/gradle-wrapper.properties"),
            distribution_url,
        )?;
    }

    println!("Android directory generated at: {}", output_dir.display());

    run_flutter_clean(&project_dir, &flutter_cmd)?;
    run_flutter_pub_get(&project_dir, &flutter_cmd)?;

    Ok(())
}

fn load_config(path: &Path) -> Result<Config> {
    match path.extension().and_then(|ext| ext.to_str()) {
        Some("pkl") => load_pkl_config(path),
        Some("toml") => {
            let content = fs::read_to_string(path)
                .with_context(|| format!("Failed to read config: {}", path.display()))?;
            let cfg: Config = toml::from_str(&content).context("Failed to parse config")?;
            Ok(cfg)
        }
        _ => {
            bail!("Unsupported config format: {}", path.display());
        }
    }
}

fn load_pkl_config(path: &Path) -> Result<Config> {
    let pkl_cmd = resolve_cmd("pkl")?;
    let output = run_pkl_eval(&pkl_cmd, path, ["-f", "json"])
        .or_else(|_| run_pkl_eval(&pkl_cmd, path, ["--format", "json"]))
        .with_context(|| format!("Failed to run pkl eval for: {}", path.display()))?;

    let cfg: Config = serde_json::from_slice(&output)
        .with_context(|| format!("Failed to parse pkl output: {}", path.display()))?;
    Ok(cfg)
}

fn run_pkl_eval(pkl_cmd: &Path, path: &Path, format_args: [&str; 2]) -> Result<Vec<u8>> {
    let output = Command::new(pkl_cmd)
        .arg("eval")
        .args(format_args)
        .arg(path)
        .output()
        .with_context(|| format!("Failed to run pkl eval for: {}", path.display()))?;

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        bail!("pkl eval failed: {stderr}");
    }

    Ok(output.stdout)
}

fn expand_config(cfg: &mut Config) -> Result<()> {
    cfg.project_name = expand_env_vars(&cfg.project_name)?;
    if let Some(value) = cfg.org.as_ref() {
        cfg.org = Some(expand_env_vars(value)?);
    }
    if let Some(value) = cfg.description.as_ref() {
        cfg.description = Some(expand_env_vars(value)?);
    }
    expand_flutter_create_config(&mut cfg.create)?;
    expand_android_config(&mut cfg.android)?;
    if cfg.android.app.build.application_id.trim().is_empty() {
        if let Some(org) = cfg.org.as_ref().map(|value| value.trim()).filter(|v| !v.is_empty()) {
            let org = org.trim_end_matches('.');
            cfg.android.app.build.application_id = format!("{}.{}", org, cfg.project_name);
        } else {
            bail!("android.app.build.application_id is required when org is not set");
        }
    }
    if cfg.android.app.manifest.main.application_label.is_none() {
        cfg.android.app.manifest.main.application_label = Some(cfg.project_name.clone());
    }
    if cfg.android.app.build.namespace.trim().is_empty() {
        cfg.android.app.build.namespace = cfg.android.app.build.application_id.clone();
    }
    Ok(())
}

fn expand_android_config(cfg: &mut AndroidConfig) -> Result<()> {
    android_app_build_gradle_expand(cfg)?;
    if let Some(value) = cfg.app.manifest.main.application_label.as_ref() {
        cfg.app.manifest.main.application_label = Some(expand_env_vars(value)?);
    }
    expand_manifest_override(cfg.app.manifest.debug.as_mut())?;
    expand_manifest_override(cfg.app.manifest.profile.as_mut())?;
    if let Some(value) = cfg.gradle_wrapper.distribution_url.as_ref() {
        cfg.gradle_wrapper.distribution_url = Some(expand_env_vars(value)?);
    }
    expand_manifest_override(Some(&mut cfg.app.manifest.main))?;
    expand_manifest_override(cfg.app.manifest.debug.as_mut())?;
    expand_manifest_override(cfg.app.manifest.profile.as_mut())?;
    cfg.build.allprojects.repositories = cfg
        .build
        .allprojects
        .repositories
        .iter()
        .map(|value| expand_env_vars(value))
        .collect::<Result<Vec<_>>>()?;
    cfg.settings.plugin_management.repositories = cfg
        .settings
        .plugin_management
        .repositories
        .iter()
        .map(|value| expand_env_vars(value))
        .collect::<Result<Vec<_>>>()?;
    Ok(())
}

fn expand_flutter_create_config(cfg: &mut FlutterCreateConfig) -> Result<()> {
    if let Some(value) = cfg.android_language.as_ref() {
        cfg.android_language = Some(expand_env_vars(value)?);
    }
    if let Some(platforms) = cfg.platforms.as_ref() {
        cfg.platforms = Some(
            platforms
                .iter()
                .map(|value| expand_env_vars(value))
                .collect::<Result<Vec<_>>>()?,
        );
    }
    Ok(())
}

fn android_app_build_gradle_expand(cfg: &mut AndroidConfig) -> Result<()> {
    cfg.app.build.namespace = expand_env_vars(&cfg.app.build.namespace)?;
    cfg.app.build.application_id = expand_env_vars(&cfg.app.build.application_id)?;
    Ok(())
}

fn expand_manifest_override(override_cfg: Option<&mut AndroidManifestConfig>) -> Result<()> {
    let Some(cfg) = override_cfg else {
        return Ok(());
    };
    if let Some(value) = cfg.application_label.as_ref() {
        cfg.application_label = Some(expand_env_vars(value)?);
    }
    if let Some(perms) = cfg.permissions.as_mut() {
        for perm in perms.iter_mut() {
            perm.name = expand_env_vars(&perm.name)?;
        }
    }
    Ok(())
}

fn expand_env_vars(input: &str) -> Result<String> {
    let mut out = String::new();
    let chars: Vec<char> = input.chars().collect();
    let mut i = 0;
    while i < chars.len() {
        if chars[i] == '$' {
            if i + 1 < chars.len() && chars[i + 1] == '{' {
                let mut end = i + 2;
                while end < chars.len() && chars[end] != '}' {
                    end += 1;
                }
                if end >= chars.len() {
                    bail!("Unclosed env var in config value: {input}");
                }
                let key: String = chars[i + 2..end].iter().collect();
                let value = env::var(&key)
                    .with_context(|| format!("Missing env var: {key}"))?;
                out.push_str(&value);
                i = end + 1;
                continue;
            }

            let mut end = i + 1;
            while end < chars.len()
                && (chars[end].is_ascii_alphanumeric() || chars[end] == '_')
            {
                end += 1;
            }
            if end > i + 1 {
                let key: String = chars[i + 1..end].iter().collect();
                let value = env::var(&key)
                    .with_context(|| format!("Missing env var: {key}"))?;
                out.push_str(&value);
                i = end;
                continue;
            }
        }
        out.push(chars[i]);
        i += 1;
    }
    Ok(out)
}

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

fn resolve_cmd(command: &str) -> Result<PathBuf> {
    if command.contains(['/', '\\']) {
        let path = PathBuf::from(command);
        if path.exists() {
            return Ok(path);
        }
        bail!("command not found at: {}", path.display());
    }
    which(command).with_context(|| format!("command not found in PATH: {command}"))
}

fn run_flutter_create(
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

fn run_flutter_pub_get(path: &Path, flutter_cmd: &Path) -> Result<()> {
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

fn run_flutter_clean(path: &Path, flutter_cmd: &Path) -> Result<()> {
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

fn remove_dir_all_with_retry(path: &Path, attempts: usize) -> Result<()> {
    for attempt in 0..attempts {
        match fs::remove_dir_all(path) {
            Ok(_) => return Ok(()),
            Err(err) => {
                if attempt + 1 == attempts {
                    let details = locking_processes_info(path);
                    return Err(err).with_context(|| {
                        if let Some(info) = details {
                            format!("Failed to remove temp dir: {}. Locked by: {}", path.display(), info)
                        } else {
                            format!("Failed to remove temp dir: {}", path.display())
                        }
                    });
                }
                std::thread::sleep(Duration::from_millis(500));
            }
        }
    }
    Ok(())
}

fn locking_processes_info(path: &Path) -> Option<String> {
    #[cfg(windows)]
    {
        if let Ok(list) = windows_lock::locking_processes(path) {
            if list.is_empty() {
                return None;
            }
            let joined = list
                .into_iter()
                .map(|(pid, name)| format!("{name} (PID {pid})"))
                .collect::<Vec<_>>()
                .join(", ");
            return Some(joined);
        }
    }
    None
}

fn apply_repositories(path: &Path, repos: &[String]) -> Result<()> {
    let content = fs::read_to_string(path)
        .with_context(|| format!("Failed to read file: {}", path.display()))?;
    let lines: Vec<String> = content.lines().map(|l| l.to_string()).collect();

    let mut out = Vec::new();
    let mut in_repos = false;
    let mut inserted = false;

    for line in &lines {
        out.push(line.clone());
        if line.trim() == "repositories {" && !inserted {
            in_repos = true;
            for repo in repos {
                let insert = format!("        maven {{ url = uri(\"{}\") }}", repo);
                out.push(insert);
            }
            inserted = true;
        } else if in_repos && line.trim() == "}" {
            in_repos = false;
        }
    }

    fs::write(path, out.join("\n") + "\n")
        .with_context(|| format!("Failed to write file: {}", path.display()))?;
    Ok(())
}

fn apply_plugin_repositories(path: &Path, repos: &[String]) -> Result<()> {
    let content = fs::read_to_string(path)
        .with_context(|| format!("Failed to read file: {}", path.display()))?;
    let mut out = Vec::new();
    let mut in_plugin_repos = false;
    let mut inserted = false;

    for line in content.lines() {
        out.push(line.to_string());
        if line.trim() == "repositories {" && !inserted {
            in_plugin_repos = true;
            for repo in repos {
                let insert = format!("        maven {{ url = uri(\"{}\") }}", repo);
                out.push(insert);
            }
            inserted = true;
        } else if in_plugin_repos && line.trim() == "}" {
            in_plugin_repos = false;
        }
    }

    fs::write(path, out.join("\n") + "\n")
        .with_context(|| format!("Failed to write file: {}", path.display()))?;
    Ok(())
}

fn apply_app_gradle(path: &Path, namespace: &str, application_id: &str) -> Result<()> {
    let content = fs::read_to_string(path)
        .with_context(|| format!("Failed to read file: {}", path.display()))?;
    let mut out = Vec::new();
    for line in content.lines() {
        if line.trim_start().starts_with("namespace = ") {
            out.push(format!("    namespace = \"{}\"", namespace));
        } else if line.trim_start().starts_with("applicationId = ") {
            out.push(format!("        applicationId = \"{}\"", application_id));
        } else {
            out.push(line.to_string());
        }
    }
    fs::write(path, out.join("\n") + "\n")
        .with_context(|| format!("Failed to write file: {}", path.display()))?;
    Ok(())
}

fn apply_manifest(path: &Path, cfg: &AndroidManifestConfig) -> Result<()> {

    let mut manifest = if path.exists() {
        let content = fs::read_to_string(path)
            .with_context(|| format!("Failed to read file: {}", path.display()))?;
        android_manifest::from_str(&content)
            .with_context(|| format!("Failed to parse XML: {}", path.display()))?
    } else {
        AndroidManifest::default()
    };

    let mut existing_permissions = std::collections::BTreeSet::new();
    for perm in &manifest.uses_permission {
        if let Some(name) = perm.name.as_ref() {
            existing_permissions.insert(name.to_string());
        }
    }

    let permissions: Vec<AndroidUsesPermission> = cfg.permissions.clone().unwrap_or_default();

    for perm_cfg in permissions {
        if existing_permissions.contains(&perm_cfg.name) {
            continue;
        }
        let mut permission = UsesPermission::default();
        permission.name = Some(perm_cfg.name.clone());
        permission.max_sdk_version = perm_cfg.max_sdk_version;

        // Note: The android_manifest crate doesn't support:
        // - android:usesPermissionFlags attribute
        // - tools:targetApi attribute
        // These would need to be added manually or the crate extended

        manifest.uses_permission.push(permission);
    }

    if let Some(label) = cfg.application_label.as_ref() {
        if !label.trim().is_empty() {
            manifest.application.label = Some(StringResourceOrString::string(label));
        }
    }

    let uses_cleartext = cfg.uses_cleartext_traffic;
    if let Some(value) = uses_cleartext {
        manifest.application.uses_cleartext_traffic = Some(VarOrBool::bool(value));
    }

    let enable_on_back_invoked_callback = cfg.enable_on_back_invoked_callback.unwrap_or(false);

    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent)
            .with_context(|| format!("Failed to create dir: {}", parent.display()))?;
    }

    let mut output = android_manifest::to_string_pretty(&manifest)
        .with_context(|| format!("Failed to write XML: {}", path.display()))?;
    output = finalize_manifest_xml(&output, enable_on_back_invoked_callback)?;
    fs::write(path, output)
        .with_context(|| format!("Failed to write file: {}", path.display()))?;
    Ok(())
}

fn finalize_manifest_xml(xml: &str, enable_on_back_invoked_callback: bool) -> Result<String> {
    let mut root = Element::parse(xml.as_bytes())
        .context("Failed to parse AndroidManifest.xml")?;
    if enable_on_back_invoked_callback {
        let mut application = None;
        for child in root.children.iter_mut() {
            if let xmltree::XMLNode::Element(element) = child {
                if element.name == "application" {
                    application = Some(element);
                    break;
                }
            }
        }

        if let Some(app) = application {
            app.attributes
                .entry("android:enableOnBackInvokedCallback".to_string())
                .or_insert_with(|| "true".to_string());
        } else {
            let mut app = Element::new("application");
            app.attributes.insert(
                "android:enableOnBackInvokedCallback".to_string(),
                "true".to_string(),
            );
            root.children.push(xmltree::XMLNode::Element(app));
        }
    }

    normalize_android_attributes(&mut root);

    let mut out = Vec::new();
    let config = EmitterConfig::new()
        .perform_indent(true)
        .write_document_declaration(true);
    root.write_with_config(&mut out, config)
        .context("Failed to write AndroidManifest.xml")?;
    Ok(String::from_utf8(out).context("Failed to encode AndroidManifest.xml")?)
}

fn normalize_android_attributes(element: &mut Element) {
    let android_keys = [
        "name",
        "label",
        "value",
        "resource",
        "icon",
        "theme",
        "exported",
        "launchMode",
        "taskAffinity",
        "configChanges",
        "hardwareAccelerated",
        "windowSoftInputMode",
        "mimeType",
        "maxSdkVersion",
        "usesCleartextTraffic",
        "enableOnBackInvokedCallback",
    ];

    let mut to_add = Vec::new();
    let mut to_remove = Vec::new();
    for (key, value) in element.attributes.iter() {
        if !key.contains(':') && android_keys.contains(&key.as_str()) {
            to_remove.push(key.clone());
            to_add.push((format!("android:{key}"), value.clone()));
        }
    }
    for key in to_remove {
        element.attributes.remove(&key);
    }
    for (key, value) in to_add {
        element.attributes.insert(key, value);
    }

    for child in &mut element.children {
        if let xmltree::XMLNode::Element(child) = child {
            normalize_android_attributes(child);
        }
    }
}



fn apply_gradle_wrapper_properties(path: &Path, distribution_url: &str) -> Result<()> {
    let mut props = read_properties(path)?;
    props.insert("distributionUrl".to_string(), distribution_url.to_string());
    write_properties(path, &props)?;
    Ok(())
}

fn read_properties(path: &Path) -> Result<HashMap<String, String>> {
    if !path.exists() {
        return Ok(HashMap::new());
    }
    let file = fs::File::open(path)
        .with_context(|| format!("Failed to read file: {}", path.display()))?;
    let props = java_properties::read(std::io::BufReader::new(file))
        .with_context(|| format!("Failed to parse properties: {}", path.display()))?;
    Ok(props)
}

fn write_properties(path: &Path, props: &HashMap<String, String>) -> Result<()> {
    let file = fs::File::create(path)
        .with_context(|| format!("Failed to write file: {}", path.display()))?;
    java_properties::write(std::io::BufWriter::new(file), props)
        .with_context(|| format!("Failed to write properties: {}", path.display()))?;
    Ok(())
}

#[cfg(windows)]
mod windows_lock {
    use std::path::Path;
    use windows::core::{PCWSTR, PWSTR};
    use windows::Win32::Foundation::{ERROR_MORE_DATA, WIN32_ERROR};
    use windows::Win32::System::RestartManager::{
        RmEndSession, RmGetList, RmRegisterResources, RmStartSession, RM_PROCESS_INFO,
    };

    const CCH_RM_SESSION_KEY: usize = 32;

    fn wide_to_string(slice: &[u16]) -> String {
        let end = slice.iter().position(|c| *c == 0).unwrap_or(slice.len());
        String::from_utf16_lossy(&slice[..end])
    }

    pub fn locking_processes(path: &Path) -> Result<Vec<(u32, String)>, String> {
        let path_str = path
            .to_str()
            .ok_or_else(|| "Invalid path".to_string())?;
        let mut wide: Vec<u16> = path_str.encode_utf16().collect();
        wide.push(0);

        let mut session_handle: u32 = 0;
        let mut session_key: [u16; CCH_RM_SESSION_KEY + 1] = [0; CCH_RM_SESSION_KEY + 1];
        let start = unsafe {
            RmStartSession(
                &mut session_handle,
                Some(0),
                PWSTR(session_key.as_mut_ptr()),
            )
        };
        if start != WIN32_ERROR(0) {
            return Err(format!("RmStartSession failed: {start:?}"));
        }

        let files = [PCWSTR(wide.as_ptr())];

        let register = unsafe { RmRegisterResources(session_handle, Some(&files), None, None) };
        if register != WIN32_ERROR(0) {
            unsafe { let _ = RmEndSession(session_handle); };
            return Err(format!("RmRegisterResources failed: {register:?}"));
        }

        let mut needed: u32 = 0;
        let mut count: u32 = 0;
        let mut reason: u32 = 0;
        let mut result = unsafe {
            RmGetList(
                session_handle,
                &mut needed,
                &mut count,
                None,
                &mut reason,
            )
        };
        if result == ERROR_MORE_DATA {
            let mut infos = vec![RM_PROCESS_INFO::default(); needed as usize];
            count = needed;
            result = unsafe {
                RmGetList(
                    session_handle,
                    &mut needed,
                    &mut count,
                    Some(infos.as_mut_ptr()),
                    &mut reason,
                )
            };
            if result == WIN32_ERROR(0) {
                let list = infos
                    .iter()
                    .take(count as usize)
                    .map(|info| {
                        let pid = info.Process.dwProcessId;
                        let name = wide_to_string(&info.strAppName);
                        (pid, name)
                    })
                    .collect();
                unsafe { let _ = RmEndSession(session_handle); };
                return Ok(list);
            }
        }

        unsafe { let _ = RmEndSession(session_handle); };
        if result == WIN32_ERROR(0) {
            Ok(Vec::new())
        } else {
            Err(format!("RmGetList failed: {result:?}"))
        }
    }
}

