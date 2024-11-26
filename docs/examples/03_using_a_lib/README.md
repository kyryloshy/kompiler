# Example 3: Using a lib

This example showcases modular program design with Kompiler.
<br>
<br>
As you can see, there are both [main.s](/docs/examples/03_using_a_lib/main.s) and [lib.s](/docs/examples/03_using_a_lib/lib.s). lib.s implements a counter 'function' that can be used by other programs.<br>
To use the function, main.s loads lib.s, and executes BL (Branch with link) to branch to the function correctly.<br>
lib.s can then use the LR (Link register, or x30) to jump back to the caller (main.s).
<br>
<br>
Follow the comments in [the file](/docs/examples/03_using_a_lib/main.s) for a detailed description.