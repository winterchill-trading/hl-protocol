open! Core
open Ppx_yojson_conv_lib.Yojson_conv.Primitives

type t =
  { builder : Address.t [@key "b"]
  ; fee_tenths_bp : int [@key "f"]
  }
[@@deriving sexp, compare, equal, yojson] [@@yojson.allow_extra_fields]

(* One tenth of a basis point is 0.001%, so the percentage is [tenths / 1000] with three
   decimals, trailing zeros trimmed as in the docs' example ["0.001%"]. *)
let percent_of_tenths_bp tenths =
  if tenths < 0 then raise_s [%message "negative builder fee" (tenths : int)];
  let whole = tenths / 1000 in
  let frac = tenths % 1000 in
  if frac = 0
  then sprintf "%d%%" whole
  else (
    let digits = String.rstrip (sprintf "%03d" frac) ~drop:(Char.equal '0') in
    sprintf "%d.%s%%" whole digits)
;;

let tenths_bp_of_percent s =
  let error () = Or_error.error_s [%message "not a fee percentage" s] in
  match String.chop_suffix s ~suffix:"%" with
  | None -> error ()
  | Some number ->
    let whole, frac =
      match String.lsplit2 number ~on:'.' with
      | None -> number, ""
      | Some (whole, frac) -> whole, frac
    in
    let is_digits x = String.for_all x ~f:Char.is_digit in
    if String.is_empty whole
       || (not (is_digits whole))
       || (not (is_digits frac))
       || String.length frac > 3
       || (String.mem number '.' && String.is_empty frac)
    then error ()
    else (
      let frac = frac ^ String.make (3 - String.length frac) '0' in
      Ok ((Int.of_string whole * 1000) + Int.of_string frac))
;;
