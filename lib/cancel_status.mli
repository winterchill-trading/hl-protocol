(** Per-cancel status in a [cancel] response: ["success"] or
    [{"error": "Order was never placed, already canceled, or filled."}]. *)

open! Core

type t =
  | Success
  | Error of string
[@@deriving sexp, compare, equal, yojson]
