(** Asset index as used by the exchange endpoint: the position of the coin in
    [Meta.universe] for perpetuals (spot assets are [10000 + index]). Encoded as a JSON
    integer. *)

open! Core

type t [@@deriving sexp, compare, equal, hash, yojson]

include Comparable.S with type t := t

val of_int : int -> t
val to_int : t -> int
