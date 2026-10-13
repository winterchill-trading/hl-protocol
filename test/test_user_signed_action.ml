open! Core
open Hl_protocol

let round_trip = Helpers.round_trip (module User_signed_action)

let print_eip712 t =
  print_endline (User_signed_action.Eip712.encode_type t);
  print_s
    [%message
      ""
        ~chain_id:(User_signed_action.Eip712.chain_id t : int)
        ~fields:
          (User_signed_action.Eip712.fields t
           : (string * User_signed_action.Eip712.Value.t) list)]
;;

let%expect_test "approveAgent, docs shape" =
  round_trip
    {|{"type":"approveAgent","hyperliquidChain":"Testnet","signatureChainId":"0xa4b1","agentAddress":"0x00000000000000000000000000000000000000a1","agentName":"copy valid_until 1760000000000","nonce":1700000000000}|};
  [%expect
    {|
    (Approve_agent (hyperliquid_chain Testnet) (signature_chain_id 0xa4b1)
     (agent_address 0x00000000000000000000000000000000000000a1)
     (agent_name ("copy valid_until 1760000000000")) (nonce 1700000000000))
    {"type":"approveAgent","hyperliquidChain":"Testnet","signatureChainId":"0xa4b1","agentAddress":"0x00000000000000000000000000000000000000a1","agentName":"copy valid_until 1760000000000","nonce":1700000000000}
    |}];
  (* No agentName: the posted action omits it, the signature covers "". *)
  let unnamed =
    User_signed_action.approve_agent
      Testnet
      ~agent_address:(Address.of_string "0x00000000000000000000000000000000000000a1")
      ~nonce:1
  in
  print_endline (Yojson.Safe.to_string (User_signed_action.yojson_of_t unnamed));
  print_eip712 unnamed;
  [%expect
    {|
    {"type":"approveAgent","hyperliquidChain":"Testnet","signatureChainId":"0x66eee","agentAddress":"0x00000000000000000000000000000000000000a1","nonce":1}
    HyperliquidTransaction:ApproveAgent(string hyperliquidChain,address agentAddress,string agentName,uint64 nonce)
    ((chain_id 421614)
     (fields
      ((hyperliquidChain (String Testnet))
       (agentAddress (Address 0x00000000000000000000000000000000000000a1))
       (agentName (String "")) (nonce (Uint64 1)))))
    |}]
;;

let%expect_test "approveBuilderFee, docs shape" =
  round_trip
    {|{"type":"approveBuilderFee","hyperliquidChain":"Mainnet","signatureChainId":"0xa4b1","maxFeeRate":"0.001%","builder":"0x00000000000000000000000000000000000000b1","nonce":1700000000000}|};
  [%expect
    {|
    (Approve_builder_fee (hyperliquid_chain Mainnet) (signature_chain_id 0xa4b1)
     (max_fee_rate 0.001%) (builder 0x00000000000000000000000000000000000000b1)
     (nonce 1700000000000))
    {"type":"approveBuilderFee","hyperliquidChain":"Mainnet","signatureChainId":"0xa4b1","maxFeeRate":"0.001%","builder":"0x00000000000000000000000000000000000000b1","nonce":1700000000000}
    |}];
  let action =
    User_signed_action.approve_builder_fee
      Testnet
      ~builder:(Address.of_string "0x00000000000000000000000000000000000000b1")
      ~max_fee_tenths_bp:10
      ~nonce:2
  in
  print_endline (Yojson.Safe.to_string (User_signed_action.yojson_of_t action));
  print_eip712 action;
  [%expect
    {|
    {"type":"approveBuilderFee","hyperliquidChain":"Testnet","signatureChainId":"0x66eee","maxFeeRate":"0.01%","builder":"0x00000000000000000000000000000000000000b1","nonce":2}
    HyperliquidTransaction:ApproveBuilderFee(string hyperliquidChain,string maxFeeRate,address builder,uint64 nonce)
    ((chain_id 421614)
     (fields
      ((hyperliquidChain (String Testnet)) (maxFeeRate (String 0.01%))
       (builder (Address 0x00000000000000000000000000000000000000b1))
       (nonce (Uint64 2)))))
    |}]
;;

let%expect_test "other types are rejected" =
  print_s
    [%sexp
      (List.map [ "approveAgent"; "approveBuilderFee"; "order"; "usdSend" ] ~f:(fun s ->
         s, User_signed_action.is_user_signed_type s)
       : (string * bool) list)];
  print_s
    [%sexp
      (Result.is_error
         (Or_error.try_with (fun () ->
            User_signed_action.t_of_yojson
              (Yojson.Safe.from_string {|{"type":"usdSend","nonce":1}|})))
       : bool)];
  [%expect
    {|
    ((approveAgent true) (approveBuilderFee true) (order false) (usdSend false))
    true
    |}]
;;
