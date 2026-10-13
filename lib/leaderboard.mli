(** The trader leaderboard served by Hyperliquid's stats host, not the API:
    [GET https://stats-data.hyperliquid.xyz/<Mainnet|Testnet>/leaderboard] returns

    {v
    {"leaderboardRows": [
      {"ethAddress": "0x...", "accountValue": "105568.988111",
       "windowPerformances": [["day", {"pnl": "212.44", "roi": "0.0020", "vlm": "1896110.17"}],
                              ["week", {...}], ["month", {...}], ["allTime", {...}]],
       "prize": 0, "displayName": null}, ...]}
    v}

    The endpoint is undocumented; the shape was read from the testnet response on
    2026-10-13 (25825 rows, every row with all four windows, [displayName] mostly [null]).
    The full response is about 20 MB. Amounts are decimal strings with up to ten decimals,
    more than {!Usd} holds, so they are kept as floats: this is ranking data, not
    accounting. [roi] is a fraction ([0.02] is 2%). *)

open! Core

module Window : sig
  type t =
    | Day
    | Week
    | Month
    | All_time
    | Other of string
  [@@deriving sexp, compare, equal, hash, yojson]

  (** ["day"], ["week"], ["month"], ["allTime"]. *)
  val to_wire : t -> string
end

module Performance : sig
  type t =
    { pnl : float
    ; roi : float
    ; vlm : float
    }
  [@@deriving sexp, compare, equal, yojson]
end

module Row : sig
  type t =
    { eth_address : Address.t
    ; account_value : float
    ; window_performances : (Window.t * Performance.t) list
    ; prize : int
    ; display_name : string option
    }
  [@@deriving sexp, compare, equal, yojson]

  val performance : t -> Window.t -> Performance.t option
end

type t = { leaderboard_rows : Row.t list } [@@deriving sexp, compare, equal, yojson]

(** [https://stats-data.hyperliquid.xyz/Mainnet/leaderboard] or [.../Testnet/...]. *)
val url : [ `Mainnet | `Testnet ] -> string
