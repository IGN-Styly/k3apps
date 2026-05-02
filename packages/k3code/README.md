# k3code

This package builds the desktop AppImage from the vendored `t3code` fork and then repackages the extracted payload using the `t3code-bin` AUR package layout as the template.

Current upstream snapshot:

- fork: `IGN-Styly/t3code`
- ref: `main`
- commit: `41f8fd2fd462cd2f7267b699d1cd41790c4145cd`
- describe: `41f8fd2`

Notes:

- `upstream/` was bootstrapped from the local fork and should be updated with `git subtree pull` going forward.
- The build currently needs network access for `bun install` and Electron/AppImage downloads.
- When updating anything under `PKGBUILD`, `.SRCINFO`, or `upstream/`, bump `pkgver` or `pkgrel`.
