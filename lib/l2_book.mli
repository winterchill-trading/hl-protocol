(** Order book snapshot, as returned by the [l2Book] info request and the
    [l2Book] websocket channel:
    [{"coin": "BTC", "time": 1754450974231,
      "levels": [[{"px": "113377.0", "sz": "7.6699", "n": 17}, ...], [...]]}]
    where [levels] is [[bids; asks]], best price first. *)

open! Core

module Level : sig
  type t =
    { px : Price.t
    ; sz : Size.t
    ; n : int (** number of orders at this level *)
    }
  [@@deriving sexp, compare, equal, yojson]
end

type t =
  { coin : Coin.t
  ; time : int (** milliseconds since the epoch *)
  ; bids : Level.t list
  ; asks : Level.t list
  }
[@@deriving sexp, compare, equal, yojson]

val best_bid : t -> Level.t option
val best_ask : t -> Level.t option
