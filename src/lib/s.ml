module type Tool = sig
  type t
  (** The format of the tool (e.g. JSON, YAML...) *)

  val to_type :
    ?config:Config.t ->
    ?name:string ->
    t ->
    Ppxlib.type_declaration list * Ppxlib.structure
  (** Construct a set of types for a given piece of data using the optional
      configuration file. See {! Config.default}. If no [name] is given
      [t] will be used.

      For example, the following Json:

      {[
        { "a": "b", "c": { "d" : 1 } }
      ]}

      Produces the following types:

      {[
        type t1 = { d : int } 
        type t = { a : string; c : t1 }
      ]}

      The function may return extra structure items that should be appended
      to the end of the file after the types.
      *)
end
