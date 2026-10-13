open! Core
open Ppx_yojson_conv_lib.Yojson_conv.Primitives

type t =
  { action : User_signed_action.t
  ; nonce : int
  ; signature : Json.t option [@default None] [@yojson_drop_if Option.is_none]
  }
[@@deriving sexp, compare, equal, yojson] [@@yojson.allow_extra_fields]

let create ?signature action =
  { action; nonce = User_signed_action.nonce action; signature }
;;

let is_user_signed_body body =
  match Option.bind (Json.member body ~key:"action") ~f:(Json.member ~key:"type") with
  | Some (`String tag) -> User_signed_action.is_user_signed_type tag
  | _ -> false
;;
