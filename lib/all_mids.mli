(** Mid prices by coin, encoded as a JSON object [{"BTC": "113000.5", ...}]. Order
    is preserved. *)

open! Core

type t = (Coin.t * Price.t) list [@@deriving sexp, compare, equal, yojson]

val find : t -> Coin.t -> Price.t option
