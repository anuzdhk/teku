# shellcheck shell=bash
# AppImages live in ~/Applications with a menu entry and icon that Teku owns.
# Teku-made entries are marked with X-Teku-AppImage so they can be removed later.

TEKU_APPS_DIR=${TEKU_APPS_DIR:-$HOME/Applications}
TEKU_MENU_DIR=${XDG_DATA_HOME:-$HOME/.local/share}/applications
TEKU_ICON_DIR=${XDG_DATA_HOME:-$HOME/.local/share}/icons/teku

# Menu-safe id from a file name: "Foo App-1.2-x86_64.AppImage" -> "foo-app-1.2-x86_64".
teku_appimage_id() {
    local base=${1##*/}
    base=${base%.*}
    base=${base,,}
    base=${base//[^a-z0-9._-]/-}
    printf '%s' "$base"
}

teku_appimage_dest() {
    printf '%s/%s' "$TEKU_APPS_DIR" "${1##*/}"
}

# Pull a single path out of the AppImage into DIR. Type 1 images can't do this;
# the caller falls back to a generic entry.
_teku_appimage_extract() {
    local app=$1 dir=$2 pattern=$3
    (cd "$dir" && timeout 30 "$app" --appimage-extract "$pattern" >/dev/null 2>&1)
}

teku_install_appimage() {
    local src dest id tmp root name="" icon="" icon_ext=svg
    src=$(readlink -f -- "$1")
    dest=$(teku_appimage_dest "$src")
    id=$(teku_appimage_id "$src")

    mkdir -p "$TEKU_APPS_DIR" "$TEKU_MENU_DIR" "$TEKU_ICON_DIR"
    if [[ $src != "$dest" ]]; then
        echo "moving to $dest"
        mv -f -- "$src" "$dest" || return 1
    fi
    chmod +x -- "$dest" || return 1

    echo "reading app metadata"
    tmp=$(mktemp -d)
    root=$tmp/squashfs-root
    if _teku_appimage_extract "$dest" "$tmp" '*.desktop'; then
        local desktop
        desktop=$(find "$root" -maxdepth 1 -name '*.desktop' | head -n1)
        if [[ -n $desktop ]]; then
            name=$(sed -n 's/^Name=//p' "$desktop" | head -n1)
        fi
        # .DirIcon is usually a symlink into the image; extract its target too.
        if _teku_appimage_extract "$dest" "$tmp" .DirIcon && [[ -L $root/.DirIcon ]]; then
            _teku_appimage_extract "$dest" "$tmp" "$(readlink "$root/.DirIcon")"
        fi
        if [[ -s $root/.DirIcon ]]; then
            [[ $(file -bL --mime-type "$root/.DirIcon") == image/png ]] && icon_ext=png
            icon=$TEKU_ICON_DIR/$id.$icon_ext
            cp -L -- "$root/.DirIcon" "$icon"
        fi
    fi
    rm -rf -- "$tmp"

    echo "creating menu entry"
    cat >"$TEKU_MENU_DIR/teku-$id.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=${name:-${id}}
Exec="$dest" %U
Icon=${icon:-application-x-executable}
Terminal=false
Categories=Utility;
X-Teku-AppImage=$dest
EOF
    if command -v update-desktop-database >/dev/null; then
        update-desktop-database "$TEKU_MENU_DIR" 2>/dev/null || true
    fi
    echo "done"
}

# Paths of AppImages Teku has installed, one per line.
teku_appimage_list() {
    local f
    for f in "$TEKU_MENU_DIR"/teku-*.desktop; do
        [[ -f $f ]] && sed -n 's/^X-Teku-AppImage=//p' "$f"
    done
}

teku_uninstall_appimage() {
    local app=$1 entry icon
    entry=$(grep -lxF "X-Teku-AppImage=$app" "$TEKU_MENU_DIR"/teku-*.desktop 2>/dev/null | head -n1)
    if [[ -n $entry ]]; then
        icon=$(sed -n 's/^Icon=//p' "$entry")
        [[ $icon == "$TEKU_ICON_DIR"/* ]] && rm -f -- "$icon"
        rm -f -- "$entry"
    fi
    # Trash rather than delete, so a mistake can be undone.
    if [[ -e $app ]]; then
        gio trash -- "$app" 2>/dev/null || rm -f -- "$app"
    fi
    if command -v update-desktop-database >/dev/null; then
        update-desktop-database "$TEKU_MENU_DIR" 2>/dev/null || true
    fi
}
