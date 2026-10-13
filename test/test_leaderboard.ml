(* Four rows trimmed from the testnet stats host's leaderboard on 2026-10-13. *)

open! Core
open Hl_protocol

let%expect_test "testnet leaderboard rows" =
  let json =
    Yojson.Safe.from_file "fixtures/testnet-leaderboard-2026-10-13/leaderboard.json"
  in
  let t = Leaderboard.t_of_yojson json in
  List.iter t.leaderboard_rows ~f:(fun row ->
    print_s
      [%message
        ""
          ~address:(row.eth_address : Address.t)
          ~account_value:(row.account_value : float)
          ~name:(row.display_name : string option)
          ~month:
            (Leaderboard.Row.performance row Month : Leaderboard.Performance.t option)
          ~all_time_roi:
            (Option.map (Leaderboard.Row.performance row All_time) ~f:(fun p -> p.roi)
             : float option)]);
  let back = Leaderboard.t_of_yojson (Leaderboard.yojson_of_t t) in
  print_s [%message "" ~round_trip:(Leaderboard.equal t back : bool)];
  [%expect
    {|
    ((address 0x5972698398d8c5bbe67c0db74906236691020417)
     (account_value 105568.988111) (name ())
     (month (((pnl 6784.635216) (roi 0.0686812741) (vlm 92682965.22))))
     (all_time_roi (2.5224887591)))
    ((address 0x768484f7e2ebb675c57838366c02ae99ba2a9b08)
     (account_value 26497846.439359) (name ())
     (month (((pnl 270787.478409) (roi 0.0103247367) (vlm 30923873.73))))
     (all_time_roi (0.0381915825)))
    ((address 0xbf11536c0b7c25d219460c119001a14fc25c9459)
     (account_value 11513974.357756) (name ("PURR TESTNET"))
     (month (((pnl 76120.253891) (roi 0.0066549509) (vlm 346.32))))
     (all_time_roi (6519.1961375858)))
    ((address 0xc64cc00b46101bd40aa1c3121195e85c0b0918d8)
     (account_value 27603881.301776) (name ())
     (month (((pnl -14716.839104) (roi -0.0005328597) (vlm 30660696.57))))
     (all_time_roi (-0.1324866568)))
    (round_trip true)
    |}]
;;

let%expect_test "unknown windows are kept" =
  let row =
    Leaderboard.Row.t_of_yojson
      (Yojson.Safe.from_string
         {|{"ethAddress":"0x00000000000000000000000000000000000000aa","accountValue":"1","windowPerformances":[["quarter",{"pnl":"1","roi":"0.5","vlm":"2"}]],"prize":0,"displayName":null}|})
  in
  print_s
    [%sexp
      (row.window_performances : (Leaderboard.Window.t * Leaderboard.Performance.t) list)];
  [%expect {| (((Other quarter) ((pnl 1) (roi 0.5) (vlm 2)))) |}]
;;
