set_pc 0x80000

load_end "onboard_led.s"
load_end "mailbox.s"
load_end "framebuffer.s"


label SP_POINTER, 0x80000

b main // Skip data definitions

align 8 // Make sure it's 8-byte aligned for loading
label COLOR
bytes 8, 0xFF9B8B36 // Teal color (alpha - blue - green - red)

align 8 // Make sure it's 8-byte aligned for loading
label FB_STRUCT
zeros 12 // Create space for the framebuffer structure (used later by fb_init)


align 4

label main

adr x0, SP_POINTER
mov_sp sp, x0 // Set the stack pointer, since we are using a lot of functions

adr x0, FB_STRUCT // Set the first argument for fb_init to the location of our framebuffer structure
bl fb_init // Go to framebuffer initialization (label available in framebuffer.s)


adr x0, FB_STRUCT // Load the address of FB_STRUCT into x0

// Next steps: Load the first 32 bits from FB_STRUCT into x1 as the framebuffer base address, and the second 32 bits into x2 as the framebuffer bytesize

ldr w1, x0 // Load 32 bits from the address in x0 (FB_STRUCT) into w1 (which is the first 32 bits of x1)

add x0, x0, 4 // Add 4 bytes (32 bits) to FB_STRUCT

ldr w2, x0 // Load 32 from the address in x0 (FB_STRUCT + 4) into w2

// Now x1 is the framebuffer base address and x2 is the framebuffer bytesize

// Load the color for filling into x3
adr x3, COLOR // Get the address for the color
ldr x3, x3 // Load from the address


// Current register purposes:
// x1 - current pixel address
// x2 - bytes to fill left
// x3 - color to fill with


// Now, fill the screen in a loop until x2 (framebuffer bytes left) reaches zero

label fill_loop

str w3, x1 // Write a 32-bit color to the current pixel address
add x1, x1, 4 // Proceed to the next pixel (+ 4 bytes / 32 bits)
sub x2, x2, 4 // Indicate how many bytes are left

cmp x2, 0 // Compare x2 to 0
b.eq 2 // If equal, skip the repeat branch
b fill_loop // Repeat branch

// Here after the loop has finished

b 0 // Hang at the end
