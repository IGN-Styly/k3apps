# Client setup

Packages are published as the `k3apps` pacman repository.

## Unsigned mode

If the repository is being published without GitHub Actions signing secrets, use:

```ini
[k3apps]
SigLevel = Optional TrustAll
Server = https://github.com/<github-user-or-org>/k3apps/releases/download/repo-x86_64
```

Then refresh pacman:

```bash
sudo pacman -Sy
```

## Signed mode

If `repo-signing-key.asc` is published as a release asset under `repo-x86_64`, you can use signature verification instead.

```ini
[k3apps]
SigLevel = Required DatabaseOptional
Server = https://github.com/<github-user-or-org>/k3apps/releases/download/repo-x86_64
```

### 1. Import the public signing key

```bash
curl -fsSLo /tmp/k3apps-repo-signing-key.asc \
  https://github.com/<github-user-or-org>/k3apps/releases/download/repo-x86_64/repo-signing-key.asc
sudo pacman-key --add /tmp/k3apps-repo-signing-key.asc
```

### 2. Locally sign the key

Replace `<fingerprint>` with the published key fingerprint:

```bash
sudo pacman-key --lsign-key <fingerprint>
```

### 3. Add the repo to `pacman.conf`

Append the repo stanza shown above to `/etc/pacman.conf`, then refresh package databases:

```bash
sudo pacman -Sy
```
