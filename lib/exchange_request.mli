(** The body POSTed to [/exchange]:
    [{"action": {...}, "nonce": 1700000000000, "signature": {...}, "vaultAddress": null}].

    The signature is carried as opaque JSON and is neither produced nor checked here.
    [signature] and [vaultAddress] may be absent or [null] on input; [None] is encoded as
    an absent field. *)

open! Core

type t =
  { action : Exchange_action.t
  ; nonce : int
  ; signature : Json.t option
  ; vault_address : Address.t option
  }
[@@deriving sexp, compare, equal, yojson]
