open! Core

type t =
  | Subscribe of Subscription.t
  | Unsubscribe of Subscription.t
  | Ping
[@@deriving sexp, compare, equal]

let yojson_of_t : t -> Yojson.Safe.t = function
  | Subscribe s ->
    `Assoc [ "method", `String "subscribe"; "subscription", Subscription.yojson_of_t s ]
  | Unsubscribe s ->
    `Assoc [ "method", `String "unsubscribe"; "subscription", Subscription.yojson_of_t s ]
  | Ping -> `Assoc [ "method", `String "ping" ]
;;

let t_of_yojson json =
  let subscription () = Subscription.t_of_yojson (Json.member_exn json ~key:"subscription") in
  match Json.tag json ~key:"method" with
  | "subscribe" -> Subscribe (subscription ())
  | "unsubscribe" -> Unsubscribe (subscription ())
  | "ping" -> Ping
  | _ -> Json.error "Ws_request: unsupported method" json
;;
