# Makefile for Minimal OS

# Compiler
CC = i686-linux-gnu-gcc

# Compiler flags
CFLAGS = -m32 \
         -ffreestanding \
         -nostdlib \
         -fno-builtin \
         -Wall \
         -Wextra \
         -O2 \
         -fno-pie

# Linker flags
LDFLAGS = -m32 \
          -nostdlib \
          -static \
          -Wl,-T,linker.ld

# Source files
SOURCES = kernel.c

# Output
TARGET = mykernel.bin

# Linker script
LINKER_SCRIPT = linker.ld

# Default target
all: $(TARGET)

# Compile kernel
$(TARGET): $(SOURCES) $(LINKER_SCRIPT)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $(SOURCES)

# Linker script
$(LINKER_SCRIPT):
	@echo "ENTRY(_start)" > $(LINKER_SCRIPT)
	@echo "SECTIONS {" >> $(LINKER_SCRIPT)
	@echo "    . = 1M;" >> $(LINKER_SCRIPT)
	@echo "    .multiboot : { *(.multiboot) }" >> $(LINKER_SCRIPT)
	@echo "    .text : { *(.text) }" >> $(LINKER_SCRIPT)
	@echo "    .rodata : { *(.rodata) }" >> $(LINKER_SCRIPT)
	@echo "    .data : { *(.data) }" >> $(LINKER_SCRIPT)
	@echo "    .bss : { *(.bss) }" >> $(LINKER_SCRIPT)
	@echo "}" >> $(LINKER_SCRIPT)

# Clean up
clean:
	rm -f $(TARGET) $(LINKER_SCRIPT)

# Run in QEMU
run: $(TARGET)
	qemu-system-i386 -kernel $(TARGET)

.PHONY: all clean run