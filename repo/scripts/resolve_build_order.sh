#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/common.sh"

include_dependents=0
select_all=0
declare -a requested_packages=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --all)
      select_all=1
      shift
      ;;
    --include-dependents)
      include_dependents=1
      shift
      ;;
    -*)
      die "usage: resolve_build_order.sh [--all] [--include-dependents] [pkgbase ...]"
      ;;
    *)
      requested_packages+=("$1")
      shift
      ;;
  esac
done

mapfile -t all_packages < <(list_package_bases)

if (( ${#all_packages[@]} == 0 )); then
  exit 0
fi

if (( select_all )); then
  requested_packages=("${all_packages[@]}")
fi

if (( ${#requested_packages[@]} == 0 )); then
  die "at least one package must be provided unless --all is used"
fi

declare -A package_exists=()
declare -A pkgname_to_pkgbase=()
declare -A deps_of=()
declare -A reverse_of=()

for pkgbase in "${all_packages[@]}"; do
  package_exists["$pkgbase"]=1
done

for pkgbase in "${requested_packages[@]}"; do
  [[ -n "${package_exists[$pkgbase]:-}" ]] || die "unknown package '$pkgbase'"
done

for pkgbase in "${all_packages[@]}"; do
  while IFS= read -r line; do
    case "$line" in
      "pkgname = "*)
        pkgname_to_pkgbase["${line#pkgname = }"]=$pkgbase
        ;;
      "pkgbase = "*)
        pkgname_to_pkgbase["${line#pkgbase = }"]=$pkgbase
        ;;
    esac
  done < <(emit_srcinfo "$pkgbase")
done

for pkgbase in "${all_packages[@]}"; do
  declare -A pkg_deps=()

  while IFS= read -r line; do
    case "$line" in
      "depends = "*|"makedepends = "*|"checkdepends = "*)
        dep_name="$(normalize_dep_name "${line#*= }")"
        dep_pkgbase="${pkgname_to_pkgbase[$dep_name]:-}"
        if [[ -n "$dep_pkgbase" && "$dep_pkgbase" != "$pkgbase" ]]; then
          pkg_deps["$dep_pkgbase"]=1
        fi
        ;;
    esac
  done < <(emit_srcinfo "$pkgbase")

  deps_of["$pkgbase"]="${!pkg_deps[*]}"

  for dep_pkgbase in "${!pkg_deps[@]}"; do
    reverse_of["$dep_pkgbase"]+="$pkgbase "
  done

  unset pkg_deps
done

declare -A target_packages=()

for pkgbase in "${requested_packages[@]}"; do
  target_packages["$pkgbase"]=1
done

if (( include_dependents )); then
  queue=("${requested_packages[@]}")
  index=0

  while (( index < ${#queue[@]} )); do
    current_pkg=${queue[$index]}
    (( index += 1 ))

    for dependent_pkg in ${reverse_of[$current_pkg]:-}; do
      if [[ -z "${target_packages[$dependent_pkg]:-}" ]]; then
        target_packages["$dependent_pkg"]=1
        queue+=("$dependent_pkg")
      fi
    done
  done
fi

queue=("${!target_packages[@]}")
index=0

while (( index < ${#queue[@]} )); do
  current_pkg=${queue[$index]}
  (( index += 1 ))

  for dep_pkgbase in ${deps_of[$current_pkg]:-}; do
    if [[ -z "${target_packages[$dep_pkgbase]:-}" ]]; then
      target_packages["$dep_pkgbase"]=1
      queue+=("$dep_pkgbase")
    fi
  done
done

mapfile -t ordered_target_packages < <(printf '%s\n' "${!target_packages[@]}" | sort)

tsort_input="$(mktemp)"
trap 'rm -f "$tsort_input"' EXIT

for pkgbase in "${ordered_target_packages[@]}"; do
  dep_count=0

  for dep_pkgbase in ${deps_of[$pkgbase]:-}; do
    if [[ -n "${target_packages[$dep_pkgbase]:-}" ]]; then
      printf '%s %s\n' "$dep_pkgbase" "$pkgbase" >> "$tsort_input"
      (( dep_count += 1 ))
    fi
  done

  if (( dep_count == 0 )); then
    printf '%s\n' "$pkgbase" >> "$tsort_input"
  fi
done

if ! tsort "$tsort_input"; then
  die "cyclic internal package dependency detected"
fi

