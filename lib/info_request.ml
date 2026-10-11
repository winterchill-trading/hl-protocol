open! Core
open Ppx_yojson_conv_lib.Yojson_conv.Primitives

type t =
  | L2_book of
      { coin : Coin.t
      ; n_sig_figs : int option
      ; mantissa : int option
      }
  | All_mids
  | Open_orders of { user : Address.t }
  | User_fills of { user : Address.t }
  | Clearinghouse_state of { user : Address.t }
  | Meta
[@@deriving sexp, compare, equal]

module L2_book_wire = struct
  type t =
    { coin : Coin.t
    ; n_sig_figs : int option
         [@key "nSigFigs"] [@default None] [@yojson_drop_if Option.is_none]
    ; mantissa : int option [@default None] [@yojson_drop_if Option.is_none]
    }
  [@@deriving yojson] [@@yojson.allow_extra_fields]
end

module User_wire = struct
  type t = { user : Address.t } [@@deriving yojson] [@@yojson.allow_extra_fields]
end

let type_tag = function
  | L2_book _ -> "l2Book"
  | All_mids -> "allMids"
  | Open_orders _ -> "openOrders"
  | User_fills _ -> "userFills"
  | Clearinghouse_state _ -> "clearinghouseState"
  | Meta -> "meta"
;;

let yojson_of_t t =
  let body =
    match t with
    | L2_book { coin; n_sig_figs; mantissa } ->
      L2_book_wire.yojson_of_t { coin; n_sig_figs; mantissa }
    | Open_orders { user } | User_fills { user } | Clearinghouse_state { user } ->
      User_wire.yojson_of_t { user }
    | All_mids | Meta -> `Assoc []
  in
  Json.with_tag body ~key:"type" ~value:(type_tag t)
;;

let t_of_yojson json =
  let user () = (User_wire.t_of_yojson json).user in
  match Json.tag json ~key:"type" with
  | "l2Book" ->
    let { L2_book_wire.coin; n_sig_figs; mantissa } = L2_book_wire.t_of_yojson json in
    L2_book { coin; n_sig_figs; mantissa }
  | "allMids" -> All_mids
  | "openOrders" -> Open_orders { user = user () }
  | "userFills" -> User_fills { user = user () }
  | "clearinghouseState" -> Clearinghouse_state { user = user () }
  | "meta" -> Meta
  | _ -> Json.error "Info_request: unsupported request type" json
;;
