[BITS 16]
[ORG 0x7C00]      ; BIOS loads the bootloader at this memory address

start:
    ; Print "Loading Kernel..." to the screen
    mov si, message       ; Load the address of the string into SI
print_char:
    lodsb                 ; Load the next character from [SI] into AL
    or al, al             ; Check if it's the null terminator
    jz load_kernel        ; If zero, proceed to load the kernel
    mov ah, 0x0E          ; BIOS teletype function
    int 0x10              ; Call BIOS interrupt
    jmp print_char        ; Repeat for the next character

load_kernel:
    ; Load the kernel into memory at 0x1000
    mov ax, 0x1000        ; Segment address where kernel will be loaded
    mov es, ax            ; Set ES to point to the kernel's segment
    xor bx, bx            ; Offset within the segment

    mov ah, 0x02          ; BIOS function to read sectors
    mov al, 3             ; Number of sectors to read (adjust as needed)
    mov ch, 0             ; Cylinder 0
    mov cl, 2             ; Sector 2 (kernel starts here)
    mov dh, 0             ; Head 0
    int 0x13              ; Call BIOS to read the sectors
    jc disk_error         ; Jump if there's an error

    ; Print "Kernel Loaded" for debugging
    mov si, success_msg
print_success:
    lodsb
    or al, al
    jz jump_to_kernel
    mov ah, 0x0E
    int 0x10
    jmp print_success

jump_to_kernel:
    ; Jump to kernel's entry point
    jmp 0x1000:0x0000     ; Far jump to kernel (segment:offset)

disk_error:
    ; Print "Disk Error!" and halt if loading fails
    mov si, error_msg
print_error:
    lodsb
    or al, al
    jz halt
    mov ah, 0x0E
    int 0x10
    jmp print_error

halt:
    hlt                   ; Halt the CPU

message db "Loading Kernel...", 0      ; Boot message
success_msg db "Kernel Loaded!", 0     ; Success message
error_msg db "Disk Error!", 0          ; Error message

times 510-($-$$) db 0                  ; Pad to 512 bytes
dw 0xAA55                              ; Boot sector signature
