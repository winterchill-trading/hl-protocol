open! Core

type t =
  | Tp
  | Sl
[@@deriving sexp, compare, equal, hash, enumerate]

let to_wire = function
  | Tp -> "tp"
  | Sl -> "sl"
;;

let of_wire = function
  | "tp" -> Some Tp
  | "sl" -> Some Sl
  | _ -> None
;;

let yojson_of_t t : Yojson.Safe.t = `String (to_wire t)

let t_of_yojson (json : Yojson.Safe.t) =
  match json with
  | `String s ->
    (match of_wire s with
     | Some t -> t
     | None -> Json.error "tpsl: unknown value" json)
  | _ -> Json.error "tpsl: string expected" json
;;
