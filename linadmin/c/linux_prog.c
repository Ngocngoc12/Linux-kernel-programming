/*
 * linux_prog.c — Linux System Programming Demo
 * Modes: proc (fork/exec), file (I/O), net (socket TCP)
 * Compile: gcc -Wall -Wextra -O2 -std=c11 -o linux_prog linux_prog.c
 */

#define _GNU_SOURCE
#include <arpa/inet.h>
#include <errno.h>
#include <fcntl.h>
#include <ifaddrs.h>
#include <netinet/in.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

#define TEST_FILE "/tmp/linadmin_test.dat"
#define DEFAULT_PORT 9090

/* ===== PROCESS MODE: fork/exec/wait ===== */
static int mode_proc(void) {
    printf("=== MODE: proc (fork / exec / wait) ===\n");
    printf("Parent PID: %d\n", getpid());

    pid_t pid = fork();
    if (pid < 0) {
        perror("fork");
        return 1;
    }
    if (pid == 0) {
        char *const argv[] = {"/bin/echo", "Hello from child (exec echo)", NULL};
        execv(argv[0], argv);
        perror("execv");
        _exit(127);
    }

    int status = 0;
    if (waitpid(pid, &status, 0) < 0) {
        perror("waitpid");
        return 1;
    }
    if (WIFEXITED(status))
        printf("Child exit code: %d\n", WEXITSTATUS(status));
    else
        printf("Child did not exit normally (status=0x%x)\n", status);
    return 0;
}

/* ===== FILE MODE: write/read/stat ===== */
static int mode_file(void) {
    printf("=== MODE: file (write / read / stat) ===\n");
    const char *msg = "LinAdmin file I/O demo\n";
    int fd = open(TEST_FILE, O_CREAT | O_RDWR | O_TRUNC, 0644);
    if (fd < 0) {
        perror("open");
        return 1;
    }
    ssize_t w = write(fd, msg, strlen(msg));
    printf("write: %zd bytes\n", w);
    if (lseek(fd, 0, SEEK_SET) < 0) {
        perror("lseek");
        close(fd);
        return 1;
    }
    char buf[128] = {0};
    ssize_t r = read(fd, buf, sizeof(buf) - 1);
    printf("read:  %zd bytes -> %s", r, buf);
    close(fd);

    struct stat st;
    if (stat(TEST_FILE, &st) == 0)
        printf("stat size: %ld bytes, mode=%o\n", (long)st.st_size, st.st_mode & 0777);
    return 0;
}

/* ===== NETWORK MODE: show interfaces ===== */
static int mode_net(void) {
    struct ifaddrs *ifa = NULL;

    printf("=== MODE: net (interfaces + TCP) ===\n");
    if (getifaddrs(&ifa) != 0) {
        perror("getifaddrs");
        return 1;
    }
    printf("--- Interfaces ---\n");
    for (struct ifaddrs *p = ifa; p; p = p->ifa_next) {
        if (!p->ifa_addr || p->ifa_addr->sa_family != AF_INET)
            continue;
        char host[INET_ADDRSTRLEN];
        struct sockaddr_in *sin = (struct sockaddr_in *)p->ifa_addr;
        inet_ntop(AF_INET, &sin->sin_addr, host, sizeof(host));
        printf("  %-16s IPv4 %s\n", p->ifa_name, host);
    }
    freeifaddrs(ifa);

    printf("\n--- TCP established ---\n");
    FILE *fp = popen("ss -t state established 2>/dev/null | head -10", "r");
    if (fp) {
        char line[256];
        while (fgets(line, sizeof(line), fp))
            fputs(line, stdout);
        pclose(fp);
    } else {
        printf("(requires iproute2)\n");
    }
    return 0;
}

/* ===== SERVER MODE: TCP listen ===== */
static int mode_server(int argc, char *argv[]) {
    int port = DEFAULT_PORT;
    const char *reply = "Hello from LinAdmin server\n";

    if (argc > 2) port = atoi(argv[2]);
    if (argc > 3) reply = argv[3];

    printf("=== MODE: server (TCP port %d) ===\n", port);
    int srv = socket(AF_INET, SOCK_STREAM, 0);
    if (srv < 0) {
        perror("socket");
        return 1;
    }
    int opt = 1;
    setsockopt(srv, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));

    struct sockaddr_in addr = {0};
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = htonl(INADDR_ANY);
    addr.sin_port = htons((uint16_t)port);

    if (bind(srv, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
        perror("bind");
        close(srv);
        return 1;
    }
    if (listen(srv, 1) < 0) {
        perror("listen");
        close(srv);
        return 1;
    }
    printf("Listening on 0.0.0.0:%d (1 client)...\n", port);

    struct sockaddr_in cli;
    socklen_t len = sizeof(cli);
    int fd = accept(srv, (struct sockaddr *)&cli, &len);
    if (fd < 0) {
        perror("accept");
        close(srv);
        return 1;
    }

    char buf[512] = {0};
    ssize_t n = recv(fd, buf, sizeof(buf) - 1, 0);
    if (n > 0) {
        buf[n] = 0;
        printf("Received: %s", buf);
    }
    send(fd, reply, strlen(reply), 0);
    printf("Sent reply: %s", reply);
    close(fd);
    close(srv);
    return 0;
}

/* ===== CLIENT MODE: TCP connect ===== */
static int mode_client(int argc, char *argv[]) {
    const char *host = "127.0.0.1";
    int port = DEFAULT_PORT;
    const char *msg = "Hello from LinAdmin client\n";

    if (argc > 2) host = argv[2];
    if (argc > 3) port = atoi(argv[3]);
    if (argc > 4) msg = argv[4];

    printf("=== MODE: client -> %s:%d ===\n", host, port);
    int fd = socket(AF_INET, SOCK_STREAM, 0);
    if (fd < 0) {
        perror("socket");
        return 1;
    }

    struct sockaddr_in addr = {0};
    addr.sin_family = AF_INET;
    addr.sin_port = htons((uint16_t)port);
    if (inet_pton(AF_INET, host, &addr.sin_addr) <= 0) {
        fprintf(stderr, "Invalid host: %s\n", host);
        close(fd);
        return 1;
    }
    if (connect(fd, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
        perror("connect");
        close(fd);
        return 1;
    }
    send(fd, msg, strlen(msg), 0);
    printf("Sent: %s", msg);

    char buf[512] = {0};
    ssize_t n = recv(fd, buf, sizeof(buf) - 1, 0);
    if (n > 0) {
        buf[n] = 0;
        printf("Reply: %s", buf);
    }
    close(fd);
    return 0;
}

static void usage(const char *prog) {
    fprintf(stderr,
            "Usage:\n"
            "  %s proc\n"
            "  %s file\n"
            "  %s net\n"
            "  %s server [port] [reply]\n"
            "  %s client [host] [port] [message]\n",
            prog, prog, prog, prog, prog);
}

int main(int argc, char *argv[]) {
    if (argc < 2) {
        usage(argv[0]);
        return 1;
    }
    if (strcmp(argv[1], "proc") == 0)
        return mode_proc();
    if (strcmp(argv[1], "file") == 0)
        return mode_file();
    if (strcmp(argv[1], "net") == 0)
        return mode_net();
    if (strcmp(argv[1], "server") == 0)
        return mode_server(argc, argv);
    if (strcmp(argv[1], "client") == 0)
        return mode_client(argc, argv);

    usage(argv[0]);
    return 1;
}
