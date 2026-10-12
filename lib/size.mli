(** Sizes in units of the base asset. Signed where Hyperliquid uses signed sizes (e.g.
    [szi], [startPosition]). Re-exported from {!Exchange_core.Size}; encoded as decimal
    strings. *)

open! Core

include module type of struct
  include Exchange_core.Size
end
