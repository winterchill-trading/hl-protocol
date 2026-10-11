(** Order type. Encoded as [{"limit": {"tif": "Gtc"}}] or
    [{"trigger": {"isMarket": true, "triggerPx": "100", "tpsl": "sl"}}]. *)

open! Core

type t =
  | Limit of { tif : Tif.t }
  | Trigger of
      { is_market : bool
      ; trigger_px : Price.t
      ; tpsl : Tpsl.t
      }
[@@deriving sexp, compare, equal, yojson]

val gtc : t
val ioc : t
val alo : t
