# k3code

This package builds the desktop AppImage from the vendored `t3code` fork and then repackages the extracted payload using the `t3code-bin` AUR package layout as the template.

Current upstream snapshot:

- fork: `IGN-Styly/t3code`
- ref: `main`
- commit: `c527da5c65d6191abfce16457f3c6b04d845e966`
- describe: `v0.0.16-6-gc527da5c`

Notes:

- `upstream/` was bootstrapped from the local fork and should be updated with `git subtree pull` going forward.
- The build currently needs network access for `bun install` and Electron/AppImage downloads.
- When updating anything under `PKGBUILD`, `.SRCINFO`, or `upstream/`, bump `pkgver` or `pkgrel`.
