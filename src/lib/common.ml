open Ppxlib.Ast_builder.Default

let loc = !Ast_helper.default_loc

let loc_name name : string Location.loc =
  let name =
    String.lowercase_ascii name |> String.split_on_char '-' |> String.concat "-"
  in
  { txt = name; loc }

let simple_type = function
  | `String -> ptyp_constr ~loc { txt = Lident "string"; loc } []
  | `Int -> ptyp_constr ~loc { txt = Lident "int"; loc } []
  | `Float -> ptyp_constr ~loc { txt = Lident "float"; loc } []
  | `Bool -> ptyp_constr ~loc { txt = Lident "bool"; loc } []
  | `List c -> ptyp_constr ~loc { txt = Lident "list"; loc } [ c ]
  | `Alias a -> ptyp_constr ~loc { txt = Lident a; loc } []

module Types = struct
  let string = simple_type `String
  let int = simple_type `Int
  let float = simple_type `Float
  let bool = simple_type `Bool
  let list c = simple_type (`List c)
  let alias a = simple_type (`Alias a)
end

let type_declaration ~name ~kind ~manifest =
  Ppxlib.Ast_builder.Default.type_declaration ~loc ~name:{ txt = name; loc }
    ~private_:Public ~params:[] ~manifest ~cstrs:[] ~kind

let type_decl ~name = function
  | `Built_in c ->
      type_declaration ~name ~kind:Ptype_abstract ~manifest:(Some c)
  | `Record r -> type_declaration ~name ~kind:(Ptype_record r) ~manifest:None

let lbl_decl key type_ =
  label_declaration ~mutable_:Immutable ~loc ~name:(loc_name key) ~type_
