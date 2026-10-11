(** Perpetuals account summary returned by the [clearinghouseState] info request:

    {v
    {"assetPositions": [{"type": "oneWay", "position": {...}}],
     "marginSummary": {...}, "crossMarginSummary": {...},
     "crossMaintenanceMarginUsed": "0.0", "withdrawable": "13104.5",
     "time": 1708622398623}
    v}

    The [{"type": "oneWay", "position": ...}] wrapper is flattened into [positions].
    Unmodelled fields (e.g. [cumFunding], [returnOnEquity]) are ignored on input. *)

open! Core

module Leverage : sig
  (** [{"type": "cross", "value": 20}] or
      [{"type": "isolated", "value": 20, "rawUsd": "-95.05"}]. *)
  type t =
    | Cross of { value : int }
    | Isolated of
        { value : int
        ; raw_usd : Usd.t
        }
  [@@deriving sexp, compare, equal, yojson]

  val value : t -> int
end

module Position : sig
  type t =
    { coin : Coin.t
    ; szi : Size.t (** signed size: positive long, negative short *)
    ; entry_px : Price.t option
    ; position_value : Usd.t
    ; unrealized_pnl : Usd.t
    ; liquidation_px : Price.t option (** [null] when there is no liquidation price *)
    ; leverage : Leverage.t
    ; margin_used : Usd.t
    ; max_leverage : int
    }
  [@@deriving sexp, compare, equal, yojson]
end

module Margin_summary : sig
  type t =
    { account_value : Usd.t
    ; total_ntl_pos : Usd.t
    ; total_raw_usd : Usd.t
    ; total_margin_used : Usd.t
    }
  [@@deriving sexp, compare, equal, yojson]
end

type t =
  { positions : Position.t list
  ; margin_summary : Margin_summary.t
  ; cross_margin_summary : Margin_summary.t
  ; cross_maintenance_margin_used : Usd.t
  ; withdrawable : Usd.t
  ; time : int
  }
[@@deriving sexp, compare, equal, yojson]

val find_position : t -> Coin.t -> Position.t option
