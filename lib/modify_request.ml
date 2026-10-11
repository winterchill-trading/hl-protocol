open! Core

module Target = struct
  type t =
    | Oid of Order_id.t
    | Cloid of Cloid.t
  [@@deriving sexp, compare, equal]

  let yojson_of_t = function
    | Oid oid -> Order_id.yojson_of_t oid
    | Cloid cloid -> Cloid.yojson_of_t cloid
  ;;

  let t_of_yojson (json : Yojson.Safe.t) =
    match json with
    | `String _ -> Cloid (Cloid.t_of_yojson json)
    | _ -> Oid (Order_id.t_of_yojson json)
  ;;
end

type t =
  { oid : Target.t
  ; order : Order_request.t
  }
[@@deriving sexp, compare, equal, yojson]
