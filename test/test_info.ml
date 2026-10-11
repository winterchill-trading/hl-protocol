open! Core
open Hl_protocol

let%expect_test "info requests" =
  List.iter
    [ {|{"type":"l2Book","coin":"BTC"}|}
    ; {|{"type":"l2Book","coin":"ETH","nSigFigs":5,"mantissa":null}|}
    ; {|{"type":"allMids"}|}
    ; {|{"type":"openOrders","user":"0x0000000000000000000000000000000000000001"}|}
    ; {|{"type":"userFills","user":"0x0000000000000000000000000000000000000001"}|}
    ; {|{"type":"clearinghouseState","user":"0x0000000000000000000000000000000000000001"}|}
    ; {|{"type":"meta"}|}
    ]
    ~f:(Helpers.round_trip (module Info_request));
  [%expect {|
    (L2_book (coin BTC) (n_sig_figs ()) (mantissa ()))
    {"type":"l2Book","coin":"BTC"}
    (L2_book (coin ETH) (n_sig_figs (5)) (mantissa ()))
    {"type":"l2Book","coin":"ETH","nSigFigs":5}
    All_mids
    {"type":"allMids"}
    (Open_orders (user 0x0000000000000000000000000000000000000001))
    {"type":"openOrders","user":"0x0000000000000000000000000000000000000001"}
    (User_fills (user 0x0000000000000000000000000000000000000001))
    {"type":"userFills","user":"0x0000000000000000000000000000000000000001"}
    (Clearinghouse_state (user 0x0000000000000000000000000000000000000001))
    {"type":"clearinghouseState","user":"0x0000000000000000000000000000000000000001"}
    Meta
    {"type":"meta"}
    |}]
;;

let round_trip_response ~request s =
  let request = Info_request.t_of_yojson (Yojson.Safe.from_string request) in
  let decoded = Info_response.of_yojson (Yojson.Safe.from_string s) ~request in
  print_s [%sexp (decoded : Info_response.t)];
  let encoded = Yojson.Safe.to_string (Info_response.yojson_of_t decoded) in
  print_endline encoded;
  let decoded' = Info_response.of_yojson (Yojson.Safe.from_string encoded) ~request in
  if not (Info_response.equal decoded decoded') then print_endline "round trip mismatch"
;;

let%expect_test "l2Book" =
  round_trip_response
    ~request:{|{"type":"l2Book","coin":"BTC"}|}
    {|{"coin":"BTC","time":1754450974231,"levels":[
        [{"px":"113377.0","sz":"7.6699","n":17},{"px":"113376.0","sz":"0.0001","n":1}],
        [{"px":"113378.0","sz":"1.2","n":3}]]}|};
  [%expect {|
    (L2_book
     ((coin BTC) (time 1754450974231)
      (bids (((px 113377) (sz 7.6699) (n 17)) ((px 113376) (sz 0.0001) (n 1))))
      (asks (((px 113378) (sz 1.2) (n 3))))))
    {"coin":"BTC","time":1754450974231,"levels":[[{"px":"113377","sz":"7.6699","n":17},{"px":"113376","sz":"0.0001","n":1}],[{"px":"113378","sz":"1.2","n":3}]]}
    |}]
;;

let%expect_test "allMids" =
  round_trip_response
    ~request:{|{"type":"allMids"}|}
    {|{"BTC":"113000.5","ETH":"3000.05","@107":"41.2"}|};
  [%expect {|
    (All_mids ((BTC 113000.5) (ETH 3000.05) (@107 41.2)))
    {"BTC":"113000.5","ETH":"3000.05","@107":"41.2"}
    |}]
;;

let%expect_test "openOrders" =
  round_trip_response
    ~request:{|{"type":"openOrders","user":"0x0000000000000000000000000000000000000001"}|}
    {|[{"coin":"BTC","limitPx":"29792.0","oid":91490942,"side":"A","sz":"0.0","timestamp":1681247412573},
       {"coin":"ETH","limitPx":"2000","oid":91490943,"side":"B","sz":"1","timestamp":1681247412574,
        "origSz":"2","cloid":"0x00000000000000000000000000000009","reduceOnly":false}]|};
  [%expect {|
    (Open_orders
     (((coin BTC) (side Sell) (limit_px 29792) (sz 0) (oid 91490942)
       (timestamp 1681247412573) (orig_sz ()) (cloid ()))
      ((coin ETH) (side Buy) (limit_px 2000) (sz 1) (oid 91490943)
       (timestamp 1681247412574) (orig_sz (2))
       (cloid (0x00000000000000000000000000000009)))))
    [{"coin":"BTC","side":"A","limitPx":"29792","sz":"0","oid":91490942,"timestamp":1681247412573},{"coin":"ETH","side":"B","limitPx":"2000","sz":"1","oid":91490943,"timestamp":1681247412574,"origSz":"2","cloid":"0x00000000000000000000000000000009"}]
    |}]
;;

let%expect_test "userFills" =
  round_trip_response
    ~request:{|{"type":"userFills","user":"0x0000000000000000000000000000000000000001"}|}
    {|[{"closedPnl":"0.0","coin":"AVAX","crossed":false,"dir":"Open Long",
        "hash":"0xa166e3fa63c25663024b03f2e0da011a00307e4017465df020210d3d432e7cb8",
        "oid":90542681,"px":"18.435","side":"B","startPosition":"26.86","sz":"93.53",
        "time":1681222254710,"fee":"0.01","feeToken":"USDC","tid":118906512037719}]|};
  [%expect {|
    (User_fills
     (((coin AVAX) (px 18.435) (sz 93.53) (side Buy) (time 1681222254710)
       (start_position 26.86) (dir "Open Long") (closed_pnl 0)
       (hash 0xa166e3fa63c25663024b03f2e0da011a00307e4017465df020210d3d432e7cb8)
       (oid 90542681) (crossed false) (fee 0.01) (tid 118906512037719)
       (fee_token (USDC)) (cloid ()))))
    [{"coin":"AVAX","px":"18.435","sz":"93.53","side":"B","time":1681222254710,"startPosition":"26.86","dir":"Open Long","closedPnl":"0","hash":"0xa166e3fa63c25663024b03f2e0da011a00307e4017465df020210d3d432e7cb8","oid":90542681,"crossed":false,"fee":"0.01","tid":118906512037719,"feeToken":"USDC"}]
    |}]
;;

let%expect_test "clearinghouseState" =
  round_trip_response
    ~request:
      {|{"type":"clearinghouseState","user":"0x0000000000000000000000000000000000000001"}|}
    {|{"assetPositions":[
        {"position":{"coin":"ETH","cumFunding":{"allTime":"514.08","sinceChange":"0.0","sinceOpen":"0.0"},
          "entryPx":"2986.3","leverage":{"rawUsd":"-95.059824","type":"isolated","value":20},
          "liquidationPx":"2866.26936529","marginUsed":"4.967826","maxLeverage":50,
          "positionValue":"100.02765","returnOnEquity":"-0.0026789","szi":"0.0335",
          "unrealizedPnl":"-0.0134"},"type":"oneWay"},
        {"position":{"coin":"BTC","entryPx":"60000","leverage":{"type":"cross","value":10},
          "liquidationPx":null,"marginUsed":"600","maxLeverage":50,
          "positionValue":"6000","szi":"-0.1","unrealizedPnl":"0"},"type":"oneWay"}],
      "crossMaintenanceMarginUsed":"0.0",
      "crossMarginSummary":{"accountValue":"13104.514502","totalMarginUsed":"0.0","totalNtlPos":"0.0","totalRawUsd":"13104.514502"},
      "marginSummary":{"accountValue":"13109.482328","totalMarginUsed":"4.967826","totalNtlPos":"100.02765","totalRawUsd":"13009.454678"},
      "time":1708622398623,"withdrawable":"13104.514502"}|};
  [%expect {|
    (Clearinghouse_state
     ((positions
       (((coin ETH) (szi 0.0335) (entry_px (2986.3)) (position_value 100.02765)
         (unrealized_pnl -0.0134) (liquidation_px (2866.26936529))
         (leverage (Isolated (value 20) (raw_usd -95.059824)))
         (margin_used 4.967826) (max_leverage 50))
        ((coin BTC) (szi -0.1) (entry_px (60000)) (position_value 6000)
         (unrealized_pnl 0) (liquidation_px ()) (leverage (Cross (value 10)))
         (margin_used 600) (max_leverage 50))))
      (margin_summary
       ((account_value 13109.482328) (total_ntl_pos 100.02765)
        (total_raw_usd 13009.454678) (total_margin_used 4.967826)))
      (cross_margin_summary
       ((account_value 13104.514502) (total_ntl_pos 0)
        (total_raw_usd 13104.514502) (total_margin_used 0)))
      (cross_maintenance_margin_used 0) (withdrawable 13104.514502)
      (time 1708622398623)))
    {"assetPositions":[{"type":"oneWay","position":{"coin":"ETH","szi":"0.0335","entryPx":"2986.3","positionValue":"100.02765","unrealizedPnl":"-0.0134","liquidationPx":"2866.26936529","leverage":{"type":"isolated","value":20,"rawUsd":"-95.059824"},"marginUsed":"4.967826","maxLeverage":50}},{"type":"oneWay","position":{"coin":"BTC","szi":"-0.1","entryPx":"60000","positionValue":"6000","unrealizedPnl":"0","liquidationPx":null,"leverage":{"type":"cross","value":10},"marginUsed":"600","maxLeverage":50}}],"marginSummary":{"accountValue":"13109.482328","totalNtlPos":"100.02765","totalRawUsd":"13009.454678","totalMarginUsed":"4.967826"},"crossMarginSummary":{"accountValue":"13104.514502","totalNtlPos":"0","totalRawUsd":"13104.514502","totalMarginUsed":"0"},"crossMaintenanceMarginUsed":"0","withdrawable":"13104.514502","time":1708622398623}
    |}]
;;

let%expect_test "meta and asset lookup" =
  let json =
    {|{"universe":[{"name":"BTC","szDecimals":5,"maxLeverage":50},
                   {"name":"ETH","szDecimals":4,"maxLeverage":50,"onlyIsolated":false},
                   {"name":"HYPE","szDecimals":2,"maxLeverage":10,"onlyIsolated":true}]}|}
  in
  round_trip_response ~request:{|{"type":"meta"}|} json;
  let meta = Meta.t_of_yojson (Yojson.Safe.from_string json) in
  print_s
    [%sexp
      (Meta.asset_of_coin meta (Coin.of_string "ETH") : Asset.t option)
      , (Meta.asset_of_coin meta (Coin.of_string "DOGE") : Asset.t option)
      , (Meta.coin_of_asset meta (Asset.of_int 2) : Coin.t option)];
  [%expect {|
    (Meta
     ((universe
       (((name BTC) (sz_decimals 5) (max_leverage 50) (only_isolated false))
        ((name ETH) (sz_decimals 4) (max_leverage 50) (only_isolated false))
        ((name HYPE) (sz_decimals 2) (max_leverage 10) (only_isolated true))))))
    {"universe":[{"name":"BTC","szDecimals":5,"maxLeverage":50},{"name":"ETH","szDecimals":4,"maxLeverage":50},{"name":"HYPE","szDecimals":2,"maxLeverage":10,"onlyIsolated":true}]}
    ((1) () (HYPE))
    |}]
;;
