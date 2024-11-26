# The Basics, Part 1: Syntax
[Next](/docs/basics/02_instructions.md)

This file explains the general structure / syntax of everything in Kompiler

## 1. Comments
Comments start with '//'. Everything from '//' to a newline character is a comment

## 2. Structure
Everything except a comment or an empty line is interpreted as a code line.
Each code line follows the same pattern:
```
keyword operand_1, operand_2, operand_3, ...
```

## 3. Operand types

As you saw previously, each code line can have operands. Each operand can be one of the following types:
 - [Register](#31-register-operands)
 - [Immediate](#32-immediate-value-operands)
 - [String](#33-string-operands)
 - [Label](#34-label-operands)
 
### 3.1 Register operands

Register operands are a pre-defined set of names, specific to the architecture used. For ARMv8-a, the currently defined ones are:
 - x0 to x31
 - w0 to w15
 - sp (stack pointer), lr (link register)
 
### 3.2 Immediate value operands
 
Immediate operands are constant values used directly in an instruction (e.g., Add *23* to the register X0). While they can be any value the programmer chooses, the size of immediate values is often limited by the instruction encoding, which imposes a constraint on how large the value can be.
Currently, immediate value operands can be denoted in three ways:
 - Decimal: 73716253
 - Binary: 0b00110011100
 - Hex: 0xf8a353bc
 
### 3.3 String operands

String operands are a sequence of characters, which are mostly used with directives ([described in part 4](/docs/basics/04_directives.md)), since CPU instruction logic usually doesn't apply to them.
To denote a string, use double quotation marks (") with the content inside:
```
"This is a string"
```

### 3.4 Label operands

Labels are used to mark different locations or 'checkpoints' in your program. Label names can be made out of letters, underscores and digits.
An example label operand might look like this:
```
label_name123
```

[Next](/docs/basics/02_instructions.md)