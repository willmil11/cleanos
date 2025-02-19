# panicoverride.nim
# Simple panic handler for our kernel

{.push stack_trace: off, profiler:off.}

proc rawoutput(s: string) =
  # Simple VGA text mode output for panics
  const vgaMemory = cast[ptr UncheckedArray[uint16]](0xB8000)
  for i in 0..<s.len:
    let index = i
    if index >= 80*25: break  # Stay within screen bounds
    vgaMemory[index] = (0x4F00'u16 or s[i].uint16)  # White on red

proc panic(s: string) {.noreturn, compilerproc.} =
  rawoutput("KERNEL PANIC: " & s)
  while true:
    {.emit: """
      cli
      hlt
    """.}

{.pop.}