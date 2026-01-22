#!/usr/bin/env rust-script
//! ```cargo
//! [dependencies]
//! windows = { version = "0.59", features = ["Win32_Foundation", "Win32_System_Threading"] }
//! clap = { version = "4.5", features = ["derive"] }
//! ```

use clap::Parser;
use std::collections::HashMap;
use std::path::Path;
use std::process::Command;
use windows::Win32::Foundation::CloseHandle;
use windows::Win32::System::Threading::{OpenProcess, TerminateProcess, PROCESS_TERMINATE};

#[derive(Parser)]
#[command(name = "kill-file-handles")]
#[command(about = "Find and terminate processes using a file or directory", long_about = None)]
struct Args {
    /// File or directory path to check
    path: String,

    /// List processes without killing them
    #[arg(short, long)]
    list_only: bool,
}

fn main() {
    let args = Args::parse();

    let path = Path::new(&args.path);
    let path = match path.canonicalize() {
        Ok(p) => p,
        Err(e) => {
            eprintln!("Failed to resolve path: {}", e);
            std::process::exit(1);
        }
    };

    println!("Finding processes using: {}", path.display());

    let processes = match find_locking_processes_via_handle(&path) {
        Ok(procs) => procs,
        Err(e) => {
            eprintln!("Failed to find processes: {}", e);
            std::process::exit(1);
        }
    };

    if processes.is_empty() {
        println!("No processes found using this path.");
        return;
    }

    let mut sorted: Vec<_> = processes.into_iter().collect();
    sorted.sort_by_key(|(pid, _)| *pid);

    println!("\nFound {} process(es):", sorted.len());
    for (i, (pid, name)) in sorted.iter().enumerate() {
        println!("  {}. PID: {} - {}", i + 1, pid, name);
    }

    if args.list_only {
        println!("\n(List only mode, not killing processes)");
        return;
    }

    println!("\nTerminating processes...");
    for (pid, name) in sorted {
        match kill_process(pid) {
            Ok(_) => println!("  Terminated: {} (PID: {})", name, pid),
            Err(e) => eprintln!("  Failed to terminate PID {}: {}", pid, e),
        }
    }
    println!("\nDone!");
}

fn find_locking_processes_via_handle(path: &Path) -> Result<HashMap<u32, String>, String> {
    let handle_exe = find_handle_exe().ok_or("handle.exe not found. Please install Sysinternals Suite")?;

    // Remove \\?\ prefix (Windows extended path prefix)
    let path_str = path.to_str().ok_or("Path contains invalid characters")?;
    let path_str = path_str.strip_prefix(r"\\?\").unwrap_or(path_str);

    let output = Command::new(&handle_exe)
        .arg("-accepteula")
        .arg(path_str)
        .output()
        .map_err(|e| format!("Failed to run handle.exe: {}", e))?;

    let stdout = String::from_utf8_lossy(&output.stdout);
    parse_handle_output(&stdout)
}

fn find_handle_exe() -> Option<String> {
    if Command::new("handle.exe").arg("-?").output().is_ok() {
        return Some("handle.exe".to_string());
    }

    let common_paths = [
        r"C:\Program Files\Sysinternals Suite\handle.exe",
        r"C:\Tools\Sysinternals\handle.exe",
        r"C:\Sysinternals\handle.exe",
    ];

    for path in &common_paths {
        if Path::new(path).exists() {
            return Some(path.to_string());
        }
    }

    None
}

fn parse_handle_output(output: &str) -> Result<HashMap<u32, String>, String> {
    let mut processes = HashMap::new();
    let lines: Vec<&str> = output.lines().collect();

    for line in &lines {
        if line.trim().is_empty() {
            continue;
        }

        // Skip header lines
        if line.contains("Nthandle") || line.contains("Copyright") || line.contains("Sysinternals") {
            continue;
        }

        // Find lines with "pid:"
        if let Some(pid_start) = line.find("pid:") {
            let after_pid = &line[pid_start + 4..];
            let pid_str: String = after_pid
                .trim_start()
                .chars()
                .take_while(|c| c.is_ascii_digit())
                .collect();

            if let Ok(pid) = pid_str.parse::<u32>() {
                // Extract process name (part before pid)
                let process_name = line[..pid_start]
                    .trim()
                    .split_whitespace()
                    .next()
                    .unwrap_or("Unknown");

                processes.insert(pid, process_name.to_string());
            }
        }
    }

    Ok(processes)
}

fn kill_process(pid: u32) -> Result<(), String> {
    unsafe {
        let handle = OpenProcess(PROCESS_TERMINATE, false, pid)
            .map_err(|e| format!("Failed to open process: {}", e))?;

        let result = TerminateProcess(handle, 1);
        let _ = CloseHandle(handle);

        result.map_err(|e| format!("Failed to terminate: {}", e))
    }
}
