#define MULTIBOOT_MAGIC 0x1BADB002
#define MULTIBOOT_FLAGS 0x00000003
#define MULTIBOOT_CHECKSUM -(MULTIBOOT_MAGIC + MULTIBOOT_FLAGS)

__attribute__((section(".multiboot")))
struct multiboot_header {
    unsigned long magic;
    unsigned long flags;
    unsigned long checksum;
} multiboot_header = {
    MULTIBOOT_MAGIC,
    MULTIBOOT_FLAGS,
    MULTIBOOT_CHECKSUM
};

#if !defined(SIZE_T_DEFINED)
typedef unsigned long size_t;
#define SIZE_T_DEFINED
#endif

#include <stdint.h>

// VGA text buffer constants
#define VGA_WIDTH 80
#define VGA_HEIGHT 25
#define VGA_MEMORY ((volatile uint16_t*)0xB8000)

// VGA color codes
enum vga_color {
    VGA_COLOR_BLACK = 0,
    VGA_COLOR_WHITE = 7  // Changed to a standard VGA color
};

// Function to clear the screen
void clear_screen() {
    for (int y = 0; y < VGA_HEIGHT; y++) {
        for (int x = 0; x < VGA_WIDTH; x++) {
            VGA_MEMORY[y * VGA_WIDTH + x] = (uint16_t)' ' | ((uint16_t)VGA_COLOR_WHITE << 8);
        }
    }
}

// Function to print a string
void kernel_print(const char* str) {
    static int row = 0;
    static int col = 0;
    
    while (*str) {
        if (*str == '\n') {
            row++;
            col = 0;
            str++;
            continue;
        }
        
        const size_t index = row * VGA_WIDTH + col;
        VGA_MEMORY[index] = (uint16_t)*str | ((uint16_t)VGA_COLOR_WHITE << 8);
        
        col++;
        if (col >= VGA_WIDTH) {
            row++;
            col = 0;
        }
        
        str++;
    }
}

// Kernel entry point
void kernel_main() {
    // Clear the screen
    clear_screen();
    
    // Print hello world
    kernel_print("Hello, World from a Minimal OS!\n");
    kernel_print("Welcome to your custom operating system!");
}

// Halt the CPU
__attribute__((noreturn))
void halt() {
    while(1) {
        __asm__ __volatile__("hlt");
    }
}

// Kernel entry point (with noreturn attribute to suppress warnings)
__attribute__((noreturn))
void _start() {
    kernel_main();
    halt();
}