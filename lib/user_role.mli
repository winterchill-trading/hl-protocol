(** The [userRole] info request (Hyperliquid info endpoint docs, "Query a user's role"):
    [{"type": "userRole", "user": "0x..."}].

    The response says what kind of account an address is:

    - [{"role": "user"}] an ordinary account
    - [{"role": "agent", "data": {"user": "0x..."}}] an API wallet acting for [user]
    - [{"role": "vault"}] a vault (e.g. HLP)
    - [{"role": "subAccount", "data": {"master": "0x..."}}] a sub-account of [master]
    - [{"role": "missing"}] an address the exchange has never seen

    Not an {!Info_request} constructor, since dependents match that type exhaustively. *)

open! Core

type t = { user : Address.t } [@@deriving sexp, compare, equal, yojson]

module Role : sig
  type t =
    | User
    | Agent of { user : Address.t }
    | Vault
    | Sub_account of { master : Address.t }
    | Missing
    | Other of string (** a role this library does not know yet *)
  [@@deriving sexp, compare, equal, yojson]

  (** The wire name: ["user"], ["agent"], ["vault"], ["subAccount"], ["missing"], or the
      [Other] string. *)
  val to_string : t -> string
end

type response = Role.t [@@deriving sexp_of, yojson]
