# Updating vendored source

Every package should track its upstream source in `packages/<pkgbase>/source.conf`.

## Update a subtree

Use the provided make target:

```bash
make subtree-update PKG=<pkgbase>
```

That command reads:

- `UPSTREAM_URL`
- `UPSTREAM_REF`
- `UPSTREAM_PREFIX`

from `packages/<pkgbase>/source.conf` and runs `git subtree pull --squash`.

## After the subtree update

1. Review the vendored diff under `packages/<pkgbase>/upstream/`.
2. Adjust `pkgver` or `pkgrel` in `PKGBUILD`.
3. Regenerate `.SRCINFO` with `make srcinfo PKG=<pkgbase>`.
4. Re-run `make validate PKG=<pkgbase>`.

