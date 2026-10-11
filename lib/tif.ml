open! Core

type t =
  | Gtc
  | Ioc
  | Alo
[@@deriving sexp, compare, equal, hash, enumerate]

let to_wire = function
  | Gtc -> "Gtc"
  | Ioc -> "Ioc"
  | Alo -> "Alo"
;;

let of_wire = function
  | "Gtc" -> Some Gtc
  | "Ioc" -> Some Ioc
  | "Alo" -> Some Alo
  | _ -> None
;;

let yojson_of_t t : Yojson.Safe.t = `String (to_wire t)

let t_of_yojson (json : Yojson.Safe.t) =
  match json with
  | `String s ->
    (match of_wire s with
     | Some t -> t
     | None -> Json.error "tif: unknown value" json)
  | _ -> Json.error "tif: string expected" json
;;
