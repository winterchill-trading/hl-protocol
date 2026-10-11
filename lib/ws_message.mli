(** Server-to-client websocket messages, [{"channel": "...", "data": ...}],
    decoded by channel. Unrecognised channels are preserved as [Unknown]. *)

open! Core

module User_fills : sig
  (** [{"isSnapshot": true, "user": "0x...", "fills": [...]}]. The first message
      after subscribing is a snapshot; [isSnapshot] is omitted on later messages. *)
  type t =
    { is_snapshot : bool
    ; user : Address.t
    ; fills : User_fill.t list
    }
  [@@deriving sexp, compare, equal, yojson]
end

type t =
  | Subscription_response of Ws_request.t
  (** Echo of an accepted (un)subscribe request. *)
  | L2_book of L2_book.t
  | Trades of Trade.t list
  | Order_updates of Order_update.t list
  | User_fills of User_fills.t
  | All_mids of All_mids.t (** [data] is [{"mids": {...}}] *)
  | Pong (** [{"channel": "pong"}], no [data] *)
  | Error of string
  | Unknown of
      { channel : string
      ; data : Json.t
      }
[@@deriving sexp, compare, equal, yojson]

val channel : t -> string
