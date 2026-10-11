(** Response from [/exchange]:

    - [{"status": "ok", "response": {"type": "order", "data": {"statuses": [...]}}}]
    - [{"status": "ok", "response": {"type": "cancel", "data": {"statuses": [...]}}}]
    - [{"status": "ok", "response": {"type": "default"}}] (e.g. for [modify])
    - [{"status": "err", "response": "message"}] *)

open! Core

module Response : sig
  type t =
    | Order of Order_status.t list
    | Cancel of Cancel_status.t list
    | Default
  [@@deriving sexp, compare, equal, yojson]
end

type t =
  | Ok of Response.t
  | Err of string
[@@deriving sexp, compare, equal, yojson]
