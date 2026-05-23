#!/bin/bash
# lib/scheduler.sh — Cron management

set -euo pipefail

sched_backup_script() { echo "$LINADMIN_ROOT/logs/cron_backup.sh"; }

sched_ensure_script() {
    local script="$(sched_backup_script)"
    cat >"$script" <<'EOF'
#!/bin/bash
WORK="$WORK_DIR"
DEST="$LINADMIN_ROOT/logs"
mkdir -p "$DEST"
tar -czf "$DEST/cron_backup_$(date +%Y%m%d_%H%M%S).tar.gz" -C "$(dirname "$WORK")" "$(basename "$WORK")" 2>/dev/null || true
echo "[$(date -Iseconds)] cron backup" >> "$LOG_FILE"
EOF
    chmod +x "$script"
}

sched_add_backup() {
    sched_ensure_script
    local script=$(sched_backup_script)
    local line="0 3 * * * $script # $CRON_TAG"
    (crontab -l 2>/dev/null | grep -v "$CRON_TAG"; echo "$line") | crontab - 2>/dev/null || return 1
    log_msg "add_cron: $line"
    show_result "Cron Added" "Job at 03:00 daily:\n$line"
}

sched_list() {
    echo "=== Cron jobs tagged $CRON_TAG ===" 
    crontab -l 2>/dev/null | grep "$CRON_TAG" || echo "(none)"
    echo ""
    echo "=== All crontab ==="
    crontab -l 2>/dev/null || echo "(empty)"
}

sched_remove_all() {
    { crontab -l 2>/dev/null | grep -v "$CRON_TAG" || true; } | crontab - 2>/dev/null || true
    log_msg "remove_cron"
    echo "✓ Removed all jobs with tag: $CRON_TAG"
    sched_list
}
