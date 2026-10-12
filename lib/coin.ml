open! Core
include Exchange_core.Symbol

let yojson_of_t t : Yojson.Safe.t = `String (to_string t)

let t_of_yojson (json : Yojson.Safe.t) =
  match json with
  | `String s -> of_string s
  | _ -> Json.error "coin: string expected" json
;;
