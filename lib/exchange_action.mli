(** The [action] of an exchange request, tagged by its ["type"] field:

    - [{"type": "order", "orders": [...], "grouping": "na"}]
    - [{"type": "cancel", "cancels": [{"a": 0, "o": 123}]}]
    - [{"type": "cancelByCloid", "cancels": [{"asset": 0, "cloid": "0x..."}]}]
    - [{"type": "modify", "oid": 123, "order": {...}}] *)

open! Core

type t =
  | Order of
      { orders : Order_request.t list
      ; grouping : Grouping.t
      }
  | Cancel of { cancels : Cancel_request.t list }
  | Cancel_by_cloid of { cancels : Cancel_by_cloid.t list }
  | Modify of Modify_request.t
[@@deriving sexp, compare, equal, yojson]

(** The value of the ["type"] field. *)
val type_tag : t -> string
