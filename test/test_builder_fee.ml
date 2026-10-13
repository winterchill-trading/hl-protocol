open! Core
open Hl_protocol

let%expect_test "builder field round trip" =
  (* Example from the exchange endpoint docs: f = 10 is 1 bp of notional. *)
  Helpers.round_trip
    (module Builder_fee)
    {|{"b":"0x8C967E73E7B15087c42A10D344cFf4c96D877f1D","f":10}|};
  [%expect
    {|
    ((builder 0x8c967e73e7b15087c42a10d344cff4c96d877f1d) (fee_tenths_bp 10))
    {"b":"0x8c967e73e7b15087c42a10d344cff4c96d877f1d","f":10}
    |}]
;;

let%expect_test "percent strings" =
  List.iter [ 0; 1; 10; 25; 100; 1000; 1234 ] ~f:(fun tenths ->
    let percent = Builder_fee.percent_of_tenths_bp tenths in
    print_s
      [%message
        ""
          (tenths : int)
          percent
          ~back:(Builder_fee.tenths_bp_of_percent percent : int Or_error.t)]);
  [%expect
    {|
    ((tenths 0) 0% (back (Ok 0)))
    ((tenths 1) 0.001% (back (Ok 1)))
    ((tenths 10) 0.01% (back (Ok 10)))
    ((tenths 25) 0.025% (back (Ok 25)))
    ((tenths 100) 0.1% (back (Ok 100)))
    ((tenths 1000) 1% (back (Ok 1000)))
    ((tenths 1234) 1.234% (back (Ok 1234)))
    |}];
  List.iter [ "0.001"; "%"; "1.%"; "0.0001%"; "-1%"; "a%"; "1.5%" ] ~f:(fun s ->
    print_s [%sexp (s : string), (Builder_fee.tenths_bp_of_percent s : int Or_error.t)]);
  [%expect
    {|
    (0.001 (Error ("not a fee percentage" 0.001)))
    (% (Error ("not a fee percentage" %)))
    (1.% (Error ("not a fee percentage" 1.%)))
    (0.0001% (Error ("not a fee percentage" 0.0001%)))
    (-1% (Error ("not a fee percentage" -1%)))
    (a% (Error ("not a fee percentage" a%)))
    (1.5% (Ok 1500))
    |}]
;;
