#!/usr/bin/env bash
################################################################################
# LinAdmin Dashboard — TUI cho Quản lý Hệ thống Linux
# Sử dụng: dialog (whiptail fallback)
# Yêu cầu: sudo privileges
################################################################################

set -euo pipefail

# Export paths & config
LINADMIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export LINADMIN_ROOT LOG_FILE="$LINADMIN_ROOT/logs/linadmin.log"
export CRON_TAG="LINADMIN_CRON"
export WORK_DIR="${HOME}/linadmin_work"
export C_BIN="$LINADMIN_ROOT/c/linux_prog"
export KMOD_NAME="hello_kmod"
export KMOD_KO="$LINADMIN_ROOT/kmod/${KMOD_NAME}.ko"
export DEFAULT_TCP_PORT=9090

mkdir -p "$LINADMIN_ROOT/logs" "$WORK_DIR"
touch "$LOG_FILE"

# Source all libs
source "$LINADMIN_ROOT/lib/files.sh"
source "$LINADMIN_ROOT/lib/scheduler.sh"
source "$LINADMIN_ROOT/lib/time.sh"
source "$LINADMIN_ROOT/lib/packages.sh"
source "$LINADMIN_ROOT/lib/processes.sh"
source "$LINADMIN_ROOT/lib/network.sh"
source "$LINADMIN_ROOT/lib/kmod.sh"

# Log message
log_msg() {
    echo "[$(date -Iseconds)] $*" >>"$LOG_FILE"
}

# Check dialog
need_dialog() {
    command -v dialog &>/dev/null || {
        echo "Cài dialog: sudo apt install -y dialog"
        exit 1
    }
}

# Check sudo
need_sudo() {
    if sudo -n true 2>/dev/null; then
        return 0
    fi
    dialog --title "sudo" --passwordbox "Mật khẩu sudo:" 8 45 2>/tmp/linadmin_pw || return 1
    sudo -S -v </tmp/linadmin_pw 2>/dev/null || {
        rm -f /tmp/linadmin_pw
        dialog --msgbox "Sai mật khẩu sudo." 6 35
        return 1
    }
    rm -f /tmp/linadmin_pw
}

# Show result in dialog
show_result() {
    local title="$1" text="$2" tmp
    log_msg "RESULT[$title]"
    tmp="$(mktemp)"
    printf '%b\n' "$text" >"$tmp"
    dialog --title "$title" --scrolltext --textbox "$tmp" 22 78
    rm -f "$tmp"
}

# Run command and show result
run_and_show() {
    local title="$1" out err rc=0
    shift
    log_msg "RUN: $*"
    out="$(mktemp)"; err="$(mktemp)"
    "$@" >"$out" 2>"$err" || rc=$?
    local body
    body="$(cat "$out")"
    [[ -s "$err" ]] && body+=$'\n\n[stderr]\n'"$(cat "$err")"
    [[ $rc -ne 0 ]] && body+=$'\n\n(exit '"$rc"')'
    show_result "$title" "$body"
    rm -f "$out" "$err"
}

# System banner
system_banner() {
    local host up kern
    host="$(hostname -s 2>/dev/null || echo 'localhost')"
    up="$(uptime -p 2>/dev/null || echo 'N/A')"
    kern="$(uname -r)"
    printf '\Zb\Z2╔ LinAdmin Dashboard ╗\Zn\n'
    printf ' Host: \Z6%s\Zn\n' "$host"
    printf ' \Z7%s\Zn\n' "$up"
    printf ' Kernel: \Z6%s\Zn' "$kern"
}

# Menus: File, Scheduler, Time, Packages, Processes, Network, KMod
menu_files() {
    while true; do
        local c
        c=$(dialog --clear --colors --title " [Shell] Quản lý File " \
            --menu "$(system_banner)\n\nEsc = quay lại" 20 78 8 \
            1 "Backup thư mục → tar.gz" \
            2 "Tìm file theo đuôi" \
            3 "Cleanup file cũ (N ngày)" \
            0 "Quay lại" 2>&1) || return 0
        case "$c" in
            1) files_backup_interactive ;;
            2) files_find_interactive ;;
            3) files_cleanup_interactive ;;
            0) return 0 ;;
        esac
    done
}

menu_scheduler() {
    while true; do
        local c
        c=$(dialog --clear --colors --title " [Shell] Cron " \
            --menu "$(system_banner)\n\nKeyword: $CRON_TAG" 20 78 8 \
            1 "Thêm job backup 03:00" \
            2 "Liệt kê job" \
            3 "Gỡ job (theo keyword)" \
            0 "Quay lại" 2>&1) || return 0
        case "$c" in
            1) sched_add_backup ;;
            2) run_and_show "Cron" sched_list ;;
            3) run_and_show "Gỡ cron" sched_remove_all ;;
            0) return 0 ;;
        esac
    done
}

menu_time() {
    while true; do
        local c
        c=$(dialog --clear --colors --title " [Shell] Thời gian " \
            --menu "$(system_banner)" 20 78 10 \
            1 "Xem timedatectl" \
            2 "Bật NTP" \
            3 "Tắt NTP" \
            4 "Đặt timezone" \
            0 "Quay lại" 2>&1) || return 0
        case "$c" in
            1) run_and_show "timedatectl" time_status ;;
            2) need_sudo && run_and_show "NTP ON" time_ntp_on ;;
            3) need_sudo && run_and_show "NTP OFF" time_ntp_off ;;
            4) time_set_tz_interactive ;;
            0) return 0 ;;
        esac
    done
}

menu_packages() {
    while true; do
        local c
        c=$(dialog --clear --colors --title " [Shell] APT " \
            --menu "$(system_banner)" 20 78 12 \
            1 "apt update" \
            2 "Cài gói (confirm)" \
            3 "Gỡ gói (confirm)" \
            4 "autoremove" \
            5 "Xem lịch sử apt" \
            0 "Quay lại" 2>&1) || return 0
        case "$c" in
            1) need_sudo && run_and_show "update" pkg_update ;;
            2) pkg_install_interactive ;;
            3) pkg_remove_interactive ;;
            4) need_sudo && run_and_show "autoremove" pkg_autoremove ;;
            5) pkg_view_history ;;
            0) return 0 ;;
        esac
    done
}

menu_processes() {
    while true; do
        local c
        c=$(dialog --clear --colors --title " [C] Tiến trình " \
            --menu "$(system_banner)" 18 78 6 \
            1 "proc — fork/exec/wait" \
            2 "Biên dịch linux_prog" \
            0 "Quay lại" 2>&1) || return 0
        case "$c" in
            1) proc_run_interactive ;;
            2) run_and_show "gcc" cprog_build ;;
            0) return 0 ;;
        esac
    done
}

menu_network() {
    while true; do
        local c
        c=$(dialog --clear --colors --title " [C] File / Socket / Mạng " \
            --menu "$(system_banner)\nPort mặc định: $DEFAULT_TCP_PORT" 22 78 10 \
            1 "file — ghi/đọc/stat" \
            2 "net — interface + TCP info" \
            3 "server — TCP server" \
            4 "client — TCP client" \
            5 "Biên dịch linux_prog" \
            0 "Quay lại" 2>&1) || return 0
        case "$c" in
            1) file_run_interactive ;;
            2) net_run_interactive ;;
            3) net_server_interactive ;;
            4) net_client_interactive ;;
            5) run_and_show "gcc" cprog_build ;;
            0) return 0 ;;
        esac
    done
}

menu_kmod() {
    while true; do
        local c
        c=$(dialog --clear --colors --title " [Kernel] hello_kmod " \
            --menu "$(system_banner)" 22 78 12 \
            1 "Build .ko" \
            2 "insmod" \
            3 "rmmod" \
            4 "Status: lsmod, /proc, dmesg" \
            5 "Tích hợp boot (modules-load.d)" \
            0 "Quay lại" 2>&1) || return 0
        case "$c" in
            1) run_and_show "Build" kmod_build ;;
            2) need_sudo && run_and_show "insmod" kmod_insmod ;;
            3) need_sudo && run_and_show "rmmod" kmod_rmmod ;;
            4) run_and_show "Status" kmod_status ;;
            5) need_sudo && run_and_show "Boot integration" kmod_install_boot ;;
            0) return 0 ;;
        esac
    done
}

view_logs() {
    dialog --clear --title " View Logs " --scrolltext \
        --textbox "$LOG_FILE" 22 78 2>/dev/null || true
}

# Main menu
main_menu() {
    while true; do
        local c
        c=$(dialog --clear --colors --backtitle "Ubuntu 24.04 LTS — LinAdmin" \
            --title "\Zb\Z4  LẬP TRÌNH NHÂN LINUX\Zn" \
            --menu "$(system_banner)\n\n\Z6Enter\Zn chọn  \Z6Esc\Zn thoát menu con" 24 78 14 \
            1 "\Z2Shell\Zn  Quản lý file" \
            2 "\Z2Shell\Zn  Lập lịch cron" \
            3 "\Z2Shell\Zn  Thời gian hệ thống" \
            4 "\Z2Shell\Zn  Cài/gỡ APT" \
            5 "\Z3C\Zn      Tiến trình" \
            6 "\Z3C\Zn      File, socket, mạng" \
            7 "\Z1K\Zn      Kernel module" \
            8 "\Z7→\Zn      View Logs" \
            0 "\Z1Thoát\Zn" 2>&1) || {
            dialog --yesno "Thoát LinAdmin?" 7 35 && exit 0
            continue
        }
        case "$c" in
            1) menu_files ;;
            2) menu_scheduler ;;
            3) menu_time ;;
            4) menu_packages ;;
            5) menu_processes ;;
            6) menu_network ;;
            7) menu_kmod ;;
            8) view_logs ;;
            0) dialog --yesno "Thoát?" 7 30 && exit 0 ;;
        esac
    done
}

################################################################################
# MAIN
################################################################################

need_dialog
log_msg "START user=$(whoami) pid=$$"
main_menu
log_msg "STOP"
