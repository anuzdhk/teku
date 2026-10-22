<p align="center"><img src="logo/tekulogo.png" width="128" alt="Teku logo"></p>

# Teku

Install Linux apps from a right-click. Teku looks at the file and your distro,
then installs it — or tells you plainly why it can't.

| File | Works on | What Teku does |
|---|---|---|
| `.deb` | Debian, Ubuntu, Mint, Pop!_OS | `pkexec apt-get install` |
| `.rpm` | Fedora / RHEL, openSUSE | `pkexec dnf install` / `pkexec zypper install` |
| `.AppImage` | any | moves it to `~/Applications`, makes it executable, adds a menu entry + icon |
| `.flatpakref` | any distro with Flatpak | `flatpak install --from` |
| `.exe` `.msi` / `.dmg` `.pkg` | — | explains it's a Windows / macOS app |

File types are detected from the file's contents (`file` plus magic bytes), so
a renamed file can't fool Teku. The distro comes from `/etc/os-release`
(`ID` and `ID_LIKE`).

The only UI is small dark popups: confirm → progress → done / error.

## Screenshots

<table>
  <tr>
    <td align="center" rowspan="3" valign="top"><b>1. Right-click a file</b><br><br><img src="screenshots/menu.png" width="220" alt="Install with Teku in the Nautilus right-click menu"></td>
    <td align="center"><b>2. Confirm</b><br><img src="screenshots/confirm.png" width="520" alt="Teku confirm popup for a .deb on Ubuntu"></td>
  </tr>
  <tr>
    <td align="center"><b>3. Installing</b><br><img src="screenshots/progress.png" width="520" alt="Teku progress popup showing apt output"></td>
  </tr>
  <tr>
    <td align="center"><b>4. Done</b><br><img src="screenshots/done.png" width="520" alt="Teku done popup"></td>
  </tr>
</table>

## Install

Download from [Releases](https://github.com/anuzdhk/teku/releases):

| Distro | File | Install |
|---|---|---|
| Debian, Ubuntu, Mint, Pop!_OS | `teku_<version>_all.deb` | `sudo apt install ./teku_<version>_all.deb` |
| Fedora, openSUSE | `teku-<version>-1.noarch.rpm` | `sudo dnf install ./teku-*.rpm` / `sudo zypper install ./teku-*.rpm` |
| Any Linux | `Teku-<version>-x86_64.AppImage` | `chmod +x` it and open it once; it offers to add itself to the right-click menu |

Then run `nautilus -q` (or log out and back in) to get **Install with Teku** in the
Nautilus right-click menu. The AppImage uses the system's `zenity`, `pkexec` and `file`.

**From source** (any distro):

```bash
sudo make install
```

or `make install-user` for a no-root install into `~/.local`. `make deb` builds the
package into `dist/`. Needs `bash`, `zenity`, `pkexec` and `file`; the top-level
Nautilus entry also needs `python3-nautilus`.

## Use

- Right-click a file → **Open With → Install with Teku**.
- Dolphin and Nemo get a top-level **Install with Teku** entry automatically.
- Nautilus: run `teku --integrate` once, then use right-click → **Scripts → Install with Teku**.

From a terminal:

```
teku FILE...                     install
teku --uninstall-appimage [FILE] remove an AppImage Teku installed
teku --detect FILE...            show what Teku sees, install nothing
teku -y FILE                     skip the confirm popup
TEKU_NO_GUI=1 teku FILE          terminal output only
```

Logs: `~/.local/state/teku/last.log` (last install) and `history.log` (every attempt).

## Layout

```
teku                    entry point
lib/detect.sh           file type + OS detection, routing rules
lib/ui.sh               zenity popups (dark, terminal style) + terminal fallback
lib/install_*.sh        one installer per format
lib/host.sh             runs host commands via flatpak-spawn inside Flatpak
data/                   desktop entry, icon, file-manager integrations
packaging/              .deb, .rpm and AppImage builders, Flathub + Snap drafts
.github/workflows/      release build: tag vX.Y.Z to publish all three
tests/run.sh            detection and AppImage tests
```

## Distribution

1. **Primary:** `.deb` on GitHub Releases.
2. **Flathub:** `packaging/flatpak/` — runs installs through `flatpak-spawn --host`,
   which needs `--talk-name=org.freedesktop.Flatpak`. Reviewers will look hard at
   that; the submission must explain that installing host packages is the app's purpose.
3. **Snap Store:** `packaging/snap/` — needs classic confinement, which is reviewed by
   hand and often refused for installers.

The Flatpak and Snap manifests are untested drafts.

## License

MIT
