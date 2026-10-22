# shellcheck shell=bash
# Inside the Flathub build, host commands go through flatpak-spawn.

teku_host() {
    if [[ -f /.flatpak-info ]]; then
        flatpak-spawn --host "$@"
    else
        "$@"
    fi
}
