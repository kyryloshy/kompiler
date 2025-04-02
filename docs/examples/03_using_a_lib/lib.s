// lib.s:
// This file implements the function "counter_function", which will be used from main.s


// Mark the counter function entry point.
// Programs will call the function using "bl counter_func".
// The instruction BL (Branch with Link) will put the return address into
// the register LR (link register), which is the same as X30.
// 
// This function expects that X0 will contain the count amount,
// so the caller should put something into X0 beforehand
label counter_function

cmp x0, 0 // Check if x0 is zero
b.eq 3 // If yes, exit the loop

sub x0, x0, 1 // Otherwise, decrement x0

b -3 // Repeat


// Now, to return the program flow to the caller,
// the register LR, which contains the return address, can be used

// We just need to branch to the address in that register

br lr

