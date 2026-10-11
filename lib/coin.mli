(** Asset name as used by Hyperliquid, e.g. ["BTC"], ["ETH"], or ["@107"] for spot pairs. *)

open! Core

type t [@@deriving sexp, compare, equal, hash, yojson]

include Comparable.S with type t := t
include Hashable.S with type t := t
include Stringable.S with type t := t
