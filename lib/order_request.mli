(** A single order in an [order] or [modify] action, in Hyperliquid's compact wire
    form: [{"a": asset, "b": isBuy, "p": limitPx, "s": sz, "r": reduceOnly,
    "t": orderType, "c": cloid}]. [c] is omitted when there is no client id.

    The asset is identified by its index (see [Meta.asset_of_coin]), as on the real
    exchange endpoint. *)

open! Core

type t =
  { asset : Asset.t
  ; is_buy : bool
  ; limit_px : Price.t
  ; sz : Size.t
  ; reduce_only : bool
  ; order_type : Order_type.t
  ; cloid : Cloid.t option
  }
[@@deriving sexp, compare, equal, yojson]

val side : t -> Side.t
