open! Core
open Ppx_yojson_conv_lib.Yojson_conv.Primitives

type t =
  { user : Address.t
  ; builder : Address.t
  }
[@@deriving sexp, compare, equal, yojson] [@@yojson.allow_extra_fields]

let yojson_of_t t = Json.with_tag (yojson_of_t t) ~key:"type" ~value:"maxBuilderFee"

let t_of_yojson json =
  match Json.tag json ~key:"type" with
  | "maxBuilderFee" -> t_of_yojson json
  | _ -> Json.error "Max_builder_fee: not a maxBuilderFee request" json
;;

type response = int [@@deriving sexp_of, yojson]
