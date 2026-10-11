open! Core

type t =
  { asset : Asset.t [@key "a"]
  ; oid : Order_id.t [@key "o"]
  }
[@@deriving sexp, compare, equal, yojson]
