(** An account address, e.g. ["0x0000000000000000000000000000000000000000"]. An alias of
    {!Exchange_core.Account}; [of_string] and the JSON decoder normalise to lowercase. *)

open! Core

include module type of struct
  include Exchange_core.Account
end

val yojson_of_t : t -> Yojson.Safe.t
val t_of_yojson : Yojson.Safe.t -> t
