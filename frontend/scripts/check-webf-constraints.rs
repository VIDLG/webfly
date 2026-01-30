#!/usr/bin/env -S rust-script --base-path . --clear-cache

//! ```cargo
//! [dependencies]
//! anyhow = "1"
//! regex = "1"
//! walkdir = "2"
//! clap = { version = "4", features = ["derive"] }
//! ```

use anyhow::{anyhow, Context, Result};
use regex::Regex;
use std::{
    collections::{BTreeMap, BTreeSet},
    fs,
    path::{Path, PathBuf},
};
use walkdir::WalkDir;
use clap::{Parser, ValueEnum};

#[derive(Copy, Clone, Debug, PartialEq, Eq, ValueEnum)]
enum OnlyMode {
    All,
    Tailwind,
    CssProps,
}

#[derive(Parser, Debug)]
#[command(name = "check-webf-constraints")]
#[command(about = "Checks WebF constraints: Tailwind blacklist + CSS property whitelist")]
struct Cli {
    /// Only run a specific check.
    #[arg(long, value_enum, default_value = "all")]
    only: OnlyMode,

    /// Also scan source files (tsx/jsx/ts/js) for unsupported properties.
    #[arg(long, alias = "scan_source")]
    scan_source: bool,
}

fn main() -> Result<()> {
    let cli = Cli::parse();

    let cwd = std::env::current_dir().context("get current working directory")?;
    let frontend_root = locate_frontend_root(&cwd)?;
    let repo_root = frontend_root
        .parent()
        .ok_or_else(|| anyhow!("frontend root has no parent: {}", frontend_root.display()))?
        .to_path_buf();

    let mut failed = false;

    if cli.only == OnlyMode::All || cli.only == OnlyMode::Tailwind {
        if !check_tailwind_blacklist(&frontend_root)? {
            failed = true;
        }
    }

    if cli.only == OnlyMode::All || cli.only == OnlyMode::CssProps {
        if !check_css_properties_with_source_flag(&frontend_root, &repo_root, cli.scan_source)? {
            failed = true;
        }
    }

    if failed {
        std::process::exit(1);
    }

    println!("[webf-check] OK");
    Ok(())
}


// No longer needed: parse_args and print_help (clap handles this)

fn locate_frontend_root(start: &Path) -> Result<PathBuf> {
    // Typical: run from `frontend/`.
    if start.join("package.json").is_file() && start.join("scripts").is_dir() {
        return Ok(start.to_path_buf());
    }

    // If run from repo root.
    let candidate = start.join("frontend");
    if candidate.join("package.json").is_file() && candidate.join("scripts").is_dir() {
        return Ok(candidate);
    }

    // Walk up a few levels and try `frontend/`.
    let mut current = start.to_path_buf();
    for _ in 0..5 {
        if current.join("frontend").join("package.json").is_file() {
            return Ok(current.join("frontend"));
        }
        if current.join("package.json").is_file() && current.join("scripts").is_dir() {
            return Ok(current);
        }
        if !current.pop() {
            break;
        }
    }

    Err(anyhow!(
        "Could not locate frontend root from: {} (expected to find frontend/package.json)",
        start.display()
    ))
}

fn check_tailwind_blacklist(frontend_root: &Path) -> Result<bool> {
    let target_dirs = [frontend_root.join("src"), frontend_root.join("public").join("effects")];

    let forbidden: Vec<(&str, Regex)> = vec![
        ("group-hover variant", Regex::new(r"\bgroup-hover:").unwrap()),
        (
            "hover transform (scale)",
            Regex::new(r#"\bhover:scale-[^\s"']+"#).unwrap(),
        ),
        (
            "hover transform (translate)",
            Regex::new(r#"\bhover:-?translate-[^\s"']+"#).unwrap(),
        ),
        (
            "hover transform (rotate)",
            Regex::new(r#"\bhover:rotate-[^\s"']+"#).unwrap(),
        ),
        (
            "hover transform (skew)",
            Regex::new(r#"\bhover:skew-[^\s"']+"#).unwrap(),
        ),
        ("transition-all utility", Regex::new(r"\btransition-all\b").unwrap()),
    ];

    let mut hits: Vec<(String, usize, usize, String, String)> = Vec::new();

    for dir in target_dirs.iter() {
        if !dir.exists() {
            continue;
        }

        for entry in WalkDir::new(dir)
            .follow_links(false)
            .into_iter()
            .filter_map(|e| e.ok())
        {
            if entry.file_type().is_dir() {
                let name = entry.file_name().to_string_lossy();
                if name == "node_modules" || name == "dist" {
                    continue;
                }
                continue;
            }

            let path = entry.path();
            let ext = path.extension().and_then(|e| e.to_str()).unwrap_or("");
            if !matches!(ext, "ts" | "tsx" | "js" | "jsx") {
                continue;
            }

            let text = fs::read_to_string(path)
                .with_context(|| format!("read {}", path.display()))?;

            // Opt-out per-file when needed (keep rare)
            if text.contains("webf-tailwind-blacklist:disable") {
                continue;
            }

            for (name, re) in forbidden.iter() {
                for m in re.find_iter(&text) {
                    let (line, col) = line_col_from_index(&text, m.start());
                    let rel = pathdiff(&frontend_root, path);
                    hits.push((rel, line, col, name.to_string(), m.as_str().to_string()));
                    if hits.len() > 200 {
                        break;
                    }
                }
            }
        }
    }

    if hits.is_empty() {
        println!("[webf-tailwind-blacklist] OK");
        return Ok(true);
    }

    eprintln!("[webf-tailwind-blacklist] Found forbidden Tailwind patterns:");
    for (file, line, col, name, snippet) in hits.iter().take(50) {
        eprintln!("- {file}:{line}:{col}  {name}  ({snippet})");
    }
    if hits.len() > 50 {
        eprintln!("...and {} more", hits.len() - 50);
    }
    eprintln!("\nIf you really need to bypass for a file, add:");
    eprintln!("  // webf-tailwind-blacklist:disable");

    Ok(false)
}


fn check_css_properties_with_source_flag(frontend_root: &Path, repo_root: &Path, scan_source: bool) -> Result<bool> {
    let css_properties_path = repo_root.join("docs").join("css_properties.json5");
    if !css_properties_path.is_file() {
        return Err(anyhow!(
            "Missing supported property list: {}",
            css_properties_path.display()
        ));
    }

    let dist_dir = frontend_root.join("dist");
    if !dist_dir.exists() {
        eprintln!(
            "[check:webf-css-props] Missing build output at {}. Run `pnpm build` first.",
            dist_dir.display()
        );
        return Ok(false);
    }

    let supported = load_supported_properties(&css_properties_path)?;

    // 1) Source-level check (TSX/JSX): catches inline styles and Tailwind arbitrary properties.
    // This gives actionable file:line pointers without needing to reverse-map Tailwind utilities.
    let source_violations = if scan_source {
        check_css_properties_in_source(frontend_root, &supported)?
    } else {
        Vec::new()
    };

    let mut css_files = Vec::new();
    for entry in WalkDir::new(&dist_dir)
        .follow_links(false)
        .into_iter()
        .filter_map(|e| e.ok())
    {
        if !entry.file_type().is_file() {
            continue;
        }
        let p = entry.path();
        if p.extension().and_then(|e| e.to_str()) == Some("css")
            && p.file_name().and_then(|n| n.to_str()) != Some(".css.map")
        {
            css_files.push(p.to_path_buf());
        }
    }

    if css_files.is_empty() {
        eprintln!(
            "[check:webf-css-props] No CSS files found under {}. Did the build succeed?",
            dist_dir.display()
        );
        return Ok(false);
    }

    // 2) Build-output check (dist CSS): authoritative gate for all generated CSS.
    let mut violations: BTreeMap<String, BTreeSet<String>> = BTreeMap::new();

    for css_file in css_files {
        let css = fs::read_to_string(&css_file)
            .with_context(|| format!("read {}", css_file.display()))?;

        for prop in extract_decl_properties(&css) {
            if prop.starts_with("--") {
                continue;
            }
            let normalized = normalize_property(&prop);
            if supported.contains(&prop)
                || supported.contains(&normalized)
                || supported.contains(&format!("-webkit-{normalized}"))
                || supported.contains(&format!("-moz-{normalized}"))
                || supported.contains(&format!("-ms-{normalized}"))
                || supported.contains(&format!("-o-{normalized}"))
            {
                continue;
            }

            let rel = pathdiff(frontend_root, &css_file);
            violations
                .entry(rel)
                .or_default()
                .insert(format!("{prop} (normalized: {normalized})"));
        }
    }

    if violations.is_empty() {
        println!("[check:webf-css-props] OK: All CSS declarations use supported properties (plus custom properties).");
        if !source_violations.is_empty() {
            // Source-only failures (e.g. inline style) should still fail.
            print_source_violations(&source_violations);
            return Ok(false);
        }

        return Ok(true);
    }

    let mut count = 0usize;
    for (_file, props) in violations.iter() {
        count += props.len();
    }

    if !source_violations.is_empty() {
        print_source_violations(&source_violations);
    }

    eprintln!("[check:webf-css-props] Found {count} unsupported CSS properties in dist CSS (grouped by file):");

    let mut shown = 0usize;
    for (file, props) in violations.iter() {
        for prop in props.iter() {
            eprintln!("- {file} -> {prop}");
            shown += 1;
            if shown >= 30 {
                break;
            }
        }
        if shown >= 30 {
            break;
        }
    }

    Ok(false)
}

#[derive(Debug, Clone)]
struct SourceViolation {
    file: String,
    line: usize,
    col: usize,
    prop: String,
    normalized: String,
    kind: String,
}

fn print_source_violations(violations: &[SourceViolation]) {
    eprintln!(
        "[check:webf-css-props] Found {} unsupported CSS properties in source:",
        violations.len()
    );
    for v in violations.iter().take(30) {
        eprintln!(
            "- {}:{}:{}  {}  {} (normalized: {})",
            v.file, v.line, v.col, v.kind, v.prop, v.normalized
        );
    }
    if violations.len() > 30 {
        eprintln!("...and {} more", violations.len() - 30);
    }
}

fn check_css_properties_in_source(
    frontend_root: &Path,
    supported: &BTreeSet<String>,
) -> Result<Vec<SourceViolation>> {
    let target_dirs = [frontend_root.join("src"), frontend_root.join("public").join("effects")];

    let arbitrary_prop_re = Regex::new(r"\[(--?[A-Za-z][A-Za-z0-9-]*):")
        .expect("compile arbitrary property regex");

    // Matches keys at object literal top-level-ish: `{ foo: ... }` or `, foo: ...`.
    // Also supports quoted keys: `{ 'background-color': ... }`.
    let style_key_ident_re = Regex::new(r"(?m)(?:^|[,{]\s*)([A-Za-z_$][A-Za-z0-9_$]*)\s*:")
        .expect("compile style ident key regex");
    let style_key_string_re =
        Regex::new(r#"(?m)(?:^|[,{]\s*)['"]([^'"]+)['"]\s*:"#)
            .expect("compile style string key regex");

    let mut violations: Vec<SourceViolation> = Vec::new();

    for dir in target_dirs.iter() {
        if !dir.exists() {
            continue;
        }

        for entry in WalkDir::new(dir)
            .follow_links(false)
            .into_iter()
            .filter_map(|e| e.ok())
        {
            if entry.file_type().is_dir() {
                let name = entry.file_name().to_string_lossy();
                if name == "node_modules" || name == "dist" {
                    continue;
                }
                continue;
            }

            let path = entry.path();
            let ext = path.extension().and_then(|e| e.to_str()).unwrap_or("");
            if !matches!(ext, "tsx" | "jsx" | "ts" | "js") {
                continue;
            }

            let text = fs::read_to_string(path)
                .with_context(|| format!("read {}", path.display()))?;

            let rel = pathdiff(frontend_root, path);

            // Tailwind arbitrary properties: className="[mask-type:luminance] ..."
            for m in arbitrary_prop_re.captures_iter(&text) {
                let prop = m.get(1).unwrap().as_str().to_string();
                if prop.starts_with("--") {
                    continue;
                }
                let normalized = normalize_property(&prop);
                if is_supported_css_property(supported, &prop, &normalized) {
                    continue;
                }
                let idx = m.get(0).unwrap().start();
                let (line, col) = line_col_from_index(&text, idx);
                violations.push(SourceViolation {
                    file: rel.clone(),
                    line,
                    col,
                    prop,
                    normalized,
                    kind: "tailwind-arbitrary".to_string(),
                });
            }

            // Inline React styles: style={{ ... }}
            for (span_start, span_end) in find_style_object_spans(&text) {
                let slice = &text[span_start..span_end];

                // Quoted keys first (can include kebab-case)
                for caps in style_key_string_re.captures_iter(slice) {
                    let key = caps.get(1).unwrap().as_str();
                    let prop = key.to_string();
                    if prop.starts_with("--") {
                        continue;
                    }
                    let normalized = normalize_property(&prop);
                    if is_supported_css_property(supported, &prop, &normalized) {
                        continue;
                    }
                    let abs_idx = span_start + caps.get(0).unwrap().start();
                    let (line, col) = line_col_from_index(&text, abs_idx);
                    violations.push(SourceViolation {
                        file: rel.clone(),
                        line,
                        col,
                        prop,
                        normalized,
                        kind: "inline-style".to_string(),
                    });
                }

                // Identifier keys (camelCase)
                for caps in style_key_ident_re.captures_iter(slice) {
                    let key = caps.get(1).unwrap().as_str();
                    // Ignore obvious non-style object literals by requiring the attribute context.
                    // This span is already inside style={{...}}, so it's safe to treat as style keys.
                    let (prop, normalized) = css_prop_from_js_key(key);
                    if prop.starts_with("--") {
                        continue;
                    }
                    if is_supported_css_property(supported, &prop, &normalized) {
                        continue;
                    }
                    let abs_idx = span_start + caps.get(0).unwrap().start();
                    let (line, col) = line_col_from_index(&text, abs_idx);
                    violations.push(SourceViolation {
                        file: rel.clone(),
                        line,
                        col,
                        prop,
                        normalized,
                        kind: "inline-style".to_string(),
                    });
                }
            }
        }
    }

    Ok(violations)
}

fn is_supported_css_property(supported: &BTreeSet<String>, prop: &str, normalized: &str) -> bool {
    if supported.contains(prop) || supported.contains(normalized) {
        return true;
    }

    // If the supported list contains vendor-prefixed variants, accept them too.
    for prefix in ["-webkit-", "-moz-", "-ms-", "-o-"] {
        let candidate = format!("{prefix}{normalized}");
        if supported.contains(&candidate) {
            return true;
        }
    }

    false
}

fn css_prop_from_js_key(key: &str) -> (String, String) {
    // Handle React CSSProperties vendor keys.
    // Common patterns:
    // - WebkitTapHighlightColor -> -webkit-tap-highlight-color
    // - MozOsxFontSmoothing -> -moz-osx-font-smoothing
    // - msOverflowStyle -> -ms-overflow-style
    let (prop, normalized) = if let Some(rest) = key.strip_prefix("Webkit") {
        let kebab = camel_to_kebab(rest);
        let prop = format!("-webkit-{kebab}");
        (prop.clone(), normalize_property(&prop))
    } else if let Some(rest) = key.strip_prefix("Moz") {
        let kebab = camel_to_kebab(rest);
        let prop = format!("-moz-{kebab}");
        (prop.clone(), normalize_property(&prop))
    } else if key.starts_with("ms") && key.len() > 2 {
        // Keep "ms" lowercase prefix.
        let rest = &key[2..];
        let kebab = camel_to_kebab(rest);
        let prop = format!("-ms-{kebab}");
        (prop.clone(), normalize_property(&prop))
    } else if let Some(rest) = key.strip_prefix('O') {
        let kebab = camel_to_kebab(rest);
        let prop = format!("-o-{kebab}");
        (prop.clone(), normalize_property(&prop))
    } else {
        let kebab = camel_to_kebab(key);
        let prop = kebab.clone();
        (prop, normalize_property(&kebab))
    };

    (prop, normalized)
}

fn camel_to_kebab(s: &str) -> String {
    let mut out = String::with_capacity(s.len() + 4);
    for (i, ch) in s.chars().enumerate() {
        if ch.is_ascii_uppercase() {
            if i != 0 {
                out.push('-');
            }
            out.push(ch.to_ascii_lowercase());
        } else {
            out.push(ch);
        }
    }
    out
}

fn find_style_object_spans(text: &str) -> Vec<(usize, usize)> {
    // Find spans inside `style={{ ... }}`.
    // We return the slice bounds of the object literal content (between the inner braces).
    let mut spans = Vec::new();
    let needle = "style={{";
    let mut search_from = 0usize;

    while let Some(found) = text[search_from..].find(needle) {
        let start = search_from + found + needle.len();
        // We are right after the inner `{`.
        let mut i = start;
        let bytes = text.as_bytes();

        let mut depth: i32 = 1; // inner object
        let mut in_single = false;
        let mut in_double = false;
        let mut in_template = false;
        let mut escape = false;

        while i < bytes.len() {
            let ch = bytes[i] as char;
            if escape {
                escape = false;
                i += 1;
                continue;
            }

            match ch {
                '\\' => {
                    escape = true;
                }
                '\'' if !in_double && !in_template => {
                    in_single = !in_single;
                }
                '"' if !in_single && !in_template => {
                    in_double = !in_double;
                }
                '`' if !in_single && !in_double => {
                    in_template = !in_template;
                }
                '{' if !in_single && !in_double && !in_template => {
                    depth += 1;
                }
                '}' if !in_single && !in_double && !in_template => {
                    depth -= 1;
                    if depth == 0 {
                        // span is [start, i)
                        spans.push((start, i));
                        i += 1;
                        break;
                    }
                }
                _ => {}
            }

            i += 1;
        }

        search_from = i.max(start + 1);
    }

    spans
}

fn load_supported_properties(path: &Path) -> Result<BTreeSet<String>> {
    let raw = fs::read_to_string(path).with_context(|| format!("read {}", path.display()))?;

    // Match both single and double quotes.
    // e.g. name: "background-color",
    //      name: '-webkit-font-smoothing',
    let re = Regex::new(r#"(?m)^\s*name:\s*(?:"([^"]+)"|'([^']+)')\s*,?\s*$"#).unwrap();

    let mut supported = BTreeSet::new();
    for caps in re.captures_iter(&raw) {
        let name = caps.get(1).or_else(|| caps.get(2)).unwrap().as_str();
        supported.insert(name.to_string());
    }

    if supported.is_empty() {
        return Err(anyhow!(
            "Failed to extract any supported property names from: {}",
            path.display()
        ));
    }

    Ok(supported)
}

fn normalize_property(prop: &str) -> String {
    if prop.starts_with("--") {
        return prop.to_string();
    }

    for prefix in ["-webkit-", "-moz-", "-ms-", "-o-"] {
        if let Some(rest) = prop.strip_prefix(prefix) {
            return rest.to_string();
        }
    }

    prop.to_string()
}

fn line_col_from_index(text: &str, index: usize) -> (usize, usize) {
    let mut line = 1usize;
    let mut last_line_start = 0usize;

    for (i, ch) in text.char_indices() {
        if i >= index {
            break;
        }
        if ch == '\n' {
            line += 1;
            last_line_start = i + 1;
        }
    }

    let col = text[index..]
        .char_indices()
        .next()
        .map(|_| index - last_line_start + 1)
        .unwrap_or(1);

    (line, col)
}

fn pathdiff(root: &Path, file: &Path) -> String {
    let rel = file.strip_prefix(root).unwrap_or(file);
    rel.to_string_lossy().replace('\\', "/")
}

/// Extract declaration property names from CSS text.
///
/// This intentionally uses a lightweight parser (no full CSS parsing).
/// It scans each innermost `{ ... }` block and then extracts `prop:` tokens,
/// skipping strings and nested parentheses so `data:` in URLs won't be mistaken
/// as a property.
fn extract_decl_properties(css: &str) -> BTreeSet<String> {
    let mut props = BTreeSet::new();

    // Find all innermost blocks via a brace stack.
    let mut stack: Vec<usize> = Vec::new();
    let mut in_single = false;
    let mut in_double = false;
    let mut escape = false;

    for (i, ch) in css.char_indices() {
        if escape {
            escape = false;
            continue;
        }

        match ch {
            '\\' => {
                escape = true;
            }
            '\'' if !in_double => {
                in_single = !in_single;
            }
            '"' if !in_single => {
                in_double = !in_double;
            }
            '{' if !in_single && !in_double => {
                stack.push(i);
            }
            '}' if !in_single && !in_double => {
                if let Some(start) = stack.pop() {
                    let block = &css[start + 1..i];
                    extract_properties_from_block(block, &mut props);
                }
            }
            _ => {}
        }
    }

    props
}

fn extract_properties_from_block(block: &str, props: &mut BTreeSet<String>) {
    // State machine that extracts `prop:` where `:` is not inside quotes/paren.
    let mut i = 0usize;
    let bytes = block.as_bytes();

    while i < bytes.len() {
        // Skip whitespace and separators
        while i < bytes.len() {
            let c = bytes[i] as char;
            if c.is_whitespace() || c == ';' {
                i += 1;
            } else {
                break;
            }
        }
        if i >= bytes.len() {
            break;
        }

        // Parse property name
        let prop_start = i;
        while i < bytes.len() {
            let c = bytes[i] as char;
            if c.is_ascii_alphanumeric() || c == '-' || c == '_' {
                i += 1;
                continue;
            }
            break;
        }

        if i == prop_start {
            // Not a declaration start; advance one char.
            i += 1;
            continue;
        }

        // Skip whitespace
        while i < bytes.len() && (bytes[i] as char).is_whitespace() {
            i += 1;
        }

        if i >= bytes.len() || bytes[i] as char != ':' {
            // Not a declaration; keep searching.
            continue;
        }

        let prop = block[prop_start..i].trim().to_string();
        i += 1; // skip ':'

        // Consume value until ';' or end of block, respecting quotes/paren.
        let mut in_single = false;
        let mut in_double = false;
        let mut escape = false;
        let mut paren_depth = 0i32;

        while i < bytes.len() {
            let c = bytes[i] as char;
            if escape {
                escape = false;
                i += 1;
                continue;
            }

            match c {
                '\\' => {
                    escape = true;
                    i += 1;
                }
                '\'' if !in_double => {
                    in_single = !in_single;
                    i += 1;
                }
                '"' if !in_single => {
                    in_double = !in_double;
                    i += 1;
                }
                '(' if !in_single && !in_double => {
                    paren_depth += 1;
                    i += 1;
                }
                ')' if !in_single && !in_double => {
                    if paren_depth > 0 {
                        paren_depth -= 1;
                    }
                    i += 1;
                }
                ';' if !in_single && !in_double && paren_depth == 0 => {
                    i += 1;
                    break;
                }
                _ => {
                    i += 1;
                }
            }
        }

        if !prop.is_empty() {
            props.insert(prop);
        }
    }
}
