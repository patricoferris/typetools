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
$ typetools example.json
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
$ typetools example.yml
type nonrec t2 = Yaml.value list
and t1 = {
  name: string ;
  age: int }
and t = {
  person: t1 ;
  hlist: t2 }
```

Jekyll formatted files will have a metadata type alongside the markdown content.


```sh
$ cat > example.md << EOF \
> ---\
> title: "A new blogpost" \
> date: 2024-10-07 \
> ---\
> # Welcome! \
> EOF
$ typetools example.md
type nonrec metadata = {
  title: string ;
  date: string }
and t = {
  metadata: metadata ;
  markdown: string }
```
