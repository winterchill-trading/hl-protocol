(* Frames follow the shapes in the Hyperliquid websocket docs ("Subscriptions":
   WsUserEvent, WsFill, WsUserFunding, WsLiquidation, WsNonUserCancel); addresses and
   values are made up. *)

open! Core
open Hl_protocol

let leader = "0x00000000000000000000000000000000000000aa"

let fill =
  {|{"coin":"BTC","px":"113000.0","sz":"0.01","side":"B","time":1760000000000,"startPosition":"0.02","dir":"Open Long","closedPnl":"0.0","hash":"0x00","oid":11,"crossed":true,"fee":"0.5085","tid":21,"feeToken":"USDC","builderFee":"0.113","liquidation":{"liquidatedUser":"0x00000000000000000000000000000000000000cc","markPx":"113000.0","method":"market"}}|}
;;

let decode frame =
  let message = Ws_message.t_of_yojson (Yojson.Safe.from_string frame) in
  match User_event.of_ws_message message with
  | None -> print_s [%message "not a user event" (message : Ws_message.t)]
  | Some event ->
    print_s [%sexp (event : User_event.t)];
    let back = User_event.t_of_yojson (User_event.yojson_of_t event) in
    if not (User_event.equal event back) then print_endline "round trip mismatch"
;;

let%expect_test "userEvents frames" =
  decode (sprintf {|{"channel":"user","data":{"fills":[%s]}}|} fill);
  decode
    {|{"channel":"user","data":{"funding":{"time":1760000000000,"coin":"ETH","usdc":"-0.0412","szi":"-1.5","fundingRate":"0.0000125"}}}|};
  decode
    (sprintf
       {|{"channel":"user","data":{"liquidation":{"lid":7,"liquidator":"0x00000000000000000000000000000000000000dd","liquidated_user":"%s","liquidated_ntl_pos":"1130.5","liquidated_account_value":"12.25"}}}|}
       leader);
  decode {|{"channel":"user","data":{"nonUserCancel":[{"coin":"SOL","oid":99}]}}|};
  decode {|{"channel":"user","data":{"somethingNew":1}}|};
  decode {|{"channel":"pong"}|};
  [%expect
    {|
    (Fills
     (((coin BTC) (px 113000) (sz 0.01) (side Buy) (time 1760000000000)
       (start_position 0.02) (dir "Open Long") (closed_pnl 0) (hash 0x00)
       (oid 11) (crossed true) (fee 0.5085) (tid 21) (fee_token (USDC))
       (cloid ()))))
    (Funding
     ((time 1760000000000) (coin ETH) (usdc -0.0412) (szi -1.5)
      (funding_rate 0.0000125)))
    (Liquidation
     ((lid 7) (liquidator 0x00000000000000000000000000000000000000dd)
      (liquidated_user 0x00000000000000000000000000000000000000aa)
      (liquidated_ntl_pos 1130.5) (liquidated_account_value 12.25)))
    (Non_user_cancel (((coin SOL) (oid 99))))
    (Other "{\"somethingNew\":1}")
    ("not a user event" (message Pong))
    |}]
;;

let%expect_test "userEvents subscription and its echo" =
  let user = Address.of_string leader in
  let request = User_event.ws_request `Subscribe ~user in
  print_endline (Yojson.Safe.to_string request);
  print_s
    [%sexp
      (Ws_message.t_of_yojson
         (`Assoc [ "channel", `String "subscriptionResponse"; "data", request ])
       : Ws_message.t)];
  [%expect
    {|
    {"method":"subscribe","subscription":{"type":"userEvents","user":"0x00000000000000000000000000000000000000aa"}}
    (Unknown (channel subscriptionResponse)
     (data
      "{\"method\":\"subscribe\",\"subscription\":{\"type\":\"userEvents\",\"user\":\"0x00000000000000000000000000000000000000aa\"}}"))
    |}]
;;

let%expect_test "another address's fills and order updates" =
  Helpers.round_trip
    (module Ws_message)
    (sprintf {|{"channel":"userFills","data":{"user":"%s","fills":[%s]}}|} leader fill);
  Helpers.round_trip
    (module Ws_message)
    {|{"channel":"orderUpdates","data":[{"order":{"coin":"BTC","side":"A","limitPx":"114000.0","sz":"0.0","oid":11,"timestamp":1760000000000,"origSz":"0.01"},"status":"filled","statusTimestamp":1760000000500}]}|};
  [%expect
    {|
    (User_fills
     ((is_snapshot false) (user 0x00000000000000000000000000000000000000aa)
      (fills
       (((coin BTC) (px 113000) (sz 0.01) (side Buy) (time 1760000000000)
         (start_position 0.02) (dir "Open Long") (closed_pnl 0) (hash 0x00)
         (oid 11) (crossed true) (fee 0.5085) (tid 21) (fee_token (USDC))
         (cloid ()))))))
    {"channel":"userFills","data":{"user":"0x00000000000000000000000000000000000000aa","fills":[{"coin":"BTC","px":"113000","sz":"0.01","side":"B","time":1760000000000,"startPosition":"0.02","dir":"Open Long","closedPnl":"0","hash":"0x00","oid":11,"crossed":true,"fee":"0.5085","tid":21,"feeToken":"USDC"}]}}
    (Order_updates
     (((order
        ((coin BTC) (side Sell) (limit_px 114000) (sz 0) (oid 11)
         (timestamp 1760000000000) (orig_sz (0.01)) (cloid ())))
       (status Filled) (status_timestamp 1760000000500))))
    {"channel":"orderUpdates","data":[{"order":{"coin":"BTC","side":"A","limitPx":"114000","sz":"0","oid":11,"timestamp":1760000000000,"origSz":"0.01"},"status":"filled","statusTimestamp":1760000000500}]}
    |}]
;;

let%expect_test "userFillsByTime request" =
  Helpers.round_trip
    (module User_fills_by_time)
    (sprintf {|{"type":"userFillsByTime","user":"%s","startTime":1760000000000}|} leader);
  Helpers.round_trip
    (module User_fills_by_time)
    (sprintf
       {|{"type":"userFillsByTime","user":"%s","startTime":1,"endTime":2,"aggregateByTime":true}|}
       leader);
  print_s
    [%sexp
      (User_fills_by_time.response_of_yojson
         (Yojson.Safe.from_string (sprintf "[%s]" fill))
       |> List.length
       : int)];
  [%expect
    {|
    ((user 0x00000000000000000000000000000000000000aa) (start_time 1760000000000)
     (end_time ()) (aggregate_by_time ()))
    {"type":"userFillsByTime","user":"0x00000000000000000000000000000000000000aa","startTime":1760000000000}
    ((user 0x00000000000000000000000000000000000000aa) (start_time 1)
     (end_time (2)) (aggregate_by_time (true)))
    {"type":"userFillsByTime","user":"0x00000000000000000000000000000000000000aa","startTime":1,"endTime":2,"aggregateByTime":true}
    1
    |}]
;;
