(** Client order id: a 128-bit value encoded as ["0x"] followed by 32 hex digits.
    Normalised to lowercase. *)

open! Core

type t [@@deriving sexp, compare, equal, hash, yojson]

include Comparable.S with type t := t
include Hashable.S with type t := t

(** Raises unless the string is ["0x"] followed by exactly 32 hex digits. *)
val of_string : string -> t

val of_string_opt : string -> t option
val to_string : t -> string

(** [of_int n] is [n] zero-padded to 32 hex digits. Requires [n >= 0]. *)
val of_int : int -> t
