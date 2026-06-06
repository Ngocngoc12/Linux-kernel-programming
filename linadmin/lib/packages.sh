#!/bin/bash
# lib/packages.sh — Package management: install, remove, history

set -euo pipefail

PKG_HIST="$LINADMIN_ROOT/logs/apt_history.log"

pkg_log() {
    echo "[$(date -Iseconds)] $*" >>"$PKG_HIST"
    log_msg "APT: $*"
}

pkg_update() {
    pkg_log "UPDATE start"
    sudo DEBIAN_FRONTEND=noninteractive apt-get update -qq 2>&1 || true
    pkg_log "UPDATE done"
    echo "✓ apt update complete"
}

pkg_install_interactive() {
    local pkg
    pkg=$(dialog --inputbox "Package name to install:" 8 50 "tree" 2>&1) || return 0
    [[ -n "$pkg" ]] || return 0
    [[ "$pkg" =~ ^[a-zA-Z0-9][a-zA-Z0-9+.-]*$ ]] || {
        dialog --msgbox "Error: Invalid package name: $pkg" 6 50
        return 0
    }
    dialog --yesno "Confirm install: $pkg ?" 7 45 || return 0
    need_sudo || return 0
    pkg_log "INSTALL $pkg"
    run_and_show "apt install $pkg" sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "$pkg"
    pkg_log "INSTALL $pkg OK"
}

pkg_remove_interactive() {
    local pkg
    pkg=$(dialog --inputbox "Package name to remove:" 8 50 "tree" 2>&1) || return 0
    [[ -n "$pkg" ]] || return 0
    dialog --yesno "Confirm remove: $pkg ?" 7 45 || return 0
    need_sudo || return 0
    pkg_log "REMOVE $pkg"
    run_and_show "apt remove $pkg" sudo apt-get remove -y "$pkg" 2>&1 || true
    pkg_log "REMOVE $pkg OK"
}

pkg_autoremove() {
    pkg_log "AUTOREMOVE start"
    sudo DEBIAN_FRONTEND=noninteractive apt-get autoremove -y 2>&1 || true
    pkg_log "AUTOREMOVE done"
    echo "✓ autoremove complete"
}

pkg_view_history() {
    touch "$PKG_HIST"
    if [[ -s "$PKG_HIST" ]]; then
        show_result "APT History" "$(tail -100 "$PKG_HIST")"
    else
        show_result "APT History" "(empty)"
    fi
}

# Non-interactive CLI functions
install_package() {
    local pkg="$1"
    if [[ -z "$pkg" ]]; then
        echo "Usage: install_package <package>"
        return 1
    fi
    pkg_log "INSTALL $pkg"
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "$pkg"
    pkg_log "INSTALL $pkg OK"
}

remove_package() {
    local pkg="$1"
    if [[ -z "$pkg" ]]; then
        echo "Usage: remove_package <package>"
        return 1
    fi
    pkg_log "REMOVE $pkg"
    sudo apt-get remove -y "$pkg"
    pkg_log "REMOVE $pkg OK"
}

autoremove_packages() {
    pkg_autoremove
}

