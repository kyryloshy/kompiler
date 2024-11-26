# Example 4: Raspberry Pi Color

This examples uses many of Kompiler's features and a multi-file design to implement the final goal - drawing a single color on the screen.

## File structure

The example contains three files:
 - mailbox.s: Implements the mailbox interface with the VideoCore GPU in the Raspberry Pi
 - framebuffer.s: Uses the mailbox interface to set display settings and get the framebuffer address
 - main.s: Uses framebuffer.s to locate the framebuffer, and draws a single color for each pixel in a loop

<br>
<br>

Follow the comments in starting from [main.s](/docs/examples/04_raspberry_pi_color/main.s) for a detailed description.