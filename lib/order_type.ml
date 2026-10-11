open! Core
open Ppx_yojson_conv_lib.Yojson_conv.Primitives

type t =
  | Limit of { tif : Tif.t }
  | Trigger of
      { is_market : bool
      ; trigger_px : Price.t
      ; tpsl : Tpsl.t
      }
[@@deriving sexp, compare, equal]

module Limit_wire = struct
  type t = { tif : Tif.t } [@@deriving yojson] [@@yojson.allow_extra_fields]
end

module Trigger_wire = struct
  type t =
    { is_market : bool [@key "isMarket"]
    ; trigger_px : Price.t [@key "triggerPx"]
    ; tpsl : Tpsl.t
    }
  [@@deriving yojson] [@@yojson.allow_extra_fields]
end

let gtc = Limit { tif = Gtc }
let ioc = Limit { tif = Ioc }
let alo = Limit { tif = Alo }

let yojson_of_t t : Yojson.Safe.t =
  match t with
  | Limit { tif } -> `Assoc [ "limit", Limit_wire.yojson_of_t { tif } ]
  | Trigger { is_market; trigger_px; tpsl } ->
    `Assoc [ "trigger", Trigger_wire.yojson_of_t { is_market; trigger_px; tpsl } ]
;;

let t_of_yojson (json : Yojson.Safe.t) =
  match json with
  | `Assoc [ ("limit", body) ] ->
    let { Limit_wire.tif } = Limit_wire.t_of_yojson body in
    Limit { tif }
  | `Assoc [ ("trigger", body) ] ->
    let { Trigger_wire.is_market; trigger_px; tpsl } = Trigger_wire.t_of_yojson body in
    Trigger { is_market; trigger_px; tpsl }
  | _ -> Json.error "Order_type: expected {\"limit\": ...} or {\"trigger\": ...}" json
;;
