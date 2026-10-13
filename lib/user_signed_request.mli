(** The body POSTed to [/exchange] for a {!User_signed_action}:
    [{"action": {"type": "approveAgent", ...}, "nonce": 1700000000000, "signature": {...}}].

    [nonce] must equal the action's own [nonce]; {!create} takes it from the action. There
    is no [vaultAddress]: approvals are signed by the account's own wallet. *)

open! Core

type t =
  { action : User_signed_action.t
  ; nonce : int
  ; signature : Json.t option
  }
[@@deriving sexp, compare, equal, yojson]

val create : ?signature:Json.t -> User_signed_action.t -> t

(** [true] when [body] is an [/exchange] body whose [action.type] is a user-signed type,
    so a server can choose between this decoder and {!Exchange_request}'s. *)
val is_user_signed_body : Json.t -> bool
