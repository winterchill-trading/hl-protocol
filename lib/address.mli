(** An account address, e.g. ["0x0000000000000000000000000000000000000000"]. Normalised to lowercase. *)

open! Core

type t [@@deriving sexp, compare, equal, hash, yojson]

include Comparable.S with type t := t
include Hashable.S with type t := t
include Stringable.S with type t := t
