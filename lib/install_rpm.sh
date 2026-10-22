# shellcheck shell=bash

# teku_install_rpm FILE dnf|zypper
teku_install_rpm() {
    local f
    f=$(readlink -f -- "$1")
    case $2 in
        dnf) pkexec dnf install -y "$f" ;;
        # Downloaded RPMs are rarely signed with a key zypper knows; the user
        # already confirmed this exact file.
        zypper) pkexec zypper --non-interactive install --allow-unsigned-rpm "$f" ;;
        *) echo "unknown rpm installer: $2" >&2; return 1 ;;
    esac
}
