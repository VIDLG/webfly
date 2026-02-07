# Flutter Project Tasks

# Use sh as the shell (from Git Bash or similar)
set shell := ["sh", "-c"]
set windows-shell := ["sh", "-c"]

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

# Generate all image assets (branding first, then logos with launcher icons/splash)
gen-assets:
    uv run --script flutter_tools/flutter_gen_branding.py
    uv run --script flutter_tools/flutter_gen_logo.py

# Generate logo variants + apply to launcher icons/splash
gen-logo:
    uv run --script flutter_tools/flutter_gen_logo.py

# Generate logo variants only (without applying to launcher icons)
logo:
    uv run --script flutter_tools/flutter_gen_logo.py --no-apply

# Generate branding images (light and dark theme)
gen-branding:
    uv run --script flutter_tools/flutter_gen_branding.py

# Kill processes locking Android directory
kill-android:
    rust-script flutter_tools/kill_file_handles.rs android

# Build APK (release)
# Usage: just build-apk [--verbose]
build-apk *FLAGS:
    rust-script flutter_tools/cmd_run.rs --log=logs/flutter-build.log flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols {{FLAGS}}

# Install and run the built release APK on Android (skips build)
install-apk:
    DEVICE_ID=$(rust-script flutter_tools/flutter_select_device.rs --platform android); if [ -z "$DEVICE_ID" ]; then echo "No Android device found." 1>&2; exit 1; fi; flutter run -d "$DEVICE_ID" --release --use-application-binary=build/app/outputs/flutter-apk/app-release.apk

# Run Dart code generation (e.g. json_serializable for lib/native/ble/dto.dart)
# Usage: just codegen [--watch]
codegen *ARGS:
    dart run build_runner build --delete-conflicting-outputs {{ARGS}}

# Analyze Dart code for syntax and semantic issues
analyze PATH='lib test' *ARGS:
    flutter analyze {{PATH}} {{ARGS}}

# Check Flutter development environment and accept Android licenses
doctor *ARGS:
    yes | flutter doctor --android-licenses {{ARGS}}

# Bump version
# Usage: just bump-version [major|minor|patch|build]
bump-version PART:
    rust-script flutter_tools/bump_version.rs {{PART}}

# Tag the current version in git (e.g. v1.2.3)
# Usage: just tag-version [-f|--force]
tag-version *FLAGS:
    rust-script flutter_tools/git_tag_version.rs {{FLAGS}}


# -----------------------------
# CI / Automation
# -----------------------------

# Run CI pipeline (Android): Deps -> Gen -> Codegen -> Analyze -> Test -> Build APK
# Usage: just ci  (self-contained: runs pub get first)
ci:
    just update
    just use-cases-refresh
    just gen-platforms
    just gen-assets
    just codegen
    just format-check
    just analyze
    just test
    just build-apk

# List all connected devices
devices *ARGS:
    flutter devices {{ARGS}}

# Run tests
test *ARGS:
    flutter test {{ARGS}}

# Format Dart code
format *ARGS:
    dart format {{ARGS}} lib test

# Check that lib/ and test/ are formatted (CI gate)
format-check:
    dart format --set-exit-if-changed lib test

# Clean build artifacts
clean:
    flutter clean

update:
    flutter pub get

# Upgrade packages to latest major versions
upgrade *ARGS:
    flutter pub upgrade --major-versions {{ARGS}}

# Build web project and copy assets to Flutter
use-cases-refresh:
    rust-script flutter_tools/web_build.rs refresh --src "contrib/webf_usecases/use_cases" --dst assets/gen/use_cases/react
    rust-script flutter_tools/web_build.rs refresh --src "contrib/webf_usecases/vue_usecases" --dst assets/gen/use_cases/vue -o dist
    sh -c 'mkdir -p assets/gen/use_cases && cp assets/use_cases/index.html assets/gen/use_cases/index.html'




