open Common

type t = Jekyll_format.t

let to_type ?(config = Config.default) ?(name = "t") (t : t) =
  let yaml = Jekyll_format.(fields_to_yaml (fields t)) in
  let yaml_types = Yml.to_type ~config ~name:"metadata" yaml in
  let record =
    type_decl ~name
      (`Record
        [
          lbl_decl "metadata" (Types.alias "metadata");
          lbl_decl "markdown" Types.string;
        ])
  in
  record :: yaml_types |> List.rev
