# Signing keys

Do not commit private keys into this repository.

The publish workflows expect these GitHub Actions secrets:

- `ARCH_REPO_GPG_PRIVATE_KEY`
- `ARCH_REPO_GPG_PASSPHRASE`
- `ARCH_REPO_GPG_KEY_ID`

`ARCH_REPO_GPG_PRIVATE_KEY` may be stored either as an armored key block or as a base64-encoded binary export.

