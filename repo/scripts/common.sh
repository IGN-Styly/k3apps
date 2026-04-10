#!/usr/bin/env bash

if [[ -n "${K3APPS_COMMON_SH_SOURCED:-}" ]]; then
  return 0
fi
K3APPS_COMMON_SH_SOURCED=1

log() {
  printf '[%s] %s\n' "$(basename "$0")" "$*" >&2
}

die() {
  log "ERROR: $*"
  exit 1
}

script_dir() {
  cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd
}

repo_root() {
  cd -- "$(script_dir)/../.." && pwd
}

package_dir() {
  printf '%s/packages/%s\n' "$(repo_root)" "$1"
}

pkgbuild_path() {
  printf '%s/PKGBUILD\n' "$(package_dir "$1")"
}

srcinfo_path() {
  printf '%s/.SRCINFO\n' "$(package_dir "$1")"
}

list_package_bases() {
  local root
  root="${1:-$(repo_root)}"

  if [[ ! -d "$root/packages" ]]; then
    return 0
  fi

  find "$root/packages" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort
}

require_package() {
  local pkgbase=$1
  [[ -d "$(package_dir "$pkgbase")" ]] || die "package '$pkgbase' does not exist"
}

normalize_dep_name() {
  local dep=$1
  dep=${dep%%:*}
  dep=${dep%%[<>=]*}
  dep=${dep%% *}
  printf '%s\n' "$dep"
}

emit_srcinfo() {
  local pkgbase=$1
  local dir

  dir="$(package_dir "$pkgbase")"
  require_package "$pkgbase"

  if command -v makepkg >/dev/null 2>&1; then
    (cd "$dir" && makepkg --printsrcinfo)
    return
  fi

  [[ -f "$dir/.SRCINFO" ]] || die "package '$pkgbase' is missing .SRCINFO and makepkg is unavailable"
  cat "$dir/.SRCINFO"
}

empty_tree_oid() {
  git -C "$(repo_root)" hash-object -t tree /dev/null
}

resolve_diff_base() {
  local base=${1:-}

  if [[ -z "$base" || "$base" =~ ^0+$ ]]; then
    empty_tree_oid
    return
  fi

  if git -C "$(repo_root)" rev-parse --verify --quiet "${base}^{commit}" >/dev/null; then
    printf '%s\n' "$base"
    return
  fi

  empty_tree_oid
}

pkgver_from_srcinfo_file() {
  awk -F ' = ' '$1 == "pkgver" { print $2; exit }' "$1"
}

pkgrel_from_srcinfo_file() {
  awk -F ' = ' '$1 == "pkgrel" { print $2; exit }' "$1"
}

render_pacman_conf() {
  local output_file=$1
  local repo_path=${2:-}
  local repo_name=${3:-k3apps-local}
  local template=${4:-$(repo_root)/repo/config/pacman.conf}
  local escaped_repo_path

  mkdir -p "$(dirname "$output_file")"

  if [[ -z "$repo_path" ]]; then
    awk '/^\[@LOCAL_REPO_NAME@\]$/ { exit } { print }' "$template" > "$output_file"
    return
  fi

  escaped_repo_path=${repo_path//|/\\|}
  sed \
    -e "s|@LOCAL_REPO_PATH@|$escaped_repo_path|g" \
    -e "s|@LOCAL_REPO_NAME@|$repo_name|g" \
    "$template" > "$output_file"
}

sync_repo_aliases() {
  local repo_dir=$1
  local repo_name=$2

  if [[ -f "$repo_dir/$repo_name.db.tar.zst" ]]; then
    rm -f "$repo_dir/$repo_name.db"
    cp -f "$repo_dir/$repo_name.db.tar.zst" "$repo_dir/$repo_name.db"
  fi

  if [[ -f "$repo_dir/$repo_name.files.tar.zst" ]]; then
    rm -f "$repo_dir/$repo_name.files"
    cp -f "$repo_dir/$repo_name.files.tar.zst" "$repo_dir/$repo_name.files"
  fi

  if [[ -f "$repo_dir/$repo_name.db.tar.zst.sig" ]]; then
    rm -f "$repo_dir/$repo_name.db.sig"
    cp -f "$repo_dir/$repo_name.db.tar.zst.sig" "$repo_dir/$repo_name.db.sig"
  fi

  if [[ -f "$repo_dir/$repo_name.files.tar.zst.sig" ]]; then
    rm -f "$repo_dir/$repo_name.files.sig"
    cp -f "$repo_dir/$repo_name.files.tar.zst.sig" "$repo_dir/$repo_name.files.sig"
  fi
}
