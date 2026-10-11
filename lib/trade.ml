open! Core
open Ppx_yojson_conv_lib.Yojson_conv.Primitives

type t =
  { coin : Coin.t
  ; side : Side.t
  ; px : Price.t
  ; sz : Size.t
  ; hash : string
  ; time : int
  ; tid : int
  ; users : Address.t * Address.t
  }
[@@deriving sexp, compare, equal, yojson] [@@yojson.allow_extra_fields]
