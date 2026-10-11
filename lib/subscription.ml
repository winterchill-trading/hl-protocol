open! Core

module T = struct
  type t =
    | L2_book of { coin : Coin.t }
    | Trades of { coin : Coin.t }
    | Order_updates of { user : Address.t }
    | User_fills of { user : Address.t }
    | All_mids
  [@@deriving sexp, compare, equal, hash]
end

include T
include Comparable.Make (T)

module Coin_wire = struct
  type t = { coin : Coin.t } [@@deriving yojson] [@@yojson.allow_extra_fields]
end

module User_wire = struct
  type t = { user : Address.t } [@@deriving yojson] [@@yojson.allow_extra_fields]
end

let channel = function
  | L2_book _ -> "l2Book"
  | Trades _ -> "trades"
  | Order_updates _ -> "orderUpdates"
  | User_fills _ -> "userFills"
  | All_mids -> "allMids"
;;

let yojson_of_t t =
  let body =
    match t with
    | L2_book { coin } | Trades { coin } -> Coin_wire.yojson_of_t { coin }
    | Order_updates { user } | User_fills { user } -> User_wire.yojson_of_t { user }
    | All_mids -> `Assoc []
  in
  Json.with_tag body ~key:"type" ~value:(channel t)
;;

let t_of_yojson json =
  let coin () = (Coin_wire.t_of_yojson json).coin in
  let user () = (User_wire.t_of_yojson json).user in
  match Json.tag json ~key:"type" with
  | "l2Book" -> L2_book { coin = coin () }
  | "trades" -> Trades { coin = coin () }
  | "orderUpdates" -> Order_updates { user = user () }
  | "userFills" -> User_fills { user = user () }
  | "allMids" -> All_mids
  | _ -> Json.error "Subscription: unsupported subscription type" json
;;
