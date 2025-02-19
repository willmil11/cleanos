# Makefile for Rust OS

# Tools
TARGET = i686-unknown-linux-gnu
AS = i686-linux-gnu-as
LD = i686-linux-gnu-ld

# Output files
KERNEL = mykernel.bin
BOOT_OBJ = target/boot.o

# Compilation flags
RUSTFLAGS = -C target-cpu=i686 \
            -C panic=abort \
            -C link-arg=-nostartfiles \
            -C link-arg=-T./linker.ld \
            -C target-feature=+sse2

# Build the kernel
$(KERNEL): $(BOOT_OBJ)
	RUSTFLAGS="$(RUSTFLAGS)" cargo build --target $(TARGET)
	$(LD) -T linker.ld -o $(KERNEL) $(BOOT_OBJ) target/$(TARGET)/debug/libcleanos.a

$(BOOT_OBJ): src/boot.s
	@mkdir -p target
	$(AS) src/boot.s -o $(BOOT_OBJ)

# Run in QEMU
run: $(KERNEL)
	qemu-system-i386 -kernel $(KERNEL)

# Clean
clean:
	cargo clean
	rm -f $(KERNEL) $(BOOT_OBJ)

.PHONY: run clean
