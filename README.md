# ppx_macro

A syntax extension that helps you build syntax extensions.

With this extension you can define functions that can match syntax constructs and perform compile-time transformations.

This is just an experiment for now and should not be used in prodcution code.

**Related projects**:

- [ppx_rule](https://github.com/rizo/ppx_rule) - Compile-time rewrite rules for OCaml.

## Examples

In the following example a special `#` keyword is used to capture all the arguments of the macro in a single variable `nums`.

```ocaml
(* Define a macro to compute an average of all its arguments. *)
let%macro avg #nums =
  let total, count =
    List.fold_left (fun (t, c) x -> t + x, c + 1) (0, 0) nums in
  total / count
  
(* Let's try it now! *)
# avg 1 2 3
- : int = 2
```

Another common use case for macros is quoting and unquting of code.

```ocaml
(* Define the imperative `unless` macro. *)
let%macro unless condition body =
  quote (if (not (unquote condition))
         then body)

(* See what code it generates. *)
# macroexpand (quote (unless true (print_endline "Hello World")))
- : Parsetree.expression = if not true then print_endline "Hello World"

(* And finally test it! *)
# unless false (print_endline "Hello World")
"Hello World"
```
