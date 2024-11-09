type t = {
  number_handling : [ `String | `Infer_integers ];
  with_parsers : string option;
}

let default = { number_handling = `Infer_integers; with_parsers = None }
