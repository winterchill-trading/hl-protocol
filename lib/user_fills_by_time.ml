open! Core
open Ppx_yojson_conv_lib.Yojson_conv.Primitives

type t =
  { user : Address.t
  ; start_time : int [@key "startTime"]
  ; end_time : int option
       [@key "endTime"] [@default None] [@yojson_drop_if Option.is_none]
  ; aggregate_by_time : bool option
       [@key "aggregateByTime"] [@default None] [@yojson_drop_if Option.is_none]
  }
[@@deriving sexp, compare, equal, yojson] [@@yojson.allow_extra_fields]

let yojson_of_t t = Json.with_tag (yojson_of_t t) ~key:"type" ~value:"userFillsByTime"

let t_of_yojson json =
  match Json.tag json ~key:"type" with
  | "userFillsByTime" -> t_of_yojson json
  | _ -> Json.error "User_fills_by_time: not a userFillsByTime request" json
;;

let max_fills_per_response = 2000

type response = User_fill.t list [@@deriving sexp_of, yojson]
