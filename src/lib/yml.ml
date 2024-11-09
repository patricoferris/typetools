type t = Yaml.value

let to_type ?(config = Config.default) ?(name = "t") (v : Yaml.value) =
  (Json.to_type_aux ~config ~name ~default_type:"Yaml.value" ~acc:[] v, [])
