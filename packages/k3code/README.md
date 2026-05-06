# k3code

This package builds the desktop AppImage from the vendored `t3code` fork and then repackages the extracted payload using the `t3code-bin` AUR package layout as the template.

Current upstream snapshot:

- fork: `IGN-Styly/t3code`
- ref: `main`
- commit: `c8c28091b42a7bd48602b404d4b40e5e01ec2cf3`
- describe: `c8c2809`

Notes:

- `upstream/` was bootstrapped from the local fork and should be updated with `git subtree pull` going forward.
- The build currently needs network access for `bun install` and Electron/AppImage downloads.
- When updating anything under `PKGBUILD`, `.SRCINFO`, or `upstream/`, bump `pkgver` or `pkgrel`.
