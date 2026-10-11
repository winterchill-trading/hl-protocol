open! Core

type t = Yojson.Safe.t

let sexp_of_t t = Sexp.Atom (Yojson.Safe.to_string t)

let t_of_sexp = function
  | Sexp.Atom s -> Yojson.Safe.from_string s
  | sexp -> of_sexp_error "Json.t_of_sexp: atom expected" sexp
;;

let compare a b = String.compare (Yojson.Safe.to_string a) (Yojson.Safe.to_string b)
let equal = Yojson.Safe.equal
let yojson_of_t = Fn.id
let t_of_yojson = Fn.id
let error msg t = Ppx_yojson_conv_lib.Yojson_conv.of_yojson_error msg t

let member (t : t) ~key =
  match t with
  | `Assoc fields -> List.Assoc.find fields key ~equal:String.equal
  | _ -> None
;;

let member_exn t ~key =
  match member t ~key with
  | Some v -> v
  | None -> error (sprintf "missing field %S" key) t
;;

let tag t ~key =
  match member_exn t ~key with
  | `String s -> s
  | _ -> error (sprintf "field %S must be a string" key) t
;;

let with_tag (t : t) ~key ~value : t =
  match t with
  | `Assoc fields -> `Assoc ((key, `String value) :: fields)
  | `Null -> `Assoc [ key, `String value ]
  | _ -> error "with_tag: object expected" t
;;

let rec sort_keys (t : t) : t =
  match t with
  | `Assoc fields ->
    `Assoc
      (List.map fields ~f:(fun (k, v) -> k, sort_keys v)
       |> List.sort ~compare:(fun (a, _) (b, _) -> String.compare a b))
  | `List l -> `List (List.map l ~f:sort_keys)
  | other -> other
;;
