
open Parsetree
open Asttypes
open Ast_mapper
open Ast_helper

type macro_argument =
  | Simple of pattern
  | Packed of pattern

let show_pat_var p =
  match p.ppat_desc with
  | Ppat_var {txt = name} -> name
  | _ -> invalid_arg "not a var pattern"

let log str = output_string stderr (str ^ "\n")

let macro_table = Hashtbl.create 100

let macro_of_value_binding {pvb_pat; pvb_expr} =
  match pvb_pat.ppat_desc with
  | Ppat_var {txt = macro_name} ->
    let rec collect (args, _body) expr =
      match expr.pexp_desc with
      (* Packed arguments. Check for errors first. *)
      | Pexp_fun ("", None, {ppat_desc = Ppat_construct ({txt = Longident.Lident "Pack"}, None)}, _next) ->
        failwith "[%%macro]: Pack expects a name for the argument list: (Pack args)"
      | Pexp_fun ("", None, {ppat_desc = Ppat_construct ({txt = Longident.Lident "Pack"}, _)}, {pexp_desc = Pexp_fun _})
      | Pexp_fun ("", None, {ppat_desc = Ppat_construct ({txt = Longident.Lident "Pack"}, _)}, {pexp_desc = Pexp_function _}) ->
        failwith "[%%macro]: regular arguments are not allowed after packed arguments"

      | Pexp_fun ("", None, {ppat_desc = Ppat_construct ({txt = Longident.Lident "Pack"}, Some packed_args)}, body) ->
        (Packed packed_args :: args, Some body)

      (* Simple argument. *)
      | Pexp_fun ("", None, arg, next) ->
        collect (Simple arg :: args, None) next

      | Pexp_fun (_label, None, _arg, _next) ->
        failwith "[%%macro]: args with labels are not supported"
      | Pexp_fun (_, Some _default_arg, _, _) ->
        failwith "[%%macro]: optional args are not supported"
      | Pexp_function _case_list ->
        failwith "[%%macro]: multiple argument cases are not supported"
      | _body_descr -> (args, Some expr) in
    let args, body =
      match collect ([], None) pvb_expr with
      | inv_args, Some body -> List.rev inv_args, body
      | _, None -> failwith "[%%macro]: impossible, body was not reached" in
    (macro_name, args, body)
  (* let%macro x = ... *)
  | _ -> failwith "macro value must be a function"

(* Finds the rule declarations. *)
let rec structure mapper items =
  match items with
  (*
   * Define macro: `let%macro m x = expr`
   *)
  | {pstr_desc = Pstr_extension
         (({txt = "macro"; loc},
           PStr [{pstr_desc = Pstr_value (_rec_flag, [value_binding])}]), _)}
    :: items ->
    (* Extract and save the macro description. *)
    let macro_name, args, body = macro_of_value_binding value_binding in
    Hashtbl.add macro_table macro_name (args, body);
    log ("info: defined macro " ^ macro_name);

    (* Skip this item, return items *)
    (* TODO: Should the original function still be defined (runtime fallback)? *)
    structure mapper items

  (* Recursive let%macro definitions are not supported. *)
  | {pstr_desc =
       Pstr_extension (({txt = "macro"}, PStr [{pstr_desc =
         Pstr_value (_rec_flag, _value_binding_list)}]), _)} :: _items ->
    failwith "recursive macro definitions are not supported."

  | item :: items ->
    mapper.structure_item mapper item :: structure mapper items

  | [] -> []

let rec mkexp_list = function
  | [] ->
    let loc = Location.none in
    let nil = { txt = Longident.Lident "[]"; loc } in
    Exp.mk ~loc (Pexp_construct (nil, None))
  | x :: xs ->
    let exp_xs = mkexp_list xs in
    let loc = Location.{loc_start = x.pexp_loc.loc_start;
                        loc_end   = exp_xs.pexp_loc.loc_end;
                        loc_ghost = true} in
    let arg = Exp.tuple ~loc [x; exp_xs] in
    Exp.construct ~loc (Location.mknoloc (Longident.Lident "::")) (Some arg)

let rec bind_args names args =
  let rec loop bindings names args =
  match names, args with
  | Simple name :: names', arg :: args' ->
    loop (Vb.mk name arg :: bindings) names' args'
  | [Packed name], args ->
    Vb.mk name (mkexp_list args) :: bindings
  | [], [] -> bindings
  | _ -> invalid_arg "mismatch in macro parameters number" in
  loop [] names args

(* Matches the rules in the expressions. *)
let expr this e =
  match e.pexp_desc with
  (*
   * Macro call: `f x y ...` -> `expr`
   *)
  | Pexp_apply ({pexp_desc = Pexp_ident {txt = Longident.Lident macro_name}}, labeled_args)
    when Hashtbl.mem macro_table macro_name ->
    log ("info: found macro call " ^ macro_name);
    let args = List.map snd labeled_args in
    let params, body = Hashtbl.find macro_table macro_name in

    (* Bind the macro parameters with the provided arguments. *)
    let vb_list = bind_args params args in

    (* Return the macro body inside the let scope with bound parameters. *)
    Exp.let_ Nonrecursive vb_list body

  | _ -> default_mapper.expr this e

let () =
  Ast_mapper.register "ppx_macro" (fun argv ->
      { default_mapper with structure; expr })

