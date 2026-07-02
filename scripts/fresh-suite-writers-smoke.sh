#!/bin/zsh

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
moon_bin="${MOON_BIN:-/Users/kq/.moon/bin/moon}"
moonbook_root="${MOONTOWN_MOONBOOK_ROOT:-/Users/kq/Workspace/moonbook}"
root="$(mktemp -d "${TMPDIR:-/tmp}/moontown-fresh-suite-writers.XXXXXX")"

cleanup() {
  rm -rf "$root"
}
trap cleanup EXIT

mkdir -p "$root/.moonsuite" "$root/.tmp" "$root/books"

run_moontown() {
  MOON="$moon_bin" \
  MOONTOWN_SUITE_ROOT="$root" \
  MOONTOWN_MOONBOOK_ROOT="$moonbook_root" \
    "$moon_bin" run src/cmd/main --target native -- "$@"
}

assert_file() {
  local path="$1"
  if [[ ! -f "$path" ]]; then
    echo "expected file missing: $path" >&2
    exit 1
  fi
}

assert_dir_absent() {
  local path="$1"
  if [[ -e "$path" ]]; then
    echo "legacy path should not exist: $path" >&2
    exit 1
  fi
}

cd "$repo_root"

run_moontown planbook bootstrap >/dev/null
run_moontown course wenyu-game-design bootstrap >/dev/null
run_moontown cookbook bootstrap >/dev/null
run_moontown books doctor >/dev/null
run_moontown live refresh >/dev/null

assert_file "$root/.moonsuite/products/moontown/moonbooks.json"
assert_file "$root/.moonsuite/products/moontown/book-quality/audit.json"
assert_file "$root/.moonsuite/products/moontown/book-quality/audit.md"
assert_file "$root/.moonsuite/products/moontown/live-autonomy.json"
assert_file "$root/books/plan-moontown-quality/wiki/index.md"
assert_file "$root/books/plan-moontown-quality/raw/bootstrap/PLANBOOK_CONTRACT.md"
assert_file "$root/books/course-wenyu-game-design/wiki/index.md"
assert_file "$root/books/course-wenyu-game-design/book/moonbook-ui-state.json"
assert_file "$root/books/moontown-cookbook/wiki/index.md"
assert_file "$root/books/moontown-cookbook/book/moonbook-ui-state.json"

assert_dir_absent "$repo_root/books/plan-moontown-quality"
assert_dir_absent "$repo_root/books/course-wenyu-game-design"
assert_dir_absent "$repo_root/books/moontown-cookbook"
assert_dir_absent "$root/.moontown"
assert_dir_absent "$root/.moonclaw"
assert_dir_absent "$root/moonclaw-jobs"

echo "Moontown fresh-suite writers smoke passed on $root"
