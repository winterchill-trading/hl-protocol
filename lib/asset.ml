open! Core
open Ppx_yojson_conv_lib.Yojson_conv.Primitives

module T = struct
  type t = int [@@deriving sexp, compare, equal, hash, yojson]
end

include T
include Comparable.Make (T)

let of_int = Fn.id
let to_int = Fn.id
