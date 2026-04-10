#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/common.sh"

declare -a packages=("$@")
status=0

if (( ${#packages[@]} == 0 )); then
  mapfile -t packages < <(list_package_bases)
fi

for pkgbase in "${packages[@]}"; do
  require_package "$pkgbase"
  pkg_dir="$(package_dir "$pkgbase")"
  generated_srcinfo="$(mktemp)"

  if [[ ! -f "$pkg_dir/.SRCINFO" ]]; then
    log "package '$pkgbase' is missing .SRCINFO"
    rm -f "$generated_srcinfo"
    status=1
    continue
  fi

  if ! (cd "$pkg_dir" && makepkg --printsrcinfo > "$generated_srcinfo"); then
    log "unable to generate .SRCINFO for '$pkgbase'"
    rm -f "$generated_srcinfo"
    status=1
    continue
  fi

  if ! diff -u "$pkg_dir/.SRCINFO" "$generated_srcinfo"; then
    log ".SRCINFO is out of date for '$pkgbase'"
    status=1
  fi

  rm -f "$generated_srcinfo"
done

exit "$status"

