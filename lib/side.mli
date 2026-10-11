(** Order or trade side. Encoded as ["B"] (bid, buy) or ["A"] (ask, sell). *)

open! Core

type t = | Buy | Sell
[@@deriving sexp, compare, equal, hash, enumerate, yojson]

(** The JSON string used on the wire. *)
val to_wire : t -> string

val of_wire : string -> t option

val of_is_buy : bool -> t
val is_buy : t -> bool
val flip : t -> t
