align 8

label VIDEOCORE_MBOX
bytes 8, 0x3f00b880

label VC_MBOX_READ
bytes 8, 0x3f00b880

label VC_MBOX_STATUS
bytes 8, 0x3f00b898

label VC_MBOX_WRITE
bytes 8, 0x3f00b8a0

label VC_MBOX_EMPTY
bytes 8, 0x40000000

label VC_MBOX_FULL
bytes 8, 0x80000000


// Mbox Call
// Writes the specified mailbox buffer and channel (as arguments) to the VideoCore mailbox
// 
// Arguments:
// x0 - buffer address to write to the mailbox. Must be 16-byte aligned, as the mailbox interface requires (but no checks)
// x1 - mailbox channel (4 bits)
//
// Uses:
// 
//
label mbox_call

// Create the value to write to VC's mailbox (buffer address (28 bits) + channel (4 bits))

// Move the mask to use for the buffer address to x2
mov x2, 0xF // (4 bits)
mvn x2, x2 // Everything except the last 4 bits

and x0, x0, x2 // Remove the last 4 bits from x0 / buffer address

// Create the mask for the channel into x2 (last 4 bits)
mov x2, 0xF

// Get last four bits from the channel
and x1, x1, x2

// Combine the buffer address and the channel into x0
orr x0, x0, x1


// Wait until the vc mbox is empty

// Load the mbox empty status into x2
ldr x2, VC_MBOX_FULL

ldr x3, VC_MBOX_STATUS // Load address of the mbox status

mov x1, 0

ldr w1, x3 // Load the current status into x1
and x1, x1, x2 // Logical AND of mbox's status and the "mbox full" flag
cmp x1, 0 // Compare the result to zero
b.eq 2 // If equal (mbox full flag is not set), exit the waiting loop / skip the branch back instruction
b -4 // Branch three instructions back

// Got here when mbox is empty
ldr x1, VC_MBOX_WRITE // Load the address of the vc mbox write

str w0, x1 // Write the 32 bits collected previously (buffer address + channel) to the write address of the VC mbox


// Wait until a reply

ldr x2, VC_MBOX_EMPTY
ldr x4, VC_MBOX_READ
ldr x3, VC_MBOX_STATUS

label mbox_call_read_mbox_loop // Mark the loop start

ldr w1, x3 // Load the current mbox status into x1
and x1, x1, x2 // Logical AND of mbox's status and the "mbox empty" flag
cmp x1, 0 // Compare the result to zero
b.eq 2 // If equal (mbox empty flag is not set), exit the loop
b -4 // Branch back

ldr w1, x4 // Load what's in the mbox to x1 from VC_MBOX_READ
cmp x1, x0 // Check if the mbox content matches the request
b.eq 2 // If it does, exit the loop
b mbox_call_read_mbox_loop // Restart the read loop if not equal

// If got here, the VideoCore has replied to the message

// Set x0 to just the buffer address
mov x1, 0xF
mvn x1, x1 // Create a mask with everything except the last 4 bits

and x0, x0, x1 // Mask the x1, which was buffer + channel, to just the buffer

br x30 // Return to the caller

