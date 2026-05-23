#!/bin/bash
# lib/time.sh — Time management: NTP, timezone

set -euo pipefail

time_status() {
    timedatectl status 2>&1 || {
        echo "date: $(date)"
        [[ -f /etc/timezone ]] && cat /etc/timezone || echo "timezone: unknown"
    }
}

time_ntp_on() {
    sudo timedatectl set-ntp true 2>&1 || true
    echo "✓ NTP enabled"
    time_status
}

time_ntp_off() {
    sudo timedatectl set-ntp false 2>&1 || true
    echo "✓ NTP disabled"
    time_status
}

time_set_tz_interactive() {
    local tz
    tz=$(dialog --menu "Select timezone:" 14 60 6 \
        1 "Asia/Ho_Chi_Minh" \
        2 "Asia/Bangkok" \
        3 "UTC" \
        4 "America/New_York" \
        5 "Europe/London" \
        6 "Custom" 2>&1) || return 0
    case "$tz" in
        1) tz="Asia/Ho_Chi_Minh" ;;
        2) tz="Asia/Bangkok" ;;
        3) tz="UTC" ;;
        4) tz="America/New_York" ;;
        5) tz="Europe/London" ;;
        6) tz=$(dialog --inputbox "Enter timezone:" 8 60 "Asia/Ho_Chi_Minh" 2>&1) || return 0 ;;
        *) return 0 ;;
    esac
    need_sudo || return 0
    log_msg "set_tz: $tz"
    run_and_show "Set Timezone: $tz" sudo timedatectl set-timezone "$tz"
}
