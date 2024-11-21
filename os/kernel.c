__attribute__((section(".text.start"))) void kernel_entry() {
    kernel_main();
}

void kernel_main() {
    char* video_memory = (char*) 0xb8000;  // VGA text mode memory address
    const char* message = "Hello from kernel!";
    int i = 0;

    while (message[i] != '\0') {
        video_memory[i * 2] = message[i];  // Character
        video_memory[i * 2 + 1] = 0x07;   // Attribute byte: light gray on black
        i++;
    }

    while (1);  // Infinite loop to keep the kernel running
}
