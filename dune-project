(lang dune 3.0)
(name hl-protocol)
(generate_opam_files true)
(license MIT)
(source (github winterchill-trading/hl-protocol))
(package
 (name hl-protocol)
 (synopsis "Hyperliquid wire types and JSON codecs")
 (depends
  (ocaml (>= 5.2))
  dune
  core
  ppx_jane
  ppx_yojson_conv
  yojson))
