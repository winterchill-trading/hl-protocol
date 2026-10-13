open! Core
open Ppx_yojson_conv_lib.Yojson_conv.Primitives

(* Decimal strings decoded to floats; [Float.to_string] prints the shortest string that
   reads back to the same float, so encoding then decoding is the identity. *)
module Decimal = struct
  type t = float [@@deriving sexp, compare, equal]

  let yojson_of_t t = `String (Float.to_string t)

  let t_of_yojson = function
    | `String s as json ->
      (match Float.of_string_opt s with
       | Some f -> f
       | None -> Json.error "Leaderboard: not a decimal string" json)
    | `Int i -> Float.of_int i
    | `Float f -> f
    | json -> Json.error "Leaderboard: expected a decimal string" json
  ;;
end

module Window = struct
  type t =
    | Day
    | Week
    | Month
    | All_time
    | Other of string
  [@@deriving sexp, compare, equal, hash]

  let to_wire = function
    | Day -> "day"
    | Week -> "week"
    | Month -> "month"
    | All_time -> "allTime"
    | Other s -> s
  ;;

  let of_wire = function
    | "day" -> Day
    | "week" -> Week
    | "month" -> Month
    | "allTime" -> All_time
    | s -> Other s
  ;;

  let yojson_of_t t = `String (to_wire t)

  let t_of_yojson = function
    | `String s -> of_wire s
    | json -> Json.error "Leaderboard.Window: expected a string" json
  ;;
end

module Performance = struct
  type t =
    { pnl : Decimal.t
    ; roi : Decimal.t
    ; vlm : Decimal.t
    }
  [@@deriving sexp, compare, equal, yojson] [@@yojson.allow_extra_fields]
end

module Row = struct
  type t =
    { eth_address : Address.t [@key "ethAddress"]
    ; account_value : Decimal.t [@key "accountValue"]
    ; window_performances : (Window.t * Performance.t) list [@key "windowPerformances"]
    ; prize : int [@default 0]
    ; display_name : string option [@key "displayName"] [@default None]
    }
  [@@deriving sexp, compare, equal, yojson] [@@yojson.allow_extra_fields]

  let performance t window =
    List.Assoc.find t.window_performances window ~equal:Window.equal
  ;;
end

type t = { leaderboard_rows : Row.t list [@key "leaderboardRows"] }
[@@deriving sexp, compare, equal, yojson] [@@yojson.allow_extra_fields]

let url = function
  | `Mainnet -> "https://stats-data.hyperliquid.xyz/Mainnet/leaderboard"
  | `Testnet -> "https://stats-data.hyperliquid.xyz/Testnet/leaderboard"
;;
