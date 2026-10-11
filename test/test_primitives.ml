open! Core
open Hl_protocol

let%expect_test "side" =
  List.iter Side.all ~f:(fun side ->
    print_s
      [%sexp
        (side : Side.t)
        , (Yojson.Safe.to_string (Side.yojson_of_t side) : string)
        , (Side.is_buy side : bool)
        , (Side.flip side : Side.t)]);
  [%expect {|
    (Buy "\"B\"" true Sell)
    (Sell "\"A\"" false Buy)
    |}]
;;

let%expect_test "cloid" =
  print_s [%sexp (Cloid.of_int 255 : Cloid.t)];
  print_s [%sexp (Cloid.of_string_opt "0xABCDEFabcdef00000000000000000000" : Cloid.t option)];
  print_s [%sexp (Cloid.of_string_opt "0x1234" : Cloid.t option)];
  print_s [%sexp (Cloid.of_string_opt "1234567890abcdef1234567890abcdef" : Cloid.t option)];
  [%expect {|
    0x000000000000000000000000000000ff
    (0xabcdefabcdef00000000000000000000)
    ()
    ()
    |}]
;;

let%expect_test "order id beyond 2^62 survives json" =
  let oid = Order_id.of_int64 Int64.max_value in
  let json = Order_id.yojson_of_t oid in
  print_endline (Yojson.Safe.to_string json);
  print_s [%sexp (Order_id.equal oid (Order_id.t_of_yojson (Yojson.Safe.from_string (Yojson.Safe.to_string json))) : bool)];
  [%expect {|
    9223372036854775807
    true
    |}]
;;

let%expect_test "address normalises case" =
  print_s
    [%sexp
      (Address.t_of_yojson (`String "0xABCDEF0000000000000000000000000000000001") : Address.t)];
  [%expect {| 0xabcdef0000000000000000000000000000000001 |}]
;;
