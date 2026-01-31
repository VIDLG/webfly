# Flutter Project Tasks

# Use sh as the shell (from Git Bash or similar)
set shell := ["sh", "-c"]
set windows-shell := ["sh", "-c"]

# Load environment variables from .env
set dotenv-load

# List all available commands
default:
    @just --list

# -----------------------------
# Web frontend (Vite/React)
# -----------------------------

# Run the unified WebF CSS checks (Tailwind blacklist + CSS property whitelist).
# Usage examples:
# - just webf-check-css
# - just webf-check-css -- --scan-source
# - just webf-check-css -- --only css-props --scan-source
webf-check-css *ARGS:
    cd frontend && pnpm -s build
    cd frontend && set -- {{ARGS}}; if [ "$1" = "--" ]; then shift; fi; rust-script scripts/check-webf-constraints.rs "$@"

# Alias for convenience
webf-check *ARGS:
    just webf-check-css {{ARGS}}

# Run on Android device (auto-detects first Android device)
# Usage: just android [debug|release] [--verbose]
android MODE='debug' *FLAGS:
    DEVICE_ID=$(rust-script flutter_tools/flutter_select_device.rs --platform android); if [ -z "$DEVICE_ID" ]; then echo "No Android device found. Run: just devices" 1>&2; exit 1; fi; VERBOSE=""; if [ "{{MODE}}" = "debug" ]; then VERBOSE="--verbose"; fi; rust-script flutter_tools/cmd_run.rs --log=logs/flutter-android-{{MODE}}.log flutter run -d "$DEVICE_ID" --{{MODE}} $VERBOSE {{FLAGS}}

# Run on Windows
# Usage: just windows [debug|release] [--verbose]
windows MODE='debug' *FLAGS:
    VERBOSE=""; if [ "{{MODE}}" = "debug" ]; then VERBOSE="--verbose"; fi; rust-script flutter_tools/cmd_run.rs --log=logs/flutter-windows-{{MODE}}.log flutter run -d windows --{{MODE}} $VERBOSE {{FLAGS}}

# Generate platform configuration
gen-platforms:
    cargo run --manifest-path flutter_tools/flutter_gen_platforms/Cargo.toml -- --config app.pkl

# Generate logo variants + apply to launcher icons/splash
gen-logo:
    flutter_tools/flutter_gen_logo.py

# Generate logo variants only (without applying to launcher icons)
logo:
    flutter_tools/flutter_gen_logo.py --no-apply

# Kill processes locking Android directory
kill-android:
    rust-script flutter_tools/kill_file_handles.rs android

# Build APK (release)
# Usage: just build-apk [--verbose]
build-apk *FLAGS:
    rust-script flutter_tools/cmd_run.rs --log=logs/flutter-build.log flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols {{FLAGS}}

# Analyze Dart code for syntax and semantic issues
analyze PATH='lib test' *ARGS:
    flutter analyze {{PATH}} {{ARGS}}

# Check Flutter development environment and accept Android licenses
doctor *ARGS:
    yes | flutter doctor --android-licenses {{ARGS}}

# Bump version and regenerate platform config
# Usage: just bump-version [major|minor|patch|build]
bump-version PART:
    rust-script flutter_tools/bump_version.rs {{PART}}
    just gen-platforms
    just gen-logo

# Tag the current version in git (e.g. v1.2.3)
# Usage: just tag-version
tag-version:
    rust-script flutter_tools/git_tag_version.rs

# One-shot refresh: update web assets + regenerate platforms + regenerate logos
# Requires .env: WEB_BUILD_SRC_DIR or WEBF_USE_CASES_DIR
refresh-all:
    just use-cases-refresh
    just gen-platforms
    just gen-logo

# List all connected devices
devices *ARGS:
    flutter devices {{ARGS}}

# Run tests
test *ARGS:
    flutter test {{ARGS}}

# Format Dart code
format *ARGS:
    flutter format {{ARGS}} lib test

# Clean build artifacts
clean:
    flutter clean

# Upgrade packages to latest major versions
upgrade *ARGS:
    flutter pub upgrade --major-versions {{ARGS}}

# Build web project and copy assets to Flutter (requires .env: WEB_BUILD_SRC_DIR or WEBF_USE_CASES_DIR)
use-cases-refresh:
    flutter_tools/web_build.rs refresh --src "${WEB_BUILD_SRC_DIR:-${WEBF_USE_CASES_DIR}}" --dst assets/use_cases


