open! Core
open Ppx_yojson_conv_lib.Yojson_conv.Primitives

type t =
  { orders : Order_request.t list
  ; grouping : Grouping.t [@default Na]
  ; builder : Builder_fee.t option [@default None] [@yojson_drop_if Option.is_none]
  }
[@@deriving sexp, compare, equal, yojson] [@@yojson.allow_extra_fields]

let create ?(grouping = Grouping.Na) ?builder orders = { orders; grouping; builder }

let of_exchange_action : Exchange_action.t -> t option = function
  | Order { orders; grouping } -> Some { orders; grouping; builder = None }
  | Cancel _ | Cancel_by_cloid _ | Modify _ -> None
;;

let to_exchange_action { orders; grouping; builder = _ } : Exchange_action.t =
  Order { orders; grouping }
;;

let yojson_of_t t = Json.with_tag (yojson_of_t t) ~key:"type" ~value:"order"

let t_of_yojson json =
  match Json.tag json ~key:"type" with
  | "order" -> t_of_yojson json
  | _ -> Json.error "Order_action: not an order action" json
;;
