(** Per-order status in an [order] response:

    - [{"resting": {"oid": 77738308, "cloid": "0x..."}}]
    - [{"filled": {"totalSz": "0.02", "avgPx": "1891.4", "oid": 77747314}}]
    - [{"error": "Order must have minimum value of $10."}]
    - ["waitingForFill"], ["waitingForTrigger"] *)

open! Core

type t =
  | Resting of
      { oid : Order_id.t
      ; cloid : Cloid.t option
      }
  | Filled of
      { oid : Order_id.t
      ; total_sz : Size.t
      ; avg_px : Price.t
      ; cloid : Cloid.t option
      }
  | Error of string
  | Waiting_for_fill
  | Waiting_for_trigger
[@@deriving sexp, compare, equal, yojson]
