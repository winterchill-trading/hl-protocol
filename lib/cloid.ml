open! Core

let validate s =
  let s = String.lowercase s in
  match String.chop_prefix s ~prefix:"0x" with
  | Some hex when String.length hex = 32 && String.for_all hex ~f:Char.is_hex_digit ->
    Some s
  | _ -> None
;;

module T = struct
  type t = string [@@deriving compare, equal, hash]

  let of_string_opt = validate

  let of_string s =
    match validate s with
    | Some t -> t
    | None -> raise_s [%message "Cloid.of_string: expected 0x + 32 hex digits" s]
  ;;

  let to_string = Fn.id
  let sexp_of_t t = Sexp.Atom t

  let t_of_sexp = function
    | Sexp.Atom s -> of_string s
    | sexp -> of_sexp_error "Cloid.t_of_sexp: atom expected" sexp
  ;;
end

include T
include Comparable.Make (T)
include Hashable.Make (T)

let of_int n =
  if Int.(n < 0) then raise_s [%message "Cloid.of_int: negative" (n : int)];
  sprintf "0x%032x" n
;;

let yojson_of_t t : Yojson.Safe.t = `String t

let t_of_yojson (json : Yojson.Safe.t) =
  match json with
  | `String s ->
    (match validate s with
     | Some t -> t
     | None -> Json.error "Cloid: expected 0x + 32 hex digits" json)
  | _ -> Json.error "Cloid: string expected" json
;;
