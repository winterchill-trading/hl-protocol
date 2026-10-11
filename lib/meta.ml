open! Core
open Ppx_yojson_conv_lib.Yojson_conv.Primitives

module Asset_meta = struct
  type t =
    { name : Coin.t
    ; sz_decimals : int [@key "szDecimals"]
    ; max_leverage : int [@key "maxLeverage"]
    ; only_isolated : bool [@key "onlyIsolated"] [@default false] [@yojson_drop_if not]
    }
  [@@deriving sexp, compare, equal, yojson] [@@yojson.allow_extra_fields]
end

type t = { universe : Asset_meta.t list }
[@@deriving sexp, compare, equal, yojson] [@@yojson.allow_extra_fields]

let asset_of_coin t coin =
  List.findi t.universe ~f:(fun _ (m : Asset_meta.t) -> Coin.equal m.name coin)
  |> Option.map ~f:(fun (i, _) -> Asset.of_int i)
;;

let coin_of_asset t asset =
  List.nth t.universe (Asset.to_int asset) |> Option.map ~f:(fun (m : Asset_meta.t) -> m.name)
;;

let find t coin = List.find t.universe ~f:(fun (m : Asset_meta.t) -> Coin.equal m.name coin)
