open! Core
open Ppx_yojson_conv_lib.Yojson_conv.Primitives

module Status = struct
  type t =
    | Open
    | Filled
    | Canceled
    | Triggered
    | Rejected
    | Margin_canceled
    | Other of string
  [@@deriving sexp, compare, equal, hash]

  let to_wire = function
    | Open -> "open"
    | Filled -> "filled"
    | Canceled -> "canceled"
    | Triggered -> "triggered"
    | Rejected -> "rejected"
    | Margin_canceled -> "marginCanceled"
    | Other s -> s
  ;;

  let of_wire = function
    | "open" -> Open
    | "filled" -> Filled
    | "canceled" -> Canceled
    | "triggered" -> Triggered
    | "rejected" -> Rejected
    | "marginCanceled" -> Margin_canceled
    | s -> Other s
  ;;

  let yojson_of_t t : Yojson.Safe.t = `String (to_wire t)

  let t_of_yojson (json : Yojson.Safe.t) =
    match json with
    | `String s -> of_wire s
    | _ -> Json.error "Order_update.Status: string expected" json
  ;;
end

type t =
  { order : Open_order.t
  ; status : Status.t
  ; status_timestamp : int [@key "statusTimestamp"]
  }
[@@deriving sexp, compare, equal, yojson] [@@yojson.allow_extra_fields]
