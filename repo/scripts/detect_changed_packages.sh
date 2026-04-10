#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/common.sh"

base_ref=""
head_ref="HEAD"
all_packages=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base)
      base_ref=${2:-}
      shift 2
      ;;
    --head)
      head_ref=${2:-}
      shift 2
      ;;
    --all)
      all_packages=1
      shift
      ;;
    *)
      die "usage: detect_changed_packages.sh [--all] [--base <ref>] [--head <ref>]"
      ;;
  esac
done

if (( all_packages )); then
  list_package_bases
  exit 0
fi

[[ -n "$base_ref" ]] || die "--base is required unless --all is used"

root="$(repo_root)"
resolved_base="$(resolve_diff_base "$base_ref")"

if ! git -C "$root" rev-parse --verify --quiet "${head_ref}^{commit}" >/dev/null; then
  die "unable to resolve head ref '$head_ref'"
fi

mapfile -t changed_paths < <(git -C "$root" diff --name-only "$resolved_base" "$head_ref")

if (( ${#changed_paths[@]} == 0 )); then
  exit 0
fi

for path in "${changed_paths[@]}"; do
  if [[ "$path" == repo/* || "$path" == .github/workflows/* || "$path" == Makefile ]]; then
    list_package_bases
    exit 0
  fi
done

declare -A seen_packages=()

for path in "${changed_paths[@]}"; do
  [[ "$path" == packages/* ]] || continue

  pkgbase=${path#packages/}
  pkgbase=${pkgbase%%/*}

  if [[ -n "$pkgbase" && -d "$(package_dir "$pkgbase")" ]]; then
    seen_packages["$pkgbase"]=1
  fi
done

if (( ${#seen_packages[@]} == 0 )); then
  exit 0
fi

printf '%s\n' "${!seen_packages[@]}" | sort

