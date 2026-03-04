#!/usr/bin/env sh
# Check that all required dev tools for the webfly project are available.
# Pixi-managed tools are verified via `pixi run`; only system tools and
# pixi itself are checked directly. LOCAL_ONLY tools are skipped when $CI is set.
set -e

TOOLS="flutter dart pixi pkl"
LOCAL_ONLY="jadx"

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

for tool in $LOCAL_ONLY; do
  if [ -n "$CI" ]; then
    continue
  fi
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
