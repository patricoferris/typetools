type kind = Json | Yaml | Jmd
type src = File of string | Stdin

let extension_opt s =
  try Some (Filename.extension s) with Invalid_argument _ -> None

let make_type ~src ~parser ~conv =
  let json =
    match src with
    | File path -> In_channel.with_open_bin path parser
    | Stdin -> parser stdin
  in
  let tds, strs = conv json in
  let types =
    List.map (fun v -> Ppxlib.Ast_helper.Str.type_ Nonrecursive [ v ]) tds
  in
  types @ strs

open Cmdliner

let path =
  Arg.(
    value
    @@ pos 0 (some file) None
    @@ info ~doc:"Input file path, defaulting to stdin" [])

let kind =
  Arg.(
    value
    @@ opt (enum [ ("json", Json); ("yaml", Yaml); ("jekyll", Jmd) ]) Json
    @@ info ~doc:"What data format to treat the input data as." [ "kind" ])

let derivers =
  Arg.(
    value @@ flag
    @@ info
         ~doc:"Whether or not to generate parsers using ppx and some glue code"
         [ "derivers" ])

let main () fname kind derivers =
  let src, kind =
    match fname with
    | None -> (Stdin, kind)
    | Some fname -> (
        match extension_opt fname with
        | Some ".json" -> (File fname, Json)
        | Some (".yaml" | ".yml") -> (File fname, Yaml)
        | Some ".md" -> (File fname, Jmd)
        | Some ext -> failwith ("Unsupported extension: " ^ ext)
        | _ -> (Stdin, kind))
  in
  match kind with
  | Json ->
      let config =
        if derivers then
          { Typetools.Config.default with with_parsers = Some "yojson" }
        else Typetools.Config.default
      in
      let s =
        make_type ~src ~parser:Ezjsonm.value_from_channel
          ~conv:(Typetools.Json.to_type ~config)
      in
      Ppxlib.Pprintast.structure Format.std_formatter s
  | Yaml ->
      let config =
        if derivers then
          { Typetools.Config.default with with_parsers = Some "yaml" }
        else Typetools.Config.default
      in
      let s =
        make_type ~src
          ~parser:(fun ic -> In_channel.input_all ic |> Yaml.of_string_exn)
          ~conv:(Typetools.Yml.to_type ~config)
      in
      Ppxlib.Pprintast.structure Format.std_formatter s
  | Jmd ->
      let config =
        if derivers then
          { Typetools.Config.default with with_parsers = Some "yaml" }
        else Typetools.Config.default
      in
      let s =
        make_type ~src
          ~parser:(fun ic ->
            In_channel.input_all ic |> Jekyll_format.of_string_exn)
          ~conv:(Typetools.Jmd.to_type ~config)
      in
      Ppxlib.Pprintast.structure Format.std_formatter s

let version =
  match Build_info.V1.version () with
  | None -> "n/a"
  | Some v -> Build_info.V1.Version.to_string v

let setup =
  let style_renderer = Fmt_cli.style_renderer () in
  Term.(
    const (fun style_renderer level ->
        Fmt_tty.setup_std_outputs ?style_renderer ();
        Logs.set_level level;
        Logs.set_reporter (Logs_fmt.reporter ()))
    $ style_renderer $ Logs_cli.level ())

let type_term = Term.(const main $ setup $ path $ kind $ derivers)
let type_cmd = Cmd.v (Cmd.info "type" ~version) type_term
let cmd = Cmd.group ~default:type_term (Cmd.info "typetools") [ type_cmd ]

let () =
  let () = Printexc.record_backtrace true in
  match Cmd.eval ~catch:false cmd with
  | i -> exit i
  | (exception Failure s) | (exception Invalid_argument s) ->
      Printexc.print_backtrace stderr;
      Fmt.epr "\n%a %s\n%!" Fmt.(styled `Red string) "[ERROR]" s;
      exit Cmd.Exit.cli_error
  | exception e ->
      Printexc.print_backtrace stderr;
      Fmt.epr "\n%a\n%!" Fmt.exn e;
      exit Cmd.Exit.some_error
