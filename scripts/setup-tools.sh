#!/usr/bin/env sh
# Install pixi + pkl for the webfly project, then run pixi install.
# Supports Linux, macOS, and Windows (Git Bash / MSYS2).
#
# Version overrides via env vars:
#   PKL_VERSION=0.29.1  sh scripts/setup-tools.sh
set -e

PKL_VERSION="${PKL_VERSION:-0.29.1}"
OS="$(uname -s)"
ARCH="$(uname -m)"

# ---------------------------------------------------------------------------
# pixi — cross-platform package manager (prefix.dev)
# ---------------------------------------------------------------------------
install_pixi() {
  case "$OS" in
    MINGW*|MSYS*)
      if command -v scoop >/dev/null 2>&1; then scoop install pixi; return $?; fi
      echo "ERROR: Install scoop (https://scoop.sh) or pixi manually: https://pixi.sh" >&2; return 1 ;;
    Darwin*)
      if command -v brew >/dev/null 2>&1; then brew install pixi; return $?; fi
      curl -fsSL https://pixi.sh/install.sh | sh ;;
    *)
      curl -fsSL https://pixi.sh/install.sh | sh ;;
  esac
}

# ---------------------------------------------------------------------------
# pkl — Apple configuration language CLI (not on conda-forge)
# ---------------------------------------------------------------------------
install_pkl() {
  case "$OS-$ARCH" in
    Linux-x86_64)   SUFFIX=pkl-linux-amd64 ;;
    Linux-aarch64)  SUFFIX=pkl-linux-aarch64 ;;
    Darwin-x86_64)  SUFFIX=pkl-macos-amd64 ;;
    Darwin-arm64)   SUFFIX=pkl-macos-aarch64 ;;
    MINGW*|MSYS*)
      if command -v scoop >/dev/null 2>&1; then scoop install pkl; return $?; fi
      echo "ERROR: Install scoop (https://scoop.sh) or pkl manually." >&2; return 1 ;;
    *) echo "ERROR: Unsupported platform ($OS-$ARCH). Install pkl manually: https://pkl-lang.org" >&2; return 1 ;;
  esac
  mkdir -p ~/.local/bin
  curl -fSL -o ~/.local/bin/pkl "https://github.com/apple/pkl/releases/download/${PKL_VERSION}/$SUFFIX"
  chmod +x ~/.local/bin/pkl
  echo "   installed pkl $PKL_VERSION -> ~/.local/bin/pkl"
}

# ---------------------------------------------------------------------------
# jadx — Android APK/DEX decompiler (local-only, not for CI)
# ---------------------------------------------------------------------------
install_jadx() {
  case "$OS" in
    MINGW*|MSYS*)
      if command -v scoop >/dev/null 2>&1; then scoop install jadx; return $?; fi
      echo "ERROR: Install scoop (https://scoop.sh) or jadx manually." >&2; return 1 ;;
    Darwin*)
      if command -v brew >/dev/null 2>&1; then brew install jadx; return $?; fi
      echo "ERROR: Install Homebrew or jadx manually." >&2; return 1 ;;
    Linux*)
      if command -v snap >/dev/null 2>&1; then sudo snap install jadx; return $?; fi
      echo "ERROR: Install jadx manually: https://github.com/skylot/jadx" >&2; return 1 ;;
  esac
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
TOOLS="pixi pkl"
# Local-only tools: skipped in CI
if [ -z "$CI" ]; then
  TOOLS="$TOOLS jadx"
fi
failed=""

for tool in $TOOLS; do
  cmd="$tool"
  if command -v "$cmd" >/dev/null 2>&1; then
    printf "OK  %-16s %s\n" "$cmd" "$(command -v "$cmd")"
  else
    printf "=>  Installing %s ...\n" "$cmd"
    case "$cmd" in
      pixi) install_pixi || failed="$failed $cmd" ;;
      pkl)  install_pkl  || failed="$failed $cmd" ;;
      jadx) install_jadx || failed="$failed $cmd" ;;
    esac
  fi
done

echo ""
if [ -n "$failed" ]; then
  echo "FAILED:$failed" >&2
  echo "Install them manually and retry." >&2
  exit 1
fi

# Install all pixi-managed tools and packages
echo "=> Running pixi install..."
pixi install
echo ""
echo "All tools OK."
