#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
label="${MOONTOWN_LAUNCHD_LABEL:-com.vectie.moontown.daemon}"
moon_bin="${MOON_BIN:-$HOME/.moon/bin/moon}"
plist_dir="$root/.moontown/launchd"
plist="$plist_dir/$label.plist"
domain="gui/$(id -u)"

mkdir -p "$plist_dir" "$root/.moontown"

cat > "$plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$label</string>
  <key>ProgramArguments</key>
  <array>
    <string>$moon_bin</string>
    <string>run</string>
    <string>cmd/main</string>
    <string>--</string>
    <string>daemon</string>
    <string>supervise</string>
    <string>--worker</string>
  </array>
  <key>WorkingDirectory</key>
  <string>$root</string>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
  <key>ThrottleInterval</key>
  <integer>30</integer>
  <key>StandardOutPath</key>
  <string>$root/.moontown/launchd.out.log</string>
  <key>StandardErrorPath</key>
  <string>$root/.moontown/launchd.err.log</string>
  <key>EnvironmentVariables</key>
  <dict>
    <key>HOME</key>
    <string>$HOME</string>
    <key>MOON_BIN</key>
    <string>$moon_bin</string>
    <key>MOONTOWN_ROOT</key>
    <string>$root</string>
    <key>PATH</key>
    <string>$HOME/.moon/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
  </dict>
</dict>
</plist>
PLIST

plutil -lint "$plist"
launchctl bootout "$domain" "$plist" >/dev/null 2>&1 || true
launchctl bootstrap "$domain" "$plist"
launchctl kickstart -k "$domain/$label"
launchctl print "$domain/$label" | sed -n '1,80p'

echo "launchd plist: $plist"
echo "logs: $root/.moontown/launchd.out.log $root/.moontown/launchd.err.log"
