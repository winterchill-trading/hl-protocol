open! Core
open Ppx_yojson_conv_lib.Yojson_conv.Primitives
open Hl_protocol

let fills () = Yojson.Safe.from_file "fixtures/docs-user-fills/user_fills.json"

let%expect_test "old readers ignore builderFee and liquidation" =
  let fills = list_of_yojson User_fill.t_of_yojson (fills ()) in
  List.iter fills ~f:(fun (fill : User_fill.t) -> print_s [%sexp (fill.tid : int)]);
  [%expect
    {|
    118906512037719
    118906512037720
    118906512037721
    |}]
;;

let%expect_test "detailed fills keep builderFee and liquidation" =
  let fills = list_of_yojson User_fill.Detailed.t_of_yojson (fills ()) in
  List.iter fills ~f:(fun (d : User_fill.Detailed.t) ->
    print_s
      [%message
        ""
          ~tid:(d.fill.tid : int)
          ~builder_fee:(d.builder_fee : Usd.t option)
          ~liquidation:(d.liquidation : User_fill.Liquidation.t option)];
    let encoded = User_fill.Detailed.yojson_of_t d in
    let again = User_fill.Detailed.t_of_yojson encoded in
    if not (User_fill.Detailed.equal d again)
    then print_s [%message "round trip differs" (again : User_fill.Detailed.t)]);
  [%expect {|
    ((tid 118906512037719) (builder_fee (0.01)) (liquidation ()))
    ((tid 118906512037720) (builder_fee ())
     (liquidation
      (((liquidated_user (0x00000000000000000000000000000000000000aa))
        (mark_px 2399.8) (method_ market)))))
    ((tid 118906512037721) (builder_fee ())
     (liquidation (((liquidated_user ()) (mark_px 99990.5) (method_ backstop)))))
    |}]
;;

let%expect_test "sexp of a detailed fill without extras matches the plain fill" =
  let fill = List.hd_exn (list_of_yojson User_fill.t_of_yojson (fills ())) in
  print_s [%sexp (User_fill.Detailed.of_fill fill : User_fill.Detailed.t)];
  [%expect {|
    ((fill
      ((coin AVAX) (px 18.435) (sz 93.53) (side Buy) (time 1681222254710)
       (start_position 26.86) (dir "Open Long") (closed_pnl 0)
       (hash 0xa166e3fa63c25663024b03f2e0da011a00307e4017465df020210d3d432e7cb8)
       (oid 90542681) (crossed false) (fee 0.01) (tid 118906512037719)
       (fee_token (USDC)) (cloid ()))))
    |}]
;;
