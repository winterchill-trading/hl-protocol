(** An [order] action with the optional builder fee:
    [{"type": "order", "orders": [...], "grouping": "na", "builder": {"b": "0x...", "f": 10}}].

    {!Exchange_action.Order} has no [builder] field and keeps its shape so that exhaustive
    matches in dependents still compile; this module is the order action with the builder
    attached, and converts to and from it. Its decoder accepts any [order] action, with or
    without [builder].

    Key order matters: L1 actions are signed over the MessagePack encoding of the action
    as sent, and the official Python SDK ([order_wires_to_order_action] in
    [hyperliquid/utils/signing.py]) appends [builder] after [grouping]. The encoder emits
    the same order. *)

open! Core

type t =
  { orders : Order_request.t list
  ; grouping : Grouping.t
  ; builder : Builder_fee.t option
  }
[@@deriving sexp, compare, equal, yojson]

val create
  :  ?grouping:Grouping.t (** default [Na] *)
  -> ?builder:Builder_fee.t
  -> Order_request.t list
  -> t

(** [Some] for [Exchange_action.Order], with no builder. *)
val of_exchange_action : Exchange_action.t -> t option

(** Drops the builder. *)
val to_exchange_action : t -> Exchange_action.t
