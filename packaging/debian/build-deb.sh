#!/usr/bin/env bash
# Builds dist/teku_<version>_all.deb with dpkg-deb. No debhelper needed.
set -euo pipefail
cd "$(dirname "$0")/../.."

version=$(sed -n 's/^TEKU_VERSION=//p' teku)
stage=$(mktemp -d)
trap 'rm -rf "$stage"' EXIT

make install DESTDIR="$stage" PREFIX=/usr >/dev/null
install -d "$stage/DEBIAN" "$stage/usr/share/doc/teku"
install -m644 LICENSE "$stage/usr/share/doc/teku/copyright"
sed "s/@VERSION@/$version/" packaging/debian/control >"$stage/DEBIAN/control"

mkdir -p dist
dpkg-deb --root-owner-group --build "$stage" "dist/teku_${version}_all.deb"
