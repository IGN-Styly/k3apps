# Packages

Each package base should live in `packages/<pkgbase>/`.

Recommended starting layout:

```text
packages/<pkgbase>/
├── PKGBUILD
├── .SRCINFO
├── source.conf
├── upstream/
├── patches/
├── files/
└── README.md
```

`source.conf` should follow this shape:

```bash
UPSTREAM_URL=https://github.com/<owner>/<repo>.git
UPSTREAM_REF=main
UPSTREAM_PREFIX=packages/<pkgbase>/upstream
BUILD_MODE=vendored
```

Use `git subtree add --prefix packages/<pkgbase>/upstream <url> <ref> --squash` for the initial vendor import.

