(** Perpetuals metadata returned by the [meta] info request:
    [{"universe": [{"name": "BTC", "szDecimals": 5, "maxLeverage": 50}, ...]}]. A coin's
    asset index is its position in [universe]. *)

open! Core

module Asset_meta : sig
  type t =
    { name : Coin.t
    ; sz_decimals : int
    ; max_leverage : int
    ; only_isolated : bool (** encoded only when [true] *)
    }
  [@@deriving sexp, compare, equal, yojson]
end

type t = { universe : Asset_meta.t list } [@@deriving sexp, compare, equal, yojson]

val asset_of_coin : t -> Coin.t -> Asset.t option
val coin_of_asset : t -> Asset.t -> Coin.t option
val find : t -> Coin.t -> Asset_meta.t option
