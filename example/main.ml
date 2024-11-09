let () =
  let blog =
    In_channel.with_open_bin "blog.md" In_channel.input_all |> Blog.of_string
  in
  ignore blog
