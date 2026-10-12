open! Core
open Hl_protocol

(* One minute of the real BTC feed (activeAssetCtx, l2Book, trades), recorded from mainnet
   as "<receive time> <frame>" lines. Every frame must decode, re-encode and decode to the
   same value. *)

let dir = "fixtures/hyperliquid-BTC-2026-10-12T13-35"

let frames file =
  In_channel.read_lines (dir ^/ file)
  |> List.map ~f:(fun line ->
    let _recv_ts, frame = String.lsplit2_exn line ~on:' ' in
    frame)
;;

let round_trips message =
  let encoded = Yojson.Safe.to_string (Ws_message.yojson_of_t message) in
  Ws_message.equal message (Ws_message.t_of_yojson (Yojson.Safe.from_string encoded))
;;

let%expect_test "every frame decodes" =
  List.iter [ "funding.ndjson"; "l2.ndjson"; "trades.ndjson" ] ~f:(fun file ->
    let messages =
      List.map (frames file) ~f:(fun frame ->
        Ws_message.t_of_yojson (Yojson.Safe.from_string frame))
    in
    let channels =
      List.map messages ~f:Ws_message.channel
      |> List.dedup_and_sort ~compare:String.compare
    in
    let not_round_tripping = List.count messages ~f:(Fn.non round_trips) in
    let ctx_errors =
      List.count messages ~f:(fun m ->
        match Asset_ctx.of_ws_message m with
        | Some (Error _) -> true
        | Some (Ok ctx) ->
          (* Rates and volumes must survive the typed re-encoding too. *)
          not (Asset_ctx.equal ctx (Asset_ctx.t_of_yojson (Asset_ctx.yojson_of_t ctx)))
        | None -> false)
    in
    print_s
      [%message
        file
          ~frames:(List.length messages : int)
          (channels : string list)
          (not_round_tripping : int)
          (ctx_errors : int)]);
  [%expect
    {|
    (funding.ndjson (frames 12) (channels (activeAssetCtx))
     (not_round_tripping 0) (ctx_errors 0))
    (l2.ndjson (frames 6) (channels (l2Book)) (not_round_tripping 0)
     (ctx_errors 0))
    (trades.ndjson (frames 25) (channels (trades)) (not_round_tripping 0)
     (ctx_errors 0))
    |}]
;;

let%expect_test "decoded contents" =
  let trades =
    List.concat_map (frames "trades.ndjson") ~f:(fun frame ->
      match Ws_message.t_of_yojson (Yojson.Safe.from_string frame) with
      | Trades trades -> trades
      | _ -> [])
  in
  let books =
    List.filter_map (frames "l2.ndjson") ~f:(fun frame ->
      match Ws_message.t_of_yojson (Yojson.Safe.from_string frame) with
      | L2_book book -> Some book
      | _ -> None)
  in
  let ctxs =
    List.filter_map (frames "funding.ndjson") ~f:(fun frame ->
      Ws_message.t_of_yojson (Yojson.Safe.from_string frame)
      |> Asset_ctx.of_ws_message
      |> Option.bind ~f:Result.ok)
  in
  let first_book = List.hd_exn books in
  print_s
    [%message
      ""
        ~trades:(List.length trades : int)
        ~buys:(List.count trades ~f:(fun t -> Side.equal t.side Buy) : int)
        ~books:(List.length books : int)
        ~first_best_bid:(L2_book.best_bid first_book : L2_book.Level.t option)
        ~first_best_ask:(L2_book.best_ask first_book : L2_book.Level.t option)
        ~first_ctx:(List.hd_exn ctxs : Asset_ctx.t)];
  [%expect
    {|
    ((trades 40) (buys 17) (books 6)
     (first_best_bid (((px 82514) (sz 0.73912) (n 1))))
     (first_best_ask (((px 82515) (sz 2.07099) (n 22))))
     (first_ctx
      ((coin BTC)
       (ctx
        ((funding (8.8036E-06)) (open_interest (38118.25156)) (prev_day_px 83037)
         (day_ntl_vlm 2163640774.58034801) (premium (-0.0004432839))
         (oracle_px (82565.6)) (mark_px 82528) (mid_px (82528.5))
         (impact_pxs ((82528 82529))) (day_base_vlm (25889.3798)))))))
    |}]
;;
