# Kompiler Examples
This directory contains example programs, which use most of Kompiler's functionality.

# Contents
 1. [counter](/docs/examples/01_counter) - A basic program that counts from a number to zero
 2. [counter_no_labels](/docs/examples/02_counter_no_labels) - The same program as the counter.s, but doesn't use some of the labels, showing the option for branching with immediate values
 3. [using_a_lib](/docs/examples/03_using_a_lib) - A program that makes the counter modular. Showcases modular programming with the load_end keyword
 4. [raspberry_pi_color](/docs/examples/04_raspberry_pi_color) - A simple kernel written for the BCM3827 chipset in Raspberry Pis which draws a single color on the screen
 
# Compiling
To compile each example, just run
```
kompile main.s program.bin
```

# Running
Since Kompiler produces raw binaries, you can run these programs with QEMU:
```
qemu-system-aarch64 -M raspi3b -cpu cortex-a53 -monitor stdio -kernel program.bin
```
You can exit with either 'quit' or Ctrl-C