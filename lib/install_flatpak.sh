# shellcheck shell=bash

teku_install_flatpak() {
    local f
    f=$(readlink -f -- "$1")
    flatpak install --noninteractive --from "$f"
}
