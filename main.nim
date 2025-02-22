# main.nim - Ultra minimal Nim kernel with keyboard support
{.passl: "-nostdlib".}
{.passc: "-ffreestanding".}
{.passl: "-fno-stack-protector".}

# Implementation of standard C library functions needed by GCC
{.emit: """
// 64-bit unsigned division for GCC
unsigned long long __udivdi3(unsigned long long a, unsigned long long b) {
  unsigned long long result = 0;
  unsigned long long remainder = 0;
  
  if (b == 0) {
    // Division by zero - just return a very large number
    return (unsigned long long)-1;
  }
  
  // Simple long division algorithm
  for (int i = 63; i >= 0; i--) {
    remainder <<= 1;
    remainder |= (a >> i) & 1;
    
    if (remainder >= b) {
      remainder -= b;
      result |= (1ULL << i);
    }
  }
  
  return result;
}

unsigned long long __umoddi3(unsigned long long a, unsigned long long b) {
  unsigned long long remainder = 0;
  
  if (b == 0) {
    // Modulo by zero - return 0
    return 0;
  }
  
  // Simple long division algorithm
  for (int i = 63; i >= 0; i--) {
    remainder <<= 1;
    remainder |= (a >> i) & 1;
    
    if (remainder >= b) {
      remainder -= b;
    }
  }
  
  return remainder;
}

// Implementation of memset required by GCC
void* memset(void* ptr, int value, unsigned int num) {
  unsigned char* p = (unsigned char*)ptr;
  for (unsigned int i = 0; i < num; i++) {
    p[i] = (unsigned char)value;
  }
  return ptr;
}
""".}

# Port I/O operations - make them available to C code
{.emit: """
// Make I/O functions available to both C and Nim
unsigned char inb(unsigned short port) {
  unsigned char ret;
  __asm__ __volatile__("inb %%dx, %%al" : "=a" (ret) : "d" (port));
  return ret;
}

void outb(unsigned short port, unsigned char value) {
  __asm__ __volatile__ ("outb %%al, %%dx" : : "a" (value), "d" (port));
}
""".}

# Nim wrappers for I/O functions
proc outb(port: uint16, value: uint8) {.importc, cdecl.}
proc inb(port: uint16): uint8 {.importc, cdecl.}

# VGA and CRT constants
const
  VGA_WIDTH = 80
  VGA_HEIGHT = 25
  VGA_MEMORY = 0xB8000
  VGA_COLOR = 0x0F00'u16  # White on black
  # CRT Control Register ports
  CRTC_ADDR_PORT = 0x3D4'u16
  CRTC_DATA_PORT = 0x3D5'u16
  # CRT cursor position registers
  CRTC_CURSOR_HIGH = 0x0E'u8
  CRTC_CURSOR_LOW = 0x0F'u8

# Global cursor position
var
  cursorX {.exportc.}: int = 0
  cursorY {.exportc.}: int = 0

# Update hardware cursor position
proc updateCursor() =
  let pos = (cursorY * VGA_WIDTH + cursorX).uint16
  
  # Set high cursor byte
  outb(CRTC_ADDR_PORT, CRTC_CURSOR_HIGH)
  outb(CRTC_DATA_PORT, uint8((pos shr 8) and 0xFF'u16))
  
  # Set low cursor byte
  outb(CRTC_ADDR_PORT, CRTC_CURSOR_LOW)
  outb(CRTC_DATA_PORT, uint8(pos and 0xFF'u16))

# Print a character to the screen
proc putChar(c: char) =
  let vga = cast[ptr UncheckedArray[uint16]](VGA_MEMORY)
  
  if c == '\b':
    if cursorX > 0:
      cursorX -= 1
      # Clear the character at current position
      vga[cursorY * VGA_WIDTH + cursorX] = VGA_COLOR or ' '.uint16
  elif c == '\n':
    cursorX = 0
    cursorY += 1
  else:
    # Print the character
    vga[cursorY * VGA_WIDTH + cursorX] = VGA_COLOR or c.uint16
    cursorX += 1
  
  # Handle wrapping
  if cursorX >= VGA_WIDTH:
    cursorX = 0
    cursorY += 1
  
  # Handle scrolling
  if cursorY >= VGA_HEIGHT:
    # Move each line up
    for y in 0..<(VGA_HEIGHT-1):
      for x in 0..<VGA_WIDTH:
        vga[y * VGA_WIDTH + x] = vga[(y+1) * VGA_WIDTH + x]
    
    # Clear the last line
    for x in 0..<VGA_WIDTH:
      vga[(VGA_HEIGHT-1) * VGA_WIDTH + x] = VGA_COLOR or ' '.uint16
    
    cursorY = VGA_HEIGHT - 1
  
  # Update hardware cursor
  updateCursor()

# Print a string to the screen
proc print*(s: string) =
  for i in 0..<s.len:
    putChar(s[i])

# Print a C-style string to the screen
proc printCString*(s: cstring) =
  var i = 0
  while s[i] != '\0':
    putChar(s[i])
    i += 1

# PIT constants
const 
  PIT_CHANNEL0_PORT = 0x40'u16
  PIT_COMMAND_PORT = 0x43'u16
  PIT_FREQ_DIVISOR = 11932'u16  # For ~100Hz (1193182 / 100)

# Initialize PIT to generate square wave
proc initPIT() =
  # Channel 0, square wave mode, lo/hi byte access
  outb(PIT_COMMAND_PORT, 0x36'u8)
  
  # Set frequency divisor
  outb(PIT_CHANNEL0_PORT, uint8(PIT_FREQ_DIVISOR and 0xFF'u16))
  outb(PIT_CHANNEL0_PORT, uint8((PIT_FREQ_DIVISOR shr 8) and 0xFF'u16))

# Read current PIT counter value (16-bit down-counter)
proc readPITCounter(): uint16 =
  # Latch counter value command
  outb(PIT_COMMAND_PORT, 0x00'u8)
  
  # Read counter value (low byte, then high byte)
  let low = inb(PIT_CHANNEL0_PORT).uint16
  let high = inb(PIT_CHANNEL0_PORT).uint16
  
  # Combine bytes
  return (high shl 8) or low

# Global spinloop calibration
var loopsPerMs: uint32 = 400000'u32  # Default value (known to work on your system)

# Calibration parameters type
type CalibrationParams* = object
  targetDurationMs*: uint32      # Calibration test duration (default: 20ms)
  iterations*: uint32            # Number of measurement iterations (default: 5)
  tolerance*: uint32             # Acceptable error percentage (default: 5%)
  samplingMultiplier*: uint32    # Sampling size multiplier (default: 10)

# Default calibration parameters
const DefaultCalibrationParams = CalibrationParams(
  targetDurationMs: 20,
  iterations: 5,
  tolerance: 5,
  samplingMultiplier: 10
)

# Enhanced calibration function with configurable parameters
proc calibrateSleep*(params: CalibrationParams = DefaultCalibrationParams) =
  # Convert desired time to PIT ticks (each tick is 10ms with 100Hz PIT)
  let targetTicks = uint16((params.targetDurationMs + 9) div 10)
  var bestLoopsPerMs = loopsPerMs
  var bestAccuracy = 100'u32  # Start with worst possible accuracy (100% error)
  
  # Run multiple calibration attempts for better precision
  for attempt in 1'u32..params.iterations:
    # Capture start conditions
    let startCounter = readPITCounter()
    let testLoops = loopsPerMs * params.targetDurationMs * params.samplingMultiplier
    
    # Run test loop with good sample size
    var counter: uint32 = 0
    while counter < testLoops:
      {.emit: """
        __asm__ __volatile__("nop");
        __asm__ __volatile__("nop");
      """.}
      counter += 1
    
    # Capture end counter and calculate elapsed ticks
    let endCounter = readPITCounter()
    var elapsedTicks: uint16 = 0
    
    if endCounter <= startCounter:
      # Normal case: counter decreased
      elapsedTicks = startCounter - endCounter
    else:  
      # Counter wrapped around
      elapsedTicks = PIT_FREQ_DIVISOR - endCounter + startCounter
    
    # Scale down the loop count for better accuracy
    let actualLoopsPerMs = (testLoops div params.targetDurationMs) div params.samplingMultiplier
    
    # Calculate error percentage (absolute value)
    var errorPercent: uint32 = 0
    if elapsedTicks > targetTicks:
      errorPercent = uint32((elapsedTicks - targetTicks) * 100) div uint32(targetTicks)
    else:
      errorPercent = uint32((targetTicks - elapsedTicks) * 100) div uint32(targetTicks)
    
    # If this attempt is more accurate, use its calibration
    if errorPercent < bestAccuracy:
      bestAccuracy = errorPercent
      
      # Adjust loops/ms based on error ratio
      if elapsedTicks > targetTicks:
        # Too slow - reduce loops
        bestLoopsPerMs = (actualLoopsPerMs * uint32(targetTicks)) div uint32(elapsedTicks)
      else:
        # Too fast - increase loops  
        bestLoopsPerMs = (actualLoopsPerMs * uint32(targetTicks)) div uint32(elapsedTicks + 1)
    
    # If we've achieved good accuracy, stop calibrating
    if errorPercent <= params.tolerance:
      break
  
  # Apply the best calibration found
  loopsPerMs = bestLoopsPerMs

# High-precision sleep function
proc sleep*(ms: int, showDots: bool = false) {.exportc.} =
  if ms <= 0:
    return
  
  # Calculate total loops based on calibration
  let totalLoops = uint64(loopsPerMs) * uint64(ms)
  
  # Main delay loop
  var counter: uint64 = 0
  while counter < totalLoops:
    # Prevent optimization
    {.emit: """
      __asm__ __volatile__("nop");
      __asm__ __volatile__("nop");
      __asm__ __volatile__("nop");
    """.}
    
    # Update counter
    counter += 1

# Stub error handling procedures
proc raiseOverflow() {.exportc, compilerproc, noreturn.} =
  {.emit: """
    asm volatile ("cli");
    while(1) { asm volatile ("hlt"); }
  """.}

proc raiseIndexError2() {.exportc, compilerproc, noreturn.} =
  {.emit: """
    asm volatile ("cli");
    while(1) { asm volatile ("hlt"); }
  """.}

proc raiseRangeError2() {.exportc, compilerproc, noreturn.} =
  {.emit: """
    asm volatile ("cli");
    while(1) { asm volatile ("hlt"); }
  """.}

# Define a very minimal memory allocator for strings
var 
  heapStart {.exportc.}: array[8192, byte] # 8KB heap
  heapIndex {.exportc.}: int = 0

# Required Nim system procedures - barebone implementations
proc rawNewString(len: int): pointer {.exportc, compilerproc.} =
  let headerSize = 2 * sizeof(int)
  let total = headerSize + len + 1
  
  if heapIndex + total > heapStart.len:
    return nil
  
  let mem = addr heapStart[heapIndex]
  heapIndex += total
  
  let str = cast[ptr UncheckedArray[int]](mem)
  str[0] = len
  str[1] = 0
  
  return mem

# Simplified addChar implementation - more C-like approach to avoid advanced Nim features
proc addChar(s: var string, c: char) {.exportc, compilerproc.} =
  if s.len == 0:
    # For empty string, allocate a small buffer to avoid frequent reallocations
    let capacity = 16  # Small initial capacity
    let str = cast[ptr UncheckedArray[char]](rawNewString(capacity))
    
    # Skip header (2 ints)
    let headerSize = 2 * sizeof(int)
    let p = cast[ptr UncheckedArray[char]](cast[uint](str) + headerSize.uint)
    
    # Set the first character
    p[0] = c
    
    # Update string length in header
    cast[ptr UncheckedArray[int]](str)[0] = 1
    
    # Update s
    s = cast[string](str)
  else:
    # Get string header
    let strPtr = cast[ptr UncheckedArray[int]](s)
    let oldLen = strPtr[0]
    
    # Skip header to get character array
    let headerSize = 2 * sizeof(int)
    let chars = cast[ptr UncheckedArray[char]](cast[uint](strPtr) + headerSize.uint)
    
    # Add character at the end if there's space
    chars[oldLen] = c
    
    # Update length
    strPtr[0] = oldLen + 1

proc appendString(dest: var string, src: string) {.exportc, compilerproc.} =
  if src.len == 0:
    return
  if dest.len == 0:
    dest = src
    return

proc copyString(dest: var string, src: string) {.exportc, compilerproc.} =
  dest = src

proc setLengthStr(s: var string, newLen: int) {.exportc, compilerproc.} =
  discard

proc newObj(typ: pointer, size: int): pointer {.exportc, compilerproc.} =
  if heapIndex + size > heapStart.len:
    return nil
    
  let mem = addr heapStart[heapIndex]
  heapIndex += size
  return mem

proc newObjRC1(typ: pointer): pointer {.exportc, compilerproc.} =
  return newObj(typ, 32)

proc initStackBottomWith(a, b: pointer) {.exportc, compilerproc.} =
  discard

#============================================================================
# Keyboard Handling (Polling-based)
#============================================================================

# Keyboard Constants
const
  KEYBOARD_DATA_PORT = 0x60'u16
  KEYBOARD_STATUS_PORT = 0x64'u16

# Keyboard state
var
  shiftPressed = false
  keyboardCallback: proc(key: cstring) {.cdecl.} = nil  # User defined callback function

# Register a keyboard callback function
proc keyboard_input*(callback: proc(key: cstring) {.cdecl.}) =
  keyboardCallback = callback

# Map scan codes to ASCII characters
proc scanCodeToAscii(scanCode: uint8): char =
  case scanCode:
    # Numbers row (AZERTY)
    of 0x02: return (if shiftPressed: '1' else: '&')
    of 0x03: return (if shiftPressed: '2' else: 'e')  # é/2
    of 0x04: return (if shiftPressed: '3' else: '"')
    of 0x05: return (if shiftPressed: '4' else: '\'')
    of 0x06: return (if shiftPressed: '5' else: '(')
    of 0x07: return (if shiftPressed: '6' else: '-')
    of 0x08: return (if shiftPressed: '7' else: 'e')  # è/7
    of 0x09: return (if shiftPressed: '8' else: '_')
    of 0x0A: return (if shiftPressed: '9' else: 'c')  # ç/9
    of 0x0B: return (if shiftPressed: '0' else: 'a')  # à/0
    of 0x0C: return (if shiftPressed: '\0' else: ')')
    of 0x0D: return (if shiftPressed: '+' else: '=')
    # Letters (AZERTY layout)
    of 0x10: return (if shiftPressed: 'A' else: 'a')
    of 0x11: return (if shiftPressed: 'Z' else: 'z')
    of 0x12: return (if shiftPressed: 'E' else: 'e')
    of 0x13: return (if shiftPressed: 'R' else: 'r')
    of 0x14: return (if shiftPressed: 'T' else: 't')
    of 0x15: return (if shiftPressed: 'Y' else: 'y')
    of 0x16: return (if shiftPressed: 'U' else: 'u')
    of 0x17: return (if shiftPressed: 'I' else: 'i')
    of 0x18: return (if shiftPressed: 'O' else: 'o')
    of 0x19: return (if shiftPressed: 'P' else: 'p')
    of 0x1E: return (if shiftPressed: 'Q' else: 'q')
    of 0x1F: return (if shiftPressed: 'S' else: 's')
    of 0x20: return (if shiftPressed: 'D' else: 'd')
    of 0x21: return (if shiftPressed: 'F' else: 'f')
    of 0x22: return (if shiftPressed: 'G' else: 'g')
    of 0x23: return (if shiftPressed: 'H' else: 'h')
    of 0x24: return (if shiftPressed: 'J' else: 'j')
    of 0x25: return (if shiftPressed: 'K' else: 'k')
    of 0x26: return (if shiftPressed: 'L' else: 'l')
    of 0x27: return (if shiftPressed: 'M' else: 'm')
    of 0x2C: return (if shiftPressed: 'W' else: 'w')
    of 0x2D: return (if shiftPressed: 'X' else: 'x')
    of 0x2E: return (if shiftPressed: 'C' else: 'c')
    of 0x2F: return (if shiftPressed: 'V' else: 'v')
    of 0x30: return (if shiftPressed: 'B' else: 'b')
    of 0x31: return (if shiftPressed: 'N' else: 'n')
    of 0x32: return (if shiftPressed: '?' else: ',')
    # Punctuation keys
    of 0x33: return (if shiftPressed: '.' else: ';')
    of 0x34: return (if shiftPressed: '/' else: ':')
    of 0x35: return (if shiftPressed: '\0' else: '!')
    # Special keys
    of 0x39: return ' '  # Space
    of 0x1C: return '\n' # Enter
    of 0x0E: return '\b' # Backspace
    of 0x0F: return '\t' # Tab
    else: return '\0'

# Poll the keyboard for input
proc pollKeyboard() =
  # Check if there's data to read
  let status = inb(KEYBOARD_STATUS_PORT)
  if (status and 0x01) == 0:
    return
  
  # Read the scancode
  let scanCode = inb(KEYBOARD_DATA_PORT)
  
  # Handle shift key state
  if scanCode == 0x2A or scanCode == 0x36:  # Left or right shift pressed
    shiftPressed = true
  elif scanCode == 0xAA or scanCode == 0xB6:  # Left or right shift released
    shiftPressed = false
  
  # Only process key presses (not releases)
  if scanCode < 0x80:
    # Convert to ASCII
    let key = scanCodeToAscii(scanCode)
    
    # Process key if it was recognized
    if key != '\0':
      # Direct key echo to screen
      putChar(key)
      
      # Call user-defined callback if registered
      if keyboardCallback != nil:
        var keyStr: array[2, char]
        keyStr[0] = key
        keyStr[1] = '\0'
        keyboardCallback(cast[cstring](addr keyStr[0]))

# Main kernel function
proc kmain() {.exportc.} =
  # Clear the screen
  let vga = cast[ptr UncheckedArray[uint16]](VGA_MEMORY)
  for i in 0..<(VGA_WIDTH * VGA_HEIGHT):
    vga[i] = VGA_COLOR or ' '.uint16
  
  # Reset cursor position
  cursorX = 0
  cursorY = 0
  
  # Initialize PIT
  initPIT()
  
  # Main welcome message
  print("Cleanos Keyboard Demo\n")
  print("----------------------\n")
  print("Keyboard polling initialized\n")
  print("Try typing on your keyboard...\n\n")
  
  # Register keyboard callback (optional)
  keyboard_input(proc(key: cstring) {.cdecl.} =
    # This is a simple echo callback
    # All processing is already done in pollKeyboard
    discard
  )
  
  # Main loop - poll the keyboard 
  while true:
    # Poll for keyboard input
    pollKeyboard()
    
    # Add a small delay to reduce CPU usage
    sleep(10)