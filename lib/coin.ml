open! Core

module T = struct
  type t = string [@@deriving sexp, compare, equal, hash]

  let of_string s = s
  let to_string = Fn.id
end

include T
include Comparable.Make (T)
include Hashable.Make (T)

let yojson_of_t t : Yojson.Safe.t = `String t

let t_of_yojson (json : Yojson.Safe.t) =
  match json with
  | `String s -> of_string s
  | _ -> Json.error "coin: string expected" json
;;
