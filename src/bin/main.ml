type kind = [ `Json | `Yaml | `Jmd | `Unknown of string ]
type src = File of kind * string | Source of string | Stdin

let extension_opt s =
  try Some (Filename.extension s) with Invalid_argument _ -> None

let make_type ~fname ~parser ~conv =
  let json = In_channel.with_open_bin fname parser in
  let tds = conv json in
  Ppxlib.Ast_helper.Str.type_ Nonrecursive tds

let main () =
  let fname = Sys.argv.(1) in
  let src =
    match (fname, extension_opt fname) with
    | "-", _ -> Stdin
    | _, Some ".json" -> File (`Json, fname)
    | _, Some (".yaml" | ".yml") -> File (`Yaml, fname)
    | _, Some ".md" -> File (`Jmd, fname)
    | _, Some ext -> failwith ("Unsupported extension: " ^ ext)
    | _, None -> Source fname
  in
  match src with
  | File (`Json, fname) ->
      let s =
        make_type ~fname ~parser:Ezjsonm.value_from_channel
          ~conv:Typetools.Json.to_type
      in
      Ppxlib.Pprintast.structure_item Format.std_formatter s
  | File (`Yaml, fname) ->
      let s =
        make_type ~fname
          ~parser:(fun ic -> In_channel.input_all ic |> Yaml.of_string_exn)
          ~conv:Typetools.Yml.to_type
      in
      Ppxlib.Pprintast.structure_item Format.std_formatter s
  | File (`Jmd, fname) ->
      let s =
        make_type ~fname
          ~parser:(fun ic ->
            In_channel.input_all ic |> Jekyll_format.of_string_exn)
          ~conv:Typetools.Jmd.to_type
      in
      Ppxlib.Pprintast.structure_item Format.std_formatter s
  | File (`Unknown s, _) -> failwith ("Unknown: " ^ s)
  | Stdin -> failwith "TODO"
  | Source _ -> failwith "TODO source"

let () = main ()
