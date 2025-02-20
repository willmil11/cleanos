# panicoverride.nim
# Simple panic handler for our kernel

{.push stack_trace: off, profiler:off.}

proc rawoutput(s: string) =
  # Simple VGA text mode output for panics
  const vgaMemory = cast[ptr UncheckedArray[uint16]](0xB8000)
  
  # Print prefix first
  const prefix = "KERNEL PANIC: "
  for i in 0..<prefix.len:
    let index = i
    if index >= 80*25: break  # Stay within screen bounds
    vgaMemory[index] = (0x4F00'u16 or prefix[i].uint16)  # White on red
  
  # Then print the actual message
  for i in 0..<s.len:
    let index = i + prefix.len
    if index >= 80*25: break  # Stay within screen bounds
    vgaMemory[index] = (0x4F00'u16 or s[i].uint16)  # White on red

proc panic(s: string) {.noreturn, compilerproc.} =
  rawoutput(s)
  # Disable interrupts and halt
  {.emit: """
    asm volatile ("cli");
    while(1) {
      asm volatile ("hlt");
    }
  """.}

{.pop.}