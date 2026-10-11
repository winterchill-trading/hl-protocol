(** Cancel by client order id. Wire form: [{"asset": asset, "cloid": "0x..."}]. *)

open! Core

type t =
  { asset : Asset.t
  ; cloid : Cloid.t
  }
[@@deriving sexp, compare, equal, yojson]
