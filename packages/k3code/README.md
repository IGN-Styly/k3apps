# k3code

This package builds the desktop AppImage from the vendored `t3code` fork and then repackages the extracted payload using the `t3code-bin` AUR package layout as the template.

Current upstream snapshot:

- fork: `IGN-Styly/t3code`
- ref: `main`
- commit: `62551e08cc375ab56a280f6fd81c8c7f00d874f1`
- describe: `62551e08`

Notes:

- `upstream/` was bootstrapped from the local fork and should be updated with `git subtree pull` going forward.
- The build currently needs network access for `bun install` and Electron/AppImage downloads.
- When updating anything under `PKGBUILD`, `.SRCINFO`, or `upstream/`, bump `pkgver` or `pkgrel`.
