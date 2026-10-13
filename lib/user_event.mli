(** The [userEvents] websocket subscription, [{"type": "userEvents", "user": "0x..."}],
    whose messages arrive on channel ["user"] (Hyperliquid websocket docs,
    "Subscriptions", [WsUserEvent]):

    {v
    type WsUserEvent = {"fills": WsFill[]} | {"funding": WsUserFunding}
                     | {"liquidation": WsLiquidation} | {"nonUserCancel": WsNonUserCancel[]}
    v}

    Any address can be subscribed, so this is how a follower watches a leader. The
    subscription is not a {!Subscription} constructor (dependents match that type
    exhaustively), and {!Ws_message} keeps these frames as [Unknown {channel = "user"}];
    {!of_ws_message} decodes them. *)

open! Core

module Funding : sig
  (** [WsUserFunding]: [{"time", "coin", "usdc", "szi", "fundingRate"}]. *)
  type t =
    { time : int
    ; coin : Coin.t
    ; usdc : Usd.t
    ; szi : Size.t
    ; funding_rate : string
    }
  [@@deriving sexp, compare, equal, yojson]
end

module Liquidation : sig
  (** [WsLiquidation]:
      [{"lid", "liquidator", "liquidated_user", "liquidated_ntl_pos", "liquidated_account_value"}]
      (snake case on the wire). Amounts are kept as the exchange's decimal strings. *)
  type t =
    { lid : int
    ; liquidator : Address.t
    ; liquidated_user : Address.t
    ; liquidated_ntl_pos : string
    ; liquidated_account_value : string
    }
  [@@deriving sexp, compare, equal, yojson]
end

module Non_user_cancel : sig
  (** [WsNonUserCancel]: [{"coin", "oid"}], an order cancelled by the exchange. *)
  type t =
    { coin : Coin.t
    ; oid : Order_id.t
    }
  [@@deriving sexp, compare, equal, yojson]
end

type t =
  | Fills of User_fill.t list
  | Funding of Funding.t
  | Liquidation of Liquidation.t
  | Non_user_cancel of Non_user_cancel.t list
  | Other of Json.t (** any other shape, kept verbatim *)
[@@deriving sexp, compare, equal, yojson]

(** ["user"]. *)
val channel : string

(** [Some] for a [Ws_message.Unknown] frame on channel ["user"]. *)
val of_ws_message : Ws_message.t -> t option

(** [{"type": "userEvents", "user": "0x..."}]. *)
val subscription : user:Address.t -> Json.t

(** [{"method": "subscribe" | "unsubscribe", "subscription": ...}]. *)
val ws_request : [ `Subscribe | `Unsubscribe ] -> user:Address.t -> Json.t
