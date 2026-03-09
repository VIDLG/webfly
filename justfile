# Flutter Project Tasks

set shell := ["sh", "-c"]
set windows-shell := ["sh", "-c"]
set allow-duplicate-recipes
set allow-duplicate-variables
set dotenv-load

import 'flutter_tools/common.just'

# Override tool prefixes: all external tools go through pixi
_tool_prefix := "pixi run"
_py := "pixi run python"

# Compile-time defines injected into local flutter run / build commands.
# GITHUB_TOKEN is loaded from .env via dotenv-load. NOT for CI — tokens
# baked into release APKs can be extracted and are a security risk.
_dart_defines := if env('CI', '') == '' { if env('GITHUB_TOKEN', '') != '' { '--dart-define=GITHUB_TOKEN=' + env('GITHUB_TOKEN', '') } else { '' } } else { '' }

# List all available commands
default:
    @just --list

# =============================================
# Development (override common.just to inject dart-defines)
# =============================================

# Run on Android device
android MODE='debug' *FLAGS:
    DEVICE_ID=$({{_tool_prefix}} rust-script flutter_tools/flutter_select_device.rs --platform android); if [ -z "$DEVICE_ID" ]; then echo "No Android device found. Run: just devices" 1>&2; exit 1; fi; VERBOSE=""; if [ "{{MODE}}" = "debug" ]; then VERBOSE="--verbose"; fi; {{_tool_prefix}} rust-script flutter_tools/cmd_run.rs --log=logs/flutter-android-{{MODE}}.log flutter run -d "$DEVICE_ID" --{{MODE}} $VERBOSE {{_dart_defines}} {{FLAGS}}

# Run on Windows
windows MODE='debug' *FLAGS:
    VERBOSE=""; if [ "{{MODE}}" = "debug" ]; then VERBOSE="--verbose"; fi; {{_tool_prefix}} rust-script flutter_tools/cmd_run.rs --log=logs/flutter-windows-{{MODE}}.log flutter run -d windows --{{MODE}} $VERBOSE {{_dart_defines}} {{FLAGS}}

# Build APK (release with obfuscation)
build-apk *FLAGS:
    {{_tool_prefix}} rust-script flutter_tools/cmd_run.rs --log=logs/flutter-build.log flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols {{_dart_defines}} {{FLAGS}}

# =============================================
# Setup & Dependencies (project-specific)
# =============================================

# Setup dev environment (one command for new developers)
# 1. Install tools & deps  2. Generate platforms & assets  3. Keystore & hooks
setup:
    just setup-tools
    flutter pub get
    cd frontend && pnpm install
    just gen-platforms
    just gen-assets
    just generate
    just use-cases-refresh
    if [ -z "$CI" ]; then {{_tool_prefix}} lefthook install || true; fi
    if [ -z "$CI" ] && [ -n "$KEYSTORE_PASSWORD" ]; then just gen-android-keystore; fi

# Install pixi, pkl, and run pixi install (+jadx locally)
setup-tools:
    sh scripts/setup-tools.sh

# Check that all required dev tools are available
check-tools:
    sh scripts/check-tools.sh

# =============================================
# Code Generation (project-specific extensions)
# =============================================

# Regenerate platforms and assets (use after deleting android/windows directories)
regen-platforms: gen-platforms gen-assets

# Run Dart code generation in root and all packages
generate *ARGS:
    dart run build_runner build --delete-conflicting-outputs {{ARGS}}
    cd webfly_packages/webfly_ble && dart run build_runner build --delete-conflicting-outputs {{ARGS}}

# Build web project and copy assets to Flutter
use-cases-refresh:
    {{_tool_prefix}} rust-script flutter_tools/web_build.rs refresh --src "contrib/webf_usecases/use_cases" --dst assets/gen/use_cases/react
    {{_tool_prefix}} rust-script flutter_tools/web_build.rs refresh --src "contrib/webf_usecases/vue_usecases" --dst assets/gen/use_cases/vue -o dist
    sh -c 'mkdir -p assets/gen/use_cases && cp assets/use_cases/index.html assets/gen/use_cases/index.html'

# =============================================
# Code Quality (project-specific extensions)
# =============================================

# Run all static checks (format + analyze + frontend lint/typecheck)
lint:
    just format-check
    just analyze
    cd frontend && pnpm lint && pnpm tsc --noEmit

# Run the unified WebF CSS checks
webf-check *ARGS:
    cd frontend && pnpm -s build
    cd frontend && set -- {{ARGS}}; if [ "$1" = "--" ]; then shift; fi; {{_tool_prefix}} rust-script scripts/check-webf-constraints.rs "$@"

# =============================================
# Testing (project-specific extensions)
# =============================================

# Run frontend tests
test-frontend *ARGS:
    cd frontend && pnpm test {{ARGS}}

# Run all tests (Flutter + frontend)
test-all *ARGS:
    flutter test {{ARGS}}
    cd frontend && pnpm test {{ARGS}}

# Compile LED effects to self-contained plain JS (for mquickjs on MCU)
# Usage: just compile-effects [target] [--outdir <dir>]
#   target: es6 (default), es5, es2020, etc.
compile-effects TARGET='es6' *ARGS:
    cd frontend && node scripts/compile-effects.mjs --target {{TARGET}} {{ARGS}}

# Benchmark the TwoSlash type-check API latency
bench-tsc *ARGS:
    node frontend/scripts/bench-typecheck-api.mjs {{ARGS}}

# =============================================
# CI / Automation (project-specific)
# =============================================

# Run CI pipeline (Android): Setup -> Lint -> Test -> Build APK
ci:
    just setup
    just lint
    just test-all
    just build-apk
