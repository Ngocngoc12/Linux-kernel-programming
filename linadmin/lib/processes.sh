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
