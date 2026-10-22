#!/usr/bin/env bash
# Teku installer:
#   curl -fsSL https://raw.githubusercontent.com/anuzdhk/teku/main/install.sh | bash
#
# Picks the latest release's .deb, .rpm or AppImage for this distro and installs it.
# TEKU_FORMAT=deb|rpm|appimage overrides the choice.
set -euo pipefail

REPO=anuzdhk/teku
tmp=""  # global so the EXIT trap can still see it

say() { printf '\033[1;32m▍teku\033[0m %s\n' "$*"; }
die() { printf '\033[1;31m▍teku\033[0m %s\n' "$*" >&2; exit 1; }

pick_format() {
    local ids
    ids=$(. /etc/os-release 2>/dev/null; echo "${ID:-} ${ID_LIKE:-}")
    for id in $ids; do
        case $id in
            debian | ubuntu) echo deb; return ;;
            fedora | rhel | centos | suse | opensuse*) echo rpm; return ;;
        esac
    done
    echo appimage
}

# URL of the latest release asset whose name matches PATTERN.
asset_url() {
    curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" |
        grep -o '"browser_download_url": *"[^"]*"' | cut -d'"' -f4 | grep -E "$1" | head -n1
}

need() { command -v "$1" >/dev/null || die "$2"; }

main() {
    need curl "curl is required."
    local format=${TEKU_FORMAT:-$(pick_format)} pattern url file
    case $format in
        deb) pattern='_all\.deb$' ;;
        rpm) pattern='\.noarch\.rpm$' ;;
        appimage)
            [[ $(uname -m) == x86_64 ]] || die "The AppImage is x86_64 only. Install from source: https://github.com/$REPO#from-source"
            pattern='x86_64\.AppImage$'
            ;;
        *) die "Unknown TEKU_FORMAT '$format' (use deb, rpm or appimage)." ;;
    esac

    url=$(asset_url "$pattern") || true
    [[ -n $url ]] || die "Couldn't find a $format download in the latest release."

    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' EXIT
    file=$tmp/${url##*/}
    say "downloading ${url##*/}"
    curl -fL --progress-bar -o "$file" "$url"

    case $format in
        deb)
            say "installing with apt (asks for your password)"
            sudo apt-get install -y "$file"
            ;;
        rpm)
            if command -v dnf >/dev/null; then
                say "installing with dnf (asks for your password)"
                sudo dnf install -y "$file"
            elif command -v zypper >/dev/null; then
                say "installing with zypper (asks for your password)"
                sudo zypper --non-interactive install --allow-unsigned-rpm "$file"
            else
                die "No dnf or zypper found. Try: TEKU_FORMAT=appimage"
            fi
            ;;
        appimage)
            command -v zenity >/dev/null ||
                say "warning: zenity isn't installed; Teku's popups need it (e.g. sudo pacman -S zenity)"
            local dest=$HOME/Applications/Teku.AppImage
            mkdir -p "$HOME/Applications"
            install -m755 "$file" "$dest"
            "$dest" --integrate >/dev/null
            say "installed to ~/Applications/Teku.AppImage"
            ;;
    esac

    say "done. Right-click an app file → Install with Teku."
    if pgrep -x nautilus >/dev/null; then
        say "GNOME Files is open: run 'nautilus -q' to load the menu entry."
    fi
}

main "$@"
