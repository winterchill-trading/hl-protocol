(** Order grouping for an [order] action: ["na"], ["normalTpsl"] or ["positionTpsl"]. *)

open! Core

type t =
  | Na
  | Normal_tpsl
  | Position_tpsl
[@@deriving sexp, compare, equal, hash, enumerate, yojson]

val to_wire : t -> string
val of_wire : string -> t option
