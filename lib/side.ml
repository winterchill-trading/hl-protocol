open! Core

type t = | Buy | Sell
[@@deriving sexp, compare, equal, hash, enumerate]

let to_wire = function
  | Buy -> "B"
  | Sell -> "A"
;;

let of_wire = function
  | "B" -> Some Buy
  | "A" -> Some Sell
  | _ -> None
;;

let yojson_of_t t : Yojson.Safe.t = `String (to_wire t)

let t_of_yojson (json : Yojson.Safe.t) =
  match json with
  | `String s ->
    (match of_wire s with
     | Some t -> t
     | None -> Json.error "side: unknown value" json)
  | _ -> Json.error "side: string expected" json
;;

let of_is_buy is_buy = if is_buy then Buy else Sell

let is_buy = function
  | Buy -> true
  | Sell -> false
;;

let flip = function
  | Buy -> Sell
  | Sell -> Buy
;;
