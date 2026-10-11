(** Response bodies from [/info]. The JSON carries no tag, so decoding needs the request
    that produced it. *)

open! Core

type t =
  | L2_book of L2_book.t
  | All_mids of All_mids.t
  | Open_orders of Open_order.t list
  | User_fills of User_fill.t list
  | Clearinghouse_state of Clearinghouse_state.t
  | Meta of Meta.t
[@@deriving sexp, compare, equal, yojson_of]

val of_yojson : Yojson.Safe.t -> request:Info_request.t -> t
