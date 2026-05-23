# Lập trình nhân Linux

Project **`linadmin/`** — chạy trên **Ubuntu 24.04 VM**.

```bash
cd ~/linadmin
sudo apt install -y dialog build-essential gcc make linux-headers-$(uname -r) iproute2
gcc -Wall -Wextra -O2 -std=c11 -o c/linux_prog c/linux_prog.c
chmod +x bin/linadmin.sh
./bin/linadmin.sh
```

Hướng dẫn đầy đủ: [linadmin/README.md](linadmin/README.md)
