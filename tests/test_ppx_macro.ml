
let%macro unless condition body =
  if not condition then body

let () =
  unless (2 + 3 = 5) (print_endline "Math is ok")

(* Will be processed to:

  let () =
    let result =
      let nums = [1; 2; 3; 4; 5; 6] in
      List.(fold_left (+) 0 nums / length nums) in
    print_endline ("result = " ^ string_of_int result)

*)


