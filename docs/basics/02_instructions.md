# The Basics, Part 2: Instructions
[Previous](/docs/basics/01_syntax.md) [Next](/docs/basics/03_labels.md)

This part shows example instructions, and how they behave.

## Example instructions

Here are some example instructions:

```
mov x1, 3 // Move 3 into x1

add x0, x0, 23 // Add 23 to x0
```


## Instruction configuration

To find all the different instructions and their specifications, Kompiler has a database of architectures and their instruction sets. Each instruction has configurable options, such as:
 - keyword: The keyword used to match the instruction
 - operands: A list of operands and their types to further match the instruction
 - bitsize: Indicates the instruction's final size in bits
 - mc_constructor: An AST indicating how to build the instruction using the operands provided
 - name: The name of the instruction (Optional)
 - description: The description for the instruction (Optional)
 
[Previous](/docs/basics/01_syntax.md) [Next](/docs/basics/03_labels.md)