/*
 * hello_kmod.c — Simple Linux Kernel Module for Learning
 * Features: module_init/exit, pr_info logging, /proc file
 * 
 * Build: cd kmod && make
 * Load:  sudo insmod hello_kmod.ko
 * Check: lsmod | grep hello_kmod
 *        cat /proc/hello_kmod
 *        dmesg | tail -10
 * Unload: sudo rmmod hello_kmod
 */

#include <linux/init.h>
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/proc_fs.h>
#include <linux/seq_file.h>
#include <linux/version.h>
#include <linux/utsname.h>

#define PROC_NAME "hello_kmod"

static struct proc_dir_entry *hello_proc;

/* /proc/hello_kmod read handler */
static int hello_proc_show(struct seq_file *m, void *v) {
    seq_printf(m, "=== LinAdmin Kernel Module ===\n");
    seq_printf(m, "Module: hello_kmod\n");
    seq_printf(m, "Status: loaded and running\n");
    seq_printf(m, "Kernel release: %s\n", utsname()->release);
    seq_printf(m, "============================\n");
    return 0;
}

static int hello_proc_open(struct inode *inode, struct file *file) {
    return single_open(file, hello_proc_show, NULL);
}

#if LINUX_VERSION_CODE >= KERNEL_VERSION(5, 6, 0)
static const struct proc_ops hello_proc_ops = {
    .proc_open = hello_proc_open,
    .proc_read = seq_read,
    .proc_lseek = seq_lseek,
    .proc_release = single_release,
};
#else
static const struct file_operations hello_proc_ops = {
    .owner = THIS_MODULE,
    .open = hello_proc_open,
    .read = seq_read,
    .llseek = seq_lseek,
    .release = single_release,
};
#endif

/* Module initialization */
static int __init hello_kmod_init(void) {
    pr_info("hello_kmod: =========== INIT ===========\n");
    pr_info("hello_kmod: Loading kernel module\n");
    pr_info("hello_kmod: Kernel version: %s\n", utsname()->release);
    
    hello_proc = proc_create(PROC_NAME, 0444, NULL, &hello_proc_ops);
    if (!hello_proc) {
        pr_err("hello_kmod: ERROR - failed to create /proc/%s\n", PROC_NAME);
        return -ENOMEM;
    }
    
    pr_info("hello_kmod: Created /proc/%s\n", PROC_NAME);
    pr_info("hello_kmod: Module loaded successfully! ✓\n");
    pr_info("hello_kmod: ==============================\n");
    return 0;
}

/* Module cleanup */
static void __exit hello_kmod_exit(void) {
    pr_info("hello_kmod: =========== EXIT ===========\n");
    pr_info("hello_kmod: Unloading kernel module\n");
    
    if (hello_proc) {
        proc_remove(hello_proc);
        pr_info("hello_kmod: Removed /proc/%s\n", PROC_NAME);
    }
    
    pr_info("hello_kmod: Module unloaded successfully! ✓\n");
    pr_info("hello_kmod: ==============================\n");
}

module_init(hello_kmod_init);
module_exit(hello_kmod_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("LinAdmin Student");
MODULE_DESCRIPTION("Simple kernel module for Linux kernel programming course");
MODULE_VERSION("1.0");
