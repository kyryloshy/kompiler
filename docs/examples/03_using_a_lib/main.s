// main.s:
// This file uses count_function from lib.s, and only needs to provide the arguments in x0
// without writing the actual counting logic every time it is needed.

b start // Skip the data definitions


// We will store the count amount in memory, since it is a large number
// That cant be directly put into x0

align 8 // Make sure the count

label count_amount // Mark the address of the large number
bytes 8, 1000000 // Insert the number into the machine code


label start // Mark the actual beginning of the program

adr x0, count_amount // Load the address of our number into x0

ldr x0, x0 // Load the actual value of the number from memory

// Now, x0 contains the counting amount, as the function in lib.s requires

// To call the function, a BL instruction can be used

// The BL instruction will put the return address into register LR (same as X30)
// that the function will then use to return a program flow to this file

bl count_function

// Program flow will return here after count_function finishes


b 0 // At the end, just hang



