(** A fill, as returned by [userFills] and the [userFills] websocket channel:
    [{"coin": "AVAX", "px": "18.435", "sz": "93.53", "side": "B", "time": 1681222254710, "startPosition": "26.86", "dir": "Open Long", "closedPnl": "0.0", "hash": "0xa166...", "oid": 90542681, "crossed": false, "fee": "0.01", "tid": 118906512037719, "feeToken": "USDC"}].

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

(** The [liquidation] object of a fill that was part of a liquidation (websocket docs,
    [FillLiquidation]): [{"liquidatedUser": "0x...", "markPx": "18.4", "method": "market"}].
    [liquidatedUser] is optional; [method] is ["market"] or ["backstop"], kept as the raw
    string. The docs type [markPx] as a number while other prices are strings, so both
    decode. *)
module Liquidation : sig
  type t =
    { liquidated_user : Address.t option
    ; mark_px : Price.t
    ; method_ : string
    }
  [@@deriving sexp, compare, equal, yojson]
end

(** A fill with the optional fields that {!t} does not carry: [builderFee] (the part of
    [fee] paid to the builder, absent when zero) and [liquidation]. Decodes the same JSON
    object as {!t}. These are not fields of {!t} itself, because simulators and tests build
    {!t} records and new fields would break them. *)
module Detailed : sig
  type fill = t [@@deriving sexp, compare, equal]

  type t =
    { fill : fill
    ; builder_fee : Usd.t option
    ; liquidation : Liquidation.t option
    }
  [@@deriving sexp, compare, equal, yojson]

  val of_fill : fill -> t
end
