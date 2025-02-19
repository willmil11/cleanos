# Configuration
NIMFLAGS = --os:standalone --noMain --mm:none --cpu:i386 --cc:gcc --passC:"-m32"
CFLAGS = -m32 -nostdlib -nostdinc -fno-builtin -fno-stack-protector -nostartfiles -nodefaultlibs -Wall -Wextra -c
CC = gcc
LD = ld
ASM = nasm
LDFLAGS = -m elf_i386 -T linker.ld -nostdlib
ASMFLAGS = -f elf32

# Files
KERNEL_NIM = main.nim
BOOT_ASM = boot.asm
KERNEL_OBJ = nimcache/@mmain.nim.c.o nimcache/boot.o
ISO_DIR = isodir
KERNEL_BIN = $(ISO_DIR)/boot/kernel.bin
ISO_IMAGE = cleanos.iso

# Default target
all: $(ISO_IMAGE)

# Compile Assembly to object file
nimcache/boot.o: $(BOOT_ASM)
	mkdir -p nimcache
	$(ASM) $(ASMFLAGS) $(BOOT_ASM) -o nimcache/boot.o

# Compile Nim to C and object files
nim_c: $(KERNEL_NIM)
	nim c $(NIMFLAGS) --noLinking --nimcache:nimcache $(KERNEL_NIM)

# Build the kernel binary
$(KERNEL_BIN): nim_c nimcache/boot.o
	mkdir -p $(ISO_DIR)/boot
	$(LD) $(LDFLAGS) $(KERNEL_OBJ) -o $(KERNEL_BIN)

# Create bootable ISO image
$(ISO_IMAGE): $(KERNEL_BIN)
	mkdir -p $(ISO_DIR)/boot/grub
	echo 'menuentry "cleanos" { multiboot /boot/kernel.bin }' > $(ISO_DIR)/boot/grub/grub.cfg
	grub-mkrescue -o $(ISO_IMAGE) $(ISO_DIR)

# Run in QEMU
run: $(ISO_IMAGE)
	qemu-system-i386 -cdrom $(ISO_IMAGE)

# Debug with QEMU and GDB
debug: $(ISO_IMAGE)
	qemu-system-i386 -cdrom $(ISO_IMAGE) -s -S &
	gdb -ex "target remote localhost:1234" -ex "symbol-file $(KERNEL_BIN)"

# Clean build files
clean:
	rm -rf nimcache $(ISO_DIR) $(ISO_IMAGE)

.PHONY: all nim_c run debug clean