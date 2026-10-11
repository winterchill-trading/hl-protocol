(** An element of the [orderUpdates] websocket channel:
    [{"order": {...}, "status": "open", "statusTimestamp": 1700000000000}]. *)

open! Core

module Status : sig
  (** ["open"], ["filled"], ["canceled"], ["triggered"], ["rejected"], ["marginCanceled"];
      any other value (Hyperliquid has many specific cancel and reject reasons) is kept
      verbatim in [Other]. *)
  type t =
    | Open
    | Filled
    | Canceled
    | Triggered
    | Rejected
    | Margin_canceled
    | Other of string
  [@@deriving sexp, compare, equal, hash, yojson]

  val to_wire : t -> string
  val of_wire : string -> t
end

type t =
  { order : Open_order.t
  ; status : Status.t
  ; status_timestamp : int
  }
[@@deriving sexp, compare, equal, yojson]
