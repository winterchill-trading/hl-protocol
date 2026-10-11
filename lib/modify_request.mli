(** Replace a resting order. Wire form: [{"oid": oid | "0x...cloid", "order": ...}]. *)

open! Core

module Target : sig
  (** The order being modified: an exchange id (JSON integer) or a client id
      (JSON string). *)
  type t =
    | Oid of Order_id.t
    | Cloid of Cloid.t
  [@@deriving sexp, compare, equal, yojson]
end

type t =
  { oid : Target.t
  ; order : Order_request.t
  }
[@@deriving sexp, compare, equal, yojson]
