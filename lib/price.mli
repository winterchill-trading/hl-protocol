(** Prices (limit prices, mark/mid prices, entry and liquidation prices). Re-exported from
    {!Exchange_core.Price}; encoded as decimal strings. *)

open! Core

include module type of struct
  include Exchange_core.Price
end
