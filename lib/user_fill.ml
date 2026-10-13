open! Core
open Ppx_yojson_conv_lib.Yojson_conv.Primitives

type t =
  { coin : Coin.t
  ; px : Price.t
  ; sz : Size.t
  ; side : Side.t
  ; time : int
  ; start_position : Size.t [@key "startPosition"]
  ; dir : string
  ; closed_pnl : Usd.t [@key "closedPnl"]
  ; hash : string
  ; oid : Order_id.t
  ; crossed : bool
  ; fee : Usd.t
  ; tid : int
  ; fee_token : string option
       [@key "feeToken"] [@default None] [@yojson_drop_if Option.is_none]
  ; cloid : Cloid.t option [@default None] [@yojson_drop_if Option.is_none]
  }
[@@deriving sexp, compare, equal, yojson] [@@yojson.allow_extra_fields]

module Liquidation = struct
  type t =
    { liquidated_user : Address.t option
         [@key "liquidatedUser"] [@default None] [@yojson_drop_if Option.is_none]
    ; mark_px : Price.t [@key "markPx"]
    ; method_ : string [@key "method"]
    }
  [@@deriving sexp, compare, equal, yojson] [@@yojson.allow_extra_fields]

  (* The websocket docs type [markPx] as a number; read a number as its decimal text. *)
  let t_of_yojson (json : Yojson.Safe.t) =
    match json with
    | `Assoc fields ->
      let fields =
        List.map fields ~f:(fun (key, value) ->
          match key, value with
          | "markPx", ((`Int _ | `Float _) as number) ->
            key, `String (Yojson.Safe.to_string number)
          | _ -> key, value)
      in
      t_of_yojson (`Assoc fields)
    | _ -> t_of_yojson json
  ;;
end

module Detailed = struct
  type fill = t [@@deriving sexp, compare, equal]

  let fill_of_yojson = t_of_yojson
  let yojson_of_fill = yojson_of_t

  type t =
    { fill : fill
    ; builder_fee : Usd.t option [@sexp.option]
    ; liquidation : Liquidation.t option [@sexp.option]
    }
  [@@deriving sexp, compare, equal]

  let of_fill fill = { fill; builder_fee = None; liquidation = None }

  let t_of_yojson json =
    let null_to_none = function
      | Some `Null -> None
      | other -> other
    in
    { fill = fill_of_yojson json
    ; builder_fee =
        Json.member json ~key:"builderFee" |> null_to_none |> Option.map ~f:Usd.t_of_yojson
    ; liquidation =
        Json.member json ~key:"liquidation"
        |> null_to_none
        |> Option.map ~f:Liquidation.t_of_yojson
    }
  ;;

  let yojson_of_t t =
    let extra =
      List.filter_opt
        [ Option.map t.liquidation ~f:(fun l -> "liquidation", Liquidation.yojson_of_t l)
        ; Option.map t.builder_fee ~f:(fun fee -> "builderFee", Usd.yojson_of_t fee)
        ]
    in
    match yojson_of_fill t.fill with
    | `Assoc fields -> `Assoc (fields @ extra)
    | json -> json
  ;;
end
