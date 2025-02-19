#![no_std]
#![no_main]

mod mem;

// VGA Buffer constants
const VGA_BUFFER: *mut u16 = 0xB8000 as *mut u16;
const VGA_WIDTH: usize = 80;
const VGA_HEIGHT: usize = 25;

// PIT and interrupt-related constants
const PIT_COMMAND: u16 = 0x43;
const PIT_CHANNEL0: u16 = 0x40;
const PIT_FREQUENCY: u32 = 1193182;
const PIC1_COMMAND: u16 = 0x20;
const PIC1_DATA: u16 = 0x21;

// IDT constants
const IDT_SIZE: usize = 256;

// Global writer state
static mut CURRENT_ROW: usize = 0;
static mut CURRENT_COL: usize = 0;

// Counter for PIT ticks
static mut TICKS: u64 = 0;

// IDT entry structure
#[repr(C, packed)]
#[derive(Copy, Clone)] // Add these derive attributes
struct IdtEntry {
    offset_low: u16,
    selector: u16,
    zero: u8,
    type_attr: u8,
    offset_high: u16,
}

// IDT pointer structure
#[repr(C, packed)]
struct IdtPointer {
    limit: u16,
    base: u32,
}

// Static IDT
static mut IDT: [IdtEntry; IDT_SIZE] = [IdtEntry {
    offset_low: 0,
    selector: 0,
    zero: 0,
    type_attr: 0,
    offset_high: 0,
}; IDT_SIZE];

// Initialize IDT
fn init_idt() {
    unsafe {
        // Set up timer handler (IRQ0, which is interrupt 32)
        let handler_addr = timer_handler_wrapper as u32;
        IDT[32] = IdtEntry {
            offset_low: (handler_addr & 0xFFFF) as u16,
            selector: 0x08, // Kernel code segment
            zero: 0,
            type_attr: 0x8E, // Present, Ring 0, 32-bit Interrupt Gate
            offset_high: ((handler_addr >> 16) & 0xFFFF) as u16,
        };

        // Create and load IDT pointer
        let idt_ptr = IdtPointer {
            limit: (core::mem::size_of::<[IdtEntry; IDT_SIZE]>() - 1) as u16,
            base: IDT.as_ptr() as u32,
        };

        core::arch::asm!("lidt [{}]", in(reg) &idt_ptr);
    }
}

// Port I/O functions
unsafe fn outb(port: u16, value: u8) {
    core::arch::asm!("out dx, al",
        in("dx") port,
        in("al") value,
    );
}

unsafe fn inb(port: u16) -> u8 {
    let value: u8;
    core::arch::asm!("in al, dx",
        out("al") value,
        in("dx") port,
    );
    value
}

// Initialize PIT for timer interrupts
fn init_pit() {
    let divisor = (PIT_FREQUENCY / 1000) as u16; // 1ms intervals
    unsafe {
        // Initialize PIT
        outb(PIT_COMMAND, 0x36);
        outb(PIT_CHANNEL0, (divisor & 0xFF) as u8);
        outb(PIT_CHANNEL0, ((divisor >> 8) & 0xFF) as u8);

        // Configure PIC
        outb(PIC1_COMMAND, 0x11); // Initialize PIC
        outb(PIC1_DATA, 0x20);    // Vector offset (32)
        outb(PIC1_DATA, 0x04);    // Tell Master PIC that there is a slave PIC
        outb(PIC1_DATA, 0x01);    // ICW4
        outb(PIC1_DATA, 0xFE);    // Enable only timer interrupt
    }
}

// Declare the wrapper function from assembly
extern "C" {
    fn timer_handler_wrapper();
}

// PIT interrupt handler
#[no_mangle]
pub extern "C" fn timer_handler() {
    unsafe {
        TICKS = TICKS.wrapping_add(1);
        outb(PIC1_COMMAND, 0x20); // Send EOI
    }
}

// Sleep function
fn sleep(ms: u64) {
    unsafe {
        let target = TICKS + ms;
        while TICKS < target {
            core::arch::asm!("hlt");
        }
    }
}

// Clear the screen
fn clear_screen() {
    for row in 0..VGA_HEIGHT {
        for col in 0..VGA_WIDTH {
            unsafe {
                VGA_BUFFER.add(row * VGA_WIDTH + col).write_volatile(0x0F00); // Black background, white foreground
            }
        }
    }
}

// Write a single character to the screen
fn write_char(c: char) {
    unsafe {
        match c {
            '\n' => {
                CURRENT_ROW += 1;
                CURRENT_COL = 0;
            }
            '\r' => {
                CURRENT_COL = 0;
            }
            c => {
                let color = 0x0F; // White on black
                let index = CURRENT_ROW * VGA_WIDTH + CURRENT_COL;

                if index < VGA_WIDTH * VGA_HEIGHT {
                    VGA_BUFFER.add(index).write_volatile((color << 8) | (c as u16));
                }

                CURRENT_COL += 1;
                if CURRENT_COL >= VGA_WIDTH {
                    CURRENT_COL = 0;
                    CURRENT_ROW += 1;
                }
            }
        }

        // Handle scrolling if we've gone past the bottom
        if CURRENT_ROW >= VGA_HEIGHT {
            // Scroll the screen up one line
            for row in 1..VGA_HEIGHT {
                for col in 0..VGA_WIDTH {
                    let prev_char = VGA_BUFFER.add(row * VGA_WIDTH + col).read_volatile();
                    VGA_BUFFER.add((row - 1) * VGA_WIDTH + col).write_volatile(prev_char);
                }
            }
            // Clear the last line
            for col in 0..VGA_WIDTH {
                VGA_BUFFER.add((VGA_HEIGHT - 1) * VGA_WIDTH + col).write_volatile(0x0F00);
            }
            CURRENT_ROW = VGA_HEIGHT - 1;
        }
    }
}

// Kernel print function
fn print(message: &str) {
    for c in message.chars() {
        write_char(c);
    }
}

#[no_mangle]
pub extern "C" fn rust_eh_personality() {}

#[panic_handler]
fn panic(_info: &core::panic::PanicInfo) -> ! {
    loop {}
}

#[no_mangle]
pub extern "C" fn kernel_main() -> ! {
    clear_screen();

    // Initialize interrupts
    init_idt();
    init_pit();

    // Enable interrupts
    unsafe {
        core::arch::asm!("sti");
    }

    print("Hello, Rust OS World!\n");
    print("Welcome to your Rust Operating System!\n");
    print("Boot successful - System is running.\n\n");

    while true {
        print("[Text] ");
        sleep(1000);
    }

    loop {
        unsafe {
            core::arch::asm!("hlt");
        }
    }
}