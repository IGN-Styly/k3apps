#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/common.sh"

base_ref=""
head_ref="HEAD"
select_all=0
include_dependents=0
run_verify_srcinfo=0
run_lint=0
enforce_version_bump=0
output_dir="$(repo_root)/.artifacts/packages"
local_repo_root="$(repo_root)/.artifacts/localrepo"
local_repo_name="k3apps-local"
arch="x86_64"
sign_packages=0
declare -a requested_packages=()
declare -a changed_packages=()

version_sensitive_paths() {
  local pkgbase=$1
  printf '%s\n' \
    "packages/$pkgbase/PKGBUILD" \
    "packages/$pkgbase/.SRCINFO" \
    "packages/$pkgbase/upstream" \
    "packages/$pkgbase/patches" \
    "packages/$pkgbase/files"
}

check_version_bump() {
  local pkgbase=$1
  local resolved_base=$2
  local old_srcinfo
  local new_srcinfo
  local old_pkgver
  local old_pkgrel
  local new_pkgver
  local new_pkgrel

  if git -C "$(repo_root)" diff --quiet "$resolved_base" "$head_ref" -- $(version_sensitive_paths "$pkgbase"); then
    return 0
  fi

  if ! git -C "$(repo_root)" cat-file -e "$resolved_base:packages/$pkgbase/.SRCINFO" 2>/dev/null; then
    return 0
  fi

  old_srcinfo="$(mktemp)"
  new_srcinfo="$(mktemp)"

  git -C "$(repo_root)" show "$resolved_base:packages/$pkgbase/.SRCINFO" > "$old_srcinfo"
  (cd "$(package_dir "$pkgbase")" && makepkg --printsrcinfo > "$new_srcinfo")

  old_pkgver="$(pkgver_from_srcinfo_file "$old_srcinfo")"
  old_pkgrel="$(pkgrel_from_srcinfo_file "$old_srcinfo")"
  new_pkgver="$(pkgver_from_srcinfo_file "$new_srcinfo")"
  new_pkgrel="$(pkgrel_from_srcinfo_file "$new_srcinfo")"

  rm -f "$old_srcinfo" "$new_srcinfo"

  if [[ "$old_pkgver" == "$new_pkgver" && "$old_pkgrel" == "$new_pkgrel" ]]; then
    die "package '$pkgbase' changed without a pkgver/pkgrel bump"
  fi
}

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
      select_all=1
      shift
      ;;
    --include-dependents)
      include_dependents=1
      shift
      ;;
    --verify-srcinfo)
      run_verify_srcinfo=1
      shift
      ;;
    --lint)
      run_lint=1
      shift
      ;;
    --enforce-version-bump)
      enforce_version_bump=1
      shift
      ;;
    --output-dir)
      output_dir=${2:-}
      shift 2
      ;;
    --repo-dir)
      local_repo_root=${2:-}
      shift 2
      ;;
    --repo-name)
      local_repo_name=${2:-}
      shift 2
      ;;
    --arch)
      arch=${2:-}
      shift 2
      ;;
    --sign)
      sign_packages=1
      shift
      ;;
    -*)
      die "usage: build_changed.sh [--base <ref>] [--head <ref>] [--all] [--include-dependents] [--verify-srcinfo] [--lint] [--enforce-version-bump] [--output-dir <dir>] [pkgbase ...]"
      ;;
    *)
      requested_packages+=("$1")
      shift
      ;;
  esac
done

mkdir -p "$output_dir"
mkdir -p "$local_repo_root/$arch"

output_dir="$(cd "$output_dir" && pwd)"
local_repo_dir="$(cd "$local_repo_root/$arch" && pwd)"
generated_pacman_conf="$(repo_root)/.artifacts/pacman.$local_repo_name.conf"
render_pacman_conf "$generated_pacman_conf" "" "$local_repo_name"

if (( select_all )); then
  mapfile -t changed_packages < <(list_package_bases)
elif (( ${#requested_packages[@]} > 0 )); then
  changed_packages=("${requested_packages[@]}")
else
  [[ -n "$base_ref" ]] || die "--base is required when no package list is provided"
  mapfile -t changed_packages < <("$(repo_root)/repo/scripts/detect_changed_packages.sh" --base "$base_ref" --head "$head_ref")
fi

if (( ${#changed_packages[@]} == 0 )); then
  log "no packages selected"
  exit 0
fi

declare -A changed_set=()
for pkgbase in "${changed_packages[@]}"; do
  require_package "$pkgbase"
  changed_set["$pkgbase"]=1
done

resolve_args=()
if (( select_all )); then
  resolve_args+=(--all)
else
  resolve_args+=("${changed_packages[@]}")
fi

if (( include_dependents )); then
  resolve_args=(--include-dependents "${resolve_args[@]}")
fi

mapfile -t ordered_packages < <("$(repo_root)/repo/scripts/resolve_build_order.sh" "${resolve_args[@]}")

if (( ${#ordered_packages[@]} == 0 )); then
  log "no packages resolved for build"
  exit 0
fi

resolved_base="$(resolve_diff_base "$base_ref")"
local_repo_db="$local_repo_dir/$local_repo_name.db.tar.zst"

for pkgbase in "${ordered_packages[@]}"; do
  log "building '$pkgbase'"

  if (( run_verify_srcinfo )); then
    "$(repo_root)/repo/scripts/verify_srcinfo.sh" "$pkgbase"
  fi

  if (( enforce_version_bump )) && [[ -n "${changed_set[$pkgbase]:-}" ]]; then
    check_version_bump "$pkgbase" "$resolved_base"
  fi

  if (( run_lint )); then
    namcap "$(pkgbuild_path "$pkgbase")"
  fi

  build_stamp="$(mktemp)"
  touch "$build_stamp"

  build_args=(
    --pkg "$pkgbase"
    --output-dir "$output_dir"
    --makepkg-conf "$(repo_root)/repo/config/makepkg.conf"
    --pacman-conf "$generated_pacman_conf"
  )

  if (( sign_packages )); then
    build_args+=(--sign)
  fi

  "$(repo_root)/repo/scripts/build_package.sh" "${build_args[@]}"

  mapfile -t new_pkgfiles < <(find "$output_dir" -maxdepth 1 -type f -name '*.pkg.tar.*' ! -name '*.sig' -newer "$build_stamp" | sort)
  rm -f "$build_stamp"

  if (( ${#new_pkgfiles[@]} == 0 )); then
    die "package '$pkgbase' did not produce any package artifacts"
  fi

  repo-add "$local_repo_db" "${new_pkgfiles[@]}"
  sync_repo_aliases "$local_repo_dir" "$local_repo_name"
  render_pacman_conf "$generated_pacman_conf" "$local_repo_dir" "$local_repo_name"
done
