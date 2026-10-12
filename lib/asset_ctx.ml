open! Core
open Ppx_yojson_conv_lib.Yojson_conv.Primitives

(* Rates in plain decimal notation, as Hyperliquid sends them: "0.0000125", never
   "1.25e-05". *)
module Rate = struct
  type t = float [@@deriving sexp, compare, equal]

  let yojson_of_t x : Yojson.Safe.t =
    let s = sprintf "%.12f" x |> String.rstrip ~drop:(Char.equal '0') in
    `String (if String.is_suffix s ~suffix:"." then s ^ "0" else s)
  ;;

  let t_of_yojson : Yojson.Safe.t -> t = function
    | `String s as json ->
      (match Float.of_string_opt s with
       | Some x when Float.is_finite x -> x
       | _ -> Json.error "Asset_ctx: rate is not a decimal string" json)
    | json -> Json.error "Asset_ctx: rate is not a string" json
  ;;
end

module Impact_pxs = struct
  type t = Price.t * Price.t [@@deriving sexp, compare, equal]

  let yojson_of_t (bid, ask) : Yojson.Safe.t =
    `List [ Price.yojson_of_t bid; Price.yojson_of_t ask ]
  ;;

  let t_of_yojson : Yojson.Safe.t -> t = function
    | `List [ bid; ask ] -> Price.t_of_yojson bid, Price.t_of_yojson ask
    | json -> Json.error "Asset_ctx: impactPxs is not [bid, ask]" json
  ;;
end

module Ctx = struct
  type t =
    { funding : Rate.t option [@default None] [@yojson_drop_if Option.is_none]
    ; open_interest : Size.t option
         [@key "openInterest"] [@default None] [@yojson_drop_if Option.is_none]
    ; prev_day_px : Price.t [@key "prevDayPx"]
    ; day_ntl_vlm : Usd.t [@key "dayNtlVlm"]
    ; premium : Rate.t option [@default None] [@yojson_drop_if Option.is_none]
    ; oracle_px : Price.t option
         [@key "oraclePx"] [@default None] [@yojson_drop_if Option.is_none]
    ; mark_px : Price.t [@key "markPx"]
    ; mid_px : Price.t option [@key "midPx"] [@default None]
    ; impact_pxs : Impact_pxs.t option
         [@key "impactPxs"] [@default None] [@yojson_drop_if Option.is_none]
    ; day_base_vlm : Size.t option
         [@key "dayBaseVlm"] [@default None] [@yojson_drop_if Option.is_none]
    }
  [@@deriving sexp, compare, equal, yojson] [@@yojson.allow_extra_fields]
end

type t =
  { coin : Coin.t
  ; ctx : Ctx.t
  }
[@@deriving sexp, compare, equal, yojson] [@@yojson.allow_extra_fields]

let channel = "activeAssetCtx"
let to_ws_message t = Ws_message.Unknown { channel; data = yojson_of_t t }

let of_ws_message : Ws_message.t -> t Or_error.t option = function
  | Unknown { channel = c; data } when String.equal c channel ->
    Some (Or_error.try_with (fun () -> t_of_yojson data))
  | _ -> None
;;

module Request = struct
  type t =
    { subscribe : bool
    ; coin : Coin.t
    }
  [@@deriving sexp, compare, equal]

  let yojson_of_t { subscribe; coin } : Yojson.Safe.t =
    `Assoc
      [ "method", `String (if subscribe then "subscribe" else "unsubscribe")
      ; "subscription", `Assoc [ "type", `String channel; "coin", Coin.yojson_of_t coin ]
      ]
  ;;

  let of_yojson_opt json =
    let open Option.Let_syntax in
    let%bind subscribe =
      match Json.member json ~key:"method" with
      | Some (`String "subscribe") -> Some true
      | Some (`String "unsubscribe") -> Some false
      | _ -> None
    in
    let%bind subscription = Json.member json ~key:"subscription" in
    match Json.member subscription ~key:"type", Json.member subscription ~key:"coin" with
    | Some (`String type_), Some (`String coin) when String.equal type_ channel ->
      Some { subscribe; coin = Coin.of_string coin }
    | _ -> None
  ;;

  let t_of_yojson json =
    match of_yojson_opt json with
    | Some t -> t
    | None -> Json.error "Asset_ctx.Request: not an activeAssetCtx request" json
  ;;

  let response t =
    Ws_message.Unknown { channel = "subscriptionResponse"; data = yojson_of_t t }
  ;;
end
