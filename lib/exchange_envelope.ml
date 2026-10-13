open! Core
open Ppx_yojson_conv_lib.Yojson_conv.Primitives

type t =
  { action : Json.t
  ; nonce : int
  ; signature : Json.t option [@default None] [@yojson_drop_if Option.is_none]
  ; vault_address : Address.t option
       [@key "vaultAddress"] [@default None] [@yojson_drop_if Option.is_none]
  ; expires_after : int option
       [@key "expiresAfter"] [@default None] [@yojson_drop_if Option.is_none]
  }
[@@deriving sexp, compare, equal, yojson] [@@yojson.allow_extra_fields]

let of_exchange_request { Exchange_request.action; nonce; signature; vault_address } =
  { action = Exchange_action.yojson_of_t action
  ; nonce
  ; signature
  ; vault_address
  ; expires_after = None
  }
;;
