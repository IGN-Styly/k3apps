#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/common.sh"

artifacts_dir="$(repo_root)/.artifacts/packages"
pages_dir=""
repo_name="k3apps"
arch="x86_64"
clean_publish=0
max_file_size_bytes="${GITHUB_PAGES_MAX_FILE_SIZE_BYTES:-0}"

package_name_from_file() {
  bsdtar -xOf "$1" .PKGINFO | awk -F ' = ' '$1 == "pkgname" { print $2; exit }'
}

detach_sign() {
  local file_path=$1
  local key_id=${ARCH_REPO_GPG_KEY_ID:-}
  local passphrase=${ARCH_REPO_GPG_PASSPHRASE:-}
  local sign_command

  [[ -n "$key_id" ]] || die "ARCH_REPO_GPG_KEY_ID is not set"

  sign_command=(gpg --batch --yes --local-user "$key_id")
  if [[ -n "$passphrase" ]]; then
    sign_command+=(--pinentry-mode loopback --passphrase "$passphrase")
  fi

  rm -f "$file_path.sig"
  "${sign_command[@]}" --detach-sign "$file_path"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --artifacts-dir)
      artifacts_dir=${2:-}
      shift 2
      ;;
    --pages-dir)
      pages_dir=${2:-}
      shift 2
      ;;
    --repo-name)
      repo_name=${2:-}
      shift 2
      ;;
    --arch)
      arch=${2:-}
      shift 2
      ;;
    --clean)
      clean_publish=1
      shift
      ;;
    *)
      die "usage: publish_repo.sh --pages-dir <dir> [--artifacts-dir <dir>] [--repo-name <name>] [--arch <arch>] [--clean]"
      ;;
  esac
done

[[ -n "$pages_dir" ]] || die "--pages-dir is required"

mkdir -p "$pages_dir/$arch"
artifacts_dir="$(cd "$artifacts_dir" && pwd)"
arch_dir="$(cd "$pages_dir/$arch" && pwd)"
repo_db="$arch_dir/$repo_name.db.tar.zst"
repo_files="$arch_dir/$repo_name.files.tar.zst"
warning_file="$arch_dir/PUBLISH-WARNINGS.txt"

if (( clean_publish )); then
  find "$arch_dir" -maxdepth 1 -type f \
    \( -name '*.pkg.tar.*' -o -name '*.pkg.tar.*.sig' -o -name "$repo_name.db*" -o -name "$repo_name.files*" \) \
    -delete
fi

mapfile -t built_pkgfiles < <(find "$artifacts_dir" -maxdepth 1 -type f -name '*.pkg.tar.*' ! -name '*.sig' | sort)
declare -a skipped_pkgfiles=()

for pkgfile in "${built_pkgfiles[@]}"; do
  if (( max_file_size_bytes > 0 )); then
    pkgfile_size="$(stat -c '%s' "$pkgfile")"
    if (( pkgfile_size > max_file_size_bytes )); then
      log "skipping '$pkgfile' because it exceeds the configured publish limit (${pkgfile_size} > ${max_file_size_bytes})"
      skipped_pkgfiles+=("$pkgfile")
      continue
    fi
  fi

  pkgname="$(package_name_from_file "$pkgfile")"

  while IFS= read -r existing_pkg; do
    [[ -n "$existing_pkg" ]] || continue

    if [[ "$(package_name_from_file "$existing_pkg")" == "$pkgname" ]]; then
      rm -f "$existing_pkg" "$existing_pkg.sig"
    fi
  done < <(find "$arch_dir" -maxdepth 1 -type f -name '*.pkg.tar.*' ! -name '*.sig' | sort)

  if [[ -n "${ARCH_REPO_GPG_KEY_ID:-}" ]]; then
    detach_sign "$pkgfile"
  fi

  cp -f "$pkgfile" "$arch_dir/"
  if [[ -f "$pkgfile.sig" ]]; then
    cp -f "$pkgfile.sig" "$arch_dir/"
  fi
done

if (( ${#skipped_pkgfiles[@]} > 0 )); then
  {
    printf 'The following package files were skipped during publish because they exceed the configured GitHub Pages push limit (%s bytes).\n\n' "$max_file_size_bytes"
    for skipped_pkgfile in "${skipped_pkgfiles[@]}"; do
      printf '%s\t%s bytes\n' "$(basename "$skipped_pkgfile")" "$(stat -c '%s' "$skipped_pkgfile")"
    done
  } > "$warning_file"
else
  rm -f "$warning_file"
fi

rm -f "$repo_db" "$repo_db.sig" "$arch_dir/$repo_name.db" "$arch_dir/$repo_name.db.sig"
rm -f "$repo_files" "$repo_files.sig" "$arch_dir/$repo_name.files" "$arch_dir/$repo_name.files.sig"
rm -f "$repo_db.old" "$repo_files.old"

mapfile -t published_pkgfiles < <(find "$arch_dir" -maxdepth 1 -type f -name '*.pkg.tar.*' ! -name '*.sig' | sort)

if (( ${#published_pkgfiles[@]} > 0 )); then
  if [[ -n "${ARCH_REPO_GPG_KEY_ID:-}" ]]; then
    if ! repo-add -s -k "${ARCH_REPO_GPG_KEY_ID}" "$repo_db" "${published_pkgfiles[@]}"; then
      log "repo-add signing failed, retrying unsigned and signing database artifacts directly"
      rm -f "$repo_db" "$repo_db.sig" "$repo_files" "$repo_files.sig"
      repo-add "$repo_db" "${published_pkgfiles[@]}"
      detach_sign "$repo_db"
      detach_sign "$repo_files"
    fi
  else
    repo-add "$repo_db" "${published_pkgfiles[@]}"
  fi

  sync_repo_aliases "$arch_dir" "$repo_name"
  rm -f "$repo_db.old" "$repo_files.old"
fi

if [[ -n "${ARCH_REPO_GPG_KEY_ID:-}" ]] && gpg --batch --yes --list-keys "${ARCH_REPO_GPG_KEY_ID}" >/dev/null 2>&1; then
  gpg --batch --yes --armor --export "${ARCH_REPO_GPG_KEY_ID}" > "$pages_dir/repo-signing-key.asc"
else
  rm -f "$pages_dir/repo-signing-key.asc"
fi
