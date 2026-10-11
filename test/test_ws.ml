open! Core
open Hl_protocol

let%expect_test "client requests" =
  List.iter
    [ {|{"method":"subscribe","subscription":{"type":"l2Book","coin":"BTC"}}|}
    ; {|{"method":"subscribe","subscription":{"type":"trades","coin":"ETH"}}|}
    ; {|{"method":"subscribe","subscription":{"type":"orderUpdates","user":"0x0000000000000000000000000000000000000001"}}|}
    ; {|{"method":"subscribe","subscription":{"type":"userFills","user":"0x0000000000000000000000000000000000000001"}}|}
    ; {|{"method":"unsubscribe","subscription":{"type":"allMids"}}|}
    ; {|{"method":"ping"}|}
    ]
    ~f:(Helpers.round_trip (module Ws_request));
  [%expect {|
    (Subscribe (L2_book (coin BTC)))
    {"method":"subscribe","subscription":{"type":"l2Book","coin":"BTC"}}
    (Subscribe (Trades (coin ETH)))
    {"method":"subscribe","subscription":{"type":"trades","coin":"ETH"}}
    (Subscribe (Order_updates (user 0x0000000000000000000000000000000000000001)))
    {"method":"subscribe","subscription":{"type":"orderUpdates","user":"0x0000000000000000000000000000000000000001"}}
    (Subscribe (User_fills (user 0x0000000000000000000000000000000000000001)))
    {"method":"subscribe","subscription":{"type":"userFills","user":"0x0000000000000000000000000000000000000001"}}
    (Unsubscribe All_mids)
    {"method":"unsubscribe","subscription":{"type":"allMids"}}
    Ping
    {"method":"ping"}
    |}]
;;

let round_trip = Helpers.round_trip (module Ws_message)

let%expect_test "subscriptionResponse, pong, error, unknown" =
  round_trip
    {|{"channel":"subscriptionResponse","data":{"method":"subscribe","subscription":{"type":"trades","coin":"SOL"}}}|};
  round_trip {|{"channel":"pong"}|};
  round_trip {|{"channel":"error","data":"Invalid subscription"}|};
  round_trip {|{"channel":"candle","data":{"t":1}}|};
  [%expect {|
    (Subscription_response (Subscribe (Trades (coin SOL))))
    {"channel":"subscriptionResponse","data":{"method":"subscribe","subscription":{"type":"trades","coin":"SOL"}}}
    Pong
    {"channel":"pong"}
    (Error "Invalid subscription")
    {"channel":"error","data":"Invalid subscription"}
    (Unknown (channel candle) (data "{\"t\":1}"))
    {"channel":"candle","data":{"t":1}}
    |}]
;;

let%expect_test "l2Book" =
  round_trip
    {|{"channel":"l2Book","data":{"coin":"BTC","time":1700000000000,"levels":[[{"px":"100","sz":"1","n":1}],[{"px":"101","sz":"2","n":2}]]}}|};
  [%expect {|
    (L2_book
     ((coin BTC) (time 1700000000000) (bids (((px 100) (sz 1) (n 1))))
      (asks (((px 101) (sz 2) (n 2))))))
    {"channel":"l2Book","data":{"coin":"BTC","time":1700000000000,"levels":[[{"px":"100","sz":"1","n":1}],[{"px":"101","sz":"2","n":2}]]}}
    |}]
;;

let%expect_test "trades" =
  round_trip
    {|{"channel":"trades","data":[{"coin":"BTC","side":"A","px":"113000.5","sz":"0.01",
       "hash":"0x0000000000000000000000000000000000000000000000000000000000000000",
       "time":1700000000000,"tid":42,
       "users":["0x0000000000000000000000000000000000000001","0x0000000000000000000000000000000000000002"]}]}|};
  [%expect {|
    (Trades
     (((coin BTC) (side Sell) (px 113000.5) (sz 0.01)
       (hash 0x0000000000000000000000000000000000000000000000000000000000000000)
       (time 1700000000000) (tid 42)
       (users
        (0x0000000000000000000000000000000000000001
         0x0000000000000000000000000000000000000002)))))
    {"channel":"trades","data":[{"coin":"BTC","side":"A","px":"113000.5","sz":"0.01","hash":"0x0000000000000000000000000000000000000000000000000000000000000000","time":1700000000000,"tid":42,"users":["0x0000000000000000000000000000000000000001","0x0000000000000000000000000000000000000002"]}]}
    |}]
;;

let%expect_test "orderUpdates" =
  round_trip
    {|{"channel":"orderUpdates","data":[{"order":{"coin":"ETH","side":"B","limitPx":"3000","sz":"0.5",
       "oid":7,"timestamp":1700000000000,"origSz":"1"},"status":"open","statusTimestamp":1700000000001},
      {"order":{"coin":"ETH","side":"B","limitPx":"3000","sz":"0","oid":8,"timestamp":1700000000000,"origSz":"1"},
       "status":"perpMaxPositionRejected","statusTimestamp":1700000000002}]}|};
  [%expect {|
    (Order_updates
     (((order
        ((coin ETH) (side Buy) (limit_px 3000) (sz 0.5) (oid 7)
         (timestamp 1700000000000) (orig_sz (1)) (cloid ())))
       (status Open) (status_timestamp 1700000000001))
      ((order
        ((coin ETH) (side Buy) (limit_px 3000) (sz 0) (oid 8)
         (timestamp 1700000000000) (orig_sz (1)) (cloid ())))
       (status (Other perpMaxPositionRejected)) (status_timestamp 1700000000002))))
    {"channel":"orderUpdates","data":[{"order":{"coin":"ETH","side":"B","limitPx":"3000","sz":"0.5","oid":7,"timestamp":1700000000000,"origSz":"1"},"status":"open","statusTimestamp":1700000000001},{"order":{"coin":"ETH","side":"B","limitPx":"3000","sz":"0","oid":8,"timestamp":1700000000000,"origSz":"1"},"status":"perpMaxPositionRejected","statusTimestamp":1700000000002}]}
    |}]
;;

let%expect_test "userFills and allMids" =
  round_trip
    {|{"channel":"userFills","data":{"isSnapshot":true,"user":"0x0000000000000000000000000000000000000001","fills":[
       {"coin":"BTC","px":"100","sz":"1","side":"A","time":1,"startPosition":"0","dir":"Open Short",
        "closedPnl":"0","hash":"0x00","oid":1,"crossed":true,"fee":"0.045","tid":2}]}}|};
  round_trip
    {|{"channel":"userFills","data":{"user":"0x0000000000000000000000000000000000000001","fills":[]}}|};
  round_trip {|{"channel":"allMids","data":{"mids":{"BTC":"100.5","ETH":"3000"}}}|};
  [%expect {|
    (User_fills
     ((is_snapshot true) (user 0x0000000000000000000000000000000000000001)
      (fills
       (((coin BTC) (px 100) (sz 1) (side Sell) (time 1) (start_position 0)
         (dir "Open Short") (closed_pnl 0) (hash 0x00) (oid 1) (crossed true)
         (fee 0.045) (tid 2) (fee_token ()) (cloid ()))))))
    {"channel":"userFills","data":{"isSnapshot":true,"user":"0x0000000000000000000000000000000000000001","fills":[{"coin":"BTC","px":"100","sz":"1","side":"A","time":1,"startPosition":"0","dir":"Open Short","closedPnl":"0","hash":"0x00","oid":1,"crossed":true,"fee":"0.045","tid":2}]}}
    (User_fills
     ((is_snapshot false) (user 0x0000000000000000000000000000000000000001)
      (fills ())))
    {"channel":"userFills","data":{"user":"0x0000000000000000000000000000000000000001","fills":[]}}
    (All_mids ((BTC 100.5) (ETH 3000)))
    {"channel":"allMids","data":{"mids":{"BTC":"100.5","ETH":"3000"}}}
    |}]
;;
