[BITS 16]         ; Tells the assembler we're in 16-bit mode
[ORG 0x7C00]      ; BIOS loads the bootloader at this memory address

start:
    ; Print "Hello, OS!" to the screen
    mov si, message       ; Load the address of the string into SI
print_char:
    lodsb                 ; Load the next character from [SI] into AL
    or al, al             ; Check if it's the null terminator
    jz done               ; If zero, end the string
    mov ah, 0x0E          ; BIOS teletype function
    int 0x10              ; Call BIOS interrupt
    jmp print_char        ; Repeat for the next character

done:
    hlt                   ; Halt the CPU

message db "Hello, OS!", 0  ; Null-terminated string

times 510-($-$$) db 0      ; Pad the rest of the bootloader to 510 bytes
dw 0xAA55                  ; Boot signature (required)
