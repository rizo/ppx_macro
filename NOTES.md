# Notes

Random notes describing the development details of the `ppx_macro` extension.

**Tasks**:

- [x] Implement simple, argument binding without `env` (no closures).
- [x] Add support for _rest_ argument packing.
- [ ] Decide how complex scoping will work.
- [ ] Add hygienic bindings.
- [ ] Define quote and unquote.

----

Will the macros be called only by name or directly like lambda functions?

```ocaml
(let%macro some_macro arg1 arg2 = ... in some_macro x y)
(fun%macro arg1 arg2 -> ... ) x y
```

In theory both are possible since the first case is still defined as a
function. Initially the limited case of direct application may be supported
where the `Pexp_apply` expression directly uses a `fun` with the macro
extension: `(fun%macro x -> x) x`.

----

The argument bindings approach will not work for complex examples since it
violates the basic property of macros: the delayed evaluation.

The `unless` macro is currently processed to:

```ocaml
let body = print_endline "Math is ok"
and condition = (2 + 2) = 5 in
if not condition then body
```

Which is so obviously wrong, it doesn't even need an explanation.
Argument replacement has to be performed in the macro's body, instead of
introducing a local scope (which actually will still pollute child scopes (even
with hygiene support)).

