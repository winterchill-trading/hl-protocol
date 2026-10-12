open! Core
open Hl_protocol

(* Info responses and websocket frames captured from mainnet (one market-making account,
   BTC), trimmed. Each must decode, and re-encoding must decode to the same value. *)

let dir = "fixtures/mainnet-info-ws-2026-10-12"
let read file = In_channel.read_all (dir ^/ file) |> Yojson.Safe.from_string
let user = "0xf5d81a135f756ca16544e53c20fc20643ec3ad53"

let%expect_test "info responses" =
  List.iter
    [ "allMids", {|{"type":"allMids"}|}
    ; "l2Book", {|{"type":"l2Book","coin":"BTC"}|}
    ; "meta", {|{"type":"meta"}|}
    ; "openOrders", sprintf {|{"type":"openOrders","user":"%s"}|} user
    ; "userFills", sprintf {|{"type":"userFills","user":"%s"}|} user
    ; "clearinghouseState", sprintf {|{"type":"clearinghouseState","user":"%s"}|} user
    ]
    ~f:(fun (name, request) ->
      let request = Info_request.t_of_yojson (Yojson.Safe.from_string request) in
      let decoded = Info_response.of_yojson (read (name ^ ".json")) ~request in
      let round_trips =
        Info_response.equal
          decoded
          (Info_response.of_yojson (Info_response.yojson_of_t decoded) ~request)
      in
      print_s [%message name (round_trips : bool)]);
  [%expect
    {|
    (allMids (round_trips true))
    (l2Book (round_trips true))
    (meta (round_trips true))
    (openOrders (round_trips true))
    (userFills (round_trips true))
    (clearinghouseState (round_trips true))
    |}]
;;

let%expect_test "clearinghouseState liquidation prices" =
  let request =
    Info_request.t_of_yojson
      (Yojson.Safe.from_string
         (sprintf {|{"type":"clearinghouseState","user":"%s"}|} user))
  in
  match Info_response.of_yojson (read "clearinghouseState.json") ~request with
  | Clearinghouse_state state ->
    List.iter state.positions ~f:(fun p ->
      print_s [%sexp (p.coin : Coin.t), (p.liquidation_px : Price.t option)]);
    [%expect
      {|
      (BTC (22321.7325857))
      (ETH ())
      (SOL ())
      (BNB (78942104.32966665))
      (LTC ())
      (ARB (309.26141448))
      (DOGE ())
      (SUI (888.54636042))
      |}]
  | other -> print_s [%message "unexpected" (other : Info_response.t)]
;;

let%expect_test "websocket frames" =
  let counts =
    In_channel.read_lines (dir ^/ "ws.ndjson")
    |> List.map ~f:(fun line ->
      let message = Ws_message.t_of_yojson (Yojson.Safe.from_string line) in
      let encoded = Ws_message.yojson_of_t message in
      let round_trips = Ws_message.equal message (Ws_message.t_of_yojson encoded) in
      let kind =
        match message, Asset_ctx.of_ws_message message with
        | _, Some (Ok _) -> "activeAssetCtx (Asset_ctx)"
        | _, Some (Error _) -> "activeAssetCtx (undecodable)"
        | Unknown { channel; _ }, None -> "Unknown " ^ channel
        | message, None -> Ws_message.channel message
      in
      kind, round_trips)
    |> List.sort_and_group ~compare:[%compare: string * bool]
    |> List.map ~f:(fun group -> List.hd_exn group, List.length group)
  in
  List.iter counts ~f:(fun ((kind, round_trips), n) ->
    print_s [%message kind (round_trips : bool) (n : int)]);
  [%expect
    {|
    ("activeAssetCtx (Asset_ctx)" (round_trips true) (n 3))
    (allMids (round_trips true) (n 3))
    (error (round_trips true) (n 1))
    (l2Book (round_trips true) (n 3))
    (orderUpdates (round_trips true) (n 3))
    (pong (round_trips true) (n 1))
    (subscriptionResponse (round_trips true) (n 3))
    (trades (round_trips true) (n 1))
    (userFills (round_trips true) (n 3))
    |}]
;;
