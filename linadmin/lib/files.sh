#!/usr/bin/env bash
# lib/files.sh — backup tar.gz, find, cleanup

files_backup_interactive() {
    local src dest name
    src=$(dialog --inputbox "Thư mục cần backup (đường dẫn tuyệt đối):" 10 60 "$WORK_DIR" 2>&1) || return 0
    [[ -d "$src" ]] || {
        show_result "Lỗi" "Không tìm thấy thư mục: $src"
        return 0
    }
    name=$(basename "$src")
    dest="$LINADMIN_ROOT/logs/backup_${name}_$(date +%Y%m%d_%H%M%S).tar.gz"
    log_msg "files_backup: $src -> $dest"
    if tar -czf "$dest" -C "$(dirname "$src")" "$(basename "$src")" 2>&1; then
        show_result "Backup OK" "Nguồn: $src\nĐích:  $dest\n\n$(ls -lh "$dest")"
    else
        show_result "Backup lỗi" "Không tạo được $dest"
    fi
}

files_find_interactive() {
    local dir ext
    dir=$(dialog --inputbox "Thư mục tìm kiếm:" 8 60 "$WORK_DIR" 2>&1) || return 0
    ext=$(dialog --inputbox "Đuôi file (vd: .log hoặc log):" 8 60 ".txt" 2>&1) || return 0
    [[ -d "$dir" ]] || {
        show_result "Lỗi" "Thư mục không tồn tại: $dir"
        return 0
    }
    [[ "$ext" == .* ]] || ext=".$ext"
    log_msg "files_find: dir=$dir ext=$ext"
    local out
    out=$(find "$dir" -type f -name "*${ext}" 2>/dev/null | head -200)
    [[ -n "$out" ]] || out="(không tìm thấy file *${ext})"
    show_result "Tìm *${ext}" "$out"
}

files_cleanup_interactive() {
    local dir days
    dir=$(dialog --inputbox "Thư mục dọn dẹp:" 8 60 "$WORK_DIR" 2>&1) || return 0
    days=$(dialog --inputbox "Xóa file cũ hơn N ngày (số nguyên):" 8 60 "7" 2>&1) || return 0
    [[ -d "$dir" ]] || {
        show_result "Lỗi" "Thư mục không tồn tại: $dir"
        return 0
    }
    [[ "$days" =~ ^[0-9]+$ ]] || {
        show_result "Lỗi" "N phải là số nguyên không âm"
        return 0
    }
    dialog --yesno "Xóa file trong $dir cũ hơn $days ngày?\n(Không xóa thư mục con)" 10 60 || return 0
    log_msg "files_cleanup: dir=$dir days=$days"
    local list count
    list=$(find "$dir" -maxdepth 1 -type f -mtime +"$days" 2>/dev/null)
    count=$(echo "$list" | grep -c . 2>/dev/null || echo 0)
    if [[ -z "$list" ]]; then
        show_result "Cleanup" "Không có file nào cũ hơn $days ngày."
        return 0
    fi
    echo "$list" | while read -r f; do
        [[ -n "$f" ]] && rm -fv "$f"
    done >"/tmp/linadmin_cleanup_$$.log" 2>&1
    show_result "Cleanup xong" "Đã xử lý ~$count file.\n\n$(cat /tmp/linadmin_cleanup_$$.log)"
    rm -f "/tmp/linadmin_cleanup_$$.log"
}

# Non-interactive CLI functions
backup_directory() {
    local src="$1"
    if [[ -z "$src" ]]; then
        echo "Usage: backup_directory <directory>"
        return 1
    fi
    if [[ ! -d "$src" ]]; then
        echo "Error: Directory '$src' does not exist"
        return 1
    fi
    local name
    name=$(basename "$src")
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    local dest
    # Save to logs folder if LINADMIN_ROOT is set, otherwise current directory
    if [[ -n "${LINADMIN_ROOT:-}" ]]; then
        dest="$LINADMIN_ROOT/logs/${name}_${timestamp}.tar.gz"
    else
        dest="${name}_${timestamp}.tar.gz"
    fi
    
    echo "Backing up directory '$src' to '$dest'..."
    if tar -czf "$dest" -C "$(dirname "$src")" "$(basename "$src")" 2>&1; then
        echo "✓ Backup successful: $dest"
        if [[ -n "${LOG_FILE:-}" ]]; then
            echo "[$(date -Iseconds)] backup_directory: $src -> $dest" >> "$LOG_FILE"
        fi
        return 0
    else
        echo "Error: Backup failed"
        return 1
    fi
}

find_files_by_extension() {
    local dir="$1"
    local ext="$2"
    if [[ -z "$dir" || -z "$ext" ]]; then
        echo "Usage: find_files_by_extension <directory> <extension>"
        return 1
    fi
    if [[ ! -d "$dir" ]]; then
        echo "Error: Directory '$dir' does not exist"
        return 1
    fi
    [[ "$ext" == .* ]] || ext=".$ext"
    
    echo "Finding files with extension '*$ext' in '$dir':"
    local count=0
    local found=""
    found=$(find "$dir" -type f -name "*${ext}" 2>/dev/null | head -50)
    if [[ -n "$found" ]]; then
        echo "$found"
        count=$(echo "$found" | wc -l)
    fi
    echo "Total: $count file(s) found."
    if [[ -n "${LOG_FILE:-}" ]]; then
        echo "[$(date -Iseconds)] find_files_by_extension: dir=$dir ext=$ext count=$count" >> "$LOG_FILE"
    fi
}

cleanup_old_files() {
    local dir="$1"
    local days="$2"
    if [[ -z "$dir" || -z "$days" ]]; then
        echo "Usage: cleanup_old_files <directory> <days>"
        return 1
    fi
    if [[ ! -d "$dir" ]]; then
        echo "Error: Directory '$dir' does not exist"
        return 1
    fi
    if [[ ! "$days" =~ ^[0-9]+$ ]]; then
        echo "Error: Days must be a non-negative integer"
        return 1
    fi
    
    echo "Cleaning up files in '$dir' older than $days days (maxdepth 1)..."
    local list
    list=$(find "$dir" -maxdepth 1 -type f -mtime +"$days" 2>/dev/null)
    if [[ -z "$list" ]]; then
        echo "No files found older than $days days."
        return 0
    fi
    
    local count=0
    echo "$list" | while read -r f; do
        if [[ -n "$f" ]]; then
            rm -fv "$f"
            count=$((count+1))
        fi
    done
    echo "✓ Cleanup complete. Processed $count file(s)."
    if [[ -n "${LOG_FILE:-}" ]]; then
        echo "[$(date -Iseconds)] cleanup_old_files: dir=$dir days=$days count=$count" >> "$LOG_FILE"
    fi
}

