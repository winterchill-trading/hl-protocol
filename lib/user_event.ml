open! Core
open Ppx_yojson_conv_lib.Yojson_conv.Primitives

module Funding = struct
  type t =
    { time : int
    ; coin : Coin.t
    ; usdc : Usd.t
    ; szi : Size.t
    ; funding_rate : string [@key "fundingRate"]
    }
  [@@deriving sexp, compare, equal, yojson] [@@yojson.allow_extra_fields]
end

module Liquidation = struct
  type t =
    { lid : int
    ; liquidator : Address.t
    ; liquidated_user : Address.t
    ; liquidated_ntl_pos : string
    ; liquidated_account_value : string
    }
  [@@deriving sexp, compare, equal, yojson] [@@yojson.allow_extra_fields]
end

module Non_user_cancel = struct
  type t =
    { coin : Coin.t
    ; oid : Order_id.t
    }
  [@@deriving sexp, compare, equal, yojson] [@@yojson.allow_extra_fields]
end

type t =
  | Fills of User_fill.t list
  | Funding of Funding.t
  | Liquidation of Liquidation.t
  | Non_user_cancel of Non_user_cancel.t list
  | Other of Json.t
[@@deriving sexp, compare, equal]

let yojson_of_t = function
  | Fills fills -> `Assoc [ "fills", [%yojson_of: User_fill.t list] fills ]
  | Funding funding -> `Assoc [ "funding", Funding.yojson_of_t funding ]
  | Liquidation liquidation ->
    `Assoc [ "liquidation", Liquidation.yojson_of_t liquidation ]
  | Non_user_cancel cancels ->
    `Assoc [ "nonUserCancel", [%yojson_of: Non_user_cancel.t list] cancels ]
  | Other json -> json
;;

let t_of_yojson json =
  match json with
  | `Assoc [ ("fills", fills) ] -> Fills ([%of_yojson: User_fill.t list] fills)
  | `Assoc [ ("funding", funding) ] -> Funding (Funding.t_of_yojson funding)
  | `Assoc [ ("liquidation", liquidation) ] ->
    Liquidation (Liquidation.t_of_yojson liquidation)
  | `Assoc [ ("nonUserCancel", cancels) ] ->
    Non_user_cancel ([%of_yojson: Non_user_cancel.t list] cancels)
  | _ -> Other json
;;

let channel = "user"

let of_ws_message : Ws_message.t -> t option = function
  | Unknown { channel = "user"; data } -> Some (t_of_yojson data)
  | _ -> None
;;

let subscription ~user =
  `Assoc [ "type", `String "userEvents"; "user", Address.yojson_of_t user ]
;;

let ws_request method_ ~user =
  let method_ =
    match method_ with
    | `Subscribe -> "subscribe"
    | `Unsubscribe -> "unsubscribe"
  in
  `Assoc [ "method", `String method_; "subscription", subscription ~user ]
;;
