#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/common.sh"

release_repo=""
release_tag=""
repo_dir=""
clean_sync=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      release_repo=${2:-}
      shift 2
      ;;
    --tag)
      release_tag=${2:-}
      shift 2
      ;;
    --repo-dir)
      repo_dir=${2:-}
      shift 2
      ;;
    --clean)
      clean_sync=1
      shift
      ;;
    *)
      die "usage: sync_release_repo.sh --repo <owner/repo> --tag <tag> --repo-dir <dir> [--clean]"
      ;;
  esac
done

[[ -n "$release_repo" ]] || die "--repo is required"
[[ -n "$release_tag" ]] || die "--tag is required"
[[ -n "$repo_dir" ]] || die "--repo-dir is required"
command -v gh >/dev/null 2>&1 || die "gh is required"

mkdir -p "$repo_dir"
repo_dir="$(cd "$repo_dir" && pwd)"

if (( clean_sync )); then
  find "$repo_dir" -mindepth 1 -maxdepth 1 -exec rm -rf {} +
fi

if ! gh release view "$release_tag" --repo "$release_repo" >/dev/null 2>&1; then
  log "release '$release_tag' does not exist yet; starting with an empty repo directory"
  exit 0
fi

gh release download "$release_tag" \
  --repo "$release_repo" \
  --dir "$repo_dir" \
  --clobber
