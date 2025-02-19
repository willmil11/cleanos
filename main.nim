# main.nim - Ultra minimal Nim kernel
{.passl: "-nostdlib".}
{.passc: "-ffreestanding".}

# Write to vga memory
proc kmain() {.exportc.} =
  # VGA memory pointer
  let vga = cast[ptr UncheckedArray[uint16]](0xB8000)
  
  # Color: white on black (0x0F00)
  const color = 0x0F00'u16
  
  # Write "Hello" directly by ASCII values
  vga[0] = color or 'H'.uint16
  vga[1] = color or 'e'.uint16
  vga[2] = color or 'l'.uint16
  vga[3] = color or 'l'.uint16
  vga[4] = color or 'o'.uint16
  vga[5] = color or ' '.uint16
  vga[6] = color or 'N'.uint16
  vga[7] = color or 'i'.uint16
  vga[8] = color or 'm'.uint16
  vga[9] = color or '!'.uint16
  
  # Halt
  while true:
    {.emit: """
      asm volatile ("hlt");
    """.}