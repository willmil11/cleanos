; Multiboot header constants
MBALIGN     equ 1 << 0                ; align loaded modules on page boundaries
MEMINFO     equ 1 << 1                ; provide memory map
FLAGS       equ MBALIGN | MEMINFO     ; this is the Multiboot 'flag' field
MAGIC       equ 0x1BADB002            ; 'magic number' lets bootloader find the header
CHECKSUM    equ -(MAGIC + FLAGS)      ; checksum of above to prove we are multiboot

; Multiboot header - see multiboot spec for details
section .multiboot
align 4
    dd MAGIC
    dd FLAGS
    dd CHECKSUM

; Stack setup
section .bss
align 16
stack_bottom:
    resb 16384 ; 16 KiB
stack_top:

; _start - kernel entry point
section .text
global _start
_start:
    ; Set up the stack
    mov esp, stack_top

    ; Call the Nim kernel main function
    extern kmain
    call kmain

    ; If kmain returns, just halt the CPU
    cli      ; Disable interrupts
.hang:
    hlt      ; Halt the CPU
    jmp .hang ; Jump back to hlt if it wakes up