open! Core

type t = { user : Address.t }
[@@deriving sexp, compare, equal, yojson] [@@yojson.allow_extra_fields]

let yojson_of_t t = Json.with_tag (yojson_of_t t) ~key:"type" ~value:"userRole"

let t_of_yojson json =
  match Json.tag json ~key:"type" with
  | "userRole" -> t_of_yojson json
  | _ -> Json.error "User_role: not a userRole request" json
;;

module Role = struct
  type t =
    | User
    | Agent of { user : Address.t }
    | Vault
    | Sub_account of { master : Address.t }
    | Missing
    | Other of string
  [@@deriving sexp, compare, equal]

  let to_string = function
    | User -> "user"
    | Agent _ -> "agent"
    | Vault -> "vault"
    | Sub_account _ -> "subAccount"
    | Missing -> "missing"
    | Other s -> s
  ;;

  let data_address json ~key =
    Json.member_exn json ~key:"data" |> Json.member_exn ~key |> Address.t_of_yojson
  ;;

  let t_of_yojson json =
    match Json.tag json ~key:"role" with
    | "user" -> User
    | "agent" -> Agent { user = data_address json ~key:"user" }
    | "vault" -> Vault
    | "subAccount" -> Sub_account { master = data_address json ~key:"master" }
    | "missing" -> Missing
    | other -> Other other
  ;;

  let yojson_of_t t =
    let role = "role", `String (to_string t) in
    match t with
    | Agent { user } ->
      `Assoc [ role; "data", `Assoc [ "user", Address.yojson_of_t user ] ]
    | Sub_account { master } ->
      `Assoc [ role; "data", `Assoc [ "master", Address.yojson_of_t master ] ]
    | User | Vault | Missing | Other _ -> `Assoc [ role ]
  ;;
end

type response = Role.t [@@deriving sexp_of, yojson]
