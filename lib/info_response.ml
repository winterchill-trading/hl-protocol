open! Core
open Ppx_yojson_conv_lib.Yojson_conv.Primitives

type t =
  | L2_book of L2_book.t
  | All_mids of All_mids.t
  | Open_orders of Open_order.t list
  | User_fills of User_fill.t list
  | Clearinghouse_state of Clearinghouse_state.t
  | Meta of Meta.t
[@@deriving sexp, compare, equal]

let yojson_of_t = function
  | L2_book x -> L2_book.yojson_of_t x
  | All_mids x -> All_mids.yojson_of_t x
  | Open_orders x -> [%yojson_of: Open_order.t list] x
  | User_fills x -> [%yojson_of: User_fill.t list] x
  | Clearinghouse_state x -> Clearinghouse_state.yojson_of_t x
  | Meta x -> Meta.yojson_of_t x
;;

let of_yojson json ~(request : Info_request.t) =
  match request with
  | L2_book _ -> L2_book (L2_book.t_of_yojson json)
  | All_mids -> All_mids (All_mids.t_of_yojson json)
  | Open_orders _ -> Open_orders ([%of_yojson: Open_order.t list] json)
  | User_fills _ -> User_fills ([%of_yojson: User_fill.t list] json)
  | Clearinghouse_state _ -> Clearinghouse_state (Clearinghouse_state.t_of_yojson json)
  | Meta -> Meta (Meta.t_of_yojson json)
;;
