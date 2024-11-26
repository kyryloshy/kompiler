# Kompiler
Kir's compiler for low-level ARM machine code. Kompiler is a modular tool written in Ruby, and can easily be changed to support other architectures!

# Contents
 - [Description](#description)
 - [Install](#install)
 - [How to use](#how_to_use)
 - [Documentation](#documentation)
 

# Description
Kompiler is a tool which can compile a low-level programming language into machine code. Each instructions written in the language will directly reflect the resulting machine code in a predictable way.

# Install
To install Kompiler through RubyGems, run:
```shell
gem install kompiler
```

# How to use
Using Kompiler is simple. To compile a program into machine code (after installation), run
```shell
kompile input_file.s output_file.bin
```
For further information, run
```
kompile --help
```

# Documentation
You can find the basics and examples of programming with Kompiler in the [docs directory](/docs).