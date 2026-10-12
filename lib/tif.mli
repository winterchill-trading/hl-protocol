(** Time in force ({!Exchange_core.Tif}): good-til-cancel, immediate-or-cancel,
    add-liquidity-only (post only), encoded as ["Gtc"], ["Ioc"], ["Alo"]. *)

open! Core

type t = Exchange_core.Tif.t =
  | Gtc
  | Ioc
  | Alo
[@@deriving sexp, compare, equal, hash, enumerate, yojson]

(** The JSON string used on the wire. *)
val to_wire : t -> string

val of_wire : string -> t option
