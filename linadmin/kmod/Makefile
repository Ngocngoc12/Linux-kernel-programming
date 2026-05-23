# Makefile for hello_kmod kernel module
# Usage: make              (build .ko file)
#        make clean        (remove build artifacts)
#        sudo insmod hello_kmod.ko
#        sudo rmmod hello_kmod

obj-m += hello_kmod.o

KDIR ?= /lib/modules/$(shell uname -r)/build
PWD  := $(shell pwd)

all:
	$(MAKE) -C $(KDIR) M=$(PWD) modules

clean:
	$(MAKE) -C $(KDIR) M=$(PWD) clean

.PHONY: all clean
