open! Core
open Ppx_yojson_conv_lib.Yojson_conv.Primitives

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
[@@deriving sexp, compare, equal]

module Resting_wire = struct
  type t =
    { oid : Order_id.t
    ; cloid : Cloid.t option [@default None] [@yojson_drop_if Option.is_none]
    }
  [@@deriving yojson] [@@yojson.allow_extra_fields]
end

module Filled_wire = struct
  type t =
    { total_sz : Size.t [@key "totalSz"]
    ; avg_px : Price.t [@key "avgPx"]
    ; oid : Order_id.t
    ; cloid : Cloid.t option [@default None] [@yojson_drop_if Option.is_none]
    }
  [@@deriving yojson] [@@yojson.allow_extra_fields]
end

let yojson_of_t : t -> Yojson.Safe.t = function
  | Resting { oid; cloid } ->
    `Assoc [ "resting", Resting_wire.yojson_of_t { oid; cloid } ]
  | Filled { oid; total_sz; avg_px; cloid } ->
    `Assoc [ "filled", Filled_wire.yojson_of_t { total_sz; avg_px; oid; cloid } ]
  | Error msg -> `Assoc [ "error", `String msg ]
  | Waiting_for_fill -> `String "waitingForFill"
  | Waiting_for_trigger -> `String "waitingForTrigger"
;;

let t_of_yojson (json : Yojson.Safe.t) =
  match json with
  | `Assoc [ ("resting", body) ] ->
    let { Resting_wire.oid; cloid } = Resting_wire.t_of_yojson body in
    Resting { oid; cloid }
  | `Assoc [ ("filled", body) ] ->
    let { Filled_wire.total_sz; avg_px; oid; cloid } = Filled_wire.t_of_yojson body in
    Filled { oid; total_sz; avg_px; cloid }
  | `Assoc [ ("error", `String msg) ] -> Error msg
  | `String "waitingForFill" -> Waiting_for_fill
  | `String "waitingForTrigger" -> Waiting_for_trigger
  | _ -> Json.error "Order_status: unrecognised status" json
;;
