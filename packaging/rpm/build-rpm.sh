#!/usr/bin/env bash
# Builds dist/teku-<version>-1.noarch.rpm. Needs rpmbuild (Fedora: rpm-build).
set -euo pipefail
cd "$(dirname "$0")/../.."

version=$(sed -n 's/^TEKU_VERSION=//p' teku)
top=$(mktemp -d)
trap 'rm -rf "$top"' EXIT

mkdir -p "$top/SOURCES" dist
git archive --format=tar.gz --prefix="teku-$version/" -o "$top/SOURCES/teku-$version.tar.gz" HEAD
rpmbuild -bb --define "_topdir $top" packaging/rpm/teku.spec
cp "$top"/RPMS/noarch/*.rpm dist/
