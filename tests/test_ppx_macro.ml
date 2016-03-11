
let%macro avg (Pack nums) =
  List.(fold_left (+) 0 nums / length nums)

let () =
  let result = avg 1 2 3 4 5 6 in
  print_endline ("result = " ^ string_of_int result)


(* After processing the current file look like:

  let () =
    let result =
      let nums = [1; 2; 3; 4; 5; 6] in
      List.(fold_left (+) 0 nums / length nums) in
    print_endline ("result = " ^ string_of_int result)

*)


