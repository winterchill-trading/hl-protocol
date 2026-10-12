open! Core
include Exchange_core.Account

let of_string s = Exchange_core.Account.of_string (String.lowercase s)
let yojson_of_t t : Yojson.Safe.t = `String (to_string t)

let t_of_yojson (json : Yojson.Safe.t) =
  match json with
  | `String s -> of_string s
  | _ -> Json.error "address: string expected" json
;;
