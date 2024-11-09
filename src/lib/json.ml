open Common

type t = Ezjsonm.value

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

let rec to_core_type ?default_type (config : Config.t) = function
  | `String _ -> Some Types.string
  | `Float _ -> (
      match config.number_handling with
      | `Infer_integers -> Some Types.int
      | `String -> Some Types.string)
  | `Bool _ -> Some Types.bool
  | `A (v :: vs) -> (
      match
        ( List.for_all (is_same_shape_as v) vs,
          default_type,
          to_core_type ?default_type config v )
      with
      | true, _, Some c -> Some (Types.list c)
      | false, Some d, _ -> Some (Types.list d)
      | false, None, _ ->
          failwith
            "Types are not the same in the list, and no default type given"
      | _, _, None -> None)
  | _ -> None

let id =
  let i = ref 0 in
  fun () ->
    incr i;
    string_of_int !i

let with_deriving ~config t =
  match config.Config.with_parsers with
  | None -> t
  | Some ppx -> with_ppx ~ppx t

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
      let make_new_type key v =
        let new_id = id () in
        let new_name = "t" ^ new_id in
        let new_types =
          to_type_aux ~config ~name:new_name ~default_type ~acc:[]
            (v :> Ezjsonm.value)
        in
        let lbl = lbl_decl key (Types.alias new_name) in
        (Some new_types, lbl)
      in
      let make_label acc (key, v) =
        match v with
        | `O _ -> make_new_type key v :: acc
        | v -> (
            match
              to_core_type ~default_type:(Types.alias default_type) config v
            with
            | Some c -> (None, lbl_decl key c) :: acc
            | None -> make_new_type key v :: acc)
      in
      let lbls = List.fold_left make_label [] assoc |> List.rev in
      let new_types = List.filter_map fst lbls |> List.concat in
      let lbls = List.map snd lbls in
      let ts =
        with_deriving ~config (type_decl ~name (`Record lbls)) :: new_types
        |> List.rev
      in
      ts @ acc
  | `A [] -> failwith "Cannot infer a type for an empty list"
  | `A (v :: values) -> (
      let same_type = List.for_all (is_same_shape_as v) values in
      if not same_type then
        let v = Types.list (Types.alias default_type) in
        let t = with_deriving ~config @@ type_decl ~name (`Built_in v) in
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
              with_deriving ~config
              @@ type_decl ~name (`Built_in (Types.list (Types.alias new_name)))
            in
            (List.rev @@ (t :: new_types)) @ acc
        | _ -> (
            match
              to_core_type ~default_type:(Types.alias default_type) config v
            with
            | Some c ->
                (with_deriving ~config @@ type_decl ~name (`Built_in c)) :: acc
            | None -> assert false))
  | _ -> failwith "Unsupported Type"

let to_type ?config ?name t =
  (to_type_aux ?config ?name ~default_type:"Ezjsonm.value" ~acc:[] t, [])
