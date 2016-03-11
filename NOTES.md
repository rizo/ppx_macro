# Notes

Random notes describing the development details of the `ppx_macro` extension.

**Tasks**:

- [x] Implement simple, argument binding without `env` (no closures).
- [x] Add support for _rest_ argument packing.
- [ ] Decide how complex scoping will work.
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

