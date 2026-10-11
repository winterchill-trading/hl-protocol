open! Core

type t =
  { asset : Asset.t
  ; cloid : Cloid.t
  }
[@@deriving sexp, compare, equal, yojson]
