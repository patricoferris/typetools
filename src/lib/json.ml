open Common

type t = Ezjsonm.value

let to_core_type (config : Config.t) = function
  | `String _ -> Types.string
  | `Float _ -> (
      match config.number_handling with
      | `Infer_integers -> Types.int
      | `String -> Types.string)
  | `Bool _ -> Types.bool
  | _ -> assert false

let rec is_same_shape_as v v' =
  match (v, v') with
  | `String _, `String _ | `Float _, `Float _ | `Bool _, `Bool _ | `Null, `Null
    ->
      true
  | `A a, `A b -> List.for_all2 is_same_shape_as a b
  | `O a, `O b ->
      List.for_all2
        (fun (k, v) (k', v') -> String.equal k k' && is_same_shape_as v v')
        a b
  | _ -> false

let id =
  let i = ref 0 in
  fun () ->
    incr i;
    string_of_int !i

let rec to_type_aux :
    ?config:Config.t ->
    ?name:string ->
    default_type:string ->
    acc:Ppxlib.type_declaration list ->
    t ->
    Ppxlib.type_declaration list =
 fun ?(config = Config.default) ?(name = "t") ~default_type ~acc -> function
  | `String _ -> type_decl ~name (`Built_in Types.string) :: acc
  | `Float _ -> (
      match config.number_handling with
      | `Infer_integers -> type_decl ~name (`Built_in Types.int) :: acc
      | `String -> type_decl ~name (`Built_in Types.string) :: acc)
  | `O [] -> failwith "Cannot infer a type for an empty object"
  | `O assoc ->
      let make_label acc (key, v) =
        match v with
        | #Ezjsonm.t ->
            let new_id = id () in
            let new_name = "t" ^ new_id in
            let new_types =
              to_type_aux ~config ~name:new_name ~default_type ~acc:[]
                (v :> Ezjsonm.value)
            in
            let lbl = lbl_decl key (Types.alias new_name) in
            (Some new_types, lbl) :: acc
        | _ -> (None, lbl_decl key (to_core_type config v)) :: acc
      in
      let lbls = List.fold_left make_label [] assoc |> List.rev in
      let new_types = List.filter_map fst lbls |> List.concat in
      let lbls = List.map snd lbls in
      let ts = type_decl ~name (`Record lbls) :: new_types |> List.rev in
      ts @ acc
  | `A [] -> failwith "Cannot infer a type for an empty list"
  | `A (v :: values) -> (
      let same_type = List.for_all (is_same_shape_as v) values in
      if not same_type then
        let v = Types.list (Types.alias default_type) in
        let t = type_decl ~name (`Built_in v) in
        t :: acc
      else
        match v with
        | #Ezjsonm.t ->
            let new_id = id () in
            let new_name = "t" ^ new_id in
            let new_types =
              to_type_aux ~config ~name:new_name ~default_type ~acc:[]
                (v :> Ezjsonm.value)
            in
            let t =
              type_decl ~name (`Built_in (Types.list (Types.alias new_name)))
            in
            (List.rev @@ (t :: new_types)) @ acc
        | _ ->
            let c = Types.list (to_core_type config v) in
            type_decl ~name (`Built_in c) :: acc)
  | _ -> failwith "TODO"

let to_type ?config ?name t =
  to_type_aux ?config ?name ~default_type:"Ezjsonm.value" ~acc:[] t