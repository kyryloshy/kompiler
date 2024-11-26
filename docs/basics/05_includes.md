# The Basics, Part 5: Includes
[Previous](/docs/basics/04_directives.md)

Containing a large program in a single file is usually hard and disorienting. To combat this, Kompiler has a few modularity features to improve development and maintaining or large systems.

## Modular programming
For modular programming, there's a possibility to load other code files into the current program.

This can be done with either the 'load' or 'include' directives.


## Include/Load directive
To include other files, you can use these directives:
 - load/include filename: Inserts code from the given file in-place of the current line
 - load_end/include_end filename: Inserts code from the given file at the end of the program.

Most of the time, or in 'library-like' design, I recommend using load_end or include_end, since it can be done at the start of the program for comfort, while keeping everything untouched.

## Example using include/load
Let's see how using the include directive affects our final program. Let's assume we have these files:
main.s:
```
b outside_label

load "outside_file.s"
```

outside_file.s:
```
label outside_label
mov x0, 0
```

Then the end result to be compiled will be:
```
b outside_label

label outside_label // The load directive was here
mov x0, 0
```

**WARNING!**

If the load directive is done as the first line (or at the start), the loaded file WILL be loaded at the start. For example, with files:

main.s:
```
load "outside_file.s"

b outside_label
```

outside_file.s:
```
label outside_label
mov x0, 0
```


The end result will be:
```
label outside_label // The load directive was here
mov x0, 0

b outside_label
```

So, the mov instruction will be executed first!


## Example using include_end/load_end
To prevent the behavior that will happen with the include and load directives, the directives load_end and include_end exist.
Using load_end will place the code of the given file at the end of the current program. For example, having files:

main.s:
```
load_end "outside_file.s"

b outside_label
```

outside_file.s:
```
label outside_label
mov x0, 0
```


Will result in:
```
// load_end was here
b outside_label

label outside_label // load_end puts the file's contents at the end
mov x0, 0
```

So, if main.s is designed to run first, and outside_file.s is just a library, use load_end or include_end!


That's the end of Kompiler's basics. You can now start writing your own programs, or look at existing [examples](/docs/examples).


[Previous](/docs/basics/04_directives.md)