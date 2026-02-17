# Flutter Project Tasks

# Use sh as the shell (from Git Bash or similar)
set shell := ["sh", "-c"]
set windows-shell := ["sh", "-c"]

# List all available commands
default:
    @just --list

# =============================================
# Setup & Dependencies
# =============================================

# Install dependencies and configure hooks
update:
    just install-tools
    flutter pub get
    if [ -z "$CI" ]; then command -v lefthook >/dev/null 2>&1 && lefthook install || true; fi

# Install small dev tools (pkl, uv, patch-package)
install-tools:
    sh scripts/install-tools.sh

# Check that all required dev tools are available
check-tools:
    sh scripts/check-tools.sh

# Upgrade packages to latest major versions
upgrade *ARGS:
    flutter pub upgrade --major-versions {{ARGS}}

# Clean build artifacts
clean:
    flutter clean

# Check Flutter development environment and accept Android licenses
doctor *ARGS:
    yes | flutter doctor --android-licenses {{ARGS}}

# =============================================
# Development
# =============================================

# Run on Android device (auto-detects first Android device)
# Usage: just android [debug|release] [--verbose]
android MODE='debug' *FLAGS:
    DEVICE_ID=$(rust-script flutter_tools/flutter_select_device.rs --platform android); if [ -z "$DEVICE_ID" ]; then echo "No Android device found. Run: just devices" 1>&2; exit 1; fi; VERBOSE=""; if [ "{{MODE}}" = "debug" ]; then VERBOSE="--verbose"; fi; rust-script flutter_tools/cmd_run.rs --log=logs/flutter-android-{{MODE}}.log flutter run -d "$DEVICE_ID" --{{MODE}} $VERBOSE {{FLAGS}}

# Run on Windows
# Usage: just windows [debug|release] [--verbose]
windows MODE='debug' *FLAGS:
    VERBOSE=""; if [ "{{MODE}}" = "debug" ]; then VERBOSE="--verbose"; fi; rust-script flutter_tools/cmd_run.rs --log=logs/flutter-windows-{{MODE}}.log flutter run -d windows --{{MODE}} $VERBOSE {{FLAGS}}

# List all connected devices
devices *ARGS:
    flutter devices {{ARGS}}

# Kill processes locking Android directory
kill-android:
    rust-script flutter_tools/kill_file_handles.rs android

# Install and run the built release APK on Android (skips build)
install-apk:
    DEVICE_ID=$(rust-script flutter_tools/flutter_select_device.rs --platform android); if [ -z "$DEVICE_ID" ]; then echo "No Android device found." 1>&2; exit 1; fi; flutter run -d "$DEVICE_ID" --release --use-application-binary=build/app/outputs/flutter-apk/app-release.apk

# =============================================
# Code Generation & Assets
# =============================================

# Generate platform configuration
gen-platforms:
    cargo run --manifest-path flutter_tools/flutter_gen_platforms/Cargo.toml -- --config app.pkl

# Regenerate platforms and assets (use after deleting android/windows directories)
regen-platforms: gen-platforms gen-assets

# Generate Android release keystore from key.properties
gen-android-keystore *FLAGS:
    rust-script flutter_tools/gen_android_keystore.rs {{FLAGS}}

# Print GitHub Actions secrets needed for CI signing
show-secrets:
    #!/usr/bin/env sh
    set -e
    PROPS="platforms/android/key.properties"
    if [ ! -f "$PROPS" ]; then echo "Error: $PROPS not found" >&2; exit 1; fi
    if [ ! -f "platforms/android/keystore.jks" ]; then echo "Error: keystore.jks not found" >&2; exit 1; fi
    get() { grep "^$1=" "$PROPS" | cut -d= -f2-; }
    echo "=== GitHub Actions Secrets ==="
    echo ""
    echo "KEYSTORE_BASE64:"
    base64 -w 0 platforms/android/keystore.jks && echo
    echo ""
    echo "KEYSTORE_PASSWORD:"
    get storePassword
    echo ""
    echo "KEY_PASSWORD:"
    get keyPassword
    echo ""

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

# Run Dart code generation in root and all packages (e.g. webfly_ble dto/options).
# Usage: just codegen [--watch]
codegen *ARGS:
    dart run build_runner build --delete-conflicting-outputs {{ARGS}}
    cd webfly_packages/webfly_ble && dart run build_runner build --delete-conflicting-outputs {{ARGS}}

# Build web project and copy assets to Flutter
use-cases-refresh:
    rust-script flutter_tools/web_build.rs refresh --src "contrib/webf_usecases/use_cases" --dst assets/gen/use_cases/react
    rust-script flutter_tools/web_build.rs refresh --src "contrib/webf_usecases/vue_usecases" --dst assets/gen/use_cases/vue -o dist
    sh -c 'mkdir -p assets/gen/use_cases && cp assets/use_cases/index.html assets/gen/use_cases/index.html'

# =============================================
# Code Quality
# =============================================

# Analyze Dart code for syntax and semantic issues
analyze PATH='lib test' *ARGS:
    flutter analyze {{PATH}} {{ARGS}}

# Run static analysis (flutter analyze)
lint *ARGS:
    flutter analyze {{ARGS}}

# Format Dart code
format *ARGS:
    dart format {{ARGS}} lib test

# Check that lib/ and test/ are formatted (CI gate)
format-check:
    dart format --set-exit-if-changed lib test

# Run the unified WebF CSS checks (Tailwind blacklist + CSS property whitelist).
# Usage: just webf-check-css [-- --scan-source] [-- --only css-props --scan-source]
webf-check-css *ARGS:
    cd frontend && pnpm -s build
    cd frontend && set -- {{ARGS}}; if [ "$1" = "--" ]; then shift; fi; rust-script scripts/check-webf-constraints.rs "$@"

# Alias for convenience
webf-check *ARGS:
    just webf-check-css {{ARGS}}

# =============================================
# Testing
# =============================================

# Run tests (Flutter + frontend)
test *ARGS:
    flutter test {{ARGS}}
    cd frontend && pnpm test

# Benchmark the TwoSlash type-check API latency
# Usage: just bench-tsc [-n 10] [-f frontend/public/effects/wave/effect.ts]
bench-tsc *ARGS:
    node frontend/scripts/bench-typecheck-api.mjs {{ARGS}}

# =============================================
# Build & Release
# =============================================

# Build APK (release)
# Usage: just build-apk [--verbose]
build-apk *FLAGS:
    rust-script flutter_tools/cmd_run.rs --log=logs/flutter-build.log flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols {{FLAGS}}

# Bump version
# Usage: just bump-version [major|minor|patch|build|revert]
bump-version PART *FLAGS:
    rust-script flutter_tools/bump_version.rs {{PART}} {{FLAGS}}

# Tag the current version in git (e.g. v1.2.3)
# Usage: just tag-version [-f|--force]
tag-version *FLAGS:
    rust-script flutter_tools/git_tag_version.rs {{FLAGS}}

# Generate changelog from git log using Claude AI
# Usage: just gen-changelog [--tag v0.8.2] [--output changelog.md]
gen-changelog *FLAGS:
    rust-script flutter_tools/gen_changelog.rs {{FLAGS}}

# Bump version, commit, tag, and push to trigger CI release
# Usage: just release [major|minor|patch]
release PART='patch':
    just format
    just bump-version {{PART}}
    git add pubspec.yaml && git commit -m "bump version to $(grep '^version:' pubspec.yaml | awk '{print $2}')"
    just tag-version
    git push && git push --tags

# =============================================
# CI / Automation
# =============================================

# Run CI pipeline (Android): Deps -> Gen -> Codegen -> Analyze -> Lint -> Test -> Build APK
# Usage: just ci  (self-contained: runs pub get first)
ci:
    just update
    just use-cases-refresh
    just gen-android-keystore
    just gen-platforms
    just gen-assets
    just codegen
    just format-check
    just analyze
    just lint
    just test
    just build-apk

# Trigger CI workflow on a branch
trigger-ci REF='main':
    gh workflow run release.yaml --ref {{REF}}

# Re-run the last failed CI workflow on GitHub
rerun-ci:
    gh run list --workflow=release.yaml --limit 1 --json databaseId --jq '.[0].databaseId' | xargs gh run rerun --failed

# Watch the latest CI run (streaming logs)
watch-ci:
    gh run watch "$(gh run list --workflow=release.yaml --limit 1 --json databaseId --jq '.[0].databaseId')" --exit-status

# View logs of the latest CI run (--log-failed for failures only)
logs-ci *ARGS:
    gh run view "$(gh run list --workflow=release.yaml --limit 1 --json databaseId --jq '.[0].databaseId')" --log {{ARGS}}
