#!/usr/bin/env bash
# Builds dist/Teku-<version>-x86_64.AppImage. Downloads appimagetool if needed.
set -euo pipefail
cd "$(dirname "$0")/../.."

version=$(sed -n 's/^TEKU_VERSION=//p' teku)
tool=${APPIMAGETOOL:-}
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

if [[ -z $tool ]]; then
    tool=$work/appimagetool
    curl -fsSL -o "$tool" \
        https://github.com/AppImage/appimagetool/releases/download/1.9.1/appimagetool-x86_64.AppImage
    chmod +x "$tool"
fi

app=$work/Teku.AppDir
make install DESTDIR="$app" PREFIX=/usr >/dev/null
install -m755 packaging/appimage/AppRun "$app/AppRun"
cp data/icons/teku.png "$app/teku.png"
cp data/teku.desktop "$app/teku.desktop"

mkdir -p dist
ARCH=x86_64 "$tool" --appimage-extract-and-run "$app" "dist/Teku-$version-x86_64.AppImage"
