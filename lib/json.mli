(** Opaque JSON values, used for fields this library does not model (e.g.
    signatures) and for unknown websocket channels. *)

open! Core

type t = Yojson.Safe.t [@@deriving sexp, compare, equal, yojson]

(** Raises [Ppx_yojson_conv_lib.Yojson_conv.Of_yojson_error]. *)
val error : string -> t -> 'a

(** [member json ~key] is the value of [key] if [json] is an object containing it. *)
val member : t -> key:string -> t option

(** Like [member] but raises if the key is missing. *)
val member_exn : t -> key:string -> t

(** [tag json ~key] reads a string-valued discriminator field. *)
val tag : t -> key:string -> string

(** [with_tag json ~key ~value] prepends [key: value] to an object. *)
val with_tag : t -> key:string -> value:string -> t

(** Recursively sorts object keys; useful for comparing encodings. *)
val sort_keys : t -> t
