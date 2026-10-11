open! Core
open Ppx_yojson_conv_lib.Yojson_conv.Primitives

module User_fills = struct
  type t =
    { is_snapshot : bool [@key "isSnapshot"] [@default false] [@yojson_drop_if not]
    ; user : Address.t
    ; fills : User_fill.t list
    }
  [@@deriving sexp, compare, equal, yojson] [@@yojson.allow_extra_fields]
end

module Mids_wire = struct
  type t = { mids : All_mids.t } [@@deriving yojson] [@@yojson.allow_extra_fields]
end

type t =
  | Subscription_response of Ws_request.t
  | L2_book of L2_book.t
  | Trades of Trade.t list
  | Order_updates of Order_update.t list
  | User_fills of User_fills.t
  | All_mids of All_mids.t
  | Pong
  | Error of string
  | Unknown of
      { channel : string
      ; data : Json.t
      }
[@@deriving sexp, compare, equal]

let channel = function
  | Subscription_response _ -> "subscriptionResponse"
  | L2_book _ -> "l2Book"
  | Trades _ -> "trades"
  | Order_updates _ -> "orderUpdates"
  | User_fills _ -> "userFills"
  | All_mids _ -> "allMids"
  | Pong -> "pong"
  | Error _ -> "error"
  | Unknown { channel; _ } -> channel
;;

let data : t -> Yojson.Safe.t option = function
  | Subscription_response r -> Some (Ws_request.yojson_of_t r)
  | L2_book b -> Some (L2_book.yojson_of_t b)
  | Trades ts -> Some ([%yojson_of: Trade.t list] ts)
  | Order_updates us -> Some ([%yojson_of: Order_update.t list] us)
  | User_fills f -> Some (User_fills.yojson_of_t f)
  | All_mids mids -> Some (Mids_wire.yojson_of_t { mids })
  | Pong -> None
  | Error msg -> Some (`String msg)
  | Unknown { data; _ } -> Some data
;;

let yojson_of_t t : Yojson.Safe.t =
  let channel = "channel", `String (channel t) in
  match data t with
  | None -> `Assoc [ channel ]
  | Some data -> `Assoc [ channel; "data", data ]
;;

let t_of_yojson json =
  let channel = Json.tag json ~key:"channel" in
  let data () = Json.member_exn json ~key:"data" in
  match channel with
  | "subscriptionResponse" -> Subscription_response (Ws_request.t_of_yojson (data ()))
  | "l2Book" -> L2_book (L2_book.t_of_yojson (data ()))
  | "trades" -> Trades ([%of_yojson: Trade.t list] (data ()))
  | "orderUpdates" -> Order_updates ([%of_yojson: Order_update.t list] (data ()))
  | "userFills" -> User_fills (User_fills.t_of_yojson (data ()))
  | "allMids" -> All_mids (Mids_wire.t_of_yojson (data ())).mids
  | "pong" -> Pong
  | "error" ->
    (match data () with
     | `String msg -> Error msg
     | other -> Error (Yojson.Safe.to_string other))
  | _ ->
    Unknown { channel; data = Option.value (Json.member json ~key:"data") ~default:`Null }
;;
