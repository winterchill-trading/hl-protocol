(** Client order id: a 128-bit value encoded as ["0x"] followed by 32 hex digits.
    Normalised to lowercase. The same type as {!Exchange_core.Client_order_id}, with
    Hyperliquid's format enforced by [of_string], [t_of_sexp] and the JSON decoder. *)

open! Core

type t = Exchange_core.Client_order_id.t [@@deriving sexp, compare, equal, hash, yojson]

include
  Comparable.S
  with type t := t
   and type comparator_witness = Exchange_core.Client_order_id.comparator_witness

include Hashable.S with type t := t

(** Raises unless the string is ["0x"] followed by exactly 32 hex digits. *)
val of_string : string -> t

val of_string_opt : string -> t option
val to_string : t -> string

(** [of_int n] is [n] zero-padded to 32 hex digits. Requires [n >= 0]. *)
val of_int : int -> t
