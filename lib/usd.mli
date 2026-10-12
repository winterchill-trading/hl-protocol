(** USD (USDC) amounts: PnL, fees, margin and account values. Re-exported from
    {!Exchange_core.Usd}; encoded as decimal strings. *)

open! Core

include module type of struct
  include Exchange_core.Usd
end
