# LinAdmin - Linux Kernel Programming Project

**Complete Linux System Management Platform** with Shell Scripts, C Programs, and Kernel Module

## 🎯 Project Overview

LinAdmin is a comprehensive Linux system administration tool built for educational purposes, demonstrating:

- **Shell Scripts**: File management, task scheduling, time/NTP config, package management
- **C Programs**: Process control, file I/O, network operations (TCP server/client)
- **Kernel Module**: LKM development with /proc interface integration
- **Web Dashboard**: Professional dark-theme UI on localhost:3000

Target OS: **Ubuntu 24.04 LTS** (Kernel 6.17+)

---

## 📋 Requirements

### System
- Ubuntu 24.04 LTS or similar
- 2GB+ RAM, 2+ CPU cores
- sudo/root access

### Build Tools
```bash
sudo apt update
sudo apt install -y build-essential gcc make
sudo apt install -y linux-headers-$(uname -r)
sudo apt install -y dialog iproute2 net-tools
sudo apt install -y nodejs npm
```

### Optional
- git (for version control)
- dialog (for TUI menus - if using shell version)

---

## 🚀 Quick Start

### 1. Clone/Setup Project
```bash
# On Ubuntu VM
git clone https://github.com/Ngocngoc12/Linux-kernel-programming.git
cd Linux-kernel-programming/linadmin
```

### 2. Install Dependencies
```bash
sudo apt install -y dialog build-essential gcc make linux-headers-$(uname -r) iproute2
```

### 3. Build C Programs
```bash
gcc -Wall -Wextra -O2 -std=c11 -o c/linux_prog c/linux_prog.c
```

### 4. Build Kernel Module
```bash
cd kmod
make
cd ..
```

### 5. Start Web Dashboard
```bash
# Install Node dependencies
cd web
npm install
npm start
```

Open browser → `http://localhost:3000`

---

## 📁 Directory Structure

```
linadmin/
├── bin/
│   └── linadmin.sh              # Main entry point
├── lib/
│   ├── files.sh                 # Backup, find, cleanup
│   ├── scheduler.sh             # Cron job management
│   ├── time.sh                  # NTP & timezone config
│   ├── packages.sh              # APT management
│   ├── processes.sh             # Process control
│   ├── network.sh               # Socket & TCP ops
│   └── kmod.sh                  # Kernel module ops
├── c/
│   └── linux_prog.c             # 5-mode C program
├── kmod/
│   ├── hello_kmod.c             # Kernel module
│   └── Makefile                 # Build config
├── web/
│   ├── server.js                # Express backend
│   └── public/
│       └── index.html           # Dark theme dashboard
├── logs/
│   ├── linadmin.log             # System logs
│   └── apt_history.log          # Package logs
└── README.md                    # Full documentation
```

---

## 🔧 Features

### 1. Shell Scripts (`lib/*.sh`)

**files.sh**
- Backup directories to tar.gz
- Find files by extension
- Cleanup files older than N days
- Disk usage analysis

**scheduler.sh**
- Add cron jobs with LINADMIN_CRON tag
- List scheduled tasks
- Remove jobs by tag
- View cron history

**time.sh**
- Check NTP status via timedatectl
- Enable/disable NTP sync
- Configure timezone (6 presets + custom)
- Display system time

**packages.sh**
- Update package list (apt update)
- Interactive package install/remove
- Auto-remove unused packages
- Log all operations to apt_history.log

**processes.sh**
- Compile C programs with proper flags
- Run system commands
- Display process status

**network.sh**
- List network interfaces (getifaddrs)
- TCP server mode (listen on port 9090)
- TCP client mode (connect to server)
- Socket operations demo

**kmod.sh**
- Build kernel module (make -C kmod)
- Load module (insmod)
- Unload module (rmmod)
- Check module status
- Install to /lib/modules (auto-boot)

### 2. C Programs (`c/linux_prog.c`)

Demonstrates 5 major system programming concepts:

```
Mode 1: Process Control
  - fork() → create child process
  - execvp() → execute command
  - waitpid() → wait for completion

Mode 2: File Operations  
  - open(), read(), write()
  - stat() → file metadata
  - Permission & size info

Mode 3: Network Interface
  - getifaddrs() → enumerate interfaces
  - inet_ntop() → convert IP to string
  - Display active network cards

Mode 4: TCP Server
  - socket() → create socket
  - bind() → attach to port
  - listen() → accept connections
  - read/write loop

Mode 5: TCP Client
  - socket() → create socket
  - connect() → connect to server
  - send/recv data
```

Compile:
```bash
gcc -Wall -Wextra -O2 -std=c11 -o c/linux_prog c/linux_prog.c
./c/linux_prog [mode] [args...]
```

### 3. Kernel Module (`kmod/hello_kmod.c`)

**Features:**
- Proc filesystem interface `/proc/hello_kmod`
- Kernel logging via `pr_info()` (dmesg)
- Display kernel version & module status
- Compatible with kernel 6.17+ (proc_ops API)
- Auto-boot integration support

**Build & Test:**
```bash
make -C kmod
sudo insmod kmod/hello_kmod.ko
cat /proc/hello_kmod
dmesg | grep hello
sudo rmmod hello_kmod
```

### 4. Web Dashboard (`web/`)

**Technology:**
- Frontend: HTML/CSS/JavaScript (vanilla - no frameworks)
- Backend: Express.js + Node.js
- Theme: Dark mode professional UI
- Port: 3000

**Pages:**
- Dashboard: Quick system metrics
- File Management: Backup, find, cleanup
- Scheduler: Cron job management
- Time & NTP: Time configuration
- Packages: APT operations
- Processes: Process management
- Network: Socket & TCP operations
- Kernel Module: Module status & logs

**API Endpoints:**
- `POST /api/command` → Execute shell commands
- Returns: `{output, error}`

---

## 📊 Demo Checklist

Use this checklist for course presentation:

### Shell Scripts
- [ ] File Management: Backup home directory
- [ ] Scheduler: Add a cron job
- [ ] Time: Check NTP status
- [ ] Packages: Install a package
- [ ] Processes: Compile and run C program

### C Programs
- [ ] Run Mode 1: Fork/exec process
- [ ] Run Mode 2: File operations
- [ ] Run Mode 3: Network interfaces
- [ ] Run Mode 4: Start TCP server (in one terminal)
- [ ] Run Mode 5: Connect as TCP client (in another terminal)

### Kernel Module
- [ ] Build: `make -C kmod`
- [ ] Load: `sudo insmod kmod/hello_kmod.ko`
- [ ] Verify: `cat /proc/hello_kmod`
- [ ] Check logs: `dmesg | grep hello`
- [ ] Unload: `sudo rmmod hello_kmod`

### Web Dashboard
- [ ] Start server: `npm start`
- [ ] Open http://localhost:3000
- [ ] Test all 8 pages
- [ ] Click buttons and verify outputs
- [ ] Check command execution in terminal

---

## 🔨 Build & Run Commands

### One-Time Setup
```bash
# Navigate to project
cd ~/linadmin

# Install dependencies
sudo apt install -y build-essential gcc make linux-headers-$(uname -r) dialog iproute2 nodejs npm

# Install npm packages
cd web && npm install && cd ..

# Make scripts executable
chmod +x bin/*.sh lib/*.sh
```

### Build
```bash
# C program
gcc -Wall -Wextra -O2 -std=c11 -o c/linux_prog c/linux_prog.c

# Kernel module
make -C kmod
```

### Run
```bash
# Shell script interface (if using dialog)
./bin/linadmin.sh

# Web dashboard
cd web && npm start
# Then open http://localhost:3000
```

---

## 🐛 Troubleshooting

### Issue: "gcc: command not found"
```bash
sudo apt install -y build-essential
```

### Issue: Kernel module build fails
```bash
sudo apt install -y linux-headers-$(uname -r)
# Then retry: make -C kmod
```

### Issue: Dialog not found
```bash
sudo apt install -y dialog
```

### Issue: npm start fails with "module not found"
```bash
cd web
npm install
npm start
```

### Issue: Port 3000 already in use
```bash
# Kill existing process
pkill -f "node server.js"
# Or use different port: modify web/server.js
```

### Issue: /proc/hello_kmod not found
```bash
# Check if module is loaded
lsmod | grep hello

# If not loaded:
sudo insmod kmod/hello_kmod.ko

# Verify:
cat /proc/hello_kmod
```

### Issue: Kernel module compilation error with UTS_RELEASE
- ✅ **FIXED**: Added `#include <linux/utsname.h>` and use `utsname()->release`

---

## 📚 Environment Variables

```bash
export LINADMIN_ROOT=~/linadmin
export LOG_FILE=$LINADMIN_ROOT/logs/linadmin.log
export CRON_TAG="LINADMIN_CRON"
export DEFAULT_TCP_PORT=9090
export C_BIN=$LINADMIN_ROOT/c/linux_prog
export KMOD_NAME=hello_kmod
export KMOD_KO=$LINADMIN_ROOT/kmod/$KMOD_NAME.ko
```

---

## 📖 Full Documentation

See [linadmin/README.md](linadmin/README.md) for detailed documentation including:
- Function descriptions
- Shell script specifications
- C program modes
- Kernel module details
- Web API reference

---

## 🎓 Learning Outcomes

By completing this project, you will understand:

✓ Shell scripting with Bash (functions, error handling, logging)
✓ Process management (fork, exec, wait)
✓ File I/O operations (open, read, write, stat)
✓ Network programming (sockets, TCP client/server)
✓ Kernel module development (LKM, proc filesystem)
✓ System administration (cron, APT, timezone)
✓ Web development (Express.js, REST API)
✓ Linux system architecture and APIs

---

## 📝 License

Educational project for Linux Kernel Programming course.

---

## 👤 Author

**Ngocngoc12** - hoangngoc12022004@gmail.com

---

## 🔗 Quick Links

- [GitHub Repository](https://github.com/Ngocngoc12/Linux-kernel-programming)
- [Full Documentation](linadmin/README.md)
- [Linux Kernel Documentation](https://kernel.org/doc/)
- [Ubuntu Manuals](https://manpages.ubuntu.com/)

---

**Last Updated:** May 23, 2026
**Target Kernel:** 6.17.0-29-generic (Ubuntu 24.04 LTS)
