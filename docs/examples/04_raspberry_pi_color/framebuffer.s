load "mailbox.s"

label VC_MBOX_FB_ADDRESS_AND_NOT
bytes 8, 0xC0000000

// Arguments:
// x0 - fb struct to fill in 
label fb_init
mov x10, x0

b fb_init_mbox_buffer_after

align 16

label fb_init_mbox_buffer
bytes 4, 140 // Buffer size in bytes (35 * 4)
bytes 4, 0 // Request code

// Tags

bytes 4, 0x00048003 // Set width/height tag
bytes 4, 8 // Value buffer size
bytes 4, 0 // Request code
bytes 4, 1920 // width
bytes 4, 1080 // height

bytes 4, 0x00048004 // Set virtual width/height tag
bytes 4, 8 // Value buffer size
bytes 4, 0 // Request code
bytes 4, 1920 // width
bytes 4, 1080 // height

bytes 4, 0x00048009 // Set virtual offset tag
bytes 4, 8 // Value buffer size
bytes 4, 0 // Request code
bytes 4, 0 // x offset
bytes 4, 0 // y offset

bytes 4, 0x00048005 // Set pixel depth
bytes 4, 4 // Value buffer size
bytes 4, 0 // Request code
bytes 4, 32 // 32 bits per pixel

bytes 4, 0x00048006 // Set pixel order
bytes 4, 4 // Value buffer size
bytes 4, 0 // Request code
bytes 4, 0x1 // rgb

bytes 4, 0x00040008 // Get pitch tag
bytes 4, 4 // Value buffer size
bytes 4, 0 // Request code
bytes 4, 0 // response buffer (bytes per line, or pitch)

bytes 4, 0x00040001 // Allocate frame buffer tag
bytes 4, 8 // Value buffer size
bytes 4, 0 // Request code
bytes 4, 4 // alignment (in bytes)
bytes 4, 0 // response buffer

bytes 4, 0 // End tag


label fb_init_mbox_buffer_after

mov x19, 4

// Save return address to stack pointer
str_pre_index lr, sp, -8

mov x19, 5

adr x0, fb_init_mbox_buffer // Load the address of the mbox buffer into x0
mov x1, 8 // Use channel 8 (ARM to VC)

bl mbox_call // Call mbox call

adr x0, fb_init_mbox_buffer // Load the mbox buffer into x0 (with VC's response)
mov x1, x10 // Move fb struct to x1 (but also keep in x10)

// Load framebuffer address from VC into x3
mov x3, x0 // Load the buffer
add x3, x3, 128 // Go to the framebuffer's address response (32 * 4)
ldr w3, x3 // Load the framebuffer address from the response buffer

mov x21, x3

ldr x4, VC_MBOX_FB_ADDRESS_AND_NOT // Load the value to and-not x3 with into x4
mvn x4, x4 // Bitwise not for x4
and x3, x3, x4 // Offset VC address to CPU address

mov x22, x3

str w3, x1 // Store the address as the first element of the fb struct
add x1, x1, 4 // Add the 4 bytes to store the next element


mov x3, x0 // Load the mbox buffer into x3 (with VC's response)
add x3, x3, 132 // Go to the framebuffer size response (offset 33 * 4)
ldr w3, x3 // Load the framebuffer size from the address

str w3, x1 // Store the framebuffer size as the second element of the fb struct
add x1, x1, 4 // Add the 4 bytes to store the next element


// Load the return address
ldr lr, sp
add sp, sp, 8

br lr
