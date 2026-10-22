#!/usr/bin/env bash
# Detection, routing and AppImage install/uninstall tests. No root, no GUI.
set -uo pipefail
cd "$(dirname "$0")/.."

export TEKU_NO_GUI=1
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
fails=0

check() { # NAME EXPECTED ACTUAL
    if [[ $2 == "$3" ]]; then
        echo "ok   $1"
    else
        echo "FAIL $1: expected '$2', got '$3'"
        fails=$((fails + 1))
    fi
}

. lib/host.sh
. lib/detect.sh

# --- fixtures
mkdir -p "$tmp/pkg/DEBIAN"
printf 'Package: tekutest\nVersion: 1\nArchitecture: all\nMaintainer: t <t@t>\nDescription: t\n' >"$tmp/pkg/DEBIAN/control"
dpkg-deb --build "$tmp/pkg" "$tmp/real.deb" >/dev/null
cp "$tmp/real.deb" "$tmp/renamed.zip"
echo "not a package" >"$tmp/fake.deb"
printf 'MZ\x90\x00\x03\x00\x00\x00PE\x00\x00' >"$tmp/setup.exe"
printf '\xd0\xcf\x11\xe0\xa1\xb1\x1a\xe1' >"$tmp/setup.msi"
{ head -c 2000 /dev/zero; printf 'koly'; head -c 508 /dev/zero; } >"$tmp/App.dmg"
printf '[Flatpak Ref]\nName=org.example.App\nUrl=https://dl.flathub.org/repo/\n' >"$tmp/app.flatpakref"
echo hello >"$tmp/notes.txt"

# A fake type-2 AppImage: a shell script with the AppImage magic at offset 8,
# which handles --appimage-extract by writing a .desktop file and icon.
make_appimage() {
    printf '\x7fELF\x02\x01\x01\x00AI\x02\n' >"$1"
    cat >>"$1" <<'EOF'
if [ "$1" = --appimage-extract ]; then
    mkdir -p squashfs-root
    case $2 in
        '*.desktop') printf '[Desktop Entry]\nName=Fake App\n' >squashfs-root/fake.desktop ;;
        .DirIcon) printf '<svg xmlns="http://www.w3.org/2000/svg"/>' >squashfs-root/.DirIcon ;;
    esac
fi
EOF
}
make_appimage "$tmp/Fake_App-1.0.AppImage"
cp "$tmp/Fake_App-1.0.AppImage" "$tmp/renamed-appimage.bin"

# --- file types
check "deb"               deb        "$(teku_file_type "$tmp/real.deb")"
check "renamed deb"       deb        "$(teku_file_type "$tmp/renamed.zip")"
check "fake .deb"         unknown    "$(teku_file_type "$tmp/fake.deb")"
check "exe"               windows    "$(teku_file_type "$tmp/setup.exe")"
check "msi"               windows    "$(teku_file_type "$tmp/setup.msi")"
check "dmg"               macos      "$(teku_file_type "$tmp/App.dmg")"
check "flatpakref"        flatpakref "$(teku_file_type "$tmp/app.flatpakref")"
check "appimage"          appimage   "$(teku_file_type "$tmp/Fake_App-1.0.AppImage")"
check "renamed appimage"  appimage   "$(teku_file_type "$tmp/renamed-appimage.bin")"
check "text"              unknown    "$(teku_file_type "$tmp/notes.txt")"

# --- OS families
os() { printf '%s\n' "$@" >"$tmp/os-release"; TEKU_OS_RELEASE=$tmp/os-release teku_os_family; }
check "ubuntu"     debian  "$(os ID=ubuntu ID_LIKE=debian)"
check "mint"       debian  "$(os ID=linuxmint 'ID_LIKE="ubuntu debian"')"
check "pop"        debian  "$(os ID=pop 'ID_LIKE="ubuntu debian"')"
check "fedora"     fedora  "$(os ID=fedora)"
check "tumbleweed" suse    "$(os ID=opensuse-tumbleweed 'ID_LIKE="opensuse suse"')"
check "neon"       debian  "$(os ID=neon 'ID_LIKE="ubuntu debian"')"
check "arch"       arch    "$(os ID=arch)"

# --- routing
check "deb on debian"   ok:apt    "$(teku_route deb debian)"
check "deb on fedora"   "err:This package is for Debian/Ubuntu systems" "$(teku_route deb fedora | cut -d'|' -f1)"
check "rpm on fedora"   ok:dnf    "$(teku_route rpm fedora)"
check "rpm on suse"     ok:zypper "$(teku_route rpm suse)"
check "rpm on ubuntu"   "err:This package is for Fedora/openSUSE systems" "$(teku_route rpm debian | cut -d'|' -f1)"
check "exe"             "err:This is a Windows app" "$(teku_route windows debian | cut -d'|' -f1)"
check "dmg"             "err:This is a macOS app"   "$(teku_route macos debian | cut -d'|' -f1)"
check "unknown"         "err:Unsupported file type" "$(teku_route unknown debian | cut -d'|' -f1)"

# --- end to end, sandboxed HOME
export HOME=$tmp/home XDG_DATA_HOME=$tmp/home/.local/share XDG_STATE_HOME=$tmp/home/.local/state
mkdir -p "$HOME"
TEKU_OS_RELEASE=$tmp/os-release
printf 'ID=fedora\nPRETTY_NAME="Fedora Linux 44"\n' >"$TEKU_OS_RELEASE"
export TEKU_OS_RELEASE

./teku -y "$tmp/real.deb" >/dev/null 2>&1
check "deb on fedora exits 1" 1 $?
out=$(./teku -y "$tmp/fake.deb" 2>&1); grep -q "isn't a real .deb" <<<"$out"
check "fake .deb message" 0 $?

./teku -y "$tmp/Fake_App-1.0.AppImage" >/dev/null 2>&1
check "appimage install exit" 0 $?
dest=$HOME/Applications/Fake_App-1.0.AppImage
entry=$XDG_DATA_HOME/applications/teku-fake_app-1.0.desktop
check "appimage moved"       yes "$([[ -x $dest && ! -e $tmp/Fake_App-1.0.AppImage ]] && echo yes)"
check "menu entry name"      "Fake App" "$(sed -n 's/^Name=//p' "$entry")"
check "menu entry icon"      yes "$([[ -s $XDG_DATA_HOME/icons/teku/fake_app-1.0.svg ]] && echo yes)"
check "listed as installed"  "$dest" "$(. lib/install_appimage.sh; teku_appimage_list)"

./teku -y --uninstall-appimage "$dest" >/dev/null 2>&1
check "uninstall exit"       0 $?
check "entry removed"        yes "$([[ ! -e $entry && ! -e $dest ]] && echo yes)"

echo
((fails == 0)) && echo "all passed" || echo "$fails failed"
exit $((fails > 0))
