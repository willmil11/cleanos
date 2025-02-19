# Multiboot header constants
.set ALIGN,     1<<0                # align loaded modules on page boundaries
.set MEMINFO,   1<<1                # provide memory map
.set FLAGS,     ALIGN | MEMINFO     # this is the Multiboot 'flag' field
.set MAGIC,     0x1BADB002          # 'magic number' lets bootloader find the header
.set CHECKSUM,  -(MAGIC + FLAGS)    # checksum of above, to prove we are multiboot

# Multiboot header
.section .multiboot
.align 4
.long MAGIC
.long FLAGS
.long CHECKSUM

# Reserve initial kernel stack.
.section .bss
.align 16
stack_bottom:
.skip 16384 # 16 KiB
stack_top:

# Interrupt handler
.section .text
.global timer_handler_wrapper
timer_handler_wrapper:
    pushal                  # Save all registers
    cld                     # Clear direction flag
    call timer_handler      # Call our Rust handler
    popal                   # Restore all registers
    iret                    # Return from interrupt

# Kernel entry point
.global _start
.type _start, @function
_start:
    # Set up stack
    mov $stack_top, %esp

    # Call kernel_main
    call kernel_main

    # Halt if kernel_main returns
    cli      # Disable interrupts
1:  hlt      # Halt the CPU
    jmp 1b   # Jump back to hlt if we ever wake up

# Set the size of the _start symbol to the current location '.' minus its start.
.size _start, . - _start