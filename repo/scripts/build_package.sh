#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/common.sh"

pkgbase=""
output_dir="$(repo_root)/.artifacts/packages"
makepkg_conf="$(repo_root)/repo/config/makepkg.conf"
pacman_conf=""
sign_packages=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --pkg)
      pkgbase=${2:-}
      shift 2
      ;;
    --output-dir)
      output_dir=${2:-}
      shift 2
      ;;
    --makepkg-conf)
      makepkg_conf=${2:-}
      shift 2
      ;;
    --pacman-conf)
      pacman_conf=${2:-}
      shift 2
      ;;
    --sign)
      sign_packages=1
      shift
      ;;
    *)
      die "usage: build_package.sh --pkg <pkgbase> [--output-dir <dir>] [--makepkg-conf <path>] [--pacman-conf <path>] [--sign]"
      ;;
  esac
done

[[ -n "$pkgbase" ]] || die "--pkg is required"
[[ $(id -u) -ne 0 ]] || die "build_package.sh must run as a non-root user"

require_package "$pkgbase"

pkg_dir="$(package_dir "$pkgbase")"
mkdir -p "$output_dir"
output_dir="$(cd "$output_dir" && pwd)"

build_root="$(repo_root)/.artifacts/build/$pkgbase"
mkdir -p "$build_root/build" "$build_root/log" "$build_root/pkg" "$build_root/src"

export BUILDDIR="$build_root/build"
export LOGDEST="$build_root/log"
export PKGDEST="$output_dir"
export SRCPKGDEST="$build_root/pkg"
export SRCDEST="$build_root/src"

if [[ -n "$pacman_conf" ]]; then
  export PACMAN="pacman --config $pacman_conf"
fi

command=(makepkg --syncdeps --cleanbuild --clean --noconfirm --config "$makepkg_conf")

if (( sign_packages )); then
  command+=(--sign)
fi

(
  cd "$pkg_dir"
  "${command[@]}"
)

