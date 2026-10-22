# Publishing Teku

Maintainer notes for getting Teku into distro repositories. Each channel needs
an account of your own; the files are already in this repo.

Package names:

| Channel | Name | Why |
|---|---|---|
| Ubuntu PPA | `teku` | |
| Fedora COPR | `teku` | |
| Arch AUR | `teku-installer` | `teku` on the AUR is the ConsenSys Ethereum client |

---

## Every release

1. Bump the version in **all** of these (`tests/run.sh` fails if they disagree):
   - `teku` — `TEKU_VERSION=`
   - `debian/changelog` — new entry on top (`dch -v X.Y.Z -D resolute`)
   - `packaging/rpm/teku.spec` — `Version:` and a `%changelog` entry
   - `packaging/aur/PKGBUILD` — `pkgver=`
   - `data/io.github.anuzdhk.Teku.metainfo.xml` — new `<release>` on top
2. Commit, then tag and push:

   ```bash
   git tag -a vX.Y.Z -m "Teku X.Y.Z"
   git push origin main vX.Y.Z
   ```

   GitHub Actions builds the .deb, .rpm and AppImage and attaches them to the release.
3. Update the PPA, COPR and AUR as below.

---

## Ubuntu PPA (Launchpad)

Users get it with:

```bash
sudo add-apt-repository ppa:anuzdhk/teku
sudo apt install teku
```

### One-time setup

1. Create an account at <https://launchpad.net>.
2. Create a GPG key and send it to Ubuntu's keyserver:

   ```bash
   gpg --full-generate-key                      # RSA 4096, your name + Launchpad email
   gpg --list-secret-keys --keyid-format long   # copy the key ID
   gpg --keyserver keyserver.ubuntu.com --send-keys <KEY_ID>
   ```

3. On Launchpad: **your profile → OpenPGP keys** → paste the fingerprint
   (`gpg --fingerprint`) and confirm the email it sends.
4. On Launchpad: **your profile → Create a new PPA**, name it `teku`.
5. Install the tools:

   ```bash
   sudo apt install devscripts debhelper dput
   ```

### Each release

From the repo root:

```bash
debuild -S -sa -k<KEY_ID>
dput ppa:anuzdhk/teku ../teku_X.Y.Z_source.changes
```

Launchpad emails you when it's accepted and built (a few minutes to an hour).

The changelog targets `resolute` (26.04). To offer it on other Ubuntu releases,
open the PPA's **View package details → Copy packages**, select the package,
pick e.g. *Noble (24.04)*, and choose **Copy existing binaries**. Teku is
architecture-independent, so the same build works on every release.

`debuild` leaves its output files (`.dsc`, `.tar.xz`, `.changes`, `.buildinfo`)
in the parent folder; delete them after uploading.

---

## Fedora / openSUSE: COPR

Users get it with:

```bash
sudo dnf copr enable anuzdhk/teku
sudo dnf install teku
```

### One-time setup

1. Create a Fedora account at <https://accounts.fedoraproject.org>.
2. Log in at <https://copr.fedorainfracloud.org> → **New Project**:
   - Name: `teku`
   - Chroots: the current `fedora-*-x86_64` releases, `fedora-rawhide-x86_64`,
     and `opensuse-tumbleweed-x86_64`
3. In the project → **Packages → New package → SCM**:
   - Clone URL: `https://github.com/anuzdhk/teku.git`
   - Committish: leave empty (`main`); the spec downloads the tagged release tarball
   - Spec file: `packaging/rpm/teku.spec`
   - Build SRPM with: **make_srpm** (uses `.copr/Makefile`)
   - Tick **Auto-rebuild**.
4. **Settings → Integrations** shows a webhook URL. Add it in GitHub under
   **Settings → Webhooks** (content type `application/json`, event: *Branch or tag
   creation*). Every new tag then rebuilds COPR automatically.

### Each release

Nothing, if the webhook is set up. Otherwise: **Packages → teku → Rebuild**.

---

## Arch: AUR

Users get it with an AUR helper:

```bash
yay -S teku-installer
```

### One-time setup

1. Create an account at <https://aur.archlinux.org> and add your SSH **public**
   key (`~/.ssh/id_ed25519.pub`) under **My Account**.
2. Clone the (empty) AUR repo next to this one:

   ```bash
   git clone ssh://aur@aur.archlinux.org/teku-installer.git ../aur-teku-installer
   ```

### Each release

After the release tag is pushed:

```bash
packaging/aur/update.sh                      # pins the checksum, writes .SRCINFO
cp packaging/aur/PKGBUILD packaging/aur/.SRCINFO ../aur-teku-installer/
cd ../aur-teku-installer
git add PKGBUILD .SRCINFO
git commit -m "Update to X.Y.Z"
git push
```

On an Arch machine you can check the package first with `makepkg -si`.
