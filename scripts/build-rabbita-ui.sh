#!/bin/zsh

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
ui_dir="$repo_root/src/ui/rabbita-town"

cd "$repo_root"

moon -C "$repo_root/src/ui/landmark-studio" build --target js --release
cd "$repo_root"
moon run scripts/assemble-landmark-studio.mbtx
moon run scripts/rebuild-wenyu-bank.mbtx

echo "[rabbita] formatting MoonBit UI package"
moon -C "$ui_dir" fmt main

echo "[rabbita] checking MoonBit UI package"
moon -C "$ui_dir" check main

echo "[rabbita] updating package interface"
moon -C "$ui_dir" info main

echo "[rabbita] compiling MoonBit browser entry"
moon -C "$ui_dir" build --target js --release

echo "[rabbita] assembling deterministic static product"
node "$ui_dir/scripts/assemble-production-build.mjs"

echo "[rabbita] verifying static product"
node "$ui_dir/scripts/verify-production-build.mjs"
moon run scripts/compile-future-center-site.mbtx -- --check-pack
moon run scripts/verify-science-city-studies.mbtx

echo "[rabbita] build complete"
