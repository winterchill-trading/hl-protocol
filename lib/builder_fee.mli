(** The optional [builder] field of an [order] action, [{"b": "0x...", "f": 10}].

    Per the Hyperliquid exchange endpoint docs ("Place an order"): [b] is the address that
    receives the builder fee and [f] is the fee in tenths of a basis point, so [f = 10]
    charges 1 bp of the order's notional. The user must first approve at least that rate
    with an [approveBuilderFee] action (see {!User_signed_action}). *)

open! Core

type t =
  { builder : Address.t (** [b] *)
  ; fee_tenths_bp : int (** [f] *)
  }
[@@deriving sexp, compare, equal, yojson]

(** The percent string used as [maxFeeRate] in [approveBuilderFee] for a fee in tenths of
    a basis point: [1] is ["0.001%"], [10] is ["0.01%"], [100] is ["0.1%"]. Raises on a
    negative fee. *)
val percent_of_tenths_bp : int -> string

(** The inverse of {!percent_of_tenths_bp}; [Error] unless the string is a non-negative
    percentage with at most three decimals. *)
val tenths_bp_of_percent : string -> int Or_error.t
