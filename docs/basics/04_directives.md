# The Basics, Part 4: Directives
[Previous](/docs/basics/03_labels.md) [Next](/docs/basics/05_includes.md)

This part describes what directives are, and the specific features available with Kompiler.

## What are directives?
Directives are a way to influence and change the program's final machine code in a way the programmer needs.<br>
For example, embedding a string to print in the console can be done with a directive. Embedding a large number to load into a register can be done with a directive. And so on.<br>
There's a pre-defined list of directives that Kompiler supports.

## How to use directives
Using a directive in code is similar to writing an instruction. You can always access a directive by writing a '.' before its name, like this:
```
.zeros 6
```
If there aren't any instructions with the same name as a directive, it can also be used without the dot:
```
zeros 6
```

## List of available directives
The currently supported directives in Kompiler are:
 - **zeros** n: Inserts n bytes set to zero into the program's machine code
 - **bytes** n, value: Encodes the immediate value (second operand) into n bytes, and inserts the result into the program's machine code
 - **4byte** value: Inserts into the program's machine code the immediate value specified, encoded into 4 bytes (same as 'bytes 4, value')
 - **8byte** value: Inserts into the program's machine code the immediate value specified, encoded into 8 bytes (same as 'bytes 8, value')
 - **align** n: Adds placeholder bytes until the PC is divisible by n. For example, if PC is 6, and 'align 4' is written, 2 bytes (set to zero) are added into the program's machine code, making PC divisible by 4. Especially useful for alignment in ARM
 - **label** label_name: Defines a label with the current address
 - **label** label_name, address: Defines a label with the specified address
 - **ascii** string: Inserts the given string encoded in ascii into the program's machine code.
 - **set_pc** address: Sets the PC to the specified address. For example, useful in a Raspberry Pi, where the kernel is loaded at 0x80000
 - **insert_file** filename: Inserts the contents of the given file into the program's machine code. Useful for embedding large data, such as an image
 - **load** or **include** filename: Loads the given file as code at the current location. See [Part 5: Includes](/docs/basics/05_includes.md)
 - **load_end** or **include_end** filename: Loads the given file as code at the end of the current file. See [Part 5: Includes](/docs/basics/05_includes.md)
 - **value** value_name, value: Associates a value (or any piece of text) with a name. After the definition can be used as an 'alias' to the input value by its name.
 - **macro** macro_name args: Creates a macro that can be used to embed a piece of code at different locations with the dynamic arguments.
 - **isomacro** macro_name args: Similar to .macro, but embeds each call in an isolated namespace, so that labels and other definitions aren't accessible outside the call.
 - **namespace** name ... **endnamespace**: Isolates a piece of code between .namespace and .endnamespace in a namespace with the given name. Basically, all labels, values, and macros will be accessible as "namespace name".item_name outside the namespace. 
 - **info** info_name, data: Creates an information entry with the given data, marking current state and other information. Created for future use
 
[Previous](/docs/basics/03_labels.md) [Next](/docs/basics/05_includes.md)
