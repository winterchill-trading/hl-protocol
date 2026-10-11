open! Core

type t = (Coin.t * Price.t) list [@@deriving sexp, compare, equal]

let yojson_of_t t : Yojson.Safe.t =
  `Assoc (List.map t ~f:(fun (coin, px) -> Coin.to_string coin, Price.yojson_of_t px))
;;

let t_of_yojson (json : Yojson.Safe.t) =
  match json with
  | `Assoc fields ->
    List.map fields ~f:(fun (coin, px) -> Coin.of_string coin, Price.t_of_yojson px)
  | _ -> Json.error "All_mids: object expected" json
;;

let find t coin = List.Assoc.find t coin ~equal:Coin.equal
