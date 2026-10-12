open! Core
include Exchange_core.Client_order_id

let validate s =
  let s = String.lowercase s in
  match String.chop_prefix s ~prefix:"0x" with
  | Some hex when Int.(String.length hex = 32) && String.for_all hex ~f:Char.is_hex_digit
    -> Some (Exchange_core.Client_order_id.of_string s)
  | _ -> None
;;

let of_string_opt = validate

let of_string s =
  match validate s with
  | Some t -> t
  | None -> raise_s [%message "Cloid.of_string: expected 0x + 32 hex digits" s]
;;

let t_of_sexp = function
  | Sexp.Atom s -> of_string s
  | sexp -> of_sexp_error "Cloid.t_of_sexp: atom expected" sexp
;;

let of_int n =
  if Int.(n < 0) then raise_s [%message "Cloid.of_int: negative" (n : int)];
  of_string (sprintf "0x%032x" n)
;;

let yojson_of_t t : Yojson.Safe.t = `String (to_string t)

let t_of_yojson (json : Yojson.Safe.t) =
  match json with
  | `String s ->
    (match validate s with
     | Some t -> t
     | None -> Json.error "Cloid: expected 0x + 32 hex digits" json)
  | _ -> Json.error "Cloid: string expected" json
;;
