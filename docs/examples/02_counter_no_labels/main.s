// counter_no_labels.s:
// This file is similar to counter.s, but it shows how branch instructions can exist without labels

// Instead of 'b label', you can also do 'b n', which will jump to PC + n * 4 (offset). The '4' is there, because each instruction is 4 bytes long in ARM


b start // Same branch to skip data definitions

// Data definitions

align 8 // Make sure out data is aligned to an 8-byte boundary, since ARM can only load 8 byte values if they are 8-byte aligned

label count_amount // The amount we will count down from
bytes 8, 1000000 // 8 bytes, since we have 64-bit (8 byte) registers



label start

adr x0, count_amount // x0 now holds the address where count_amount is

ldr x1, x0 // This line loads 8 bytes from the address stored in x0 into x1 (x1 will now hold 1000000, or count_amount)

// label loop_start // Don't do this, we will now calculate the branch

sub x1, x1, 1 // Subtract 1 from the value in x1, and store the result in x1 (Pseudo-code: x1 = x1 - 1)

cmp x1, 0 // Compare x1 to zero. This line will set some condition flags on the CPU
b.eq 2 // If x1 is equal to zero, offset the PC by 2 * 4 (8). Right now, PC is at the start the b.eq line; by doing b.eq 2, we skip the current and the next instruction (the repeat one)

b -3 // If this instruction wasn't skipped, jump back to the right instruction. Since PC is at the start of 'b -3', we need to go back to the start of 'sub x1, x1, 1'. This takes 3 instructions to jump back

// If we are here, the 'b.eq 2' skipped the repeat branch instruction, so the loop is over!

// Now, we can hang
b 0 // Instead of having a label, we tell the CPU to go to PC + 0, which is equal to PC, so it repeats the branch to the same instruction in an infinite loop