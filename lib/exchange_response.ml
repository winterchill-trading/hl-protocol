open! Core
open Ppx_yojson_conv_lib.Yojson_conv.Primitives

module Response = struct
  type t =
    | Order of Order_status.t list
    | Cancel of Cancel_status.t list
    | Default
  [@@deriving sexp, compare, equal]

  module Statuses (Status : Codec.S) = struct
    type t = { statuses : Status.t list }
    [@@deriving yojson] [@@yojson.allow_extra_fields]
  end

  module Order_statuses = Statuses (Order_status)
  module Cancel_statuses = Statuses (Cancel_status)

  let yojson_of_t : t -> Yojson.Safe.t = function
    | Order statuses ->
      `Assoc
        [ "type", `String "order"; "data", Order_statuses.yojson_of_t { statuses } ]
    | Cancel statuses ->
      `Assoc
        [ "type", `String "cancel"; "data", Cancel_statuses.yojson_of_t { statuses } ]
    | Default -> `Assoc [ "type", `String "default" ]
  ;;

  let t_of_yojson json =
    match Json.tag json ~key:"type" with
    | "order" ->
      Order (Order_statuses.t_of_yojson (Json.member_exn json ~key:"data")).statuses
    | "cancel" ->
      Cancel (Cancel_statuses.t_of_yojson (Json.member_exn json ~key:"data")).statuses
    | "default" -> Default
    | _ -> Json.error "Exchange_response: unknown response type" json
  ;;
end

type t =
  | Ok of Response.t
  | Err of string
[@@deriving sexp, compare, equal]

let yojson_of_t : t -> Yojson.Safe.t = function
  | Ok response -> `Assoc [ "status", `String "ok"; "response", Response.yojson_of_t response ]
  | Err msg -> `Assoc [ "status", `String "err"; "response", `String msg ]
;;

let t_of_yojson json =
  match Json.tag json ~key:"status", Json.member_exn json ~key:"response" with
  | "ok", response -> Ok (Response.t_of_yojson response)
  | "err", `String msg -> Err msg
  | _ -> Json.error "Exchange_response: unrecognised envelope" json
;;
