open! Core
open Hl_protocol

let%expect_test "userRole request" =
  Helpers.round_trip
    (module User_role)
    {|{"type":"userRole","user":"0xDFC24B077BC1425AD1DEA75BCB6F8158E10DF303"}|};
  [%expect
    {|
    ((user 0xdfc24b077bc1425ad1dea75bcb6f8158e10df303))
    {"type":"userRole","user":"0xdfc24b077bc1425ad1dea75bcb6f8158e10df303"}
    |}]
;;

let%expect_test "mainnet responses, one per role" =
  (* Bodies returned by the mainnet info endpoint on 2026-10-13 for HLP, a leaderboard
     trader, an API wallet, a sub-account and an address never seen. *)
  List.iter
    [ {|{"role":"vault"}|}
    ; {|{"role":"user"}|}
    ; {|{"role":"agent","data":{"user":"0x024294c53a69c1e6b39810b3fac87385752fffa1"}}|}
    ; {|{"role":"subAccount","data":{"master":"0x0b8aa35c28b7c6ab18f11dc168f437a8a69fd4f8"}}|}
    ; {|{"role":"missing"}|}
    ; {|{"role":"somethingNew","data":{}}|}
    ]
    ~f:(fun body ->
      let role = User_role.response_of_yojson (Yojson.Safe.from_string body) in
      let back = User_role.yojson_of_response role in
      print_s
        [%message
          ""
            (role : User_role.Role.t)
            ~wire:(User_role.Role.to_string role)
            ~same:
              ([%equal: User_role.Role.t] role (User_role.response_of_yojson back) : bool)]);
  [%expect
    {|
    ((role Vault) (wire vault) (same true))
    ((role User) (wire user) (same true))
    ((role (Agent (user 0x024294c53a69c1e6b39810b3fac87385752fffa1)))
     (wire agent) (same true))
    ((role (Sub_account (master 0x0b8aa35c28b7c6ab18f11dc168f437a8a69fd4f8)))
     (wire subAccount) (same true))
    ((role Missing) (wire missing) (same true))
    ((role (Other somethingNew)) (wire somethingNew) (same true))
    |}]
;;
