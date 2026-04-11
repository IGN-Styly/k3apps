#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/common.sh"

release_repo=""
release_tag=""
asset_dir=""
release_title=""
release_notes=""
target_ref=""

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
    --asset-dir)
      asset_dir=${2:-}
      shift 2
      ;;
    --title)
      release_title=${2:-}
      shift 2
      ;;
    --notes)
      release_notes=${2:-}
      shift 2
      ;;
    --target)
      target_ref=${2:-}
      shift 2
      ;;
    *)
      die "usage: publish_release_assets.sh --repo <owner/repo> --tag <tag> --asset-dir <dir> [--title <title>] [--notes <text>] [--target <ref>]"
      ;;
  esac
done

[[ -n "$release_repo" ]] || die "--repo is required"
[[ -n "$release_tag" ]] || die "--tag is required"
[[ -n "$asset_dir" ]] || die "--asset-dir is required"
command -v gh >/dev/null 2>&1 || die "gh is required"

asset_dir="$(cd "$asset_dir" && pwd)"
[[ -d "$asset_dir" ]] || die "asset directory '$asset_dir' does not exist"

if [[ -z "$release_title" ]]; then
  release_title="k3apps pacman repo ($release_tag)"
fi

if [[ -z "$release_notes" ]]; then
  release_notes=$'Automated pacman repository assets.\n\nUse this release as the pacman server base URL.'
fi

if gh release view "$release_tag" --repo "$release_repo" >/dev/null 2>&1; then
  gh release edit "$release_tag" \
    --repo "$release_repo" \
    --title "$release_title" \
    --notes "$release_notes"
else
  create_args=(
    "$release_tag"
    --repo "$release_repo"
    --title "$release_title"
    --notes "$release_notes"
    --latest=false
  )

  if [[ -n "$target_ref" ]]; then
    create_args+=(--target "$target_ref")
  fi

  gh release create "${create_args[@]}"
fi

mapfile -t existing_assets < <(gh release view "$release_tag" --repo "$release_repo" --json assets --jq '.assets[].name')
mapfile -t asset_files < <(find "$asset_dir" -maxdepth 1 -type f | sort)
if (( ${#asset_files[@]} == 0 )); then
  for asset_name in "${existing_assets[@]}"; do
    gh release delete-asset "$release_tag" "$asset_name" --repo "$release_repo" --yes
  done

  log "no release assets to upload"
  exit 0
fi

declare -A desired_assets=()
for asset_file in "${asset_files[@]}"; do
  desired_assets["$(basename "$asset_file")"]=1
done

for asset_name in "${existing_assets[@]}"; do
  if [[ -z "${desired_assets[$asset_name]:-}" ]]; then
    gh release delete-asset "$release_tag" "$asset_name" --repo "$release_repo" --yes
  fi
done

gh release upload "$release_tag" --repo "$release_repo" --clobber "${asset_files[@]}"
