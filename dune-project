(lang dune 3.16)

(using mdx 0.4)

(name typetools)

(generate_opam_files true)

(source
 (github patricoferris/typetools))

(authors "Patrick Ferris")

(maintainers "patrick@sirref.org")

(license MIT)


(package
 (name typetools)
 (synopsis "Tools for OCaml types")
 (description "Generate OCaml types from example data")
 (depends 
   (ocaml (>= "4.14.0")) 
   dune
   ppxlib
   ezjsonm
   yaml
   dune-build-info
   (ppx_deriving_yaml :with-test)
   (jekyll-format (>= "0.2.0"))
   (mdx :with-test)
  )
 (tags
  (topics ppx)))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/reference/dune-project/index.html
