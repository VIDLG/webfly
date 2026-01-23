#!/usr/bin/env rust-script
//! ```cargo
//! [dependencies]
//! chrono = "0.4"
//! anyhow = "1.0"
//! which = "6.0"
//! ```

use anyhow::{Context, Result};
use chrono::Local;
use std::fs::{self, File};
use std::io::{BufRead, BufReader, Write};
use std::path::PathBuf;
use std::process::{Command, Stdio};
use which::which;

fn main() -> Result<()> {
    let args: Vec<String> = std::env::args().collect();

    let mut log_path: Option<PathBuf> = None;
    let mut working_dir: Option<PathBuf> = None;
    let mut cmd_args: Vec<String> = Vec::new();
    let mut command_name: Option<String> = None;

    let mut i = 1; // Skip program name
    while i < args.len() {
        if args[i].starts_with("--log=") {
            let path_str = args[i].strip_prefix("--log=").unwrap();
            log_path = Some(PathBuf::from(path_str));
        } else if args[i] == "--log" && i + 1 < args.len() {
            log_path = Some(PathBuf::from(&args[i + 1]));
            i += 1; // Skip next argument
        } else if args[i].starts_with("--cwd=") {
            let path_str = args[i].strip_prefix("--cwd=").unwrap();
            working_dir = Some(PathBuf::from(path_str));
        } else if args[i] == "--cwd" && i + 1 < args.len() {
            working_dir = Some(PathBuf::from(&args[i + 1]));
            i += 1; // Skip next argument
        } else {
            // First non-log argument is the command
            if command_name.is_none() {
                command_name = Some(args[i].clone());
            } else {
                cmd_args.push(args[i].clone());
            }
        }
        i += 1;
    }

    let command_name = command_name.ok_or_else(|| {
        anyhow::anyhow!("Usage: cmd-run [--log=FILE] [--cwd=DIR] <command> [args...]\nExample: cmd-run --log=build.log --cwd=flutter flutter build apk --release")
    })?;

    // Resolve command path
    let resolved_command = if command_name.contains(['/', '\\']) {
        PathBuf::from(&command_name)
    } else {
        which(&command_name)
            .with_context(|| format!("Command not found in PATH: {}", command_name))?
    };

    // Change to working directory if specified
    if let Some(ref cwd) = working_dir {
        std::env::set_current_dir(cwd)
            .with_context(|| format!("Failed to change directory to: {}", cwd.display()))?;
    }

    // Resolve log file path
    let log_path = log_path.map(|p| {
        if p.is_absolute() {
            p
        } else {
            std::env::current_dir().unwrap().join(p)
        }
    });

    let mut log_file_handle = if let Some(ref path) = log_path {
        // Create log directory if needed
        if let Some(parent) = path.parent() {
            fs::create_dir_all(parent)
                .with_context(|| format!("Failed to create log directory: {}", parent.display()))?;
        }

        let mut file = File::create(path)
            .with_context(|| format!("Failed to create log file: {}", path.display()))?;

        println!("Logging to: {}\n", path.display());

        // Write log header
        let timestamp = Local::now().to_rfc3339();
        let cwd = std::env::current_dir().unwrap();
        writeln!(file, "=== Command Log ===")?;
        writeln!(file, "Timestamp: {}", timestamp)?;
        writeln!(file, "Command: {} {}", command_name, cmd_args.join(" "))?;
        writeln!(file, "Working Directory: {}", cwd.display())?;
        writeln!(file, "===================\n")?;

        Some(file)
    } else {
        None
    };

    // Spawn command process
    let mut child = Command::new(&resolved_command)
        .args(&cmd_args)
        .stdin(Stdio::inherit())  // Allow stdin to be inherited for interactive commands
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()
        .with_context(|| format!("Failed to start command: {}", command_name))?;

    // Get stdout and stderr handles
    let stdout = child.stdout.take().expect("Failed to capture stdout");
    let stderr = child.stderr.take().expect("Failed to capture stderr");

    // Create threads to handle output
    let log_path_clone = log_path.clone();
    let stdout_thread = std::thread::spawn(move || {
        let reader = BufReader::new(stdout);
        let mut log_file = log_path_clone.and_then(|p| File::options().append(true).open(p).ok());

        for line in reader.lines() {
            if let Ok(line) = line {
                println!("{}", line);
                if let Some(ref mut file) = log_file {
                    let _ = writeln!(file, "{}", line);
                }
            }
        }
    });

    let log_path_clone2 = log_path.clone();
    let stderr_thread = std::thread::spawn(move || {
        let reader = BufReader::new(stderr);
        let mut log_file = log_path_clone2.and_then(|p| File::options().append(true).open(p).ok());

        for line in reader.lines() {
            if let Ok(line) = line {
                eprintln!("{}", line);
                if let Some(ref mut file) = log_file {
                    let _ = writeln!(file, "{}", line);
                }
            }
        }
    });

    // Wait for threads to finish
    stdout_thread.join().expect("stdout thread panicked");
    stderr_thread.join().expect("stderr thread panicked");

    // Wait for process to complete
    let status = child.wait().with_context(|| format!("Failed to wait for command: {}", command_name))?;
    let exit_code = status.code().unwrap_or(1);

    // Write log footer
    if let Some(ref mut file) = log_file_handle {
        writeln!(file, "\n===================")?;
        writeln!(file, "Exit code: {}", exit_code)?;
        writeln!(file, "Finished at: {}", Local::now().to_rfc3339())?;
    }

    if !status.success() {
        eprintln!("\nCommand failed with exit code {}", exit_code);
        if let Some(ref path) = log_path {
            eprintln!("Check log file: {}", path.display());
        }
        std::process::exit(exit_code);
    } else {
        println!("\n✓ Command completed successfully");
    }

    Ok(())
}
