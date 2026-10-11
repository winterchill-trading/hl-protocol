open! Core
open Hl_protocol

let round_trip_request = Helpers.round_trip (module Exchange_request)

let%expect_test "order action" =
  round_trip_request
    {|{"action":{"type":"order","orders":[
        {"a":0,"b":true,"p":"113000.0","s":"0.001","r":false,"t":{"limit":{"tif":"Alo"}},
         "c":"0x00000000000000000000000000000001"},
        {"a":4,"b":false,"p":"3000","s":"1.5","r":true,
         "t":{"trigger":{"isMarket":true,"triggerPx":"2900.5","tpsl":"sl"}}}],
       "grouping":"na"},
      "nonce":1700000000000,
      "signature":{"r":"0xabc","s":"0xdef","v":27},
      "vaultAddress":null}|};
  [%expect
    {|
    ((action
      (Order
       (orders
        (((asset 0) (is_buy true) (limit_px 113000) (sz 0.001)
          (reduce_only false) (order_type (Limit (tif Alo)))
          (cloid (0x00000000000000000000000000000001)))
         ((asset 4) (is_buy false) (limit_px 3000) (sz 1.5) (reduce_only true)
          (order_type (Trigger (is_market true) (trigger_px 2900.5) (tpsl Sl)))
          (cloid ()))))
       (grouping Na)))
     (nonce 1700000000000)
     (signature ("{\"r\":\"0xabc\",\"s\":\"0xdef\",\"v\":27}"))
     (vault_address ()))
    {"action":{"type":"order","orders":[{"a":0,"b":true,"p":"113000","s":"0.001","r":false,"t":{"limit":{"tif":"Alo"}},"c":"0x00000000000000000000000000000001"},{"a":4,"b":false,"p":"3000","s":"1.5","r":true,"t":{"trigger":{"isMarket":true,"triggerPx":"2900.5","tpsl":"sl"}}}],"grouping":"na"},"nonce":1700000000000,"signature":{"r":"0xabc","s":"0xdef","v":27}}
    |}]
;;

let%expect_test "cancel actions" =
  round_trip_request
    {|{"action":{"type":"cancel","cancels":[{"a":0,"o":77738308}]},"nonce":1}|};
  round_trip_request
    {|{"action":{"type":"cancelByCloid","cancels":[{"asset":3,"cloid":"0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"}]},"nonce":2,"vaultAddress":"0xABCDEF0000000000000000000000000000000001"}|};
  [%expect
    {|
    ((action (Cancel (cancels (((asset 0) (oid 77738308)))))) (nonce 1)
     (signature ()) (vault_address ()))
    {"action":{"type":"cancel","cancels":[{"a":0,"o":77738308}]},"nonce":1}
    ((action
      (Cancel_by_cloid
       (cancels (((asset 3) (cloid 0xffffffffffffffffffffffffffffffff))))))
     (nonce 2) (signature ())
     (vault_address (0xabcdef0000000000000000000000000000000001)))
    {"action":{"type":"cancelByCloid","cancels":[{"asset":3,"cloid":"0xffffffffffffffffffffffffffffffff"}]},"nonce":2,"vaultAddress":"0xabcdef0000000000000000000000000000000001"}
    |}]
;;

let%expect_test "modify by oid and by cloid" =
  let order =
    {|{"a":1,"b":true,"p":"25.5","s":"10","r":false,"t":{"limit":{"tif":"Gtc"}}}|}
  in
  round_trip_request
    (sprintf {|{"action":{"type":"modify","oid":123,"order":%s},"nonce":3}|} order);
  round_trip_request
    (sprintf
       {|{"action":{"type":"modify","oid":"0x0000000000000000000000000000002a","order":%s},"nonce":4}|}
       order);
  [%expect
    {|
    ((action
      (Modify
       ((oid (Oid 123))
        (order
         ((asset 1) (is_buy true) (limit_px 25.5) (sz 10) (reduce_only false)
          (order_type (Limit (tif Gtc))) (cloid ()))))))
     (nonce 3) (signature ()) (vault_address ()))
    {"action":{"type":"modify","oid":123,"order":{"a":1,"b":true,"p":"25.5","s":"10","r":false,"t":{"limit":{"tif":"Gtc"}}}},"nonce":3}
    ((action
      (Modify
       ((oid (Cloid 0x0000000000000000000000000000002a))
        (order
         ((asset 1) (is_buy true) (limit_px 25.5) (sz 10) (reduce_only false)
          (order_type (Limit (tif Gtc))) (cloid ()))))))
     (nonce 4) (signature ()) (vault_address ()))
    {"action":{"type":"modify","oid":"0x0000000000000000000000000000002a","order":{"a":1,"b":true,"p":"25.5","s":"10","r":false,"t":{"limit":{"tif":"Gtc"}}}},"nonce":4}
    |}]
;;

let%expect_test "decode errors" =
  let try_decode s =
    match Exchange_action.t_of_yojson (Yojson.Safe.from_string s) with
    | t -> print_s [%sexp (t : Exchange_action.t)]
    | exception Ppx_yojson_conv_lib.Yojson_conv.Of_yojson_error (exn, json) ->
      print_s [%message (exn : exn) ~json:(Yojson.Safe.to_string json)]
  in
  try_decode {|{"type":"twapOrder"}|};
  try_decode {|{"type":"cancel","cancels":[{"a":0,"o":"x"}]}|};
  [%expect {|
    ((exn (Failure "Exchange_action: unsupported action type"))
     (json "{\"type\":\"twapOrder\"}"))
    ((exn (Failure "Order_id: integer expected")) (json "\"x\""))
    |}]
;;
