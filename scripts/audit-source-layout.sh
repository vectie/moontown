#!/bin/zsh

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"

failures=()

allowed_root_files=(
  ".gitignore"
  "AGENTS.md"
  "LICENSE"
  "README.md"
  "README.mbt.md"
  "moon.mod"
)

root_files=()
while IFS= read -r file; do
  root_files+=("${file#./}")
done < <(find . -maxdepth 1 \( -type f -o -type l \) | sort)

for file in "${root_files[@]}"; do
  allowed=false
  for allowed_file in "${allowed_root_files[@]}"; do
    if [[ "$file" == "$allowed_file" ]]; then
      allowed=true
      break
    fi
  done
  if [[ "$allowed" == false ]]; then
    failures+=("repo root contains unexpected file: $file")
  fi
done

allowed_root_dirs=(
  ".git"
  ".github"
  ".mooncakes"
  ".moonclaw"
  ".moontown"
  "_build"
  "assets"
  "docs"
  "scripts"
  "src"
)

root_dirs=()
while IFS= read -r dir; do
  root_dirs+=("${dir#./}")
done < <(find . -maxdepth 1 -type d -not -path . | sort)

for dir in "${root_dirs[@]}"; do
  allowed=false
  for allowed_dir in "${allowed_root_dirs[@]}"; do
    if [[ "$dir" == "$allowed_dir" ]]; then
      allowed=true
      break
    fi
  done
  if [[ "$allowed" == false ]]; then
    failures+=("repo root contains unexpected directory: $dir")
  fi
done

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

generated_src_dirs=()
while IFS= read -r dir; do
  generated_src_dirs+=("${dir#./}")
done < <(
  find src -type d \
    \( -name "node_modules" -o -name "_build" -o -name ".mooncakes" -o -name "dist" \) \
    -prune -print | sort
)

if (( ${#generated_src_dirs[@]} > 0 )); then
  failures+=("src contains generated/dependency directories; clean ignored artifacts before architecture review: ${generated_src_dirs[*]}")
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
