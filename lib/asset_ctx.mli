(** The [activeAssetCtx] websocket channel: funding, mark and oracle prices and daily
    volume of one asset.

    {v
{"channel": "activeAssetCtx",
 "data": {"coin": "BTC",
          "ctx": {"funding": "0.0000125", "openInterest": "25000.1",
                  "prevDayPx": "112000.0", "dayNtlVlm": "1234567890.0",
                  "premium": "0.0001", "oraclePx": "113010.0", "markPx": "113020.0",
                  "midPx": "113015.5", "impactPxs": ["113015.0", "113016.0"],
                  "dayBaseVlm": "11000.0"}}}
    v}

    Spot contexts ([coin] ["@107"]) carry no [funding], [openInterest], [premium],
    [oraclePx] or [impactPxs], and add [circulatingSupply], which is ignored.

    Named [Asset_ctx] so that it does not shadow a consumer's own [Active_asset_ctx] under
    [open Hl_protocol]. {!Subscription} and {!Ws_message} have no constructor for this
    channel yet (adding one would break exhaustive matches downstream). Requests are built with {!Request} and
    messages arrive as [Ws_message.Unknown]; {!of_ws_message} and {!to_ws_message}
    convert. *)

open! Core

module Ctx : sig
  type t =
    { funding : float option
    (** hourly funding rate; perps only. Rates are encoded in plain decimal notation
        (["0.0000125"]) with up to 12 decimals. *)
    ; open_interest : Size.t option
    ; prev_day_px : Price.t
    ; day_ntl_vlm : Usd.t
    ; premium : float option
    ; oracle_px : Price.t option
    ; mark_px : Price.t
    ; mid_px : Price.t option (** [null] when the book is one-sided *)
    ; impact_pxs : (Price.t * Price.t) option (** [[bid, ask]]; absent when one-sided *)
    ; day_base_vlm : Size.t option
    }
  [@@deriving sexp, compare, equal, yojson]
end

type t =
  { coin : Coin.t
  ; ctx : Ctx.t
  }
[@@deriving sexp, compare, equal, yojson]

(** ["activeAssetCtx"], the subscription type and the channel name. *)
val channel : string

(** The whole message, [{"channel": "activeAssetCtx", "data": ...}], as
    [Ws_message.Unknown]. *)
val to_ws_message : t -> Ws_message.t

(** [None] for messages of other channels, [Some (Error _)] when the [data] does not
    decode. *)
val of_ws_message : Ws_message.t -> t Or_error.t option

(** [{"method": "subscribe" | "unsubscribe", "subscription": {"type": "activeAssetCtx", "coin": C}}]. *)
module Request : sig
  type t =
    { subscribe : bool (** [false] for [unsubscribe] *)
    ; coin : Coin.t
    }
  [@@deriving sexp, compare, equal, yojson]

  (** [None] for anything other than an [activeAssetCtx] (un)subscription. *)
  val of_yojson_opt : Yojson.Safe.t -> t option

  (** The [subscriptionResponse] echo the server sends, as [Ws_message.Unknown]. *)
  val response : t -> Ws_message.t
end
