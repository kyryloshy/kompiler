# The Basics, Part 6: Macros
[Previous](/docs/basics/05_includes.md) [Next](/docs/basics/07_namespaces.md)

Sometimes you need to write the same big piece of code multiple times. Just pasting it in could feel bulky and unnecessary. To aid this, Kompiler has multiple features to improve readability and elegance of your code.

## Macros

Macros are a concept where you can write a big piece of text just once, give it a name, and then use it as many times as you need.
For more flexibility, macros can have dynamic arguments that are swapped inside of the macro definition - think of it as a function that is embedded in the program every time you call it.


In Kompiler, macros can be written with the ".macro" and ".isomacro" directives.


## Macro directive

To define basic macros, you can use the ".macro" directive, providing the macro's name, arguments, and definition, which is enclosed between the lines ".macro" and ".endmacro"
In general, a macro definition will look like this:
```
.macro macro_name arg1, arg2, arg3
// Some code in here that uses the dynamic arguments
.endmacro
```
Then, the macro can be used (or called) like this:
```
macro_name arg1, arg2, arg3
```
The dynamic arguments used inside the macro (arg1, arg2, arg3), will be matched and swapped for the arguments provided in the call.

## A meaningful example

Let's add some meaning to it. For example, here is a triple addition macro, that adds three registers into a destination register:
```
.macro triple_add destination, reg1, reg2, reg3
add destination, reg1, reg2
add destination, destination, reg3
.endmacro
```
We can then use it like this:
```
triple_add x0, x1, x2, x3
```
Which will automatically "unwrap" the macro call into the macro's definition.
After Kompiler does its magic, the macro call will transform into:
```
add x0, x1, x2
add x0, x0, x3
```
As you might see, this can turn into a very useful feature in a variety of contexts. But sometimes, regular macros won't be enough.


## Issues with macro

Let's consider the following example macro that uses a label:
```
// A load_val macro that loads an 8-byte value into a register
.macro load_val register, value
b value_end // Skip the value embedded in the program

align 8 // Align the value to an 8-byte boundary
.label value_label // Mark the address of the embedded value
.bytes 8, value
.label value_end // Mark the end to skip in the branch above

ldr register, value_label // Load the value
.endmacro
```
The problem is, that when we call this macro multiple times, a label with the same name will be created repeatedly. This will result in unexpected behaviour, since a label can only have one associated address.
This can be fixed with Kompiler's isolated macro feature.

## Isolated macro directive

Isolated macros can solve the problem described above. They are defined the same way as macros are, except that you use the keywords ".isomacro" and ".endisomacro". This way Kompiler will place the "unwrapped" macro call in a unique namespace (see [Part 7: Namespaces](/docs/basics/07_namespaces.md)) every time.
This way, the labels will be accessible form inside the namespace, but differ in between macro calls.
Let's see an example:
```
.isomacro load_val register, value
b value_end

align 8
.label value_label
.bytes 8, value
.label value_end

ldr register, value_label
.endisomacro
```
Now, when we use the isolated macro:
```
load_val x0, 1 << 63
```
It will unwrap into something like this:
```
.namespace macro.load_val.1234 // Here will be a unique ID
b value_end

.label value_label
.bytes 8, 1 << 63
.label value_end

ldr x0, value_label
.endnamespace
// Here, labels value_label and value_end won't be accessible by their simple names.
```

So, these macros are useful to avoid code-repetition. But what about simple value associations?

## Value directive

Imagine this: you have a unique value that has to be used multiple times in your program - maybe an ID, an index, a specific length, or anything else. You hard-write it everytime in your program, but then realize: the value has to be changed. And now you don't even remember all the places you used it in, and other people won't understand what this value actually is.

Kompiler has a feature to solve this problem. With the ".value" directive, you can associate a value with a unique name, and now use this easily readable name instead of writing the special value every time.

Let's look at an example. We can define our value like this:
```
.value special_value, 0xF0F0
```
And then simply use the associated name in any way we need:
```
mov x3, special_value

.bytes 4, special_value
```
The value can be not only an immediate, but also a label, a register, a string or anything else!
```
// Define them!
.value special_label, A_VERY_NEEDED_BUT_HARD_TO_WRITE_LABEL

.value special_register, x5

.value special_string, "Hello there!"

// Use them!
label special_label
.ascii special_string

.align 4

adr special_register, special_label
```


That's the end of Kompiler's basics. You can now start writing your own programs, or look at existing [examples](/docs/examples).


[Previous](/docs/basics/05_includes.md) [Next](/docs/basics/07_namespaces.md)
