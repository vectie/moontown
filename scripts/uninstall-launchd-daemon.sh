#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
label="${MOONTOWN_LAUNCHD_LABEL:-com.vectie.moontown.daemon}"
plist="$root/.moontown/launchd/$label.plist"
domain="gui/$(id -u)"

launchctl bootout "$domain" "$plist" >/dev/null 2>&1 || true
"${MOON_BIN:-$HOME/.moon/bin/moon}" run cmd/main -- daemon stop || true

echo "launchd daemon stopped: $label"
