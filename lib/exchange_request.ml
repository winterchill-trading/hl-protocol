open! Core
open Ppx_yojson_conv_lib.Yojson_conv.Primitives

type t =
  { action : Exchange_action.t
  ; nonce : int
  ; signature : Json.t option [@default None] [@yojson_drop_if Option.is_none]
  ; vault_address : Address.t option
       [@key "vaultAddress"] [@default None] [@yojson_drop_if Option.is_none]
  }
[@@deriving sexp, compare, equal, yojson] [@@yojson.allow_extra_fields]
