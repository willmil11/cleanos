; keyboard.asm - Simple keyboard interrupt handler

[BITS 32]
global keyboard_handler
extern nim_keyboard_handler

section .text

keyboard_handler:
    ; Create a stack frame
    push ebp
    mov ebp, esp
    
    ; Save registers we'll use
    push eax
    push ecx
    push edx
    
    ; Read scan code from keyboard port (0x60)
    mov dx, 0x60
    in al, dx
    
    ; Convert the scan code to a 32-bit parameter for Nim
    movzx ecx, al
    push ecx
    
    ; Call the Nim handler
    call nim_keyboard_handler
    
    ; Clean up stack
    add esp, 4
    
    ; Send EOI to PIC
    mov dx, 0x20
    mov al, 0x20
    out dx, al
    
    ; Restore registers
    pop edx
    pop ecx
    pop eax
    
    ; Restore frame pointer
    pop ebp
    
    ; Return from interrupt
    iret