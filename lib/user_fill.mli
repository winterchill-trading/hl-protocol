(** A fill, as returned by [userFills] and the [userFills] websocket channel:
    [{"coin": "AVAX", "px": "18.435", "sz": "93.53", "side": "B",
      "time": 1681222254710, "startPosition": "26.86", "dir": "Open Long",
      "closedPnl": "0.0", "hash": "0xa166...", "oid": 90542681, "crossed": false,
      "fee": "0.01", "tid": 118906512037719, "feeToken": "USDC"}].

    [dir] is kept as the raw string (["Open Long"], ["Close Short"], ["Buy"],
    ["Long > Short"], ...). [crossed] is true when the fill took liquidity. *)

open! Core

type t =
  { coin : Coin.t
  ; px : Price.t
  ; sz : Size.t
  ; side : Side.t
  ; time : int
  ; start_position : Size.t
  ; dir : string
  ; closed_pnl : Usd.t
  ; hash : string
  ; oid : Order_id.t
  ; crossed : bool
  ; fee : Usd.t
  ; tid : int
  ; fee_token : string option
  ; cloid : Cloid.t option
  }
[@@deriving sexp, compare, equal, yojson]
