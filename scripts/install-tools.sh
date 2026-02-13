#!/usr/bin/env sh
# Install small dev tools (pkl, uv, patch-package) for the webfly project.
# Supports Linux, macOS, and Windows (Git Bash / MSYS2).
#
# Version overrides via env vars:
#   PKL_VERSION=0.29.1  sh scripts/install-tools.sh
set -e

PKL_VERSION="${PKL_VERSION:-0.29.1}"
OS="$(uname -s)"
ARCH="$(uname -m)"

# ---------------------------------------------------------------------------
# pkl — Apple configuration language CLI
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
# uv — fast Python package runner (astral.sh)
# ---------------------------------------------------------------------------
install_uv() {
  case "$OS" in
    MINGW*|MSYS*) powershell -c "irm https://astral.sh/uv/install.ps1 | iex" ;;
    *)            curl -LsSf https://astral.sh/uv/install.sh | sh ;;
  esac
}

# ---------------------------------------------------------------------------
# patch-package — npm tool for patching node_modules
# ---------------------------------------------------------------------------
install_patch_package() {
  npm install -g patch-package
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
TOOLS="pkl uv patch-package"
failed=""

for tool in $TOOLS; do
  cmd="$tool"
  # patch-package binary is named patch-package
  if command -v "$cmd" >/dev/null 2>&1; then
    printf "OK  %-16s %s\n" "$cmd" "$(command -v "$cmd")"
  else
    printf "=>  Installing %s ...\n" "$cmd"
    case "$cmd" in
      pkl)           install_pkl           || failed="$failed $cmd" ;;
      uv)            install_uv            || failed="$failed $cmd" ;;
      patch-package) install_patch_package || failed="$failed $cmd" ;;
    esac
  fi
done

echo ""
if [ -n "$failed" ]; then
  echo "FAILED:$failed" >&2
  echo "Install them manually and retry." >&2
  exit 1
fi
echo "All tools OK."
