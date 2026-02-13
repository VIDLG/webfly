#!/usr/bin/env sh
# Check that all required dev tools for the webfly project are available.
set -e

TOOLS="flutter dart rustup cargo rust-script just pkl node pnpm uv gh lefthook patch-package"

ok=0; fail=0

echo "Checking project tools..."
for tool in $TOOLS; do
  if command -v "$tool" >/dev/null 2>&1; then
    printf "  OK   %-16s %s\n" "$tool" "$(command -v "$tool")"
    ok=$((ok + 1))
  else
    printf "  MISS %-16s\n" "$tool"
    fail=$((fail + 1))
  fi
done

echo ""
echo "$ok found, $fail missing."
[ "$fail" -eq 0 ] || exit 1
