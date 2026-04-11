# k3apps

`k3apps` is a source monorepo for custom Arch Linux packages plus the CI needed to publish a pacman repository to GitHub Pages.

## Branch contract

- `main`: package source, `PKGBUILD`s, vendored upstream trees, patches, and CI.
- `gh-pages`: generated binary repository content served by GitHub Pages.

## Repository layout

- `packages/`: one directory per package base.
- `repo/config/`: shared `makepkg` and `pacman` configuration for local and CI builds.
- `repo/scripts/`: build, validation, optional signing, and publish automation.
- `site/`: static SvelteKit package index published from the root of `gh-pages`.
- `docs/`: maintainer and client-facing setup guides.
- `.github/workflows/`: validation, publish, and full rebuild pipelines.

## Package contract

Each package base lives under `packages/<pkgbase>/` and should contain:

- `PKGBUILD`
- `.SRCINFO`
- `source.conf`
- `upstream/`
- `patches/`
- `files/`

`upstream/` is expected to be managed with `git subtree --squash`.

## Local maintainer commands

These commands assume an Arch environment with `base-devel`, `git`, `namcap`, `nodejs`, `pacman-contrib`, `pnpm`, and `sudo` installed.

- `make validate PKG=<pkgbase>`: verify `.SRCINFO`, lint, and build a package with its internal dependencies.
- `make build PKG=<pkgbase>`: build a package and any required internal dependencies.
- `make srcinfo PKG=<pkgbase>`: regenerate `.SRCINFO`.
- `make subtree-update PKG=<pkgbase>`: update vendored upstream source using `source.conf`.
- `make site-dev`: run the static package index locally.
- `make site-build-pages`: build the package index with the `/k3apps` base path used by GitHub Pages.
- `make site-check`: run `svelte-check` against the site.

## GitHub setup

Configure the repository with:

- default branch `main`
- GitHub Pages serving from `gh-pages` root
- Actions permission to write repository contents

Add the following repository secrets if you want signed package publishing:

- `ARCH_REPO_GPG_PRIVATE_KEY`
- `ARCH_REPO_GPG_PASSPHRASE`
- `ARCH_REPO_GPG_KEY_ID`

## Client configuration

Published packages are served as the `k3apps` repo.

Unsigned mode, the current default when no signing secrets are configured:

```ini
[k3apps]
SigLevel = Optional TrustAll
Server = https://<github-user-or-org>.github.io/k3apps/$arch
```

If you later configure signing secrets, switch clients to the signed setup documented in [client-setup.md](/home/styly/projects/personal/k3apps/docs/client-setup.md).

The static package index is published at `https://<github-user-or-org>.github.io/k3apps/`.
