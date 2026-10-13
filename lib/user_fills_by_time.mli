(** The [userFillsByTime] info request (Hyperliquid info endpoint docs, "Retrieve a user's
    fills by time"):
    [{"type": "userFillsByTime", "user": "0x...", "startTime": ms, "endTime": ms, "aggregateByTime": false}];
    [endTime] (default now) and [aggregateByTime] are optional, both bounds inclusive. The
    response is a list of {!User_fill.t}.

    "Returns at most 2000 fills per response and only the 10000 most recent fills are
    available"; page by passing the last returned [time] as the next [startTime].

    Not an {!Info_request} constructor, since dependents match that type exhaustively. *)

open! Core

type t =
  { user : Address.t
  ; start_time : int
  ; end_time : int option
  ; aggregate_by_time : bool option
  }
[@@deriving sexp, compare, equal, yojson]

(** The documented page size. *)
val max_fills_per_response : int

type response = User_fill.t list [@@deriving sexp_of, yojson]
