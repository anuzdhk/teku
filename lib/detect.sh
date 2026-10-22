# shellcheck shell=bash
# File type and OS detection, plus the rule table that decides what Teku
# does with a given file on a given system.

# Lowercased extension of a path, or empty.
teku_ext() {
    local name=${1##*/}
    [[ $name == *.* ]] || return 0
    local ext=${name##*.}
    printf '%s' "${ext,,}"
}

_teku_is_appimage() {
    # ELF (type 2) or ISO 9660 (type 1) with the "AI\x01"/"AI\x02" magic at offset 8.
    local magic
    magic=$(head -c 11 -- "$1" 2>/dev/null | tail -c 3 | od -An -tx1 | tr -d ' \n')
    [[ $magic == 414901 || $magic == 414902 ]]
}

_teku_is_dmg() {
    # UDIF images end with a 512-byte "koly" trailer.
    [[ $(tail -c 512 -- "$1" 2>/dev/null | head -c 4) == koly ]]
}

# Echoes one of: deb rpm appimage flatpakref windows macos unknown.
# Content wins over the extension, so a renamed file can't fool it.
teku_file_type() {
    local f=$1 ext desc mime
    ext=$(teku_ext "$f")
    desc=$(file -b -- "$f" 2>/dev/null)
    mime=$(file -b --mime-type -- "$f" 2>/dev/null)

    case $mime in
        application/vnd.debian.binary-package) echo deb; return ;;
        application/x-rpm) echo rpm; return ;;
        application/vnd.flatpak.ref) echo flatpakref; return ;;
        application/x-dosexec | application/vnd.microsoft.portable-executable) echo windows; return ;;
        application/x-msi) echo windows; return ;;
        application/x-xar) echo macos; return ;;
    esac
    case $desc in
        "Debian binary package"*) echo deb; return ;;
        RPM*) echo rpm; return ;;
        PE32* | "MS-DOS executable"*) echo windows; return ;;
        "xar archive"*) echo macos; return ;;
        # .msi files are OLE compound documents, same container as old .doc files.
        "Composite Document File"*) [[ $ext == msi ]] && { echo windows; return; } ;;
    esac
    if _teku_is_appimage "$f"; then echo appimage; return; fi
    if _teku_is_dmg "$f"; then echo macos; return; fi
    if [[ $mime == text/* ]] && grep -qm1 '^\[Flatpak Ref\]' -- "$f"; then
        echo flatpakref
        return
    fi
    # Content didn't match anything. Foreign-platform extensions are still worth
    # a specific message; everything else is unknown.
    case $ext in
        exe | msi) echo windows ;;
        dmg | pkg) echo macos ;;
        *) echo unknown ;;
    esac
}

_teku_os_release() {
    local file=${TEKU_OS_RELEASE:-/etc/os-release}
    [[ -r $file ]] || file=/usr/lib/os-release
    # shellcheck disable=SC1090
    (. "$file" 2>/dev/null && eval "printf '%s' \"\${$1:-}\"")
}

# Echoes one of: debian fedora suse arch unknown.
teku_os_family() {
    local id
    for id in $(_teku_os_release ID) $(_teku_os_release ID_LIKE); do
        case $id in
            debian | ubuntu) echo debian; return ;;
            fedora | rhel | centos) echo fedora; return ;;
            suse | opensuse*| sles) echo suse; return ;;
            arch) echo arch; return ;;
        esac
    done
    echo unknown
}

teku_os_name() {
    local name
    name=$(_teku_os_release PRETTY_NAME)
    printf '%s' "${name:-Unknown Linux}"
}

# teku_route TYPE FAMILY
# Echoes "ok:<method>" or "err:<headline>|<hint>".
teku_route() {
    local type=$1 family=$2
    case $type in
        deb)
            [[ $family == debian ]] && { echo ok:apt; return; }
            echo "err:This package is for Debian/Ubuntu systems|Look for an .rpm, Flatpak or AppImage version of this app instead."
            ;;
        rpm)
            case $family in
                fedora) echo ok:dnf ;;
                suse) echo ok:zypper ;;
                *) echo "err:This package is for Fedora/openSUSE systems|Look for a .deb, Flatpak or AppImage version of this app instead." ;;
            esac
            ;;
        appimage) echo ok:appimage ;;
        flatpakref)
            if command -v flatpak >/dev/null || [[ -f /.flatpak-info ]]; then
                echo ok:flatpak
            else
                echo "err:Flatpak isn't installed|Install the flatpak package with your package manager, then try again."
            fi
            ;;
        windows) echo "err:This is a Windows app|It can't be installed on Linux. Check the developer's site for a Linux version, or try Wine." ;;
        macos) echo "err:This is a macOS app|It can't be installed on Linux. Check the developer's site for a Linux version." ;;
        *) echo "err:Unsupported file type|Teku can install .deb, .rpm, .AppImage and .flatpakref files." ;;
    esac
}

teku_type_label() {
    case $1 in
        deb) echo "Debian package" ;;
        rpm) echo "RPM package" ;;
        appimage) echo "AppImage" ;;
        flatpakref) echo "Flatpak reference" ;;
        windows) echo "Windows executable" ;;
        macos) echo "macOS package" ;;
        *) echo "unknown" ;;
    esac
}
