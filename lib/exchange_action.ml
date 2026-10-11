open! Core
open Ppx_yojson_conv_lib.Yojson_conv.Primitives

type t =
  | Order of
      { orders : Order_request.t list
      ; grouping : Grouping.t
      }
  | Cancel of { cancels : Cancel_request.t list }
  | Cancel_by_cloid of { cancels : Cancel_by_cloid.t list }
  | Modify of Modify_request.t
[@@deriving sexp, compare, equal]

module Order_wire = struct
  type t =
    { orders : Order_request.t list
    ; grouping : Grouping.t [@default Na]
    }
  [@@deriving yojson] [@@yojson.allow_extra_fields]
end

module Cancel_wire = struct
  type t = { cancels : Cancel_request.t list }
  [@@deriving yojson] [@@yojson.allow_extra_fields]
end

module Cancel_by_cloid_wire = struct
  type t = { cancels : Cancel_by_cloid.t list }
  [@@deriving yojson] [@@yojson.allow_extra_fields]
end

module Modify_wire = struct
  type t = Modify_request.t =
    { oid : Modify_request.Target.t
    ; order : Order_request.t
    }
  [@@deriving yojson] [@@yojson.allow_extra_fields]
end

let type_tag = function
  | Order _ -> "order"
  | Cancel _ -> "cancel"
  | Cancel_by_cloid _ -> "cancelByCloid"
  | Modify _ -> "modify"
;;

let yojson_of_t t =
  let body =
    match t with
    | Order { orders; grouping } -> Order_wire.yojson_of_t { orders; grouping }
    | Cancel { cancels } -> Cancel_wire.yojson_of_t { cancels }
    | Cancel_by_cloid { cancels } -> Cancel_by_cloid_wire.yojson_of_t { cancels }
    | Modify modify -> Modify_wire.yojson_of_t modify
  in
  Json.with_tag body ~key:"type" ~value:(type_tag t)
;;

let t_of_yojson json =
  match Json.tag json ~key:"type" with
  | "order" ->
    let { Order_wire.orders; grouping } = Order_wire.t_of_yojson json in
    Order { orders; grouping }
  | "cancel" ->
    let { Cancel_wire.cancels } = Cancel_wire.t_of_yojson json in
    Cancel { cancels }
  | "cancelByCloid" ->
    let { Cancel_by_cloid_wire.cancels } = Cancel_by_cloid_wire.t_of_yojson json in
    Cancel_by_cloid { cancels }
  | "modify" -> Modify (Modify_wire.t_of_yojson json)
  | _ -> Json.error "Exchange_action: unsupported action type" json
;;
