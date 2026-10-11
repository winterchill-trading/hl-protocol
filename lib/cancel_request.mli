(** Cancel by exchange order id. Wire form: [{"a": asset, "o": oid}]. *)

open! Core

type t =
  { asset : Asset.t
  ; oid : Order_id.t
  }
[@@deriving sexp, compare, equal, yojson]
