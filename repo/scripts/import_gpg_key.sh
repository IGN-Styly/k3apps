#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/common.sh"

export_path="$(repo_root)/.artifacts/repo-signing-key.asc"
gpg_home="${GNUPGHOME:-$(repo_root)/.artifacts/gnupg}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --export)
      export_path=${2:-}
      shift 2
      ;;
    --gnupghome)
      gpg_home=${2:-}
      shift 2
      ;;
    *)
      die "usage: import_gpg_key.sh [--export <path>] [--gnupghome <path>]"
      ;;
  esac
done

private_key="${ARCH_REPO_GPG_PRIVATE_KEY:-}"
passphrase="${ARCH_REPO_GPG_PASSPHRASE:-}"
key_id="${ARCH_REPO_GPG_KEY_ID:-}"

[[ -n "$private_key" ]] || die "ARCH_REPO_GPG_PRIVATE_KEY is not set"
[[ -n "$key_id" ]] || die "ARCH_REPO_GPG_KEY_ID is not set"

mkdir -p "$gpg_home"
chmod 700 "$gpg_home"
export GNUPGHOME="$gpg_home"

printf 'allow-loopback-pinentry\n' > "$GNUPGHOME/gpg-agent.conf"
gpgconf --kill gpg-agent >/dev/null 2>&1 || true

key_file="$(mktemp)"
probe_file="$(mktemp)"
signature_file="$(mktemp)"
trap 'rm -f "$key_file" "$probe_file" "$signature_file"' EXIT

if [[ "$private_key" == *"BEGIN PGP PRIVATE KEY BLOCK"* ]]; then
  printf '%s\n' "$private_key" > "$key_file"
else
  printf '%s' "$private_key" | base64 -d > "$key_file"
fi

gpg_import_command=(gpg --batch --yes)
gpg_sign_command=(gpg --batch --yes --local-user "$key_id")

if [[ -n "$passphrase" ]]; then
  gpg_import_command+=(--pinentry-mode loopback --passphrase "$passphrase")
  gpg_sign_command+=(--pinentry-mode loopback --passphrase "$passphrase")
fi

"${gpg_import_command[@]}" --import "$key_file"

printf 'k3apps signing probe\n' > "$probe_file"
"${gpg_sign_command[@]}" --output "$signature_file" --detach-sign "$probe_file"

mkdir -p "$(dirname "$export_path")"
gpg --batch --yes --armor --export "$key_id" > "$export_path"

