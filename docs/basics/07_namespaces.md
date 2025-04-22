# The Basics, Part 7: Namespaces
[Previous](/docs/basics/06_macros.md)

Managing label, value, and macro names can be hard in a large codebase, especially since every name has to be unique. This problem can be solved with Kompiler's namespaces.

 
## Namespaces

With namespaces, you can separate pieces of code into separate name "modules", inside of which the names are simple, but outside each name is prefixed by its space's name.

In Kompiler, namespaces can be created using '.namespace' and '.endnamespace' directives.


## Namespace directive

In general, a namespace definition will look like this:
```
.namespace unique_space
// Some code in here
.endnamespace
```

Now, inside of the namespace, we can define labels, values, or macros, and use them as usual:
```
.namespace unique_space
// Create a value and a label
.value some_value, 0xFF
.label some_label

// Use them
mov x0, some_value
adr x1, some_label
.endnamespace
```

But outside the namespace, these definitions **won't** be available by their simple names. Instead, they are **only** available through "{namespace name}.{definition name}". Here is an example:
```
.namespace unique_space
// Create a value and a label inside the namespace
.value some_value, 0xFF
.label some_label
// ...
.endnamespace

// Use them outside the namespace, use them like this
mov x0, unique_space.some_value
adr x1, unique_space.some_label
```


That's the end of Kompiler's basics. You can now start writing your own programs, or look at existing [examples](/docs/examples).


[Previous](/docs/basics/06_macros.md)
