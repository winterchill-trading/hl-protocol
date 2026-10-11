open! Core
open Ppx_yojson_conv_lib.Yojson_conv.Primitives

type t =
  { coin : Coin.t
  ; side : Side.t
  ; limit_px : Price.t [@key "limitPx"]
  ; sz : Size.t
  ; oid : Order_id.t
  ; timestamp : int
  ; orig_sz : Size.t option
       [@key "origSz"] [@default None] [@yojson_drop_if Option.is_none]
  ; cloid : Cloid.t option [@default None] [@yojson_drop_if Option.is_none]
  }
[@@deriving sexp, compare, equal, yojson] [@@yojson.allow_extra_fields]
