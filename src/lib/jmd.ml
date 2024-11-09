open Common

type t = Jekyll_format.t

let of_string_function =
  [%stri
    let of_string s =
      let jk = Jekyll_format.of_string s in
      let markdown = Result.map Jekyll_format.body jk in
      let fields =
        Result.map Jekyll_format.fields_to_yaml
          (Result.map Jekyll_format.fields jk)
      in
      let metadata = Result.bind fields metadata_of_yaml in
      match (markdown, metadata) with
      | Ok markdown, Ok metadata -> Ok { metadata; markdown }
      | Error (`Msg m1), Error (`Msg m2) -> Error (`Msg (m1 ^ " " ^ m2))
      | (Error _ as e), _ | _, (Error _ as e) -> e]

let to_type ?(config = Config.default) ?(name = "t") (t : t) =
  let yaml = Jekyll_format.(fields_to_yaml (fields t)) in
  let yaml_types, strs = Yml.to_type ~config ~name:"metadata" yaml in
  let record =
    type_decl ~name
      (`Record
        [
          lbl_decl "metadata" (Types.alias "metadata");
          lbl_decl "markdown" Types.string;
        ])
  in
  let strs =
    if Option.is_some config.Config.with_parsers then
      strs @ [ of_string_function ]
    else strs
  in
  (record :: yaml_types |> List.rev, strs)
