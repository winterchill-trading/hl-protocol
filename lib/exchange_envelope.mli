(** An [/exchange] body around an action given as raw JSON:
    [{"action": {...}, "nonce": n, "signature": {...}, "vaultAddress": "0x...", "expiresAfter": ms}].

    Same layout as {!Exchange_request}, for actions that type does not model, such as an
    {!Order_action} with a [builder]. [vaultAddress] and [expiresAfter] are dropped when
    [None]. *)

open! Core

type t =
  { action : Json.t
  ; nonce : int
  ; signature : Json.t option
  ; vault_address : Address.t option
  ; expires_after : int option
  }
[@@deriving sexp, compare, equal, yojson]

val of_exchange_request : Exchange_request.t -> t
