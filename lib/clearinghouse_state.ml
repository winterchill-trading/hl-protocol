open! Core
open Ppx_yojson_conv_lib.Yojson_conv.Primitives

module Leverage = struct
  type t =
    | Cross of { value : int }
    | Isolated of
        { value : int
        ; raw_usd : Usd.t
        }
  [@@deriving sexp, compare, equal]

  module Wire = struct
    type t =
      { value : int
      ; raw_usd : Usd.t option
           [@key "rawUsd"] [@default None] [@yojson_drop_if Option.is_none]
      }
    [@@deriving yojson] [@@yojson.allow_extra_fields]
  end

  let value = function
    | Cross { value } | Isolated { value; _ } -> value
  ;;

  let yojson_of_t t =
    let tag, body =
      match t with
      | Cross { value } -> "cross", { Wire.value; raw_usd = None }
      | Isolated { value; raw_usd } -> "isolated", { Wire.value; raw_usd = Some raw_usd }
    in
    Json.with_tag (Wire.yojson_of_t body) ~key:"type" ~value:tag
  ;;

  let t_of_yojson json =
    let { Wire.value; raw_usd } = Wire.t_of_yojson json in
    match Json.tag json ~key:"type" with
    | "cross" -> Cross { value }
    | "isolated" -> Isolated { value; raw_usd = Option.value raw_usd ~default:Usd.zero }
    | _ -> Json.error "Leverage: unknown type" json
  ;;
end

(* [null], absent, or a price outside the fixed-point range (deep out-of-the-money
   liquidation prices of small positions can be astronomically large) all mean "no usable
   liquidation price". *)
module Liquidation_px = struct
  type t = Price.t option [@@deriving sexp, compare, equal]

  let yojson_of_t : t -> Yojson.Safe.t = function
    | None -> `Null
    | Some px -> Price.yojson_of_t px
  ;;

  let t_of_yojson : Yojson.Safe.t -> t = function
    | `Null -> None
    | `String s -> Price.of_string_opt s
    | (`Int _ | `Intlit _ | `Float _) as json ->
      Price.of_string_opt (Yojson.Safe.to_string json)
    | json -> Json.error "Clearinghouse_state: liquidationPx is not a price" json
  ;;
end

module Position = struct
  type t =
    { coin : Coin.t
    ; szi : Size.t
    ; entry_px : Price.t option [@key "entryPx"] [@default None]
    ; position_value : Usd.t [@key "positionValue"]
    ; unrealized_pnl : Usd.t [@key "unrealizedPnl"]
    ; liquidation_px : Liquidation_px.t [@key "liquidationPx"] [@default None]
    ; leverage : Leverage.t
    ; margin_used : Usd.t [@key "marginUsed"]
    ; max_leverage : int [@key "maxLeverage"]
    }
  [@@deriving sexp, compare, equal, yojson] [@@yojson.allow_extra_fields]
end

module Margin_summary = struct
  type t =
    { account_value : Usd.t [@key "accountValue"]
    ; total_ntl_pos : Usd.t [@key "totalNtlPos"]
    ; total_raw_usd : Usd.t [@key "totalRawUsd"]
    ; total_margin_used : Usd.t [@key "totalMarginUsed"]
    }
  [@@deriving sexp, compare, equal, yojson] [@@yojson.allow_extra_fields]
end

module Asset_position_wire = struct
  type t =
    { type_ : string [@key "type"] [@default "oneWay"]
    ; position : Position.t
    }
  [@@deriving yojson] [@@yojson.allow_extra_fields]
end

type t =
  { positions : Position.t list
  ; margin_summary : Margin_summary.t
  ; cross_margin_summary : Margin_summary.t
  ; cross_maintenance_margin_used : Usd.t
  ; withdrawable : Usd.t
  ; time : int
  }
[@@deriving sexp, compare, equal]

module Wire = struct
  type t =
    { asset_positions : Asset_position_wire.t list [@key "assetPositions"]
    ; margin_summary : Margin_summary.t [@key "marginSummary"]
    ; cross_margin_summary : Margin_summary.t [@key "crossMarginSummary"]
    ; cross_maintenance_margin_used : Usd.t [@key "crossMaintenanceMarginUsed"]
    ; withdrawable : Usd.t
    ; time : int
    }
  [@@deriving yojson] [@@yojson.allow_extra_fields]
end

let yojson_of_t
  { positions
  ; margin_summary
  ; cross_margin_summary
  ; cross_maintenance_margin_used
  ; withdrawable
  ; time
  }
  =
  Wire.yojson_of_t
    { asset_positions =
        List.map positions ~f:(fun position ->
          { Asset_position_wire.type_ = "oneWay"; position })
    ; margin_summary
    ; cross_margin_summary
    ; cross_maintenance_margin_used
    ; withdrawable
    ; time
    }
;;

let t_of_yojson json =
  let { Wire.asset_positions
      ; margin_summary
      ; cross_margin_summary
      ; cross_maintenance_margin_used
      ; withdrawable
      ; time
      }
    =
    Wire.t_of_yojson json
  in
  { positions = List.map asset_positions ~f:(fun p -> p.position)
  ; margin_summary
  ; cross_margin_summary
  ; cross_maintenance_margin_used
  ; withdrawable
  ; time
  }
;;

let find_position t coin =
  List.find t.positions ~f:(fun (p : Position.t) -> Coin.equal p.coin coin)
;;
