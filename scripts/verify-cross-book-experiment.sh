#!/usr/bin/env bash
# Cwd-independent exact production contract checks. Host/UI/provider coverage
# is separate; the companion fixtures are never represented as executed here.
set -euo pipefail
SOURCE=$(cd "$(dirname "$0")/.." && pwd)
OUTPUT=${1:-"$(dirname "$SOURCE")/collective-verification"}
bash "$SOURCE/scripts/verify-idea-salon-contract.sh" "$OUTPUT"
