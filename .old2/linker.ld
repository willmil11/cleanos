OUTPUT_FORMAT("elf32-i386")
ENTRY(_start)

SECTIONS {
    /* Start sections at 1MB */
    . = 1M;

    /* Multiboot header first /
    .text BLOCK(4K) : ALIGN(4K) {
        / Ensure multiboot header is at the beginning /
        KEEP((.multiboot))
        *(.text)
    }

    /* Read-only data */
    .rodata BLOCK(4K) : ALIGN(4K) {
        *(.rodata)
    }

    /* Read-write data (initialized) */
    .data BLOCK(4K) : ALIGN(4K) {
        *(.data)
    }

    /* Read-write data (uninitialized) and stack */
    .bss BLOCK(4K) : ALIGN(4K) {
        *(COMMON)
        *(.bss)
    }

    /* Strip unnecessary sections */
    /DISCARD/ : {
        *(.comment)
        *(.eh_frame)
        *(.note.gnu.build-id)
    }
}