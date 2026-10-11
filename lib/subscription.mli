(** Websocket subscription descriptors, tagged by ["type"]:

    - [{"type": "l2Book", "coin": "BTC"}]
    - [{"type": "trades", "coin": "BTC"}]
    - [{"type": "orderUpdates", "user": "0x..."}]
    - [{"type": "userFills", "user": "0x..."}]
    - [{"type": "allMids"}] *)

open! Core

type t =
  | L2_book of { coin : Coin.t }
  | Trades of { coin : Coin.t }
  | Order_updates of { user : Address.t }
  | User_fills of { user : Address.t }
  | All_mids
[@@deriving sexp, compare, equal, hash, yojson]

include Comparable.S with type t := t

(** The ["type"] tag, which is also the name of the data channel. *)
val channel : t -> string
