(** The [maxBuilderFee] info request (Hyperliquid info endpoint docs, "Check builder fee
    approval"): [{"type": "maxBuilderFee", "user": "0x...", "builder": "0x..."}].

    The response is a bare integer, the largest fee [user] has approved for [builder] in
    tenths of a basis point ([1] means 0.001%), [0] when there is no approval.

    Not an {!Info_request} constructor, since dependents match that type exhaustively. *)

open! Core

type t =
  { user : Address.t
  ; builder : Address.t
  }
[@@deriving sexp, compare, equal, yojson]

(** Tenths of a basis point. *)
type response = int [@@deriving sexp_of, yojson]
