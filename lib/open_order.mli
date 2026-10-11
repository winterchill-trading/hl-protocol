(** A resting order, as returned by [openOrders] and embedded in websocket
    [orderUpdates]:
    [{"coin": "BTC", "side": "A", "limitPx": "29792.0", "sz": "0.0",
      "oid": 91490942, "timestamp": 1681247412573, "origSz": "5.0",
      "cloid": "0x..."}].
    [sz] is the remaining size. [origSz] and [cloid] are optional. *)

open! Core

type t =
  { coin : Coin.t
  ; side : Side.t
  ; limit_px : Price.t
  ; sz : Size.t
  ; oid : Order_id.t
  ; timestamp : int
  ; orig_sz : Size.t option
  ; cloid : Cloid.t option
  }
[@@deriving sexp, compare, equal, yojson]
