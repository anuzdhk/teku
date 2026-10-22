# shellcheck shell=bash

teku_install_deb() {
    local f
    f=$(readlink -f -- "$1")
    # apt-get treats an absolute path as a local package file.
    pkexec env DEBIAN_FRONTEND=noninteractive apt-get install -y "$f"
}
