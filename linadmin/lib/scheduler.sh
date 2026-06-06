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

# Non-interactive CLI functions
add_cron_backup() {
    local src="$1"
    if [[ -z "$src" ]]; then
        echo "Usage: add_cron_backup <directory>"
        return 1
    fi
    sched_ensure_script
    local script
    script=$(sched_backup_script)
    # Set work directory to target dir for the cron job to back up
    export WORK_DIR="$src"
    # Update script content to back up this directory
    cat >"$script" <<EOF
#!/bin/bash
WORK="$src"
DEST="$LINADMIN_ROOT/logs"
mkdir -p "\$DEST"
tar -czf "\$DEST/cron_backup_\$(date +%Y%m%d_%H%M%S).tar.gz" -C "\$(dirname "\$WORK")" "\$(basename "\$WORK")" 2>/dev/null || true
echo "[\$(date -Iseconds)] cron backup of \$WORK" >> "$LOG_FILE"
EOF
    chmod +x "$script"
    
    # 2AM daily: 0 2 * * *
    local line="0 2 * * * $script # $CRON_TAG"
    (crontab -l 2>/dev/null | grep -v "$CRON_TAG"; echo "$line") | crontab - 2>/dev/null || return 1
    echo "✓ Daily cron backup scheduled at 2:00 AM for '$src'"
    if [[ -n "${LOG_FILE:-}" ]]; then
        echo "[$(date -Iseconds)] add_cron_backup: dir=$src" >> "$LOG_FILE"
    fi
}

list_cron_jobs() {
    sched_list
}

remove_cron_backup() {
    local tag="${1:-$CRON_TAG}"
    (crontab -l 2>/dev/null | grep -v "$tag" || true) | crontab - 2>/dev/null || true
    echo "✓ Removed cron backup job(s) matching '$tag'"
    if [[ -n "${LOG_FILE:-}" ]]; then
        echo "[$(date -Iseconds)] remove_cron_backup: tag=$tag" >> "$LOG_FILE"
    fi
}

