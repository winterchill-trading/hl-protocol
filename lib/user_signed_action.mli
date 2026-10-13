(** Exchange actions signed by the user's own wallet as EIP-712 typed data, rather than as
    an L1 action hash: [approveAgent] and [approveBuilderFee].

    Wire forms, from the Hyperliquid exchange endpoint docs ("Approve an API wallet",
    "Approve a builder fee"), keys in the documented order:

    - [{"type": "approveAgent", "hyperliquidChain": "Mainnet" | "Testnet", "signatureChainId": "0xa4b1", "agentAddress": "0x...", "agentName": "...", "nonce": 1700000000000}];
      [agentName] is optional.
    - [{"type": "approveBuilderFee", "hyperliquidChain": "Mainnet" | "Testnet", "signatureChainId": "0xa4b1", "maxFeeRate": "0.001%", "builder": "0x...", "nonce": 1700000000000}]

    The action [nonce] must equal the request's outer [nonce]. These are not
    {!Exchange_action} constructors on purpose: dependents match that type exhaustively.

    Signing (official Python SDK, [hyperliquid/utils/signing.py],
    [sign_user_signed_action] and [user_signed_payload]): the message is the action
    itself, typed by {!Eip712.fields}, under primary type
    ["HyperliquidTransaction:ApproveAgent"] or
    ["HyperliquidTransaction:ApproveBuilderFee"] in the domain
    [{name: "HyperliquidSignTransaction", version: "1", chainId: signatureChainId, verifyingContract: 0x0}].
    [hyperliquidChain] picks the environment and stops replay across chains;
    [signatureChainId] is only the chain the wallet signs on and "can be any chain". *)

open! Core

module Hyperliquid_chain : sig
  (** ["Mainnet"] or ["Testnet"]. *)
  type t =
    | Mainnet
    | Testnet
  [@@deriving sexp, compare, equal, enumerate, yojson]

  val to_string : t -> string
end

type t =
  | Approve_agent of
      { hyperliquid_chain : Hyperliquid_chain.t
      ; signature_chain_id : string (** hex, e.g. ["0x66eee"] *)
      ; agent_address : Address.t
      ; agent_name : string option
      (** [None] approves the account's single unnamed agent, evicting the previous one.
          Up to three named agents per account; a name may end in [" valid_until <ms>"] to
          expire the agent (at most 180 days ahead), per the docs. Prefer named agents,
          and never reuse an agent address. *)
      ; nonce : int
      }
  | Approve_builder_fee of
      { hyperliquid_chain : Hyperliquid_chain.t
      ; signature_chain_id : string
      ; max_fee_rate : string (** a percentage, e.g. ["0.001%"]; see {!Builder_fee} *)
      ; builder : Address.t
      ; nonce : int
      }
[@@deriving sexp, compare, equal, yojson]

(** ["0x66eee"], the [signatureChainId] the official SDK signs with for both networks. The
    docs' example uses ["0xa4b1"]; any chain id is accepted because [hyperliquidChain],
    not the signing chain, selects mainnet or testnet. *)
val default_signature_chain_id : string

val approve_agent
  :  ?signature_chain_id:string (** default {!default_signature_chain_id} *)
  -> ?agent_name:string
  -> Hyperliquid_chain.t
  -> agent_address:Address.t
  -> nonce:int
  -> t

(** [max_fee_tenths_bp] becomes [maxFeeRate] via {!Builder_fee.percent_of_tenths_bp}.
    Signed by the main wallet, not an agent. Perps cap builder fees at 0.1% (100). *)
val approve_builder_fee
  :  ?signature_chain_id:string
  -> Hyperliquid_chain.t
  -> builder:Address.t
  -> max_fee_tenths_bp:int
  -> nonce:int
  -> t

(** ["approveAgent"] or ["approveBuilderFee"]. *)
val type_tag : t -> string

(** Whether [type_tag] names an action of this module. *)
val is_user_signed_type : string -> bool

val nonce : t -> int
val hyperliquid_chain : t -> Hyperliquid_chain.t
val signature_chain_id : t -> string

(** The EIP-712 view of an action, from the SDK's [sign_agent] and
    [sign_approve_builder_fee] type lists. *)
module Eip712 : sig
  module Value : sig
    type t =
      | String of string (** hashed with Keccak-256 *)
      | Address of Address.t (** left-padded to 32 bytes *)
      | Uint64 of int (** big-endian, left-padded to 32 bytes *)
    [@@deriving sexp, compare, equal]

    (** ["string"], ["address"] or ["uint64"]. *)
    val solidity_type : t -> string
  end

  (** E.g. ["HyperliquidTransaction:ApproveAgent"]. *)
  val primary_type : t -> string

  (** The message fields in type order. An absent [agentName] is signed as [""], as the
      SDK does before deleting the key from the posted action. *)
  val fields : t -> (string * Value.t) list

  (** The encoded type, e.g.
      ["HyperliquidTransaction:ApproveAgent(string hyperliquidChain,address agentAddress,string agentName,uint64 nonce)"]. *)
  val encode_type : t -> string

  (** [signatureChainId] as an integer, the domain's [chainId]. Raises if it is not hex. *)
  val chain_id : t -> int

  (** ["HyperliquidSignTransaction"]. *)
  val domain_name : string

  (** ["1"]. *)
  val domain_version : string
end
