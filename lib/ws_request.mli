(** Client-to-server websocket messages:

    - [{"method": "subscribe", "subscription": {...}}]
    - [{"method": "unsubscribe", "subscription": {...}}]
    - [{"method": "ping"}] *)

open! Core

type t =
  | Subscribe of Subscription.t
  | Unsubscribe of Subscription.t
  | Ping
[@@deriving sexp, compare, equal, yojson]
