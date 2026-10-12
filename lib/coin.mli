(** Asset name as used by Hyperliquid, e.g. ["BTC"], ["ETH"], or ["@107"] for spot pairs.
    An alias of {!Exchange_core.Symbol}, encoded as a JSON string. *)

open! Core

include module type of struct
  include Exchange_core.Symbol
end

val yojson_of_t : t -> Yojson.Safe.t
val t_of_yojson : Yojson.Safe.t -> t
