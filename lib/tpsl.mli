(** Whether a trigger order is a take-profit or a stop-loss. *)

open! Core

type t = | Tp | Sl
[@@deriving sexp, compare, equal, hash, enumerate, yojson]

(** The JSON string used on the wire. *)
val to_wire : t -> string

val of_wire : string -> t option
