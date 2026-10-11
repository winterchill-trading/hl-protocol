open! Core

type t =
  | Na
  | Normal_tpsl
  | Position_tpsl
[@@deriving sexp, compare, equal, hash, enumerate]

let to_wire = function
  | Na -> "na"
  | Normal_tpsl -> "normalTpsl"
  | Position_tpsl -> "positionTpsl"
;;

let of_wire = function
  | "na" -> Some Na
  | "normalTpsl" -> Some Normal_tpsl
  | "positionTpsl" -> Some Position_tpsl
  | _ -> None
;;

let yojson_of_t t : Yojson.Safe.t = `String (to_wire t)

let t_of_yojson (json : Yojson.Safe.t) =
  match json with
  | `String s ->
    (match of_wire s with
     | Some t -> t
     | None -> Json.error "Grouping: unknown value" json)
  | _ -> Json.error "Grouping: string expected" json
;;
