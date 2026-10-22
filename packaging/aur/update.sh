#!/usr/bin/env bash
# After tagging a release: pins the tarball checksum in PKGBUILD and writes
# .SRCINFO, ready to copy into the AUR repo. No makepkg needed.
set -euo pipefail
cd "$(dirname "$0")"

version=$(sed -n 's/^TEKU_VERSION=//p' ../../teku)
url=https://github.com/anuzdhk/teku/archive/v$version.tar.gz
sum=$(curl -fsSL "$url" | sha256sum | cut -d' ' -f1)

sed -i -e "s/^pkgver=.*/pkgver=$version/" -e "s/^sha256sums=.*/sha256sums=('$sum')/" PKGBUILD

cat >.SRCINFO <<SRCINFO
pkgbase = teku-installer
	pkgdesc = $(sed -n "s/^pkgdesc='\(.*\)'/\1/p" PKGBUILD)
	pkgver = $version
	pkgrel = $(sed -n 's/^pkgrel=//p' PKGBUILD)
	url = https://github.com/anuzdhk/teku
	arch = any
	license = MIT
	depends = bash
	depends = zenity
	depends = polkit
	depends = file
	conflicts = teku
	optdepends = python-nautilus: top-level "Install with Teku" in GNOME Files
	optdepends = flatpak: install .flatpakref files
	source = teku-$version.tar.gz::$url
	sha256sums = $sum

pkgname = teku-installer
SRCINFO
echo "PKGBUILD and .SRCINFO updated for $version"
