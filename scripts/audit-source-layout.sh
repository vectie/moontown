#!/bin/zsh

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"

failures=()

if [[ -f "moon.pkg" ]]; then
  failures+=("repo root must not contain moon.pkg; keep implementation packages under src/")
fi

root_source_files=()
while IFS= read -r file; do
  root_source_files+=("$file")
done < <(
  find . -maxdepth 1 -type f \
    \( -name "*.mbt" -o -name "*.js" -o -name "*.ts" -o -name "*.tsx" -o -name "*.css" \) \
    -print | sort
)

if (( ${#root_source_files[@]} > 0 )); then
  failures+=("repo root contains implementation-like source files: ${root_source_files[*]}")
fi

allowed_src_root_files=(
  "src/facade.mbt"
  "src/moon.pkg"
  "src/pkg.generated.mbti"
)

src_root_files=()
while IFS= read -r file; do
  src_root_files+=("${file#./}")
done < <(find src -maxdepth 1 -type f -print | sort)

for file in "${src_root_files[@]}"; do
  allowed=false
  for allowed_file in "${allowed_src_root_files[@]}"; do
    if [[ "$file" == "$allowed_file" ]]; then
      allowed=true
      break
    fi
  done
  if [[ "$allowed" == false ]]; then
    failures+=("src root contains non-facade file: $file")
  fi
done

civic_salon_runtime_files=()
while IFS= read -r file; do
  civic_salon_runtime_files+=("${file#./}")
done < <(
  find src/civic_runtime -maxdepth 1 -type f \
    \( -name "civic_salon_*.mbt" -o -name "civic_protocol_salon_*.mbt" \) \
    -print | sort
)

if (( ${#civic_salon_runtime_files[@]} > 0 )); then
  failures+=("civic runtime contains salon-specific implementation filenames: ${civic_salon_runtime_files[*]}")
fi

if (( ${#failures[@]} > 0 )); then
  print "source layout audit failed:"
  for failure in "${failures[@]}"; do
    print "- $failure"
  done
  exit 1
fi

print "source layout audit passed"
