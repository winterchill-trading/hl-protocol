open! Core
open Ppx_yojson_conv_lib.Yojson_conv.Primitives

type t =
  { asset : Asset.t [@key "a"]
  ; is_buy : bool [@key "b"]
  ; limit_px : Price.t [@key "p"]
  ; sz : Size.t [@key "s"]
  ; reduce_only : bool [@key "r"]
  ; order_type : Order_type.t [@key "t"]
  ; cloid : Cloid.t option [@key "c"] [@default None] [@yojson_drop_if Option.is_none]
  }
[@@deriving sexp, compare, equal, yojson]

let side t = Side.of_is_buy t.is_buy
