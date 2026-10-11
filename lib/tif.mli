(** Time in force: good-til-cancel, immediate-or-cancel, add-liquidity-only (post only). *)

open! Core

type t =
  | Gtc
  | Ioc
  | Alo
[@@deriving sexp, compare, equal, hash, enumerate, yojson]

(** The JSON string used on the wire. *)
val to_wire : t -> string

val of_wire : string -> t option
