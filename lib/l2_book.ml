open! Core
open Ppx_yojson_conv_lib.Yojson_conv.Primitives

module Level = struct
  type t =
    { px : Price.t
    ; sz : Size.t
    ; n : int
    }
  [@@deriving sexp, compare, equal, yojson] [@@yojson.allow_extra_fields]
end

type t =
  { coin : Coin.t
  ; time : int
  ; bids : Level.t list
  ; asks : Level.t list
  }
[@@deriving sexp, compare, equal]

module Wire = struct
  type t =
    { coin : Coin.t
    ; time : int
    ; levels : Level.t list list
    }
  [@@deriving yojson] [@@yojson.allow_extra_fields]
end

let yojson_of_t { coin; time; bids; asks } =
  Wire.yojson_of_t { coin; time; levels = [ bids; asks ] }
;;

let t_of_yojson json =
  let { Wire.coin; time; levels } = Wire.t_of_yojson json in
  match levels with
  | [ bids; asks ] -> { coin; time; bids; asks }
  | _ -> Json.error "L2_book: levels must be [bids, asks]" json
;;

let best_bid t = List.hd t.bids
let best_ask t = List.hd t.asks
