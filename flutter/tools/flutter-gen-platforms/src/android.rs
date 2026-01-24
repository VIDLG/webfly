use anyhow::{Context, Result};
use android_manifest::{AndroidManifest, StringResourceOrString, UsesPermission, VarOrBool};
use std::collections::HashMap;
use std::fs;
use std::path::Path;
use xmltree::{Element, EmitterConfig};

use crate::config::{AndroidConfig, AndroidManifestConfig, AndroidUsesPermission};

pub fn apply_repositories(path: &Path, repos: &[String]) -> Result<()> {
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

pub fn apply_plugin_repositories(path: &Path, repos: &[String]) -> Result<()> {
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

pub fn apply_app_gradle(
    path: &Path,
    namespace: &str,
    application_id: &str,
    output_file_name: Option<&str>,
    abi_filters: Option<&[String]>,
    kotlin_incremental: Option<bool>,
) -> Result<()> {
    let content = fs::read_to_string(path)
        .with_context(|| format!("Failed to read file: {}", path.display()))?;
    let mut out = Vec::new();
    let mut in_build_types = false;
    let mut in_default_config = false;
    let mut in_kotlin_options = false;
    let mut added_output_config = false;
    let mut added_abi_filters = false;
    let mut added_kotlin_incremental = false;

    for line in content.lines() {
        if line.trim_start().starts_with("namespace = ") {
            out.push(format!("    namespace = \"{}\"", namespace));
        } else if line.trim_start().starts_with("applicationId = ") {
            out.push(format!("        applicationId = \"{}\"", application_id));
        } else {
            out.push(line.to_string());
        }

        if line.trim().starts_with("kotlinOptions {") {
            in_kotlin_options = true;
        }

        if in_kotlin_options && line.trim() == "}" && !added_kotlin_incremental {
            in_kotlin_options = false;
            if let Some(false) = kotlin_incremental {
                out.push(String::new());
                out.push("    // 禁用 Kotlin 增量编译以避免跨盘符路径问题".to_string());
                out.push("    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile> {".to_string());
                out.push("        incremental = false".to_string());
                out.push("    }".to_string());
                added_kotlin_incremental = true;
            }
        }

        if line.trim().starts_with("defaultConfig {") {
            in_default_config = true;
        }

        if in_default_config && line.trim() == "}" && !added_abi_filters {
            if let Some(abis) = abi_filters {
                if !abis.is_empty() {
                    out.insert(out.len() - 1, format!("        ndk {{"));
                    for abi in abis {
                        out.insert(out.len() - 1, format!("            abiFilters.add(\"{}\")", abi));
                    }
                    out.insert(out.len() - 1, format!("        }}"));
                }
            }
            in_default_config = false;
            added_abi_filters = true;
        }

        if line.trim().starts_with("buildTypes {") {
            in_build_types = true;
        }

        if in_build_types && line.trim() == "}" && !added_output_config {
            in_build_types = false;
            if let Some(filename_pattern) = output_file_name {
                out.push(String::new());
                out.push("    applicationVariants.all {".to_string());
                out.push("        outputs.all {".to_string());
                out.push("            val output = this as com.android.build.gradle.internal.api.BaseVariantOutputImpl".to_string());
                out.push(format!("            output.outputFileName = \"{}\"", filename_pattern));
                out.push("        }".to_string());
                out.push("    }".to_string());
                added_output_config = true;
            }
        }
    }
    fs::write(path, out.join("\n") + "\n")
        .with_context(|| format!("Failed to write file: {}", path.display()))?;
    Ok(())
}

pub fn apply_manifest(path: &Path, cfg: &AndroidManifestConfig) -> Result<()> {
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

pub fn apply_gradle_wrapper_properties(path: &Path, distribution_url: &str) -> Result<()> {
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

pub fn process_android_platform(
    project_dir: &Path,
    config: &AndroidConfig,
) -> Result<()> {
    let android_dir = project_dir.join("android");

    apply_repositories(
        &android_dir.join("build.gradle.kts"),
        &config.build.allprojects.repositories,
    )?;
    apply_plugin_repositories(
        &android_dir.join("settings.gradle.kts"),
        &config.settings.plugin_management.repositories,
    )?;
    apply_app_gradle(
        &android_dir.join("app/build.gradle.kts"),
        &config.app.build.namespace,
        &config.app.build.application_id,
        config.app.build.output_file_name.as_deref(),
        config.app.build.abi_filters.as_deref(),
        config.app.build.kotlin_incremental,
    )?;
    apply_manifest(
        &android_dir.join("app/src/main/AndroidManifest.xml"),
        &config.app.manifest.main,
    )?;
    if let Some(debug) = config.app.manifest.debug.as_ref() {
        apply_manifest(&android_dir.join("app/src/debug/AndroidManifest.xml"), debug)?;
    }
    if let Some(profile) = config.app.manifest.profile.as_ref() {
        apply_manifest(&android_dir.join("app/src/profile/AndroidManifest.xml"), profile)?;
    }
    if let Some(distribution_url) = &config.gradle_wrapper.distribution_url {
        apply_gradle_wrapper_properties(
            &android_dir.join("gradle/wrapper/gradle-wrapper.properties"),
            distribution_url,
        )?;
    }

    println!("Android directory generated at: {}", android_dir.display());
    Ok(())
}
