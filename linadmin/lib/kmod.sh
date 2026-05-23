#!/bin/bash
# lib/kmod.sh — Kernel module: build, load, unload, status

set -euo pipefail

kmod_build() {
    echo "Building kernel module..."
    make -C "$LINADMIN_ROOT/kmod" clean all 2>&1 || {
        echo "Error: Build failed"
        return 1
    }
    [[ -f "$KMOD_KO" ]] && ls -la "$KMOD_KO"
    echo "✓ Build OK"
}

kmod_insmod() {
    [[ -f "$KMOD_KO" ]] || { echo "Error: $KMOD_KO not found — build first"; return 1; }
    if lsmod 2>/dev/null | grep -q "^${KMOD_NAME} "; then
        echo "Module already loaded."
    else
        sudo insmod "$KMOD_KO" || { echo "Error: insmod failed"; return 1; }
        echo "✓ insmod OK"
    fi
    echo ""
    if [[ -r "/proc/${KMOD_NAME}" ]]; then
        echo "=== /proc/${KMOD_NAME} ==="
        cat "/proc/${KMOD_NAME}"
    else
        echo "(cannot read /proc)"
    fi
}

kmod_rmmod() {
    if lsmod 2>/dev/null | grep -q "^${KMOD_NAME} "; then
        sudo rmmod "$KMOD_NAME" || { echo "Error: rmmod failed"; return 1; }
        echo "✓ rmmod OK"
    else
        echo "Module not loaded."
    fi
}

kmod_status() {
    echo "=== lsmod ==="
    lsmod 2>/dev/null | grep -E "^Module|^${KMOD_NAME} " || echo "(not loaded)"
    echo ""
    echo "=== /proc/${KMOD_NAME} ==="
    if [[ -r "/proc/${KMOD_NAME}" ]]; then
        cat "/proc/${KMOD_NAME}"
    else
        echo "(not available — need insmod)"
    fi
    echo ""
    echo "=== dmesg (last 20) ==="
    dmesg 2>/dev/null | tail -20 | grep -i "$KMOD_NAME" || dmesg 2>/dev/null | tail -10
}

kmod_install_boot() {
    need_sudo || return 1
    [[ -f "$KMOD_KO" ]] || { echo "Error: Build module first"; return 1; }
    local kver
    kver="$(uname -r)"
    echo "Installing to /lib/modules/${kver}/extra/..."
    sudo mkdir -p "/lib/modules/${kver}/extra"
    sudo cp "$KMOD_KO" "/lib/modules/${kver}/extra/"
    sudo depmod -a
    echo "$KMOD_NAME" | sudo tee "/etc/modules-load.d/${KMOD_NAME}.conf" >/dev/null
    echo "✓ Auto-load configured"
    echo "Test: sudo modprobe $KMOD_NAME"
    echo "Reboot to verify"
}
