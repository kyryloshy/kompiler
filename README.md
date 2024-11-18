# Kompiler
Kir's compiler for low-level ARM machine code. Kompiler is a modular tool written in Ruby, and can easily be changed to support other architectures!

# Contents
 - [Description](#description)
 - [Comparison](#comparison)
 - [Install](#install)
 - [How to use](#how_to_use)
 

# Description
Kompiler is a tool which can compile a low-level programming language into machine code. Each instructions written in the language will reflect the resulting machine code in a very predictable way.

# Comparison
Alongside Kompiler, many low-level compilers exist, such as the GNU Assembly compiler, Clang, NASM, and so on. In comparison to them, Kompiler has a relatively low footprint, and is significantly faster in certain areas: for example, embedding a 6 megabyte image into your machine code takes 10 seconds with Clang, but just less than a second with Kompiler.

# Install


# How to use
## Compiling
Using Kompiler is simple. To compile a program into machine code (after installation), run
```
kompile input_file.s output_file.bin
```
## Examples
You can find examples of writing for Kompiler in the (examples folder)[/kyryloshy/kompiler/examples].