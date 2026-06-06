# LinAdmin — Quản lý Hệ thống Linux

**Mục đích:** Project học tập **Lập trình nhân Linux** bao gồm Shell scripting, Lập trình C (processes/files/sockets/network), Linux Kernel Module, và Giao diện Web Cyber-HUD sáng tạo.

**Cấu trúc:**
```
linadmin/
├── bin/
│   └── linadmin.sh          # Dashboard TUI chính (dialog)
├── lib/
│   ├── files.sh             # Quản lý file/backup
│   ├── scheduler.sh         # Quản lý cron job
│   ├── time.sh              # Thiết lập thời gian/NTP
│   ├── packages.sh          # Cài đặt/gỡ bỏ gói
│   ├── processes.sh         # Quản lý tiến trình
│   ├── network.sh           # Thông tin mạng
│   └── kmod.sh              # Build/load kernel module
├── c/
│   └── linux_prog.c         # C program: proc/file/server/client
├── kmod/
│   ├── hello_kmod.c         # Kernel module
│   └── Makefile             # Build kernel module
├── web/
│   ├── server.js            # Express.js Backend Server
│   └── public/
│       ├── index.html       # Web Dashboard chính (Cyber-HUD)
│       └── style.css        # Hệ thống CSS 4 theme màu sắc
├── logs/
│   └── linadmin.log         # Ghi lại tất cả hoạt động
└── README.md                # File này
```

---

## 1. CHUẨN BỊ

### 1.1 Cài đặt Dependencies

```bash
sudo apt update
sudo apt install -y build-essential gcc make dialog iproute2 net-tools dnsutils curl wget
sudo apt install -y linux-headers-$(uname -r) cron
```

### 1.2 Setup Project

```bash
cd ~
chmod +x linadmin/bin/linadmin.sh
chmod +x linadmin/lib/*.sh
```

---

## 2. HƯỚNG DẪN SỬ DỤNG

### 2.1 Chạy Dashboard Chính

```bash
cd ~/linadmin
sudo ./bin/linadmin.sh
```

**Giao diện:**
- Header: Hostname, IP, Uptime, Kernel Version
- Menu 9 tùy chọn chính
- Điều khiển: Enter chọn, Esc quay lại
- Tất cả hoạt động ghi vào `logs/linadmin.log`

### 2.2 Build C Program

```bash
cd ~/linadmin
gcc -Wall -Wextra -O2 -std=c11 -o c/linux_prog c/linux_prog.c
```

### 2.3 Build Kernel Module

```bash
cd ~/linadmin/kmod
sudo make
```

---

## 3. CHỨC NĂNG CHI TIẾT

### 3.1 File Manager (Menu 1)

**Backup thư mục:**
```bash
# Từ dashboard menu 1, hoặc:
source lib/files.sh
backup_directory /home/user/mydir
# → Tạo mydir_YYYYMMDD_HHMMSS.tar.gz
```

**Tìm file theo đuôi:**
```bash
source lib/files.sh
find_files_by_extension /tmp .log
```

**Cleanup file cũ:**
```bash
source lib/files.sh
cleanup_old_files /tmp 7  # Xóa file cũ > 7 ngày
```

### 3.2 Scheduler (Menu 2)

**Thêm cron job backup hàng ngày:**
```bash
source lib/scheduler.sh
add_cron_backup /home/user/data
# → Cron: 2AM hàng ngày
```

**Liệt kê cron jobs:**
```bash
source lib/scheduler.sh
list_cron_jobs
```

**Xóa cron job:**
```bash
source lib/scheduler.sh
remove_cron_backup backup_data_daily
```

### 3.3 Time Management (Menu 3)

**Bật NTP:**
```bash
source lib/time.sh
enable_ntp
```

**Set timezone:**
```bash
source lib/time.sh
set_timezone Asia/Ho_Chi_Minh
```

**Xem trạng thái:**
```bash
source lib/time.sh
show_time_status
```

### 3.4 Packages Management (Menu 4)

**Cài gói:**
```bash
source lib/packages.sh
install_package htop
```

**Gỡ bỏ gói:**
```bash
source lib/packages.sh
remove_package htop
```

**Dọn dẹp:**
```bash
source lib/packages.sh
autoremove_packages
```

### 3.5 Processes (Menu 5)

```bash
source lib/processes.sh
list_processes
show_resource_usage
kill_process 1234
```

### 3.6 Network (Menu 6)

```bash
source lib/network.sh
show_network_info
test_connection google.com
show_listening_ports
```

### 3.7 Kernel Module (Menu 7)

```bash
source lib/kmod.sh
build_kmod
load_kmod
unload_kmod
show_kmod_status
```

### 3.8 View Logs (Menu 8)

```bash
tail -f logs/linadmin.log
```

### 3.9 Exit (Menu 9)

Thoát dashboard.

---

## 4. C PROGRAM MODES

### 4.1 Compile

```bash
cd ~/linadmin
gcc -Wall -Wextra -O2 -std=c11 -o c/linux_prog c/linux_prog.c
```

### 4.2 Mode: Process (fork/exec/wait)

```bash
./c/linux_prog proc /bin/echo "Hello Process"
./c/linux_prog proc /bin/ls -la /tmp
./c/linux_prog proc /usr/bin/whoami
```

**Output:** PID, exit code, output

### 4.3 Mode: File Operations

```bash
# Write
./c/linux_prog file write /tmp/test.txt "Hello Linux"

# Read
./c/linux_prog file read /tmp/test.txt

# Stat
./c/linux_prog file stat /tmp/test.txt
```

### 4.4 Mode: TCP Server (Port 9090 mặc định)

```bash
# Terminal 1:
./c/linux_prog server
# hoặc
./c/linux_prog server 9999
```

Server sẽ lắng nghe, nhận 1 message, gửi reply, thoát.

### 4.5 Mode: TCP Client

```bash
# Terminal 2:
./c/linux_prog client localhost 9090 "Hello Server"
```

Client kết nối, gửi message, nhận reply, thoát.

---

## 5. KERNEL MODULE

### 5.1 Tính năng

- Load: In thông báo via `pr_info`
- Unload: In thông báo unload
- **/proc/hello_kmod:** Đọc kernel release + trạng thái

### 5.2 Build & Test

```bash
cd ~/linadmin/kmod
sudo make

# Load
sudo insmod hello_kmod.ko
dmesg | tail -10

# Xem /proc file
cat /proc/hello_kmod

# Unload
sudo rmmod hello_kmod
dmesg | tail -5

# Cleanup
sudo make clean
```

### 5.3 Auto-load on Boot (BẮT BUỘC)

**Bước 1: Copy module**
```bash
sudo cp kmod/hello_kmod.ko /lib/modules/$(uname -r)/extra/
sudo depmod -a
```

**Bước 2: Tạo cấu hình auto-load**
```bash
echo "hello_kmod" | sudo tee /etc/modules-load.d/hello_kmod.conf
```

**Bước 3: Reboot & Verify**
```bash
sudo reboot
# Sau reboot:
lsmod | grep hello_kmod
cat /proc/hello_kmod
```

### 5.4 Gỡ bỏ Auto-load

```bash
sudo rm -f /etc/modules-load.d/hello_kmod.conf
sudo modprobe -r hello_kmod
```

---

## 6. BONUS: DKMS (Dynamic Kernel Module Support)

Để kernel module tự-build sau kernel update:

```bash
sudo apt install -y dkms
sudo mkdir -p /usr/src/hello_kmod-1.0
sudo cp kmod/hello_kmod.c kmod/Makefile /usr/src/hello_kmod-1.0/
```

Tạo `/usr/src/hello_kmod-1.0/dkms.conf`:

```
PACKAGE_NAME="hello_kmod"
PACKAGE_VERSION="1.0"
CLEAN="make clean"
MAKE="make all"
BUILT_MODULE_LOCATION[0]="."
BUILT_MODULE_NAME[0]="hello_kmod"
DEST_MODULE_LOCATION[0]="/kernel/drivers/misc"
AUTOINSTALL="yes"
```

```bash
sudo dkms add -m hello_kmod -v 1.0
sudo dkms build -m hello_kmod -v 1.0
sudo dkms install -m hello_kmod -v 1.0
sudo dkms status
```

---

## 7. DEMO CHECKLIST

Để nộp project, chụp ảnh các bước sau:

```
□ Screenshot linadmin.sh dashboard (header, menu)

File Manager:
□ Backup thư mục → tar.gz file
□ Tìm file theo đuôi
□ Cleanup file cũ
□ logs/linadmin.log content

Scheduler:
□ Add cron job
□ List cron jobs
□ Remove cron job

Time Management:
□ Enable NTP
□ Set timezone
□ timedatectl status

Packages:
□ Install gói (ví dụ: htop)
□ Remove gói
□ Autoremove
□ apt history log

Processes:
□ List processes
□ Resource usage

Network:
□ Network info (IP/MAC)
□ Connectivity test

C Program:
□ Compile linux_prog
□ Mode proc: fork/exec/wait
□ Mode file: write/read/stat
□ Mode server: start server
□ Mode client: connect & reply

Kernel Module:
□ Build: make
□ Load: insmod
□ /proc/hello_kmod content
□ lsmod verify
□ dmesg output
□ Unload: rmmod
□ Auto-load setup
□ Reboot verify

Logs:
□ logs/linadmin.log full content
```

---

## 8. QUICK START (Copy-Paste)

```bash
# Setup
cd ~/linadmin
chmod +x bin/linadmin.sh lib/*.sh

# Build C program
gcc -Wall -Wextra -O2 -std=c11 -o c/linux_prog c/linux_prog.c

# Build kernel module
sudo make -C kmod

# Run dashboard
sudo ./bin/linadmin.sh

# Test C program
./c/linux_prog proc /bin/echo "Test"
./c/linux_prog file write /tmp/t.txt "Hi"
./c/linux_prog file read /tmp/t.txt

# Test server/client
# Terminal 1:
./c/linux_prog server 9090
# Terminal 2:
./c/linux_prog client localhost 9090 "Hello"

# Test kernel module
sudo insmod kmod/hello_kmod.ko
cat /proc/hello_kmod
sudo rmmod hello_kmod
dmesg | tail -5
```

---

## 9. TROUBLESHOOTING

| Vấn đề | Cách khắc phục |
|--------|----------------|
| `command not found: dialog` | `sudo apt install -y dialog` |
| `Permission denied` .sh files | `chmod +x lib/*.sh bin/linadmin.sh` |
| Kernel headers không tìm thấy | `sudo apt install -y linux-headers-$(uname -r)` |
| TCP client không kết nối | Server phải chạy trước; kiểm tra firewall |
| C program lỗi compile | `gcc -v`, check linux kernel headers |
| Cron không chạy | `sudo service cron status` |
| Module load lỗi | `dmesg` → check error messages |

---

**Tác giả:** Ngocngoc12 (hoangngoc12022004@gmail.com)  
**Ngày:** June 2026  
**Yêu cầu:** Ubuntu 24.04+, Kernel 6.0+, sudo privileges
