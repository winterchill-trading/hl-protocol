open! Core
open Ppx_yojson_conv_lib.Yojson_conv.Primitives

module Hyperliquid_chain = struct
  type t =
    | Mainnet
    | Testnet
  [@@deriving sexp, compare, equal, enumerate]

  let to_string = function
    | Mainnet -> "Mainnet"
    | Testnet -> "Testnet"
  ;;

  let yojson_of_t t = `String (to_string t)

  let t_of_yojson = function
    | `String "Mainnet" -> Mainnet
    | `String "Testnet" -> Testnet
    | json -> Json.error "Hyperliquid_chain: expected \"Mainnet\" or \"Testnet\"" json
  ;;
end

type t =
  | Approve_agent of
      { hyperliquid_chain : Hyperliquid_chain.t
      ; signature_chain_id : string
      ; agent_address : Address.t
      ; agent_name : string option
      ; nonce : int
      }
  | Approve_builder_fee of
      { hyperliquid_chain : Hyperliquid_chain.t
      ; signature_chain_id : string
      ; max_fee_rate : string
      ; builder : Address.t
      ; nonce : int
      }
[@@deriving sexp, compare, equal]

(* Field order follows the docs' examples; it does not affect the signature (typed data is
   hashed field by field in type order), only how the body reads. *)
module Approve_agent_wire = struct
  type t =
    { hyperliquid_chain : Hyperliquid_chain.t [@key "hyperliquidChain"]
    ; signature_chain_id : string [@key "signatureChainId"]
    ; agent_address : Address.t [@key "agentAddress"]
    ; agent_name : string option
         [@key "agentName"] [@default None] [@yojson_drop_if Option.is_none]
    ; nonce : int
    }
  [@@deriving yojson] [@@yojson.allow_extra_fields]
end

module Approve_builder_fee_wire = struct
  type t =
    { hyperliquid_chain : Hyperliquid_chain.t [@key "hyperliquidChain"]
    ; signature_chain_id : string [@key "signatureChainId"]
    ; max_fee_rate : string [@key "maxFeeRate"]
    ; builder : Address.t
    ; nonce : int
    }
  [@@deriving yojson] [@@yojson.allow_extra_fields]
end

let type_tag = function
  | Approve_agent _ -> "approveAgent"
  | Approve_builder_fee _ -> "approveBuilderFee"
;;

let is_user_signed_type = function
  | "approveAgent" | "approveBuilderFee" -> true
  | _ -> false
;;

let yojson_of_t t =
  let body =
    match t with
    | Approve_agent
        { hyperliquid_chain; signature_chain_id; agent_address; agent_name; nonce } ->
      Approve_agent_wire.yojson_of_t
        { hyperliquid_chain; signature_chain_id; agent_address; agent_name; nonce }
    | Approve_builder_fee
        { hyperliquid_chain; signature_chain_id; max_fee_rate; builder; nonce } ->
      Approve_builder_fee_wire.yojson_of_t
        { hyperliquid_chain; signature_chain_id; max_fee_rate; builder; nonce }
  in
  Json.with_tag body ~key:"type" ~value:(type_tag t)
;;

let t_of_yojson json =
  match Json.tag json ~key:"type" with
  | "approveAgent" ->
    let { Approve_agent_wire.hyperliquid_chain
        ; signature_chain_id
        ; agent_address
        ; agent_name
        ; nonce
        }
      =
      Approve_agent_wire.t_of_yojson json
    in
    Approve_agent
      { hyperliquid_chain; signature_chain_id; agent_address; agent_name; nonce }
  | "approveBuilderFee" ->
    let { Approve_builder_fee_wire.hyperliquid_chain
        ; signature_chain_id
        ; max_fee_rate
        ; builder
        ; nonce
        }
      =
      Approve_builder_fee_wire.t_of_yojson json
    in
    Approve_builder_fee
      { hyperliquid_chain; signature_chain_id; max_fee_rate; builder; nonce }
  | _ -> Json.error "User_signed_action: unsupported action type" json
;;

(* The SDK's [sign_user_signed_action] hard-codes this for both networks. *)
let default_signature_chain_id = "0x66eee"

let approve_agent ?signature_chain_id ?agent_name hyperliquid_chain ~agent_address ~nonce =
  Approve_agent
    { hyperliquid_chain
    ; signature_chain_id =
        Option.value signature_chain_id ~default:default_signature_chain_id
    ; agent_address
    ; agent_name
    ; nonce
    }
;;

let approve_builder_fee
  ?signature_chain_id
  hyperliquid_chain
  ~builder
  ~max_fee_tenths_bp
  ~nonce
  =
  Approve_builder_fee
    { hyperliquid_chain
    ; signature_chain_id =
        Option.value signature_chain_id ~default:default_signature_chain_id
    ; max_fee_rate = Builder_fee.percent_of_tenths_bp max_fee_tenths_bp
    ; builder
    ; nonce
    }
;;

let nonce = function
  | Approve_agent { nonce; _ } | Approve_builder_fee { nonce; _ } -> nonce
;;

let hyperliquid_chain = function
  | Approve_agent { hyperliquid_chain; _ } | Approve_builder_fee { hyperliquid_chain; _ }
    -> hyperliquid_chain
;;

let signature_chain_id = function
  | Approve_agent { signature_chain_id; _ }
  | Approve_builder_fee { signature_chain_id; _ } -> signature_chain_id
;;

module Eip712 = struct
  module Value = struct
    type t =
      | String of string
      | Address of Address.t
      | Uint64 of int
    [@@deriving sexp, compare, equal]

    let solidity_type = function
      | String _ -> "string"
      | Address _ -> "address"
      | Uint64 _ -> "uint64"
    ;;
  end

  let primary_type = function
    | Approve_agent _ -> "HyperliquidTransaction:ApproveAgent"
    | Approve_builder_fee _ -> "HyperliquidTransaction:ApproveBuilderFee"
  ;;

  (* Type lists from the SDK's [sign_agent] and [sign_approve_builder_fee]. *)
  let fields : t -> (string * Value.t) list = function
    | Approve_agent { hyperliquid_chain; agent_address; agent_name; nonce; _ } ->
      [ "hyperliquidChain", String (Hyperliquid_chain.to_string hyperliquid_chain)
      ; "agentAddress", Address agent_address
      ; "agentName", String (Option.value agent_name ~default:"")
      ; "nonce", Uint64 nonce
      ]
    | Approve_builder_fee { hyperliquid_chain; max_fee_rate; builder; nonce; _ } ->
      [ "hyperliquidChain", String (Hyperliquid_chain.to_string hyperliquid_chain)
      ; "maxFeeRate", String max_fee_rate
      ; "builder", Address builder
      ; "nonce", Uint64 nonce
      ]
  ;;

  let encode_type t =
    let members =
      List.map (fields t) ~f:(fun (name, value) -> Value.solidity_type value ^ " " ^ name)
    in
    primary_type t ^ "(" ^ String.concat ~sep:"," members ^ ")"
  ;;

  let chain_id t =
    let hex = signature_chain_id t in
    match String.chop_prefix hex ~prefix:"0x" with
    | Some digits
      when (not (String.is_empty digits)) && String.for_all digits ~f:Char.is_hex_digit ->
      Int.of_string ("0x" ^ digits)
    | _ -> raise_s [%message "signatureChainId is not hex" hex]
  ;;

  let domain_name = "HyperliquidSignTransaction"
  let domain_version = "1"
end
