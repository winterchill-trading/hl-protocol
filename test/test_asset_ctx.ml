open! Core
open Hl_protocol

let show frame =
  let message = Ws_message.t_of_yojson (Yojson.Safe.from_string frame) in
  match Asset_ctx.of_ws_message message with
  | None -> print_s [%message "not activeAssetCtx" (message : Ws_message.t)]
  (* Decoder errors embed the source path, which differs between build layouts. *)
  | Some (Error _) -> print_endline "undecodable"
  | Some (Ok ctx) ->
    print_s (Asset_ctx.sexp_of_t ctx);
    let encoded =
      Yojson.Safe.to_string (Ws_message.yojson_of_t (Asset_ctx.to_ws_message ctx))
    in
    print_endline encoded;
    (match
       Asset_ctx.of_ws_message (Ws_message.t_of_yojson (Yojson.Safe.from_string encoded))
     with
     | Some (Ok ctx') when Asset_ctx.equal ctx ctx' -> ()
     | _ -> print_endline "round trip mismatch")
;;

let%expect_test "perp context (hl-client sample)" =
  show
    {|{"channel":"activeAssetCtx","data":{"coin":"BTC","ctx":{"funding":"0.0000125","openInterest":"25000.1","prevDayPx":"112000.0","dayNtlVlm":"1234567890.0","premium":"0.0001","oraclePx":"113010.0","markPx":"113020.0","midPx":"113015.5","impactPxs":["113015.0","113016.0"],"dayBaseVlm":"11000.0"}}}|};
  [%expect
    {|
    ((coin BTC)
     (ctx
      ((funding (1.25E-05)) (open_interest (25000.1)) (prev_day_px 112000)
       (day_ntl_vlm 1234567890) (premium (0.0001)) (oracle_px (113010))
       (mark_px 113020) (mid_px (113015.5)) (impact_pxs ((113015 113016)))
       (day_base_vlm (11000)))))
    {"channel":"activeAssetCtx","data":{"coin":"BTC","ctx":{"funding":"0.0000125","openInterest":"25000.1","prevDayPx":"112000","dayNtlVlm":"1234567890","premium":"0.0001","oraclePx":"113010","markPx":"113020","midPx":"113015.5","impactPxs":["113015","113016"],"dayBaseVlm":"11000"}}}
    |}]
;;

let%expect_test "simulator shapes: one-sided book, negative premium" =
  show
    {|{"channel":"activeAssetCtx","data":{"coin":"BTC","ctx":{"funding":"0.0000125","openInterest":"0.001","prevDayPx":"100000","dayNtlVlm":"100","premium":"0.0","oraclePx":"100000","markPx":"100000","midPx":null,"dayBaseVlm":"0.001"}}}|};
  show
    {|{"channel":"activeAssetCtx","data":{"coin":"BTC","ctx":{"funding":"0.0000125","openInterest":"0.05","prevDayPx":"100000","dayNtlVlm":"1000","premium":"-0.005","oraclePx":"100000","markPx":"100000","midPx":"99500","impactPxs":["99000","100000"],"dayBaseVlm":"0.01"}}}|};
  [%expect
    {|
    ((coin BTC)
     (ctx
      ((funding (1.25E-05)) (open_interest (0.001)) (prev_day_px 100000)
       (day_ntl_vlm 100) (premium (0)) (oracle_px (100000)) (mark_px 100000)
       (mid_px ()) (impact_pxs ()) (day_base_vlm (0.001)))))
    {"channel":"activeAssetCtx","data":{"coin":"BTC","ctx":{"funding":"0.0000125","openInterest":"0.001","prevDayPx":"100000","dayNtlVlm":"100","premium":"0.0","oraclePx":"100000","markPx":"100000","midPx":null,"dayBaseVlm":"0.001"}}}
    ((coin BTC)
     (ctx
      ((funding (1.25E-05)) (open_interest (0.05)) (prev_day_px 100000)
       (day_ntl_vlm 1000) (premium (-0.005)) (oracle_px (100000))
       (mark_px 100000) (mid_px (99500)) (impact_pxs ((99000 100000)))
       (day_base_vlm (0.01)))))
    {"channel":"activeAssetCtx","data":{"coin":"BTC","ctx":{"funding":"0.0000125","openInterest":"0.05","prevDayPx":"100000","dayNtlVlm":"1000","premium":"-0.005","oraclePx":"100000","markPx":"100000","midPx":"99500","impactPxs":["99000","100000"],"dayBaseVlm":"0.01"}}}
    |}]
;;

let%expect_test "spot context has no funding" =
  show
    {|{"channel":"activeAssetCtx","data":{"coin":"@107","ctx":{"prevDayPx":"40.0","dayNtlVlm":"1.0","markPx":"41.0","midPx":"41.0","circulatingSupply":"1.0","coin":"@107"}}}|};
  [%expect
    {|
    ((coin @107)
     (ctx
      ((funding ()) (open_interest ()) (prev_day_px 40) (day_ntl_vlm 1)
       (premium ()) (oracle_px ()) (mark_px 41) (mid_px (41)) (impact_pxs ())
       (day_base_vlm ()))))
    {"channel":"activeAssetCtx","data":{"coin":"@107","ctx":{"prevDayPx":"40","dayNtlVlm":"1","markPx":"41","midPx":"41"}}}
    |}]
;;

let%expect_test "malformed contexts and other channels" =
  show {|{"channel":"activeAssetCtx","data":{"coin":"BTC","ctx":{"funding":"x"}}}|};
  show {|{"channel":"activeAssetCtx","data":{}}|};
  show {|{"channel":"pong"}|};
  [%expect
    {|
    undecodable
    undecodable
    ("not activeAssetCtx" (message Pong))
    |}]
;;

let%expect_test "requests and their echoes" =
  List.iter
    [ {|{"method":"subscribe","subscription":{"type":"activeAssetCtx","coin":"BTC"}}|}
    ; {|{"method":"unsubscribe","subscription":{"type":"activeAssetCtx","coin":"ETH"}}|}
    ; {|{"method":"subscribe","subscription":{"type":"trades","coin":"BTC"}}|}
    ; {|{"method":"ping"}|}
    ]
    ~f:(fun s ->
      match Asset_ctx.Request.of_yojson_opt (Yojson.Safe.from_string s) with
      | None -> print_endline "None"
      | Some req ->
        print_s [%sexp (req : Asset_ctx.Request.t)];
        print_endline (Yojson.Safe.to_string (Asset_ctx.Request.yojson_of_t req));
        let echo = Ws_message.yojson_of_t (Asset_ctx.Request.response req) in
        print_endline (Yojson.Safe.to_string echo);
        (* The echo decodes back to the same message. *)
        let decoded = Ws_message.t_of_yojson echo in
        if not (Ws_message.equal decoded (Asset_ctx.Request.response req))
        then print_s [%message "echo mismatch" (decoded : Ws_message.t)]);
  [%expect
    {|
    ((subscribe true) (coin BTC))
    {"method":"subscribe","subscription":{"type":"activeAssetCtx","coin":"BTC"}}
    {"channel":"subscriptionResponse","data":{"method":"subscribe","subscription":{"type":"activeAssetCtx","coin":"BTC"}}}
    ((subscribe false) (coin ETH))
    {"method":"unsubscribe","subscription":{"type":"activeAssetCtx","coin":"ETH"}}
    {"channel":"subscriptionResponse","data":{"method":"unsubscribe","subscription":{"type":"activeAssetCtx","coin":"ETH"}}}
    None
    None
    |}]
;;
