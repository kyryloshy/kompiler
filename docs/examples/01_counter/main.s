// counter.s:
// Showcases branch, comparison, load, and math instructions

// This code loads the count_amount into a register, and counts down until it reaches zero

b start // This branch is needed, because it skips data definitions following it (we don't want the CPU to think our data is something to interpret)

// Data definitions

align 8 // Make sure out data is aligned to an 8-byte boundary, since ARM can only load 8 byte values if they are 8-byte aligned

label count_amount // Remember the address that holds the amount we will count down from
bytes 8, 1000000 // Insert 8 bytes into the program's machine code with the value 1000000. 8 bytes since we have 64-bit (8 byte) registers


label start

adr x0, count_amount // x0 now holds the address where count_amount is

ldr x1, x0 // This line loads 8 bytes from the address stored in x0 into x1 (x1 will now hold 1000000, or count_amount)

label loop_start // Remember the address for the loop

sub x1, x1, 1 // Subtract 1 from the value in x1, and store the result in x1 (Pseudo-code: x1 = x1 - 1)

cmp x1, 0 // Compare x1 to zero. This line will set some condition flags on the CPU
b.eq loop_end // If x1 is equal to zero, branch to loop_end

b loop_start // If not skipped this instruction (meaning x1 is not zero), repeat the loop


label loop_end // Remember the address for the loop's end
// We are here when the loop ended (x1 is 0)

// Now, we can hang (just be in an infinite loop), for example

label hang
b hang // This effectively jumps to the current instruction (an infinite loop with nothing)