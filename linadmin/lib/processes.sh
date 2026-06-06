#!/bin/bash
# lib/processes.sh — Build & run C program (process mode)

set -euo pipefail

cprog_build() {
    echo "Compiling: gcc -Wall -Wextra -O2 -std=c11"
    gcc -Wall -Wextra -O2 -std=c11 \
        -o "$C_BIN" "$LINADMIN_ROOT/c/linux_prog.c" || {
        echo "Error: Compilation failed"
        return 1
    }
    ls -la "$C_BIN"
    echo "✓ Compilation success: $C_BIN"
}

cprog_ensure() {
    if [[ ! -x "$C_BIN" ]]; then
        local log="/tmp/linadmin_build_$$.log"
        if ! cprog_build >"$log" 2>&1; then
            dialog --msgbox "Build failed:\n\n$(cat "$log")" 12 60
            rm -f "$log"
            return 1
        fi
        rm -f "$log"
    fi
    return 0
}

proc_run_interactive() {
    cprog_ensure || return 0
    log_msg "linux_prog proc"
    run_and_show "Process Mode (fork/exec/wait)" "$C_BIN" proc
}

# Non-interactive CLI functions
list_processes() {
    ps aux --sort=-%mem | head -30
}

show_resource_usage() {
    echo "=== CPU Load & Uptime ==="
    uptime
    echo ""
    echo "=== Memory Stats ==="
    free -h
    echo ""
    echo "=== Disk Usage ==="
    df -h /
}

kill_process() {
    local pid="$1"
    if [[ -z "$pid" ]]; then
        echo "Usage: kill_process <pid>"
        return 1
    fi
    if kill -0 "$pid" 2>/dev/null; then
        echo "Killing process $pid..."
        sudo kill -9 "$pid"
        echo "✓ Process $pid terminated"
        if [[ -n "${LOG_FILE:-}" ]]; then
            echo "[$(date -Iseconds)] kill_process: $pid" >> "$LOG_FILE"
        fi
    else
        echo "Error: Process PID $pid does not exist or permission denied"
        return 1
    fi
}

