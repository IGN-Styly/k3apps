# Adding packages

## 1. Create the package directory

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

Create the empty directories first:

```bash
mkdir -p packages/<pkgbase>/{upstream,patches,files}
```

## 2. Vendor the upstream source

Populate `upstream/` with a squashed subtree import:

```bash
git subtree add \
  --prefix packages/<pkgbase>/upstream \
  https://github.com/<owner>/<repo>.git \
  <ref> \
  --squash
```

Record the source metadata in `packages/<pkgbase>/source.conf`:

```bash
UPSTREAM_URL=https://github.com/<owner>/<repo>.git
UPSTREAM_REF=main
UPSTREAM_PREFIX=packages/<pkgbase>/upstream
BUILD_MODE=vendored
```

## 3. Write the package files

- `PKGBUILD` must build from the vendored `upstream/` tree.
- `.SRCINFO` must be regenerated from the checked-in `PKGBUILD`.
- `patches/` and `files/` hold package-specific assets.

After editing `PKGBUILD`, refresh `.SRCINFO`:

```bash
make srcinfo PKG=<pkgbase>
```

## 4. Validate locally

Run the local validation flow before opening a PR:

```bash
make validate PKG=<pkgbase>
```

Any change under `PKGBUILD`, `.SRCINFO`, `upstream/`, `patches/`, or `files/` must also bump `pkgver` or `pkgrel`.

