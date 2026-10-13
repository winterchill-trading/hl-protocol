open! Core
open Hl_protocol

let order =
  {|{"a":4,"b":true,"p":"1670.1","s":"0.0147","r":false,"t":{"limit":{"tif":"Ioc"}}}|}
;;

let%expect_test "order action with a builder" =
  Helpers.round_trip
    (module Order_action)
    (sprintf
       {|{"type":"order","orders":[%s],"grouping":"na","builder":{"b":"0x00000000000000000000000000000000000000bb","f":10}}|}
       order);
  [%expect
    {|
    ((orders
      (((asset 4) (is_buy true) (limit_px 1670.1) (sz 0.0147) (reduce_only false)
        (order_type (Limit (tif Ioc))) (cloid ()))))
     (grouping Na)
     (builder
      (((builder 0x00000000000000000000000000000000000000bb) (fee_tenths_bp 10)))))
    {"type":"order","orders":[{"a":4,"b":true,"p":"1670.1","s":"0.0147","r":false,"t":{"limit":{"tif":"Ioc"}}}],"grouping":"na","builder":{"b":"0x00000000000000000000000000000000000000bb","f":10}}
    |}]
;;

let%expect_test "without a builder the encoding equals Exchange_action's" =
  let json =
    Yojson.Safe.from_string
      (sprintf {|{"type":"order","orders":[%s],"grouping":"normalTpsl"}|} order)
  in
  let action = Order_action.t_of_yojson json in
  let via_exchange_action =
    Order_action.to_exchange_action action |> Exchange_action.yojson_of_t
  in
  print_s
    [%message
      ""
        ~builder:(action.builder : Builder_fee.t option)
        ~same_bytes:
          (String.equal
             (Yojson.Safe.to_string (Order_action.yojson_of_t action))
             (Yojson.Safe.to_string via_exchange_action)
           : bool)
        ~back:
          ([%equal: Order_action.t option]
             (Order_action.of_exchange_action (Exchange_action.t_of_yojson json))
             (Some action)
           : bool)];
  [%expect {| ((builder ()) (same_bytes true) (back true)) |}];
  print_s
    [%sexp
      (Or_error.try_with (fun () ->
         Order_action.t_of_yojson
           (Yojson.Safe.from_string {|{"type":"cancel","cancels":[]}|}))
       |> Result.is_error
       : bool)];
  [%expect {| true |}]
;;

let%expect_test "builder order in an envelope decodes as a plain Exchange_request" =
  let action =
    Order_action.create
      ~builder:
        { builder = Address.of_string "0x00000000000000000000000000000000000000bb"
        ; fee_tenths_bp = 10
        }
      [ Order_request.t_of_yojson (Yojson.Safe.from_string order) ]
  in
  let envelope =
    { Exchange_envelope.action = Order_action.yojson_of_t action
    ; nonce = 7
    ; signature = None
    ; vault_address = None
    ; expires_after = Some 99
    }
  in
  let json = Exchange_envelope.yojson_of_t envelope in
  print_endline (Yojson.Safe.to_string json);
  (* A server that only knows [Exchange_request] still accepts it, without the builder. *)
  let plain = Exchange_request.t_of_yojson json in
  print_endline
    (Yojson.Safe.to_string
       (Exchange_envelope.yojson_of_t (Exchange_envelope.of_exchange_request plain)));
  [%expect
    {|
    {"action":{"type":"order","orders":[{"a":4,"b":true,"p":"1670.1","s":"0.0147","r":false,"t":{"limit":{"tif":"Ioc"}}}],"grouping":"na","builder":{"b":"0x00000000000000000000000000000000000000bb","f":10}},"nonce":7,"expiresAfter":99}
    {"action":{"type":"order","orders":[{"a":4,"b":true,"p":"1670.1","s":"0.0147","r":false,"t":{"limit":{"tif":"Ioc"}}}],"grouping":"na"},"nonce":7}
    |}]
;;
