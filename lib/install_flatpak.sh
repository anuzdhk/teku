# shellcheck shell=bash

teku_install_flatpak() {
    local f
    f=$(readlink -f -- "$1")
    teku_host flatpak install --noninteractive --from "$f"
}
