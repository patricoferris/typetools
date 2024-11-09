module Config = Config
module Json : S.Tool with type t = Ezjsonm.value
module Yml : S.Tool with type t = Yaml.value
module Jmd : S.Tool with type t = Jekyll_format.t
