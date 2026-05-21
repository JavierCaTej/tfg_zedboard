BUILDROOT_HOST ?= ../buildroot/output/zedboard/host
CROSS_COMPILE ?= $(BUILDROOT_HOST)/bin/arm-buildroot-linux-gnueabihf-

ifeq ($(origin CC),default)
CC := $(CROSS_COMPILE)gcc
endif

CPPFLAGS += -I../include
CFLAGS ?= -O2 -Wall -Wextra -std=c11

TARGET := tfg_axi_memtool
SRCS := tfg_axi_memtool.c

.PHONY: all clean

all: $(TARGET)

$(TARGET): $(SRCS) ../include/tfg_axi_lite_regs.h
	$(CC) $(CPPFLAGS) $(CFLAGS) -o $@ $(SRCS)

clean:
	$(RM) $(TARGET)
