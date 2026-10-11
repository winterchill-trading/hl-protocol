(** A public trade from the [trades] websocket channel:
    [{"coin": "BTC", "side": "B", "px": "113000", "sz": "0.01", "hash": "0x...",
      "time": 1700000000000, "tid": 123, "users": ["0xbuyer", "0xseller"]}].
    [side] is the aggressor side. *)

open! Core

type t =
  { coin : Coin.t
  ; side : Side.t
  ; px : Price.t
  ; sz : Size.t
  ; hash : string
  ; time : int
  ; tid : int
  ; users : Address.t * Address.t (** (buyer, seller) *)
  }
[@@deriving sexp, compare, equal, yojson]
