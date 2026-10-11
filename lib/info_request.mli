(** Body POSTed to [/info], tagged by ["type"]:

    - [{"type": "l2Book", "coin": "BTC", "nSigFigs": 5, "mantissa": 2}] ([nSigFigs] and
      [mantissa] optional)
    - [{"type": "allMids"}]
    - [{"type": "openOrders", "user": "0x..."}]
    - [{"type": "userFills", "user": "0x..."}]
    - [{"type": "clearinghouseState", "user": "0x..."}]
    - [{"type": "meta"}] *)

open! Core

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
[@@deriving sexp, compare, equal, yojson]

val type_tag : t -> string
