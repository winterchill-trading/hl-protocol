open! Core
open Ppx_yojson_conv_lib.Yojson_conv.Primitives

type t =
  { coin : Coin.t
  ; px : Price.t
  ; sz : Size.t
  ; side : Side.t
  ; time : int
  ; start_position : Size.t [@key "startPosition"]
  ; dir : string
  ; closed_pnl : Usd.t [@key "closedPnl"]
  ; hash : string
  ; oid : Order_id.t
  ; crossed : bool
  ; fee : Usd.t
  ; tid : int
  ; fee_token : string option
       [@key "feeToken"] [@default None] [@yojson_drop_if Option.is_none]
  ; cloid : Cloid.t option [@default None] [@yojson_drop_if Option.is_none]
  }
[@@deriving sexp, compare, equal, yojson] [@@yojson.allow_extra_fields]
