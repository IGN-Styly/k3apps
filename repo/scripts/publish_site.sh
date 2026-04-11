#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/common.sh"

site_dir=""
pages_dir=""
clean_publish=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --site-dir)
      site_dir=${2:-}
      shift 2
      ;;
    --pages-dir)
      pages_dir=${2:-}
      shift 2
      ;;
    --clean)
      clean_publish=1
      shift
      ;;
    *)
      die "usage: publish_site.sh --site-dir <dir> --pages-dir <dir> [--clean]"
      ;;
  esac
done

[[ -n "$site_dir" ]] || die "--site-dir is required"
[[ -n "$pages_dir" ]] || die "--pages-dir is required"
[[ -d "$site_dir" ]] || die "site directory '$site_dir' does not exist"

site_dir="$(cd "$site_dir" && pwd)"
mkdir -p "$pages_dir"
pages_dir="$(cd "$pages_dir" && pwd)"

if (( clean_publish )); then
  find "$pages_dir" -mindepth 1 -maxdepth 1 \
    ! -name '.git' \
    -exec rm -rf {} +
fi

rsync -a --delete \
  --exclude '/.git' \
  "$site_dir"/ "$pages_dir"/
