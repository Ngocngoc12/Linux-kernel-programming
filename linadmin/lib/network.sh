#!/bin/bash
# lib/network.sh — C program: file, socket, network operations

set -euo pipefail

file_run_interactive() {
    cprog_ensure || return 0
    log_msg "linux_prog file"
    run_and_show "File I/O (read/write/stat)" "$C_BIN" file
}

net_run_interactive() {
    cprog_ensure || return 0
    log_msg "linux_prog net"
    run_and_show "Network Info (interfaces, TCP)" "$C_BIN" net
}

net_server_interactive() {
    cprog_ensure || return 0
    local port msg
    port=$(dialog --inputbox "TCP server port (default $DEFAULT_TCP_PORT):" 8 55 "$DEFAULT_TCP_PORT" 2>&1) || return 0
    port="${port:-$DEFAULT_TCP_PORT}"
    if ! [[ "$port" =~ ^[0-9]+$ ]] || [[ "$port" -lt 1 ]] || [[ "$port" -gt 65535 ]]; then
        dialog --msgbox "Error: Invalid port: $port" 6 50
        return 0
    fi
    msg=$(dialog --inputbox "Reply message:" 8 55 "Hello from LinAdmin server" 2>&1) || return 0
    log_msg "linux_prog server port=$port"
    dialog --infobox "Server listening on port $port.\nOpen terminal 2 → TCP Client menu." 8 60
    sleep 1
    run_and_show "TCP Server (port $port)" "$C_BIN" server "$port" "$msg"
}

net_client_interactive() {
    cprog_ensure || return 0
    local host port msg
    host=$(dialog --inputbox "Server address:" 8 55 "127.0.0.1" 2>&1) || return 0
    port=$(dialog --inputbox "Server port (default $DEFAULT_TCP_PORT):" 8 55 "$DEFAULT_TCP_PORT" 2>&1) || return 0
    port="${port:-$DEFAULT_TCP_PORT}"
    msg=$(dialog --inputbox "Message to send:" 8 55 "Hello from LinAdmin client" 2>&1) || return 0
    if ! [[ "$port" =~ ^[0-9]+$ ]]; then
        dialog --msgbox "Error: Invalid port" 6 50
        return 0
    fi
    log_msg "linux_prog client $host:$port"
    run_and_show "TCP Client ($host:$port)" "$C_BIN" client "$host" "$port" "$msg"
}
