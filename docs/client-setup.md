# Client setup

Packages are published as the `k3apps` pacman repository:

```ini
[k3apps]
SigLevel = Required DatabaseOptional
Server = https://<github-user-or-org>.github.io/k3apps/$arch
```

## 1. Import the public signing key

```bash
curl -fsSLo /tmp/k3apps-repo-signing-key.asc \
  https://<github-user-or-org>.github.io/k3apps/repo-signing-key.asc
sudo pacman-key --add /tmp/k3apps-repo-signing-key.asc
```

## 2. Locally sign the key

Replace `<fingerprint>` with the published key fingerprint:

```bash
sudo pacman-key --lsign-key <fingerprint>
```

## 3. Add the repo to `pacman.conf`

Append the repo stanza shown above to `/etc/pacman.conf`, then refresh package databases:

```bash
sudo pacman -Sy
```

