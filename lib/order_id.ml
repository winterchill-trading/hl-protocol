open! Core

module T = struct
  type t = Int64.t [@@deriving sexp, compare, equal, hash]
end

include T
include Comparable.Make (T)
include Hashable.Make (T)

let of_int64 = Fn.id
let to_int64 = Fn.id
let of_int = Int64.of_int
let to_int_exn = Int64.to_int_exn
let to_string = Int64.to_string
let of_string = Int64.of_string

let yojson_of_t t : Yojson.Safe.t =
  match Int64.to_int t with
  | Some i -> `Int i
  | None -> `Intlit (Int64.to_string t)
;;

let t_of_yojson (json : Yojson.Safe.t) =
  match json with
  | `Int i -> Int64.of_int i
  | `Intlit s -> Int64.of_string s
  | _ -> Json.error "Order_id: integer expected" json
;;
