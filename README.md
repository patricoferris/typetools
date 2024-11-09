typetools
---------

A simple CLI tool for generating OCaml types from raw data. 

Supported formats:

 - JSON
 - Yaml
 - Jekyll Format (Yaml frontmatter + Markdown)

## Examples

Typetools is supposed to be used once to help quickly get you started with
some types for your data.

```sh
$ echo "{ \"name\": \"Alice\", \"age\": 42 }" > example.json
$ typetools type example.json
type nonrec t = {
  name: string ;
  age: int }
```

Sometimes it is not possible to extract a type from some data for OCaml. For example,
heterogeneous lists. 

```sh
$ cat > example.yml << EOF \
> person: \
>   name: "alice" \
>   age: 42 \
> hlist: \
>   - "a string" \
>   - 1.2345 \
> EOF
$ typetools type --derivers example.yml
type nonrec t1 = {
  name: string ;
  age: int }[@@deriving yaml]
type nonrec t = {
  person: t1 ;
  hlist: Yaml.value list }[@@deriving yaml]
```

This example also show's how we can use the tool to add derivers and generate
some glue code for quick parsers.

Jekyll formatted files will have a metadata type alongside the markdown content.


```sh
$ cat > example.md << EOF \
> ---\
> title: "A new blogpost" \
> date: 2024-10-07 \
> ---\
> # Welcome! \
> EOF
$ typetools type --derivers example.md
type nonrec metadata = {
  title: string ;
  date: string }[@@deriving yaml]
type nonrec t = {
  metadata: metadata ;
  markdown: string }
let of_string s =
  let jk = Jekyll_format.of_string s in
  let markdown = Result.map Jekyll_format.body jk in
  let fields =
    Result.map Jekyll_format.fields_to_yaml
      (Result.map Jekyll_format.fields jk) in
  let metadata = Result.bind fields metadata_of_yaml in
  match (markdown, metadata) with
  | (Ok markdown, Ok metadata) -> Ok { metadata; markdown }
  | (Error (`Msg m1), Error (`Msg m2)) -> Error (`Msg (m1 ^ (" " ^ m2)))
  | ((Error _ as e), _) | (_, (Error _ as e)) -> e
```
