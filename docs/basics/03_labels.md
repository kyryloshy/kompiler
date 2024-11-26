# The Basics, Part 3: Labels
[Previous](/docs/basics/02_instructions.md) [Next](/docs/basics/04_directives.md)

This page explains how to define and use labels.

## Information

To keep track of the current and next instruction to execute, CPUs have a special register called PC (Program Counter), which contains the address for the current instruction. With every instruction, the PC increases to reflect a new instruction.<br>
To avoid misunderstandings, Kompiler also keeps an address of the current instruction. By default, Kompiler starts with PC set to 0.<br>

## What are labels for?

Labels are a compiler-side dataset of locations and their names to ease the development process. Instead of calculating addresses manually, the program can simply create a reference point and use it anywhere in code. Consequently, each label will have a unique name for referencing and an associated address.

## Creating labels

You can define labels that will hold the current PC / address with:
```
label label_name
```


To create a label at a specific address, provide it as the second immediate operand:
```
label specific_label, 0x80000
```


## Using labels

After a label was created, some useful instructions are:
```
b label_name // Branches to the specified label by changing the PC to the label's address

adr x0, label_name // Loads the address of label_name into x0

ldr x0, label_name // Loads the first 8 bytes from the address of label_name into x0
```


## Important note
Labels don't actually change the machine code's content in any way.<br>
The PC isn't changed after a label is defined, as is the machine code - everything stays the same.



[Previous](/docs/basics/02_instructions.md) [Next](/docs/basics/04_directives.md)