# Flutter Project Tasks

set shell := ["sh", "-c"]
set windows-shell := ["sh", "-c"]
set allow-duplicate-recipes
set allow-duplicate-variables

import 'flutter_tools/common.just'

# List all available commands
default:
    @just --list

# =============================================
# Setup & Dependencies (project-specific)
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

# =============================================
# Code Generation (project-specific extensions)
# =============================================

# Regenerate platforms and assets (use after deleting android/windows directories)
regen-platforms: gen-platforms gen-assets

# Run Dart code generation in root and all packages
codegen *ARGS:
    dart run build_runner build --delete-conflicting-outputs {{ARGS}}
    cd webfly_packages/webfly_ble && dart run build_runner build --delete-conflicting-outputs {{ARGS}}

# Build web project and copy assets to Flutter
use-cases-refresh:
    rust-script flutter_tools/web_build.rs refresh --src "contrib/webf_usecases/use_cases" --dst assets/gen/use_cases/react
    rust-script flutter_tools/web_build.rs refresh --src "contrib/webf_usecases/vue_usecases" --dst assets/gen/use_cases/vue -o dist
    sh -c 'mkdir -p assets/gen/use_cases && cp assets/use_cases/index.html assets/gen/use_cases/index.html'

# =============================================
# Code Quality (project-specific extensions)
# =============================================

# Run frontend lint + typecheck
lint-frontend:
    cd frontend && pnpm lint && pnpm tsc --noEmit

# Run the unified WebF CSS checks
webf-check-css *ARGS:
    cd frontend && pnpm -s build
    cd frontend && set -- {{ARGS}}; if [ "$1" = "--" ]; then shift; fi; rust-script scripts/check-webf-constraints.rs "$@"

# Alias for convenience
webf-check *ARGS:
    just webf-check-css {{ARGS}}

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

# Benchmark the TwoSlash type-check API latency
bench-tsc *ARGS:
    node frontend/scripts/bench-typecheck-api.mjs {{ARGS}}

# =============================================
# CI / Automation (project-specific)
# =============================================

# Run CI pipeline (Android): Deps -> Gen -> Codegen -> Analyze -> Lint -> Test -> Build APK
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
