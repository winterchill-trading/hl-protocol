open! Core

type t =
  | Success
  | Error of string
[@@deriving sexp, compare, equal]

let yojson_of_t : t -> Yojson.Safe.t = function
  | Success -> `String "success"
  | Error msg -> `Assoc [ "error", `String msg ]
;;

let t_of_yojson (json : Yojson.Safe.t) =
  match json with
  | `String "success" -> Success
  | `Assoc [ ("error", `String msg) ] -> Error msg
  | _ -> Json.error "Cancel_status: unrecognised status" json
;;
